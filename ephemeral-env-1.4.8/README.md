# Ephemeral Environment Chart
## Minimal Configuration
```
general:
  coreVersion: "server-branch-name"
  webVersion: "web-branch-name"
  domain: "<random-id>.eph.bitwarden.pw"
  email:
    replyToEmail: "no-reply@<random-id>.eph.bitwarden.pw"
  admins: "<list of admins from the Storage Account>"

ingress:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt  # defaults to letsencrypt-staging. Should we change this at some point?
```

## `tmp`
Until we have a fully functioning EE management system, `tmp` will hold the value files for any manually created
ephemeral environments. The name of the value file will match the namespace it is deployed in on the QA cluster.
