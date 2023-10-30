# Bitwarden Helm Charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

    helm repo add bitwarden https://charts.bitwarden.com/

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
bitwarden --devel` to see the charts.

We recommend creating a namespace for the self-host deployment.

To install/upgrade the self-host chart:

    helm upgrade my-self-host bitwarden/self-host --install --namespace bitwarden --values my-values.yaml --devel

To uninstall the chart:

    helm uninstall my-self-host --namespace bitwarden