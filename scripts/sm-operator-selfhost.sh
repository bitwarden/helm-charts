#!/bin/bash
# Self-hosted Secrets Manager backend for sm-operator-failure-paths.sh. Run from the repo root
# after `setup.sh setup-cluster ingress postgres` and `setup.sh install-self-host ingress postgres`.
# Usage: build-seeder <server-dir> | deploy-seeder | seed <env-file> | install-operator
set -eo pipefail

NAMESPACE="bitwarden"
OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-sm-operator}"
SEEDER_IMAGE="${SEEDER_IMAGE:-seederapi:local}"
SEEDER_PORT="${SEEDER_PORT:-15000}"
# The operator's minimum.
REFRESH_INTERVAL="${REFRESH_INTERVAL:-180}"

function buildSeeder() {
    server_dir="$1"
    if [ ! -f "$server_dir/util/SeederApi/Dockerfile" ]; then
        echo "::error::No util/SeederApi/Dockerfile under '$server_dir'."
        exit 1
    fi
    # Upstream's CARGO_TARGET_DIR leaves libsdk.so out of the image.
    dockerfile="$(mktemp)"
    sed '/export CARGO_TARGET_DIR=/d' "$server_dir/util/SeederApi/Dockerfile" > "$dockerfile"
    docker build -f "$dockerfile" -t "$SEEDER_IMAGE" --platform linux/amd64 "$server_dir"
    rm -f "$dockerfile"
    if ! docker run --rm --entrypoint test "$SEEDER_IMAGE" -f /app/runtimes/linux-x64/native/libsdk.so; then
        echo "::error::$SEEDER_IMAGE has no libsdk.so."
        exit 1
    fi
}

function deploySeeder() {
    cluster_name="$(kind get clusters | head -n1)"
    kind load docker-image "$SEEDER_IMAGE" --name "$cluster_name"

    kubectl create secret generic seederapi-auth -n "$NAMESPACE" \
        --from-literal=username=seeder --from-literal=password="$(openssl rand -hex 24)"

    kubectl apply -n "$NAMESPACE" -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: seederapi
  labels:
    app: seederapi
spec:
  containers:
    - name: seederapi
      image: $SEEDER_IMAGE
      imagePullPolicy: Never
      ports:
        - containerPort: 5000
      env:
        - name: ASPNETCORE_ENVIRONMENT
          value: Development
        - name: globalSettings__selfHosted
          value: "true"
        - name: globalSettings__databaseProvider
          value: postgres
        - name: globalSettings__postgreSql__connectionString
          valueFrom:
            secretKeyRef: {name: custom-secret, key: globalSettings__postgreSql__connectionString}
        - name: globalSettings__installation__id
          valueFrom:
            secretKeyRef: {name: custom-secret, key: globalSettings__installation__id}
        - name: globalSettings__installation__key
          valueFrom:
            secretKeyRef: {name: custom-secret, key: globalSettings__installation__key}
        - name: seederSettings__Accounts__0__Username
          valueFrom:
            secretKeyRef: {name: seederapi-auth, key: username}
        - name: seederSettings__Accounts__0__Password
          valueFrom:
            secretKeyRef: {name: seederapi-auth, key: password}
      readinessProbe:
        httpGet:
          path: /alive
          port: 5000
EOF
    kubectl wait pod/seederapi -n "$NAMESPACE" --for=condition=Ready --timeout=180s
}

function seedScene() {
    template="$1"
    args="$2"
    if ! response="$(curl -sS --fail-with-body -X POST "http://localhost:$SEEDER_PORT/seed" \
        -H 'Content-Type: application/json' -H "Authorization: Basic $seeder_auth" \
        -H "X-Play-Id: $play_id" -d "{\"template\":\"$template\",\"arguments\":$args}")"; then
        echo "::error::Seeding $template failed: $response" >&2
        return 1
    fi
    jq -c '.result' <<< "$response"
}

function seed() {
    env_file="$1"
    if [ -z "$env_file" ]; then
        echo "Usage: $0 seed <env-file>"
        exit 1
    fi

    kubectl port-forward -n "$NAMESPACE" pod/seederapi "$SEEDER_PORT:5000" > /dev/null &
    forward_pid=$!
    trap 'kill "$forward_pid" 2> /dev/null || true' EXIT
    for _ in $(seq 30); do
        curl -s -o /dev/null "http://localhost:$SEEDER_PORT/alive" && break
        sleep 1
    done

    seeder_auth="$(kubectl get secret seederapi-auth -n "$NAMESPACE" -o json \
        | jq -j '.data | (.username | @base64d) + ":" + (.password | @base64d)' | base64 -w0)"
    play_id="sm-operator-$(date +%s)"

    user_id="$(seedScene SingleUserScene \
        "{\"email\":\"owner-$play_id@sm-operator.example\",\"password\":\"$(openssl rand -hex 16)\",\"emailVerified\":true}" \
        | jq -r '.userId')"
    # planType 20: EnterpriseAnnually.
    org="$(seedScene SingleOrganizationScene \
        "{\"ownerUserId\":\"$user_id\",\"planType\":20,\"name\":\"sm-operator\",\"domain\":\"sm-operator.example\",\"seats\":5,\"enableSecretsManager\":true,\"smSeats\":5,\"smServiceAccounts\":10}")"
    org_id="$(jq -r '.organizationId' <<< "$org")"
    org_key="$(jq -r '.organizationKeyB64' <<< "$org")"

    project_id="$(seedScene OrganizationProjectScene \
        "{\"organizationId\":\"$org_id\",\"organizationKeyB64\":\"$org_key\",\"name\":\"operator-test\"}" \
        | jq -r '.projectId')"
    secret_ids=()
    for i in 1 2 3; do
        secret_ids+=("$(seedScene OrganizationSecretScene \
            "{\"organizationId\":\"$org_id\",\"organizationKeyB64\":\"$org_key\",\"key\":\"test_secret_$i\",\"value\":\"$(openssl rand -hex 8)\",\"projectIds\":[\"$project_id\"]}" \
            | jq -r '.secretId')")
    done
    service_account_id="$(seedScene OrganizationServiceAccountScene \
        "{\"organizationId\":\"$org_id\",\"organizationKeyB64\":\"$org_key\",\"name\":\"operator\"}" \
        | jq -r '.serviceAccountId')"
    # granteeType 2: ServiceAccount, grantableType 0: Project.
    seedScene OrganizationAccessPolicyScene \
        "{\"organizationId\":\"$org_id\",\"grants\":[{\"granteeType\":2,\"granteeId\":\"$service_account_id\",\"grantableType\":0,\"grantableId\":\"$project_id\",\"read\":true,\"write\":true}]}" \
        > /dev/null
    access_token="$(seedScene OrganizationAccessTokenScene \
        "{\"organizationId\":\"$org_id\",\"organizationKeyB64\":\"$org_key\",\"serviceAccountId\":\"$service_account_id\",\"name\":\"operator\"}" \
        | jq -r '.accessToken')"

    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "::add-mask::$access_token"
    fi
    (
        umask 077
        {
            echo "ORG_ID=$org_id"
            echo "SECRET_IDS=${secret_ids[*]}"
            echo "AUTH_TOKEN=$access_token"
        } >> "$env_file"
    )
    echo "Seeded org $org_id, secrets ${secret_ids[*]}"
}

function installOperator() {
    if [ ! -f rootCA.pem ]; then
        echo "::error::rootCA.pem not found; run setup.sh setup-cluster from this directory first."
        exit 1
    fi
    kubectl create namespace "$OPERATOR_NAMESPACE"
    kubectl create configmap selfhost-ca -n "$OPERATOR_NAMESPACE" --from-file=rootCA.pem=rootCA.pem
    helm install sm-operator charts/sm-operator -n "$OPERATOR_NAMESPACE" \
        -f charts/sm-operator/ci/test-values.yaml \
        --set settings.bwApiUrlOverride=https://bitwarden.localhost/api \
        --set settings.bwIdentityUrlOverride=https://bitwarden.localhost/identity \
        --set settings.bwSecretsManagerRefreshInterval="$REFRESH_INTERVAL" \
        --wait --timeout 300s

    # The chart has no values for host aliases or a custom CA, and the operator requires HTTPS.
    ingress_ip="$(kubectl get service traefik -n traefik -o jsonpath='{.spec.clusterIP}')"
    deployment="$(kubectl get deployment -n "$OPERATOR_NAMESPACE" -l app.kubernetes.io/name=sm-operator -o name)"
    kubectl patch "$deployment" -n "$OPERATOR_NAMESPACE" --type=strategic -p "{
      \"spec\": {\"template\": {\"spec\": {
        \"hostAliases\": [{\"ip\": \"$ingress_ip\", \"hostnames\": [\"bitwarden.localhost\"]}],
        \"volumes\": [{\"name\": \"selfhost-ca\", \"configMap\": {\"name\": \"selfhost-ca\"}}],
        \"containers\": [{
          \"name\": \"manager\",
          \"env\": [{\"name\": \"SSL_CERT_FILE\", \"value\": \"/selfhost-ca/rootCA.pem\"}],
          \"volumeMounts\": [{\"name\": \"selfhost-ca\", \"mountPath\": \"/selfhost-ca\", \"readOnly\": true}]
        }]
      }}}
    }"
    kubectl rollout status "$deployment" -n "$OPERATOR_NAMESPACE" --timeout=180s
}

case "$1" in
    build-seeder)
        buildSeeder "$2"
        ;;
    deploy-seeder)
        deploySeeder
        ;;
    seed)
        seed "$2"
        ;;
    install-operator)
        installOperator
        ;;
    *)
        echo "Usage: $0 build-seeder <server-dir>|deploy-seeder|seed <env-file>|install-operator"
        exit 1
        ;;
esac
