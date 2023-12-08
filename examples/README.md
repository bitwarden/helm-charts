# Example Files

The files in this directory provide further examples for working with the Helm chart deployments. The scripts and other files here are provided as-is.

## Self-host chart

These following examples are for use with the `self-host` chart.

### Database Pod Backup and Restore Examples

We have provided two example jobs for backing up and restoring the database in the Bitwarden database pod. If you are using your own SQL Server instance that is not deployed as part of this Helm chart, please follow your corporate backup and restore policies. These are illustrative examples of what can be done. Database backups and backup policies are ultimately up to the implementor.

The example jobs for the database pod can be found in the `database-backup` and `database-restore` folders under the `examples` directory. Note that the backup could be scheduled outside of the cluster to run at a regular interval, or it could be modified to create a CronJob object within Kubernetes for scheduling purposes.

The backup job will create timestamped versions of the previous backups. The current backup is simply called `vault.bak`. These files are placed in the MS SQL backups persistent volume. The restore job will look for `vault.bak` in the same persistent volume.
