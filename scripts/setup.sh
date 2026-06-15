#!/bin/bash
set -eo pipefail

GATEWAY_API_VERSION="v1.3.0"   # standard channel CRDs — confirm against NGF 2.6.x supported version
NGF_CHART_VERSION="2.6.3"      # oci://ghcr.io/nginx/charts/nginx-gateway-fabric

function createKindCluster() {
    routing="${1:-ingress}"
    dirname=$(dirname "$0")
    if [ -z "$dirname" ]; then
        dirname="."
    fi
    if [ "$routing" = "gateway" ]; then
        config="$dirname/cluster-gateway.yaml"
    else
        config="$dirname/cluster.yaml"
    fi
    kind create cluster --name bitwarden --config "$config"
}

function setupCluster() {
    routing="${1:-ingress}"
    installation_id=$(uuidgen)
    echo $installation_id
    installation_key=$(openssl rand -base64 12)
    sa_password=$(openssl rand -base64 12)
    cert_pass=$(openssl rand -base64 12)

    #TLS setup
    echo "Creating root CA cert"
    openssl req -x509 -sha256 -days 1 -newkey rsa:2048 -keyout rootCA.key -out rootCA.crt -subj "/CN=Bitwarden Ingress" --passout pass:$cert_pass
    echo "Generating TLS key"
    openssl genrsa -out bitwarden.localhost.key 2048
    echo "Generating TLS cert"
    openssl req -key bitwarden.localhost.key -new -out bitwarden.localhost.csr --passin pass:$cert_pass -subj "/CN=bitwarden.localhost"

    echo "Signing TLS cert"
    cat > bitwarden.localhost.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
subjectAltName = @alt_names
[alt_names]
DNS.1 = bitwarden.localhost
EOF

    openssl x509 -req -CA rootCA.crt -CAkey rootCA.key -in bitwarden.localhost.csr -out bitwarden.localhost.crt -days 1 -CAcreateserial -extfile bitwarden.localhost.ext  --passin pass:$cert_pass

    echo "Exporting TLS certs to PEM"
    openssl x509 -in bitwarden.localhost.crt -out bitwarden.localhost.pem --passin pass:$cert_pass
    openssl x509 -in rootCA.crt -out rootCA.pem --passin pass:$cert_pass

    sudo echo "127.0.0.1 bitwarden.localhost" | sudo tee -a /etc/hosts

    #Namespace
    kubectl create ns bitwarden

    kubectl config set-context --current --namespace=bitwarden

    #Secrets
    kubectl create secret generic custom-secret \
    --from-literal=globalSettings__installation__id=$installation_id \
    --from-literal=globalSettings__installation__key=$installation_key \
    --from-literal=globalSettings__mail__smtp__username="REPLACE" \
    --from-literal=globalSettings__mail__smtp__password="REPLACE" \
    --from-literal=globalSettings__yubico__clientId="REPLACE" \
    --from-literal=globalSettings__yubico__key="REPLACE" \
    --from-literal=SA_PASSWORD=$sa_password

    kubectl create secret tls tls-secret --cert=bitwarden.localhost.pem --key=bitwarden.localhost.key

    if [ "$routing" = "gateway" ]; then
        setupGateway
    else
        setupIngress
    fi
}

function setupIngress() {
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
}

function setupGateway() {
    # 1. Gateway API standard-channel CRDs (pinned)
    kubectl apply -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml"
    kubectl wait --for=condition=Established --timeout=60s \
        crd/gateways.gateway.networking.k8s.io \
        crd/gatewayclasses.gateway.networking.k8s.io \
        crd/httproutes.gateway.networking.k8s.io

    # 2. NGF control plane + NodePort data plane (chart auto-creates GatewayClass "nginx")
    helm install ngf oci://ghcr.io/nginx/charts/nginx-gateway-fabric \
        --version "${NGF_CHART_VERSION}" -n nginx-gateway --create-namespace \
        --set nginx.service.type=NodePort \
        --set-json 'nginx.service.nodePorts=[{"port":30080,"listenerPort":80},{"port":30443,"listenerPort":443}]' \
        --wait --timeout 300s

    # 3. TLS secret in the Gateway's namespace (default) — certificateRefs resolve locally
    kubectl create secret tls tls-secret -n default \
        --cert=bitwarden.localhost.pem --key=bitwarden.localhost.key

    # 4. Gateway referencing the chart-created "nginx" GatewayClass; allow cross-ns routes
    kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ci-gateway
  namespace: default
spec:
  gatewayClassName: nginx
  listeners:
  - name: https
    protocol: HTTPS
    port: 443
    hostname: bitwarden.localhost
    tls:
      mode: Terminate
      certificateRefs:
      - kind: Secret
        name: tls-secret
    allowedRoutes:
      namespaces:
        from: All
EOF

    # 5. Real readiness gate — data-plane NodePort Service exists once Programmed
    kubectl wait --for=condition=Programmed --timeout=180s -n default gateway/ci-gateway
}

function installSelfHost() {
    routing="${1:-ingress}"
    if [ "$routing" = "gateway" ]; then
        values="charts/self-host/ci/test-values-gateway.yaml"
    else
        values="charts/self-host/ci/test-values.yaml"
    fi
    time helm install self-host charts/self-host -n bitwarden -f "$values" --timeout 500s --wait
}

if [ "$1" = "create-cluster" ]; then
    createKindCluster "$2"
elif [ "$1" = "setup-cluster" ]; then
    setupCluster "$2"
elif [ "$1" = "install-self-host" ]; then
    installSelfHost "$2"
elif [ "$1" = "all" ]; then
    createKindCluster "$2"
    setupCluster "$2"
    installSelfHost "$2"
else
    echo "Usage: $0 {all|create-cluster|setup-cluster|install-self-host} [ingress|gateway]"
    exit 1
fi