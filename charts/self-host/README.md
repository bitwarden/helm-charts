
# Bitwarden Helm Chart

The purpose of this chart is to enable the deployment of [Bitwarden](https://bitwarden.com/) to different Kubernetes environments. This chart is built for usage across multiple Kubernetes hosting scenarios.

## Requirements

- Kubectl
- Helm 3
- SSL cert and key or certificate provider
- SMTP server/account
- Storage Class that supports ReadWriteMany

---

## Add the repo to Helm

```shell
helm repo add bitwarden https://charts.bitwarden.com/
helm repo update
```

## Installation Steps

### Request Installation secrets

- Request an installation ID and key from: [https://bitwarden.com/host/](https://bitwarden.com/host/)

### Create config file

Run the following command to create a custom values file used for deployment:

```shell
helm show values bitwarden/self-host --devel > my-values.yaml
```

### Update the config file

Edit the `my-values.yaml` file and fill out the values.  Required values that must be set:

- general.domain
- general.ingress.enabled (set to disbled if you are creating your own ingress)
- general.ingress.className (nginx example provided)
- general.ingress.annotations (nginx example provided)
- general.ingress.paths (nginx example provided)
- general.ingress.cert.tls.name
- general.email.replyToEmail
- general.email.smtpHost
- general.emal.smtpPort
- general.email.smtpSsl
- sharedStorageClassName
- database.enabled (set to disbled if using an external SQL server)

Note that default values for Nginx have been setup for the ingress in the values.yaml file.  __*However, you will need to uncomment the ingress annotations and edit them as necessary for your environment.*__  Some other ingress controller examples are provided later in this document.

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
          - /attachements
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
          match: Host(`REPLACEME.COM`) && PathPrefix(`/attachments`)
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

### Install Helm Chart

1. Run `helm upgrade bitwarden bitwarden/self-host --install --devel --namespace bitwarden --values my-values.yaml`.
    - This installs/upgrades a release named `bitwarden`, in the namespace `bitwarden`, using values from `my-values.yaml`.
    - This may take over a minute to fully come up (some of the services might register as failed in the meantime)
    - You can see help information for the `helm install` command by running `helm install --help`.
    - You can see help information for the `helm upgrade` command by running `helm upgrade --help`.

> The current Bitwarden release is architected in a way which requires the sharing of persistent data between containers and therefore requires storage which supports the access mode ReadWriteMany.

Edit values.yaml and update to suit your configuration.

Minimal required to get a running installation:

## Example Deployment on AKS

Below is an example of deploying this chart on AKS using various ingress controllers and cert-manager to provision the certificate from LetsEncrypt.

### Create namespace in AKS

```shell
kubectl create ns bitwarden
```

### Deploy the ingress controller

#### Nginx

This is the simplest ingress to setup and has been provided as the default.  You will need the ingress controller installed if you have not already done so. Follow the basic configuration found at ["Create an unmanaged ingress controller"](https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli#basic-configuration).

Then update the my-values.yaml file:

```yaml
general:
  # Domain name for the service
  domain: "REPLACE"
  ingress:
    # Set to false if using a custom ingress
    enabled: true
    # Current supported values for ingress type include: nginx
    className: "nginx"
     ## - Annotations to add to the Ingress resource
    annotations:
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/use-regex: "true"
      nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
      nginx.ingress.kubernetes.io/rewrite-target: /$1
```

__*Make certain to uncomment the annotations section and tweak as necessary for your environment.*__  These annotations can be used as-is.

#### Azure Application Gateway

Azure customers might want to use an Azure Application Gateway as the ingress controller for their AKS cluster.  You will want to [enable the Application Gateway ingress controller for your cluster](https://learn.microsoft.com/en-us/azure/application-gateway/tutorial-ingress-controller-add-on-existing) before making these configuration changes.

Update the my-values.yaml file.  Tweak the annotations as necessary for your environment.

```yaml
general:
  domain: "replaceme.com"
  ingress:
    enabled: true
    className: "azure-application-gateway" # This value might be different depending on how you created your ingress controller.  Use "kubectl get ingressclasses -A" to find the name if unsure
     ## - Annotations to add to the Ingress resource
    annotations:
      appgw.ingress.kubernetes.io/ssl-redirect: "true"
      appgw.ingress.kubernetes.io/use-private-ip: "false" # This might be true depending on your setup
      appgw.ingress.kubernetes.io/rewrite-rule-set: "bitwarden-ingress" # Make note of whatever you set this value to.  It will be used later.
      appgw.ingress.kubernetes.io/connection-draining: "true" # Update as necessary
      appgw.ingress.kubernetes.io/connection-draining-timeout: "30" # Update as necessary
    ## - Labels to add to the Ingress resource
    labels: {}
    # Certificate options
    tls:
      # TLS certificate secret name
      name: tls-secret
      # Cluster cert issuer (ex. Let's Encrypt) name if one exists
      clusterIssuer: letsencrypt-staging
    paths:
      web:
        path: /*
        pathType: Prefix
      attachments:
        path: /attachments/*
        pathType: Prefix
      api:
        path: /api/*
        pathType: Prefix
      icons:
        path: /icons/*
        pathType: Prefix
      notifications:
        path: /notifications/*
        pathType: Prefix
      events:
        path: /events/*
        pathType: Prefix
      sso:
        path: /sso/*
        pathType: Prefix
      identity:
        path: /identity/*
        pathType: Prefix
      admin:
        path: /admin*
        pathType: Prefix
```

__*NOTE: Make sure to update the paths to what you see here.*__

Further settings will need to be set after the deployment on the Application Gateway itself.

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
            class: nginx #use "azure/application-gateway" for Application Gateway ingress
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
            class: nginx #use "azure/application-gateway" for Application Gateway ingress
EOF
```

Finally, set the ingress TLS information in `my-values.yaml`:

```yaml
  ingress:

    ...

    # Certificate options
    tls:
      # TLS certificate secret name
      name: tls-secret
      # Cluster cert issuer (ex. Let's Encrypt) name if one exists
      clusterIssuer: letsencrypt-staging
```

### Create a storage class

We will use the Azure File storage class for persistent storage:

```shell
cat <<EOF | kubectl apply -n bitwarden -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: azure-file
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
sharedStorageClassName: "azure-file"
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
helm upgrade bitwarden bitwarden/self-host --install --devel --namespace bitwarden --values my-values.yaml
```

### Azure Application Gateway Rewrite Set

Application Gateway ingress deployments have one more required step for Bitwarden to function correctly.  If you are using another ingress controller, you may skip to the next section.

We will need to create a rewrite set on the Application Gateway.  There are various ways of doing this, but we will discuss using the Azure Portal.

  1. Navigate to the Application Gateway in the Azure Portal
  2. Once in the Application Gateway, find the "Rewrites" blade   in the left-hand navigation menu.
  3. Click the "+ Rewrite set" button at the top of the main page   section to add a new rewrite set
  4. On the "Update rewrite set" page in the "Name and Association" tab:
     - Set the Name field to the same value specified in the `appgw.ingress.kubernetes.io/rewrite-rule-set` ingress annotation
     - Select all routing rules that start with something similar to "pr-bitwarden-bitwarden-ingress-rule-*"
  5. Click Next
  6. On the "Rewrite rule configuration" tab, click the "Add rewrite rule" button
  7. Enter a name for the rule.  This can be anything that helps you with organization.  Something simlar to "bitwarden-rewrite" will work.
  8. The rule sequence value does not matter for this purpose.
  9. Add a condition and set the following values:
     - Type of variable to check: Server variable
     - Server variable: uri_path
     - Case-sensitive: No
     - Operator: equal (=)
     - Pattern to match: `^(\/(?!admin)[^\/]*)\/(.*)`
     - Click OK
  10. Add an action and set the following values:
     - Rewrite type: URL
     - Action type: Set
     - Components: URL path
     - URL path value: `/{var_uri_path_2}`
     - Re-evalueate path map: Unchecked
     - Click OK
  11. Click "Create" at the bottom of the screen

### Pointing your DNS

#### Nginx Deployments

You can find the public IP to point your DNS record at by running:

```shell
kubectl get ingress -n bitwarden

```

#### Application Gateway Deployments

The public IP will be found on the Overview tab of the Application Gateway service in the Azure Portal.

## Example Deployment on OpenShift

This section will walk through an example of hosting Bitwarden on OpenShift. Note that there are many different permutations of how you can host Bitwarden on this platform.  We will provide some basic pointers.

### Create project in OpenShift

Run the following shell commands to create a project in OpenShift.

```shell
oc new-project bitwarden
oc project bitwarden
```

### Setup ingress

We will use OpenShift Routes for our ingress in this example.  Alternatively, ingress operators could be used.

#### Disable default ingress

In your `my-values.yaml`, disable the default ingress.

```yaml
general:
  domain: "replaceme.com"
  ingress:
    enabled: false
```

You can ignore the rest of the ingress section.

#### Add raw manifests for routes

Update the `rawManifests` section in `my-values.yaml` to include OpenShift Route manifests.

```yaml
rawManifests:
  preInstall: []
  postInstall:
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-web
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/"
      to:
        kind: Service
        name: bitwarden-web
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-api
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/api"
      to:
        kind: Service
        name: bitwarden-api
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-attachments
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/attachments"
      to:
        kind: Service
        name: bitwarden-attachments
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-icons
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/icons"
      to:
        kind: Service
        name: bitwarden-icons
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-notifications
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/notifications"
      to:
        kind: Service
        name: bitwarden-notifications
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-events
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/events"
      to:
        kind: Service
        name: bitwarden-events
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-sso
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/sso"
      to:
        kind: Service
        name: bitwarden-sso
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-identity
      namespace: bitwarden
      annotations:
        haproxy.router.openshift.io/rewrite-target: /
    spec:
      host: bitwarden.apps-crc.testing
      path: "/identity"
      to:
        kind: Service
        name: bitwarden-identity
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
  - kind: Route
    apiVersion: route.openshift.io/v1
    metadata:
      name: bitwarden-admin
      namespace: bitwarden
      annotations:
        # Rewrite will not work with admin
    spec:
      host: bitwarden.apps-crc.testing
      path: "/admin"
      to:
        kind: Service
        name: bitwarden-admin
        weight: 100
      port:
        targetPort: 5000
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
        destinationCACertificate: ''
```

Note that in this example we are setting `destinationCACertificate` to an empty string.  This will use the default certificate setup in OpenShift.  Alternatively, specify a certificate name here, or you can use Let's Encrypt by following this guide: [Secure Red Had OpenShift routs with Let's Encrypt](https://developer.ibm.com/tutorials/secure-red-hat-openshift-routes-with-lets-encrypt/).  If you do so, you will need to add `kubernetes.io/tls-acme: "true"` to the annotations for each route.

### Setup storage class

A shared storage class will be required.  As stated earlier in the document, a ReadWriteMany-capable Storage Class will need to be set up.  There are several options for this in OpenShift.  One viable option is to use the [NFS Subdir External Provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/blob/master/charts/nfs-subdir-external-provisioner/README.md).

### Setting secrets

Using a secrets provider [HashiCorp Vault](https://developer.hashicorp.com/vault/docs/platform/k8s/csi/installation#installation-on-openshift) is valid, but we will focus on using the `oc` command to deploy our secrets. The process is similar to using `kubectl` detailed earlier.

```shell
oc create secret generic custom-secret -n bitwarden \
    --from-literal=globalSettings__installation__id="REPLACE" \
    --from-literal=globalSettings__installation__key="REPLACE" \
    --from-literal=globalSettings__mail__smtp__username="REPLACE" \
    --from-literal=globalSettings__mail__smtp__password="REPLACE" \
    --from-literal=globalSettings__yubico__clientId="REPLACE" \
    --from-literal=globalSettings__yubico__key="REPLACE" \
    --from-literal=SA_PASSWORD="REPLACE" # If using SQL pod
    # --from-literal="REPLACE" # If using your own SQL server
```

### Create a service account

Bitwarden currently requires the use of a service account in OpenShift due to each container's need to run elevated commands on start-up.  These commands are blocked by OpenShift's restricted SCCs.  We need to create a service account and assign it to the `anyuid` SCC.

```shell
oc create sa bitwarden-sa
oc adm policy add-scc-to-user anyuid -z bitwarden-sa
```

Next, update `my-values.yaml` to use this service account.  Note that this is a different service account from the one in the `serviceAccount` section of the values YAML file.  Instead, set the following keys to the name of the service account created:

- component.admin.podServiceAccount
- component.api.podServiceAccount
- component.attachments.podServiceAccount
- component.events.podServiceAccount
- component.icons.podServiceAccount
- component.identity.podServiceAccount
- component.notifications.podServiceAccount
- component.scim.podServiceAccount
- component.sso.podServiceAccount
- component.web.podServiceAccount
- database.podServiceAccount

#### Example

```yaml
component:
  # The Admin component
  admin:
    # Additional deployment labels
    labels: {}
    # Image name, tag, and pull policy
    image:
      name: bitwarden/admin
    resources:
      requests:
        memory: "64Mi"
        cpu: "50m"
      limits:
        memory: "128Mi"
        cpu: "100m"
    securityContext:
    podServiceAccount: bitwarden-sa
```

__*NOTE: You can create your own SSC to fine-tune the security of these pods. [Managing SSCs in OpenShift](https://cloud.redhat.com/blog/managing-sccs-in-openshift) describes the out-of-the-box SSCs and how to create your own if desired.*__

### Update other settings

Update the other settings in `my-values.yaml` based on your environment.  Follow the instructions earlier in this document for required settings to update.

### Deploy via Helm

```shell
helm upgrade bitwarden bitwarden/self-host --install --devel --namespace bitwarden --values my-values.yaml
```
