# Bitwarden EKS Deployment

## Description

This value file is configured to set up a Bitwarden installation on Amazon EKS.  This assumes EFS as a Storage Class for backing the Attachments, Data Protection, and Licenses Persistent Volume Claims, an RDS instance for the database, and a Traefik Ingress Controller with the default entrypoint as "websecure".

## Requirements

- Kubectl
- Helm 3
- Traefik Ingress Controller
- AWS EKS Cluster
- EFS Storage Class
- Traefik Ingress Controller
- SSL cert and key
- SMTP server/account

---

## Steps
### Request Installation secrets
- Request an installation ID and key from https://bitwarden.com/host/

### Create config file
**NOTE:** Make sure you are in the `kubernetes-poc` directory.  
1. Edit the `eks-deployment-values.yaml` file and fill out the values.  Required values that must be replaced:
    - General Config
      - certSSL
      - keySSL
      - domain
      - installationId
      - installationKey
      - admins

    - SMTP Config
      - replyToEmail
      - smtpHost
      - smtpPort
      - smtpSsl
      - smtpUsername
      - smtpPassword

1. Replace any optional values in `eks-deployment-values.yaml` for your cluster. Common sections to replace values include:

    - Ingress Config
      - ingressAnnotations

    - Database Config
      - dbHostname
      - dbPort
      - dbUser
      - dbPassword

    - PVC Storage Class Config
      - dataprotectionVolumeStorageClassName
      - licensesVolumeStorageClassName
      - attachmentsVolumeStorageClassName

    - Replica Count Config
      - adminDeploymentReplicaCount
      - apiDeploymentReplicaCount
      - attachmentsDeploymentReplicaCount
      - eventsDeploymentReplicaCount
      - iconsDeploymentReplicaCount
      - identityDeploymentReplicaCount
      - notificationsDeploymentReplicaCount
      - portalDeploymentReplicaCount
      - proxyDeploymentReplicaCount
      - ssoDeploymentReplicaCount
      - webDeploymentReplicaCount

### Create namespace
1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.

### Run Helm Install
1. Run `helm install bitwarden bitwarden-chart -n bitwarden -f folder-containing/eks-deployment-values.yaml`.
    - This installs a release named `bitwarden`, in the namespace `bitwarden`, using values from `eks-deployment-values.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
    - You can see help information for the `helm install` command by running `helm install --help`.
