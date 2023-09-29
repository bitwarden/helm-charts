
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

## Get Repo Info

```console
helm repo add bitwarden https://bwhelmtest.blob.core.windows.net/helm-charts/
helm repo update
```

### Create config file
1. Run `helm show values bitwarden/bitwarden > my-values.yaml`.

### Update the config file
Edit the `my-values.yaml` file and fill out the values.  Required values that must be set:
- general.domain
- general.ingress.enabled (set to disbled if you are creating your own ingress)
- general.ingress.cert.tls.name
- sharedStorageClassName
- secrets.secretSource
- database.enabled (set to disbled if using an external SQL server)

### Create namespace
1. Create a namespace to deploy Bitwarden to.  In this guide, we will be using `bitwarden` as the namespace.
    - Run `kubectl create namespace bitwarden`.
### Secrets
Set secrets based on one of the three options for secrets.secretSource (fromEnv, fromValues, fromSecret). The following secrets are required regardless of secret source
- globalSettings__installation__id
- globalSettings__installation__key
- globalSettings__mail__replyToEmail
- globalSettings__mail__smtp__host
- globalSettings__mail__smtp__port
- globalSettings__mail__smtp__ssl
- SA_PASSWORD (if using the Bitwarden SQL pod)
- globalSettings__sqlServer__connectionString (if using your own SQL server)

#### Secret Sources
The following speaks to configuring these secrets for each of the different possible secret sources:
- fromValues
  - Update all values in the `secrets.fromValues` section of the `my-values.yaml` file
- fromSecret:
  - Create a secret on your own.  This can either be via the kubectl command line or via a YAML deployment file.  Examples of kubectl creation are provided below.  One is for use with SQL deployed in a pod.  The other is for usage with an external SQL server.
    - With included SQL pod
      ```shell
      kubectl create secret generic custom-secret -n bitwarden\
          --from-literal=globalSettings__installation__id="REPLACE" \
          --from-literal=globalSettings__installation__key="REPLACE" \
          --from-literal=globalSettings__mail__replyToEmail="replace@replace.com" \
          --from-literal=globalSettings__mail__smtp__host="stmp.host" \
          --from-literal=globalSettings__mail__smtp__port="386" \
          --from-literal=globalSettings__mail__smtp__ssl="true" \
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
          --from-literal=globalSettings__mail__replyToEmail="replace@replace.com" \
          --from-literal=globalSettings__mail__smtp__host="stmp.host" \
          --from-literal=globalSettings__mail__smtp__port="386" \
          --from-literal=globalSettings__mail__smtp__ssl="true" \
          --from-literal=globalSettings__mail__smtp__username="REPLACE" \
          --from-literal=globalSettings__mail__smtp__password="REPLACE" \
          --from-literal=globalSettings__sqlServer__connectionString="Data Source=tcp:<SERVERNAME>,1433;Initial Catalog=vault;Persist Security Info=False;User ID=<USER>;Password=<PASSWORD>;Multiple Active Result Sets=False;Connect Timeout=30;Encrypt=True;Trust Server Certificate=True" \
          --from-literal=globalSettings__yubico__clientId="REPLACE" \
          --from-literal=globalSettings__yubico__key="REPLACE" \
      ```
  - Set `secrets.fromSecret.secretName` to the name of the secret created above.
- fromEnv:
    - Create a file called envvars.env and copy one of the provided example envvars.env file contents below for your usage and update the values as necessary.  One is for use with SQL deployed in a pod.  The other is for usage with an external SQL server
       -  Using provided SQL pod
           ```yaml
           globalSettings__installation__id: REPLACE
           globalSettings__installation__key: REPLACE
           globalSettings__mail__replyToEmail: REPLACE
           globalSettings__mail__smtp__host: stmp.host
           globalSettings__mail__smtp__port: 386
           globalSettings__mail__smtp__ssl: true
           globalSettings__mail__smtp__username: REPLACE
           globalSettings__mail__smtp__password: REPLACE
           globalSettings__yubico__clientId: REPLACE
           globalSettings__yubico__key: REPLACE
           SA_PASSWORD: REPLACE
           ```
       - Using  your own SQL server
           ```yaml
           globalSettings__installation__id: REPLACE
           globalSettings__installation__key: REPLACE
           globalSettings__mail__replyToEmail: REPLACE
           globalSettings__mail__smtp__host: stmp.host
           globalSettings__mail__smtp__port: 386
           globalSettings__mail__smtp__ssl: true
           globalSettings__mail__smtp__username: REPLACE
           globalSettings__mail__smtp__password: REPLACE
           globalSettings__sqlServer__connectionString: "Data Source=tcp:<server_name>,1433;Initial Catalog=vault;Persist Security Info=False;User ID=<REPLACE>;Password=<REPLACE>;Multiple Active Result Sets=False;Connect Timeout=30;Encrypt=True;Trust Server Certificate=True"
           globalSettings__yubico__clientId: REPLACE
           globalSettings__yubico__key=: REPLACE
           ```
  - Set `secrets.fromEnv.fileName` to the filepath for the file

### Optional Values

Replace any optional values in `my-values.yaml` to best fit your cluster.  This includes changing of resource limits and requests.

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

### Create namespace

```shell
kubectl create ns bitwarden
```

### Deploy the nginx ingress controller

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/aws/deploy.yaml
```

Then update the my-values.yaml file:
```
general:
  enabled: true
  ingress: "nginx"
```

### Lets Encrypt

> It is recommended to use the staging configuration until your DNS records have been pointed correctly.

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

You must also deploy the Let's Encrypt certificate manager:

```shell
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
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
We will use the Azure Disk storage class:
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
See the configuration sections above for required values.  Secrets can be configured using any of the standard methods already provided.  However, you can also use Azure Key Vault as a source for your secret, though this is completely optional.

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
          objectName: smtpreplytoemail
          objectAlias: smtpreplytoemail
          objectType: secret
          objectVersion: ""
        - |
          objectName: smtphost
          objectAlias: smtphost
          objectType: secret
          objectVersion: ""
        - |
          objectName: smtpport
          objectAlias: smtpport
          objectType: secret
          objectVersion: ""
        - |
          objectName: smtpssl
          objectAlias: smtpssl
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
   - objectName: smtpreplytoemail
      key: globalSettings__mail__replyToEmail
    - objectName: smtphost
      key: globalSettings__mail__smtp__host
   - objectName: smtpreplytoemail
      key: globalSettings__mail__smtp__port
    - objectName: smtphost
      key: globalSettings__mail__smtp__ssl
    - objectName: smtpusername
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

Now, edit `my-values.yaml` to use this secret provider class we created.
```yaml
  fromSecret:
    secretName: bitwarden-secret # spec.secretObjects.secretName in example
    secretProviderClass: bitwarden-azure-keyvault-csi #metadata.name in example
```

### Helm

```
helm install bitwarden ./bitwarden -n bitwarden
```

### Pointing your DNS

You can find the public IP to point your DNS record at by running:

```
kubectl get ingress -n bitwarden

```
