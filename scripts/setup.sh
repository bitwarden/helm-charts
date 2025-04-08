#!/bin/sh
set -e

function createKindCluster() {
    dirname=$(dirname "$0")
    if [ -z "$dirname" ]; then
        dirname="."
    fi
    kind create cluster --name bitwarden --config $dirname/cluster.yaml
}

function setupCluster() {
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

    #Ingress
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
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
}

function installSelfHost() {
    time ct install --helm-extra-set-args '--timeout 500s'  --target-branch main --skip-clean-up --namespace bitwarden
}

if [ "$1" = "create-cluster" ]; then
    createKindCluster
elif [ "$1" = "setup-cluster" ]; then
    setupCluster
elif [ "$1" = "install-self-host" ]; then
    installSelfHost
elif [ "$1" = "all" ]; then
    createKindCluster
    setupCluster
    installSelfHost
else
    echo "Usage: $0 {all|create-cluster|setup-cluster|install-self-host}"
    exit 1
fi