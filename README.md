# Bitwarden Helm Charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add bitwarden https://charts.bitwarden.com/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
bitwarden` to see the charts.

To install the self-host chart:

    helm install my-self-host bitwarden/self-host

To uninstall the chart:

    helm delete my-self-host