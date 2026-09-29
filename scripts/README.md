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
Example: `$(git rev-parse --show-toplevel)/scripts/setup.sh all ingress mssql byos`
