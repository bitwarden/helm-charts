# Bitwarden Helm Charts - Claude Code Configuration

## Project Context Files

**Read these files before making changes to ensure you fully understand the project and contributing guidelines**

1. @README.md
2. @CONTRIBUTING.md
3. @charts/self-host/README.md
4. @charts/sm-operator/README.md

## Critical Rules

- **NEVER** commit secrets or credentials: Installation IDs, keys, passwords must be provided via Kubernetes secrets or CSI secret providers
- **NEVER** skip schema regeneration: After modifying values.yaml, always run `helm schema` to regenerate the JSON schema
- **ALWAYS** follow version resolution pattern: Component tag → coreVersionOverride → chart default
- **ALWAYS** add helm-unittest tests for new components or template logic changes
- **ALWAYS** use documentSelector in tests when templates produce multiple Kubernetes resources

## Project Structure

- **Charts**:
  - `/charts/self-host/` - Full Bitwarden self-hosted deployment (API, Identity, Web, Admin, SSO, etc.)
  - `/charts/sm-operator/` - Secrets Manager Kubernetes Operator
- **Templates**: `/charts/*/templates/` - Kubernetes manifests and Helm hooks (pre-install, post-install)
- **Tests**: `/charts/*/tests/` - helm-unittest test files
- **Scripts**: `/scripts/` - Local development with Kind cluster
- **CI Values**: `/charts/*/ci/test-values.yaml` - Test configuration for CI

## Common Commands

**Linting**:
```bash
ct lint --charts charts/self-host
ct lint --charts charts/sm-operator
```

**Schema Generation** (required after values.yaml changes):
```bash
helm plugin install https://github.com/dadav/helm-schema
cd charts/<chart-name>
helm schema -k additionalProperties --skip-auto-generation required
```

**Testing**:
```bash
helm plugin install https://github.com/helm-unittest/helm-unittest
helm unittest charts/self-host
helm unittest charts/sm-operator
```

**Local Development**:
```bash
# Full Kind cluster setup
./scripts/setup.sh all

# Or individual steps
./scripts/setup.sh create-cluster
./scripts/setup.sh setup-cluster
./scripts/setup.sh install-self-host
```

**Template Rendering**:
```bash
helm template charts/self-host --values charts/self-host/ci/test-values.yaml
helm template charts/sm-operator --values charts/sm-operator/ci/test-values.yaml
```

## Development Workflow

**Before making changes**:
- Read existing templates to understand patterns (version resolution, secret persistence, CSI volumes)
- Check `helpers.tpl` for reusable template functions
- Review existing tests to understand test patterns


**Pre-commit checklist**:
- [ ] Schema regenerated after values.yaml changes
- [ ] Tests added/updated for new functionality
- [ ] Linting passes: `ct lint --charts charts/<chart-name>`
- [ ] Unit tests pass: `helm unittest charts/<chart-name>`
- [ ] Templates render correctly with test values
- [ ] Breaking changes documented


## Security Requirements

- **Secret Management**: Support both Kubernetes secrets and CSI secret providers (Azure Key Vault, AWS Secrets Manager, etc.)
- **Service Accounts**: Proper RBAC for pre/post-install hooks and pod access to secrets
- **No Secrets in Values**: Installation IDs, keys, passwords, connection strings must never be in values.yaml


## References

### Official Documentation
- [Bitwarden Self-Host Documentation](https://bitwarden.com/help/self-host-an-organization/)
- [Bitwarden Helm Charts Repository](https://github.com/bitwarden/helm-charts)
- [Contributing Guidelines](https://contributing.bitwarden.com/contributing/)

### Chart Documentation
- [Self-Host Chart README](charts/self-host/README.md) - Comprehensive deployment guide with AKS, EKS, OpenShift examples
- [SM Operator Chart README](charts/sm-operator/README.md) - Operator installation and BitwardenSecret CRD usage

### Tools & Libraries
- [Helm Documentation](https://helm.sh/docs/)
- [helm-unittest](https://github.com/helm-unittest/helm-unittest)
- [helm-schema](https://github.com/dadav/helm-schema)
- [chart-testing (ct)](https://github.com/helm/chart-testing)
