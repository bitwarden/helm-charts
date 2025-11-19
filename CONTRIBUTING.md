# How to Contribute

Our [Contributing Guidelines](https://contributing.bitwarden.com/contributing/) are located in our [Contributing Documentation](https://contributing.bitwarden.com/). The documentation also includes recommended tooling, code style tips, and lots of other great information to get you started.

## Helm Schema

Helm chart schemas are generated from `values.yaml` files. The CI validates that schemas are up-to-date using the Helm plugin: [helm-schema](https://github.com/dadav/helm-schema).

To update schemas after making changes to a values file:

```bash
helm plugin install https://github.com/dadav/helm-schema

# From a chart directory
helm schema --skip-auto-generation required
```
