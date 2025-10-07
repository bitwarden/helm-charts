#!/usr/bin/env bash
apt-get update
apt-get install -y kubernetes-client  # kubectl
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
kind delete cluster --name helm-charts && kind create cluster --name helm-charts --config .devcontainer/common/kind-config.yaml

