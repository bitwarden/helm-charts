# K8S Deployment

## Requirements

- Kubectl
- Helm 3
- SSL cert and key
- SMTP server/account

---

## Steps
### Request Installation secrets
- Request an installation ID and key from https://bitwarden.com/host/

### Create config file
**NOTE:** Make sure you are in the `kubernetes-poc` directory.  
1. Run `helm show values bitwarden-chart > config.yaml`.
1. Edit the `config.yaml` file and fill out the values.  Required values that must be replaced:
    - certSSL
    - keySSL
    - domain
    - installationId
    - installationKey
    - ***SMTP Information***

1. Replace any optional values in `config.yaml` for your cluster.  Common sections to replace values include:
    - Ingress
    - RBAC
    - Database
    - Storage Class for PVCs
    - Replica counts per component

### Create namespace
1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.

### Run Helm Install
1. Run `helm install bitwarden-rel bitwarden-chart -n bitwarden -f config.yaml`.
    - This installs a release named `bitwarden-rel`, in the namespace `bitwarden`, using values from `config.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
