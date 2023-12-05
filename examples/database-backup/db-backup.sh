#!/bin/bash
namespace="bitwarden"

kubectl delete job -n $namespace -l app=bitwarden-backup
kubectl apply -n $namespace -f $(dirname "$0")/backup-job.yaml
echo -n "Starting job..."
while [[ $(kubectl get pods -n $namespace -l app=bitwarden-backup -o jsonpath="{.items[*].status.containerStatuses[*].ready}") != "true" ]]; do echo -n "..."; sleep 1; done
echo "..."
echo "Backing up..."
kubectl logs -l app=bitwarden-backup -n $namespace -f
