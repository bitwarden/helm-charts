# Running Locally

## Prerequisites
1. brew install kind
1. brew install kubernetes-cli
1. brew install chart-testing

## Usage
Run the `setup.sh` script from the root of the repository for `ct` (chart-testing) to correctly run differing.
Example: `$(git rev-parse --show-toplevel)/scripts/setup.sh`

Optional arguments select the routing (`ingress` or `gateway`, default `ingress`) and the database
(`mssql` or `postgres`, default `mssql`). The `postgres` option deploys an external PostgreSQL
(`scripts/postgres.yaml`) and installs the chart with `databaseProvider: postgres`.
Example: `$(git rev-parse --show-toplevel)/scripts/setup.sh all ingress postgres`

A fourth argument selects how secrets are provided (`generate` or `byos`, default `generate`). With `byos`,
`setup.sh` creates the encryption keys and the identity certificate secret itself, and the chart installs with
`secrets.secretKeys.generate` and `secrets.identityCertificate.generate` set to `false`.
Example: `$(git rev-parse --show-toplevel)/scripts/setup.sh all gateway mssql byos`

## sm-operator failure paths
`sm-operator-failure-paths.sh` tests how an installed operator handles bad tokens (`bad-token`,
`replaced-token`, or `all`) and an upstream-deleted secret (`deleted-secret`). The token cases use the
CI test org by default, with `AUTH_TOKEN` set.

`deleted-secret` deletes a secret upstream, so it runs against a seeded self-hosted instance:
```
./scripts/setup.sh setup-cluster ingress postgres
./scripts/sm-operator-selfhost.sh build-seeder <path to bitwarden/server checkout>
./scripts/setup.sh install-self-host ingress postgres
./scripts/sm-operator-selfhost.sh deploy-seeder
./scripts/sm-operator-selfhost.sh seed sm-operator.env
./scripts/sm-operator-selfhost.sh install-operator
```
Then run the tests with `OPERATOR_NAMESPACE=sm-operator`, plus the values from `sm-operator.env`.
`deleted-secret` also needs `REFRESH_INTERVAL=180`, `API_URL=https://bitwarden.localhost/api`,
`IDENTITY_URL=https://bitwarden.localhost/identity` and `CURL_CA_BUNDLE=rootCA.pem`. The
`build-seeder` checkout should be at the tag matching `charts/self-host` `appVersion`.
