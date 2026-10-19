#!/bin/bash
# sm-operator failure-path tests against an installed operator.
# Usage: bad-token | replaced-token | all | deleted-secret | cleanup
# deleted-secret is destructive and needs AUTH_TOKEN with write access, API_URL and IDENTITY_URL.
set -eo pipefail

NAMESPACE="${NAMESPACE:-bitwarden}"
OPERATOR_NAMESPACE="${OPERATOR_NAMESPACE:-$NAMESPACE}"
TIMEOUT="${TIMEOUT:-90}"
# Must match the operator's bwSecretsManagerRefreshInterval.
REFRESH_INTERVAL="${REFRESH_INTERVAL:-300}"
# Defaults match .github/config/sample-bw-secret.yaml.
ORG_ID="${ORG_ID:-0cbc2036-7ee5-420f-8a13-b40a01153cba}"
read -r -a SECRET_IDS <<< "${SECRET_IDS:-af795aef-1605-4b51-92c0-b40c0130ff5f d489d8d3-a7d6-4820-a3a8-b40c0131106d 431a070e-35b1-4ed1-b8ac-b40c01311e8d}"

created=()

function applyBitwardenSecret() {
    name="$1"
    auth_secret="$2"
    target_secret="$3"
    kubectl apply -n "$NAMESPACE" -f - << EOF
apiVersion: k8s.bitwarden.com/v1
kind: BitwardenSecret
metadata:
  name: $name
spec:
  organizationId: "$ORG_ID"
  secretName: $target_secret
  authToken:
    secretName: $auth_secret
    secretKey: token
  map:
    - bwSecretId: ${SECRET_IDS[0]}
      secretKeyName: test__secret__1
    - bwSecretId: ${SECRET_IDS[1]}
      secretKeyName: test__secret__2
    - bwSecretId: ${SECRET_IDS[2]}
      secretKeyName: test__secret__3
EOF
    created+=("$name")
}

function setAuthToken() {
    auth_secret="$1"
    token="$2"
    kubectl create secret generic "$auth_secret" -n "$NAMESPACE" --from-literal=token="$token" \
        --dry-run=client -o yaml | kubectl apply -f -
}

function conditionField() {
    name="$1"
    type="$2"
    field="$3"
    kubectl get bitwardensecret "$name" -n "$NAMESPACE" \
        -o jsonpath="{.status.conditions[?(@.type==\"$type\")].$field}"
}

# FailedSync is set with status "False", so `kubectl wait --for=condition` never matches it.
function waitForCondition() {
    name="$1"
    type="$2"
    reason="$3"
    after="${4:-}"
    for _ in $(seq "$TIMEOUT"); do
        if [ "$(conditionField "$name" "$type" reason)" = "$reason" ]; then
            changed="$(conditionField "$name" "$type" lastTransitionTime)"
            if [ -z "$after" ] || [[ "$changed" > "$after" ]]; then
                return 0
            fi
        fi
        sleep 1
    done
    echo "::error::$name: no $type condition with reason $reason within ${TIMEOUT}s."
    return 1
}

function secretFingerprint() {
    data="$(kubectl get secret "$1" -n "$NAMESPACE" -o json | jq -S -c '.data')"
    echo "$(jq -r 'keys | join(",")' <<< "$data") $(sha256sum <<< "$data" | cut -c1-16)"
}

function diagnostics() {
    echo "*****FAILURE-PATH DIAGNOSTICS*****"
    for name in "${created[@]}"; do
        echo "--- $name status"
        kubectl get bitwardensecret "$name" -n "$NAMESPACE" -o jsonpath='{.status}' || true
        echo
    done
    echo "--- Secrets"
    kubectl get secrets -n "$NAMESPACE" || true
    echo "--- Operator logs (last 50 lines)"
    kubectl logs -n "$OPERATOR_NAMESPACE" -l app.kubernetes.io/name=sm-operator -c manager --tail=50 || true
}

function badToken() {
    echo "*****BAD TOKEN: MALFORMED*****"
    setAuthToken bw-auth-token-malformed "not-an-access-token"
    applyBitwardenSecret bitwardensecret-malformed-token bw-auth-token-malformed bw-malformed-token-secret
    waitForCondition bitwardensecret-malformed-token FailedSync ReconciliationFailed
    echo "FailedSync: $(conditionField bitwardensecret-malformed-token FailedSync message)"

    echo "*****BAD TOKEN: UNKNOWN*****"
    unknown_token="0.$(uuidgen).$(openssl rand -hex 15):$(openssl rand -base64 16)"
    setAuthToken bw-auth-token-unknown "$unknown_token"
    applyBitwardenSecret bitwardensecret-unknown-token bw-auth-token-unknown bw-unknown-token-secret
    waitForCondition bitwardensecret-unknown-token FailedSync ReconciliationFailed
    message="$(conditionField bitwardensecret-unknown-token FailedSync message)"
    echo "FailedSync: $message"
    # Every failure shares one reason; make sure the server actually rejected the token.
    if [[ "$message" != *"Received error message from server"* ]]; then
        echo "::error::bitwardensecret-unknown-token failed, but not because the server rejected the token."
        return 1
    fi

    for target in bw-malformed-token-secret bw-unknown-token-secret; do
        if kubectl get secret "$target" -n "$NAMESPACE" > /dev/null 2>&1; then
            echo "::error::$target was created despite an invalid token."
            return 1
        fi
    done
    for name in bitwardensecret-malformed-token bitwardensecret-unknown-token; do
        if [ -n "$(conditionField "$name" SuccessfulSync reason)" ]; then
            echo "::error::$name reports SuccessfulSync with an invalid token."
            return 1
        fi
    done
    # Failed objects keep retrying logins until deleted.
    kubectl delete bitwardensecret -n "$NAMESPACE" bitwardensecret-malformed-token bitwardensecret-unknown-token
    echo "*****BAD TOKEN OK*****"
}

function replacedToken() {
    if [ -z "$AUTH_TOKEN" ]; then
        echo "::error::replaced-token needs AUTH_TOKEN set to a valid access token."
        return 1
    fi

    echo "*****REPLACED TOKEN: INITIAL SYNC*****"
    setAuthToken bw-auth-token-replaced "$AUTH_TOKEN"
    applyBitwardenSecret bitwardensecret-replaced-token bw-auth-token-replaced bw-replaced-token-secret
    waitForCondition bitwardensecret-replaced-token SuccessfulSync ReconciliationComplete
    before="$(secretFingerprint bw-replaced-token-secret)"
    echo "Synced: $before"
    if [ "${before%% *}" != "test__secret__1,test__secret__2,test__secret__3" ]; then
        echo "::error::Initial sync produced unexpected keys: ${before%% *}"
        return 1
    fi

    echo "*****REPLACED TOKEN: INVALID TOKEN, FORCED RESYNC*****"
    started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    sleep 1
    setAuthToken bw-auth-token-replaced "0.$(uuidgen).$(openssl rand -hex 15):$(openssl rand -base64 16)"
    # Backdating the last sync forces an immediate resync.
    kubectl patch bitwardensecret bitwardensecret-replaced-token -n "$NAMESPACE" \
        --subresource=status --type=merge \
        -p '{"status":{"lastSuccessfulSyncTime":"2000-01-01T00:00:00Z"}}'
    waitForCondition bitwardensecret-replaced-token FailedSync ReconciliationFailed "$started"
    echo "FailedSync: $(conditionField bitwardensecret-replaced-token FailedSync message)"

    after="$(secretFingerprint bw-replaced-token-secret)"
    echo "After failure: $after"
    if [ "$after" != "$before" ]; then
        echo "::error::bw-replaced-token-secret changed after a failed sync."
        return 1
    fi
    echo "SuccessfulSync still reads: $(conditionField bitwardensecret-replaced-token SuccessfulSync status)"
    kubectl delete bitwardensecret -n "$NAMESPACE" bitwardensecret-replaced-token
    echo "*****REPLACED TOKEN OK*****"
}

function deleteUpstreamSecret() {
    secret_id="$1"
    rest="${AUTH_TOKEN#0.}"
    client_id="${rest%%.*}"
    rest="${rest#*.}"
    client_secret="${rest%%:*}"
    bearer="$(curl -sS -f "$IDENTITY_URL/connect/token" -d grant_type=client_credentials \
        -d scope=api.secrets --data-urlencode client_id="$client_id" \
        --data-urlencode client_secret="$client_secret" | jq -r '.access_token')"
    result="$(curl -sS -f -X POST "$API_URL/secrets/delete" -H "Authorization: Bearer $bearer" \
        -H 'Content-Type: application/json' -d "[\"$secret_id\"]")"
    if [ "$(jq -r '.data[0].error // ""' <<< "$result")" != "" ]; then
        echo "::error::Deleting $secret_id failed: $(jq -r '.data[0].error' <<< "$result")"
        return 1
    fi
}

function deletedSecret() {
    if [ -z "$AUTH_TOKEN" ] || [ -z "$API_URL" ] || [ -z "$IDENTITY_URL" ]; then
        echo "::error::deleted-secret needs AUTH_TOKEN (with write access), API_URL and IDENTITY_URL."
        return 1
    fi

    echo "*****DELETED SECRET: INITIAL SYNC*****"
    setAuthToken bw-auth-token-deletion "$AUTH_TOKEN"
    applyBitwardenSecret bitwardensecret-deletion bw-auth-token-deletion bw-deletion-secret
    waitForCondition bitwardensecret-deletion SuccessfulSync ReconciliationComplete
    synced="$(kubectl get bitwardensecret bitwardensecret-deletion -n "$NAMESPACE" \
        -o jsonpath='{.status.lastSuccessfulSyncTime}')"
    data="$(kubectl get secret bw-deletion-secret -n "$NAMESPACE" -o json | jq -S -c '.data')"
    keys="$(jq -r 'keys | join(",")' <<< "$data")"
    echo "Synced at $synced: $keys"
    if [ "$keys" != "test__secret__1,test__secret__2,test__secret__3" ]; then
        echo "::error::Initial sync produced unexpected keys: $keys"
        return 1
    fi
    kept_before="$(jq -c '{test__secret__1, test__secret__2}' <<< "$data" | sha256sum | cut -c1-16)"

    echo "*****DELETED SECRET: DELETE UPSTREAM, WAIT FOR SCHEDULED SYNC*****"
    deleteUpstreamSecret "${SECRET_IDS[2]}"
    echo "Deleted ${SECRET_IDS[2]} at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    # Only a scheduled delta sync shows whether the deletion is picked up.
    resynced=""
    for _ in $(seq $((REFRESH_INTERVAL + 60))); do
        resynced="$(kubectl get bitwardensecret bitwardensecret-deletion -n "$NAMESPACE" \
            -o jsonpath='{.status.lastSuccessfulSyncTime}')"
        if [ "$resynced" != "$synced" ] || [ -n "$(conditionField bitwardensecret-deletion FailedSync reason)" ]; then
            break
        fi
        sleep 1
    done
    if [ "$resynced" = "$synced" ]; then
        echo "::error::No successful resync within $((REFRESH_INTERVAL + 60))s of the deletion."
        return 1
    fi

    data="$(kubectl get secret bw-deletion-secret -n "$NAMESPACE" -o json | jq -S -c '.data')"
    keys="$(jq -r 'keys | join(",")' <<< "$data")"
    echo "Resynced at $resynced: $keys"
    if [ "$keys" != "test__secret__1,test__secret__2" ]; then
        echo "::error::Expected test__secret__3 to be dropped and the others kept, got: $keys"
        return 1
    fi
    if [ "$(jq -c '{test__secret__1, test__secret__2}' <<< "$data" | sha256sum | cut -c1-16)" != "$kept_before" ]; then
        echo "::error::The remaining keys changed value after the deletion."
        return 1
    fi
    if [ -n "$(conditionField bitwardensecret-deletion FailedSync reason)" ]; then
        echo "::error::Unexpected FailedSync: $(conditionField bitwardensecret-deletion FailedSync message)"
        return 1
    fi
    if [ "$(conditionField bitwardensecret-deletion SuccessfulSync status)" != "True" ]; then
        echo "::error::SuccessfulSync is not True after the resync."
        return 1
    fi
    kubectl delete bitwardensecret -n "$NAMESPACE" bitwardensecret-deletion
    echo "*****DELETED SECRET OK*****"
}

function cleanup() {
    kubectl delete bitwardensecret -n "$NAMESPACE" --ignore-not-found \
        bitwardensecret-malformed-token bitwardensecret-unknown-token bitwardensecret-replaced-token \
        bitwardensecret-deletion
    kubectl delete secret -n "$NAMESPACE" --ignore-not-found \
        bw-auth-token-malformed bw-auth-token-unknown bw-auth-token-replaced bw-auth-token-deletion
}

function onExit() {
    status=$?
    if [ "$status" -ne 0 ]; then
        diagnostics
    fi
}

trap onExit EXIT

case "$1" in
    bad-token)
        badToken
        ;;
    replaced-token)
        replacedToken
        ;;
    all)
        badToken
        replacedToken
        ;;
    deleted-secret)
        deletedSecret
        ;;
    cleanup)
        cleanup
        ;;
    *)
        echo "Usage: $0 bad-token|replaced-token|all|deleted-secret|cleanup"
        exit 1
        ;;
esac
