# Bitwarden Helm Chart

> Ensure you clone this repo and add values.yaml to .gitignore to avoid storing sensitive data. 

ToDo:

- [] Add email capability
- [] Improve values file documentation, what do people need to change minimum.

The purpose of this chart is to enable the deployment of [Bitwarden](https://bitwarden.com/) to different Kubernetes environments. This chart is built to cater for common cloud providers and supporting infrastructure.


> The current Bitwarden release is architected in a way which requires the sharing of persistent data between containers and therefore requires storage which supports the access mode ReadWriteMany. 

Edit values.yaml and update to suit your configuration.

Minimal required to get a running installation:

```
general:
  domain: "vault.mydomain.com"
  mail:
    replyTo: "replace@me.com"

secrets:
  installation:
    id: ""
    key: ""
```

## Example Deployment on AKS

Below is an example of deploying this chart on AKS using the Nginx ingress controller and cert-manager to provision the certificate from LetsEncrypt.

### Deploy the nginx ingress controller

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.0/deploy/static/provider/aws/deploy.yaml
```

Then update the values.yaml file:
```
general:
  ingress: "nginx"
```

### Lets Encrypt

> It is recommended to use the staging configuration until your DNS records have been pointed correctly.

```
letsencrypt:
  enable: "yes"
  # Values staging or production
  server: "staging"
  email: "me@example.com"
```

You must also deploy let's encrypt 

```
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```

### Helm

```
helm install bitwarden ./bitwarden -n bitwarden --create-namespace
```

### Pointing your DNS

You can find the public IP to point your DNS record at by running:

```
kubectl get ingress -n bitwarden

```
