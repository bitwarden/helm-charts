# bitwarden

Installs Bitwarden on a Kubernetes cluster.

## Prerequisites

- Kubernetes 1.18+
- Helm 3+

## Get Repo Info

```console
helm repo add bitwarden URL-HERE
helm repo update
```

_See [helm repo](https://helm.sh/docs/helm/helm_repo/) for command documentation._

## Install Chart

```console
# Helm
$ helm install [RELEASE_NAME] bitwarden/bitwarden
```

_See [configuration](#configuration) below._

_See [helm install](https://helm.sh/docs/helm/helm_install/) for command documentation._

## Uninstall Chart

```console
# Helm
$ helm uninstall [RELEASE_NAME]
```

This removes all the Kubernetes components associated with the chart and deletes the release.

_See [helm uninstall](https://helm.sh/docs/helm/helm_uninstall/) for command documentation._

## Upgrading Chart

```console
# Helm
$ helm upgrade [RELEASE_NAME] bitwarden/bitwarden

_See [helm upgrade](https://helm.sh/docs/helm/helm_upgrade/) for command documentation._
```

## Configuration

See [Customizing the Chart Before Installing](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing). To see all configurable options with detailed comments:

```console
helm show values bitwarden/bitwarden
```
