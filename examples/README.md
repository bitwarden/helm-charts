# Example Files

The files in this directory provide further examples for working with the Helm chart deployments. The scripts and other files here are provided as-is.

## Self-host chart

These following examples are for use with the `self-host` chart.

### Database Pod Backup and Restore Examples

These examples back up and restore the database in the chart's database pod. They are illustrative only. If you run your own SQL Server, follow your own backup and restore policies. Update the secret and persistent volume claim names in the manifests to match your release name.

#### Backup

`database-backup/backup-cronjob.yaml` runs nightly at 00:00 UTC, like the standard self-hosted backup. Each run writes `vault_FULL_<YYYYmmdd_HHMMSS>.BAK` to the backups volume, points `vault.bak` at it, and deletes backups older than `BACKUP_RETENTION_DAYS` (default 32). If the backup fails, the job fails and no files are changed or deleted.

`database-backup/db-backup.sh` runs the same backup on demand, using `backup-job.yaml`.

- Size `database.volume.backups.size` for `BACKUP_RETENTION_DAYS` of full backups. With a `ReadWriteOnce` backups volume, the backup pod must run on the same node as the database pod.
- Keep the image tag in line with `database.image.tag`.
- A plain `vault.bak` from earlier versions of this example is renamed to `vault.bak.<timestamp>`. Retention does not remove these files; delete them yourself.

#### Restore

`database-restore/restore-job.yaml` restores from `vault.bak`, the latest successful backup. To restore an older backup, point `vault.bak` at that file.
