#!/bin/bash
namespace="bitwarden"

kubectl delete job -n $namespace -l app=bitwarden-restore
kubectl apply -n $namespace -f $(dirname "$0")/restore-job.yaml
echo -n "Starting job..."
while [[ $(kubectl get pods -n $namespace -l app=bitwarden-restore -o jsonpath="{.items[*].status.containerStatuses[*].ready}") != "true" ]]; do echo -n "..."; sleep 1; done
echo "..."
echo "Restoring..."
kubectl logs -l app=bitwarden-restore -n $namespace -f