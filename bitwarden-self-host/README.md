
# Bitwarden Helm Chart


The purpose of this chart is to enable the deployment of [Bitwarden](https://bitwarden.com/) to different Kubernetes environments. This chart is built for usage across multiple Kubernetes hosting scenarios.

## Requirements

- Kubectl
- Helm 3
- SSL cert and key or certificate provider
- SMTP server/account
- Storage Class that supports ReadWriteMany

---

## Steps

### Request Installation secrets

- Request an installation ID and key from https://bitwarden.com/host/

### Create config file

Run the following command to create a custom values file used for deployment:

```shell
helm show values bitwarden/bitwarden > my-values.yaml
```

### Update the config file

Edit the `my-values.yaml` file and fill out the values.  Required values that must be set:

- general.domain
- general.ingress.enabled (set to disbled if you are creating your own ingress)
- general.ingress.cert.tls.name
- general.email.replyToEmail
- general.email.smtpHost
- general.emal.smtpPort
- general.email.smtpSsl
- sharedStorageClassName
- secrets.secretSource
- database.enabled (set to disbled if using an external SQL server)

### Create namespace

1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.

### Secrets

Create a secret to set the following values.

- globalSettings__installation__id
- globalSettings__installation__key
- globalSettings__mail__smtp__username
- globalSettings__mail__smtp__password
- globalSettings__yubico__clientId
- globalSettings__yubico__key
- SA_PASSWORD (if using the Bitwarden SQL pod)
- globalSettings__sqlServer__connectionString (if using your own SQL server)

Here we document the process of creating the secret using the command line.  However, you can also use a CSI secret provider class, which we document an example of under "Installing the Azure Key Vault CSI Driver" later in this README.

Examples of kubectl secret creation are provided below.  One is for use with SQL deployed in a pod.  The other is for usage with an external SQL server.

- With included SQL pod

  ```shell
  kubectl create secret generic custom-secret -n bitwarden\
      --from-literal=globalSettings__installation__id="REPLACE" \
      --from-literal=globalSettings__installation__key="REPLACE" \
      --from-literal=globalSettings__mail__smtp__username="REPLACE" \
      --from-literal=globalSettings__mail__smtp__password="REPLACE" \
      --from-literal=globalSettings__yubico__clientId="REPLACE" \
      --from-literal=globalSettings__yubico__key="REPLACE" \
      --from-literal=SA_PASSWORD="REPLACE"
  ```

- With external SQL server

  ```shell
  kubectl create secret generic custom-secret -n bitwarden\
      --from-literal=globalSettings__installation__id="REPLACE" \
      --from-literal=globalSettings__installation__key="REPLACE" \
      --from-literal=globalSettings__mail__smtp__username="REPLACE" \
      --from-literal=globalSettings__mail__smtp__password="REPLACE" \
      --from-literal=globalSettings__sqlServer__connectionString="Data Source=tcp:<SERVERNAME>,1433;Initial Catalog=vault;Persist Security Info=False;User ID=<USER>;Password=<PASSWORD>;Multiple Active Result Sets=False;Connect Timeout=30;Encrypt=True;Trust Server Certificate=True" \
      --from-literal=globalSettings__yubico__clientId="REPLACE" \
      --from-literal=globalSettings__yubico__key="REPLACE" \
  ```

__*NOTE: These commands are recorded in your shell history.  To avoid this, consider setting up a CSI secret provider class.*__

Set `secrets.secretName` to the name of the secret created above.

### Optional Values

Replace any optional values in `my-values.yaml` to best fit your cluster.  This includes changing of resource limits and requests.

#### Raw Manifests Files

This chart allows you to include other Kubernetes manifest files either pre- or post-install.  To do this, update the `rawManifests` section of the chart

```yaml
rawManifests:
  preInstall: []
  postInstall: []
```

The example below shows how you can use the raw manifests to install Traefik's IngressRoute instead of using the Kubernetes Ingress controller.  Note that you will want to disable the ingress controller under `general.ingress.enabled` to use this.

```yaml
rawManifests:
  preInstall: []
  postInstall:
  - apiVersion: traefik.containo.us/v1alpha1
    kind: Middleware
    metadata:
      name: "bitwarden-middleware-stripprefix"
    spec:
      stripPrefix:
        prefixes:
          - /api
          - /icons
          - /notifications
          - /events
          - /sso
          - /identity
          ##### NOTE:  Admin will not function correctly with path strip middleware
  - apiVersion: traefik.containo.us/v1alpha1
    kind: IngressRoute
    metadata:
      name: "bitwarden-ingress"
    spec:
      entryPoints:
        - websecure
      routes:
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/`)
          services:
            - kind: Service
              name: bitwarden-web
              passHostHeader: true
              port: 5000
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/api`)
          services:
            - kind: Service
              name: bitwarden-api
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/icons`)
          services:
            - kind: Service
              name: bitwarden-icons
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/notifications`)
          services:
            - kind: Service
              name: bitwarden-notifications
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/events`)
          services:
            - kind: Service
              name: bitwarden-events
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/sso`)
          services:
            - kind: Service
              name: bitwarden-sso
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/identity`)
          services:
            - kind: Service
              name: bitwarden-identity
              port: 5000
          middlewares:
            - name: "bitwarden-middleware-stripprefix"
        ##### NOTE:  Admin will not function correctly with path strip middleware
        - kind: Rule
          match: Host(`REPLACEME.COM`) && PathPrefix(`/admin`)
          services:
            - kind: Service
              name: bitwarden-admin
              port: 5000
      tls:
        certResolver: letsencrypt
```

Note that the certResolver is deployed with the Traefik ingress configuration.

### Run Helm Install

1. Run `helm install bitwarden bitwarden/bitwarden -n bitwarden -f my-values.yaml`.
    - This installs a release named `bitwarden`, in the namespace `bitwarden`, using values from `my-values.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
    - You can see help information for the `helm install` command by running `helm install --help`.

> The current Bitwarden release is architected in a way which requires the sharing of persistent data between containers and therefore requires storage which supports the access mode ReadWriteMany.

Edit values.yaml and update to suit your configuration.

Minimal required to get a running installation:

## Example Deployment on AKS

Below is an example of deploying this chart on AKS using the Nginx ingress controller and cert-manager to provision the certificate from LetsEncrypt.

### Create namespace in AKS

```shell
kubectl create ns bitwarden
```

### Deploy the nginx ingress controller

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/aws/deploy.yaml
```

Then update the my-values.yaml file:

```yaml
general:
  enabled: true
  ingress: "nginx"
```

### Let's Encrypt

If you have not done so, first install cert-manager on the cluster.

```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```

> It is recommended to use the staging configuration of Let's Encrypt until your DNS records have been pointed correctly.

Use one of the following certificate issuers depending on if you are in a production or a pre-production environment:

#### Staging

```shell
cat <<EOF | kubectl apply -n bitwarden -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: me@example.com
    privateKeySecretRef:
      name: tls-secret
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

#### Production

```shell
cat <<EOF | kubectl apply -n bitwarden -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: me@example.com
    privateKeySecretRef:
      name: tls-secret
    solvers:
      - http01:
          ingress:
            class: nginx
EOF
```

Finally, set the ingress TLS information in `my-values.yaml`:

```yaml
  ingress:
    enabled: true
    type: "nginx"
     ## - Annotations to add to the Ingress resource
    annotations: {}
    ## - Labels to add to the Ingress resource
    labels: {}
    # Certificate options
    tls:
      # TLS certificate secret name
      name: tls-secret
      # Cluster cert issuer (ex. Let's Encrypt) name if one exists
      clusterIssuer: letsencrypt-staging
```

### Create a storage class

We will use the Azure Disk storage class for persistent storage:

```shell
cat <<EOF | kubectl apply -n bitwarden -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azure-disk
  namespace: bitwaren
provisioner: file.csi.azure.com
allowVolumeExpansion: true
mountOptions:
  - dir_mode=0777
  - file_mode=0777
  - uid=0
  - gid=0
  - mfsymlinks
  - cache=strict
  - actimeo=30
parameters:
  skuName: Standard_LRS
EOF
```

Set the `sharedStorageClassName` value in `my-values.yaml` to match the name provided.

```yaml
sharedStorageClassName: "azure-disk"
```

### Configure remaining values

See the configuration sections above for required values.  Secrets can be configured using the standard CLI method already provided.  However, you can also use Azure Key Vault as the source for your secrets.  This is optional but recommended.

#### Installing the Azure Key Vault CSI Driver

The following will add the Azure Key Vault CSI driver to an existing cluster.  More information can be found in this article: [Use the Azure Key Vault Provider for Secrets Store CSI Driver in an Azure Kubernetes Service (AKS) cluster](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)

```shell
az aks enable-addons --addons azure-keyvault-secrets-provider --name REPLACE --resource-group REPLACE
```

You will also want to configure identity access for your cluster to the Key Vault.  This article provides a couple of different options: [Provide an identity to access the Azure Key Vault Provider for Secrets Store CSI Driver in Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access)

Once the cluster identity has been granted access to the Key Vault, you will need to create a SecretProviderClass.  An example is provided below.

```shell
cat <<EOF | kubectl apply -n bitwarden -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: bitwarden-azure-keyvault-csi
  labels:
    app.kubernetes.io/component: secrets
  annotations:
spec:
  provider: azure
  parameters:
    useVMManagedIdentity: "true" # Set to false for workload identity
    userAssignedIdentityID: "<REPLACE>" # Set the clientID of the user-assigned managed identity to use
    # clientID: "<REPLACE>" # Setting this to use workload identity
    keyvaultName: "<REPLACE>"
    cloudName: "AzurePublicCloud"
    objects: |
      array:
        - |
          objectName: installationid
          objectAlias: installationid
          objectType: secret
          objectVersion: ""
        - |
          objectName: installationkey
          objectAlias: installationkey
          objectType: secret
          objectVersion: ""
        - |
          objectName: smtpusername
          objectAlias: smtpusername
          objectType: secret
          objectVersion: ""
        - |
          objectName: smtppassword
          objectAlias: smtppassword
          objectType: secret
          objectVersion: ""
        - |
          objectName: yubicoclientid
          objectAlias: yubicoclientid
          objectType: secret
          objectVersion: ""
        - |
          objectName: yubicokey
          objectAlias: yubicokey
          objectType: secret
          objectVersion: ""
        - |
          objectName: sapassowrd #-OR- dbconnectionstring if external SQL
          objectAlias: sapassowrd #-OR- dbconnectionstring if external SQL
          objectType: secret
          objectVersion: ""
    tenantId: "<REPLACE>"
  secretObjects:
  - secretName: "bitwarden-secret"
    type: Opaque
    data:
    - objectName: installationid
      key: globalSettings__installation__id
    - objectName: installationkey
      key: globalSettings__installation__key
      key: globalSettings__mail__smtp__username
    - objectName: smtppassword
      key: globalSettings__mail__smtp__password
    - objectName: yubicoclientid
      key: globalSettings__yubico__clientId
    - objectName: yubicokey
      key: globalSettings__yubico__key
    - objectName: sapassowrd #-OR- dbconnectionstring if external SQL
      key: SA_PASSWORD #-OR- globalSettings__sqlServer__connectionString if external SQL
EOF
```

Note the spots in the definition that say `"<REPLACE>"`.  These will need to be updated for your environment.  Also note that you will again have the choice between using the SQL Server Pod and an external SQL Server.  Those spots that will need to change have been marked with a comment.  Finally, you can name the secrets in Azure Key Vault based on your own naming convention.  If you do so, you must make certain that to update the objectName properties under `spec.parameters.objects.array` to match the secrets created in Key Vault.

The following commands would create these secrts in a Key Vault:

```shell
kvname="kv-aks-bw-helm-cus-01"
az keyvault secret set --name installationid --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name installationkey --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name smtpusername --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name smtppassword --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name yubicoclientid --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name yubicokey --vault-name $kvname --value <REPLACEME>
az keyvault secret set --name sapassword --vault-name $kvname --value '"<REPLACEME>"'
# - OR -
# az keyvault secret set --name dbconnectionstring --vault-name $kvname --value '"<REPLACEME>"'
```

__*NOTE:  These values will be stored in your shell history.  There are many other ways to set Key Vault secrets that are outside of the scope of this document.  This provides you with one option.*__

Now, edit `my-values.yaml` to use this secret provider class we created.

```yaml
secrets:
  secretName: bitwarden-secret # spec.secretObjects.secretName in example
  secretProviderClass: bitwarden-azure-keyvault-csi #metadata.name in example
```

### Helm

```shell
helm install bitwarden ./bitwarden -n bitwarden
```

### Pointing your DNS

You can find the public IP to point your DNS record at by running:

```shell
kubectl get ingress -n bitwarden

```
