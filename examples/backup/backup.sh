#!/bin/bash
kubectl delete job -n bitwarden -l app=bitwarden-backup
kubectl apply -n bitwarden -f $(dirname "$0")/backup-job.yaml
kubectl wait pod --for=condition=complete -l app=bitwarden-backup --timeout=1h
kubectl logs -l app=bitwarden-backup -n bitwarden -f