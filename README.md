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

## Get Repo Info

```console
helm repo add bitwarden https://bwhelmtest.blob.core.windows.net/helm-charts/
helm repo update
```

### Create config file
1. Run `helm show values bitwarden/bitwarden > my-values.yaml`.
1. Edit the `my-values.yaml` file and fill out the values.  Required values that must be set:
    - general.domain
    - general.installationId
    - general.installationKey
    - general.email.replyToEmail
    - general.email.smtpHost
    - general.email.smtpPort
    - general.email.smtpSsl
    - general.email.smtpUsername
    - general.email.smtpPassword
    - general.admins
    - ingress.enabled
    - ingress.cert.tls.enabled
    - ingress.cert.tls.cert
    - ingress.cert.tls.key

1. Replace any optional values in `my-values.yaml` for your cluster.

### Create namespace
1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.

### Run Helm Install
1. Run `helm install bitwarden bitwarden/bitwarden -n bitwarden -f my-values.yaml`.
    - This installs a release named `bitwarden`, in the namespace `bitwarden`, using values from `my-values.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
    - You can see help information for the `helm install` command by running `helm install --help`.
