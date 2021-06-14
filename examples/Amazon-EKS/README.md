# Bitwarden EKS Deployment

## Description

This value file is configured to set up a Bitwarden installation on Amazon EKS.  This assumes EFS as a Storage Class for backing the Attachments, Data Protection, and Licenses Persistent Volume Claims, an RDS instance for the database, and a Traefik Ingress Controller with the default entrypoint as "websecure".

## Requirements

- Kubectl
- Helm 3
- Traefik Ingress Controller
- AWS EKS Cluster
- EFS Storage Class
- SSL cert and key
- SMTP server/account

---

## Steps
### Request Installation secrets
- Request an installation ID and key from https://bitwarden.com/host/

### Create config file
**NOTE:** Make sure you are in the `examples/Amazon-EKS` directory.  
1. Edit the `eks-deployment-values.yaml` file and fill out the values.  Required values that must be replaced:
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

1. Replace any optional values in `eks-deployment-values.yaml` for your cluster.

### Create namespace
1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.

### Run Helm Install
1. Make sure you are in the root of the repo.
1. Run `helm install bitwarden bitwarden -n bitwarden -f examples/Amazon-EKS/eks-deployment-values.yaml`.
    - This installs a release named `bitwarden`, in the namespace `bitwarden`, using values from `eks-deployment-values.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
    - You can see help information for the `helm install` command by running `helm install --help`.
