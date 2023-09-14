{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "bitwarden.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bitwarden.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bitwarden.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "bitwarden.serviceAccountName" -}}
{{- default (include "bitwarden.fullname" .) .Values.serviceAccount.name -}}
{{- end -}}

{{/*
Generate basic labels
*/}}
{{- define "bitwarden.labels" -}}
app.kubernetes.io/name: {{ template "bitwarden.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ template "bitwarden.chart" . }}
{{- if .Values.general.labels }}
{{ toYaml .Values.general.labels }}
{{- end -}}
{{- end -}}

{{/*
The database connection string
The database name must remain as 'vault' as services such as the webhook container requires it.
*/}}
{{- define "bitwarden.dbConnectionString" -}}
{{ printf "Data Source=tcp:%s,%v;Initial Catalog=vault;Persist Security Info=False;User ID=%s;Password=%s;MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True" .Values.database.hostname .Values.database.port .Values.database.user .Values.database.password }}
{{- end -}}

{{/*
Name of Admin components
*/}}
{{- define "bitwarden.admin" -}}
{{ template "bitwarden.fullname" . }}-admin
{{- end -}}

{{/*
Name of API components
*/}}
{{- define "bitwarden.api" -}}
{{ template "bitwarden.fullname" . }}-api
{{- end -}}

{{/*
Name of Attachments components
*/}}
{{- define "bitwarden.attachments" -}}
{{ template "bitwarden.fullname" . }}-attachments
{{- end -}}

{{/*
Name of Events components
*/}}
{{- define "bitwarden.events" -}}
{{ template "bitwarden.fullname" . }}-events
{{- end -}}

{{/*
Name of Icons components
*/}}
{{- define "bitwarden.icons" -}}
{{ template "bitwarden.fullname" . }}-icons
{{- end -}}

{{/*
Name of Identity components
*/}}
{{- define "bitwarden.identity" -}}
{{ template "bitwarden.fullname" . }}-identity
{{- end -}}

{{/*
Name of MSSQL components
*/}}
{{- define "bitwarden.mssql" -}}
{{ template "bitwarden.fullname" . }}-mssql
{{- end -}}

{{/*
Name of Notifications components
*/}}
{{- define "bitwarden.notifications" -}}
{{ template "bitwarden.fullname" . }}-notifications
{{- end -}}

{{/*
Name of SSO components
*/}}
{{- define "bitwarden.sso" -}}
{{ template "bitwarden.fullname" . }}-sso
{{- end -}}

{{/*
Name of Web components
*/}}
{{- define "bitwarden.web" -}}
{{ template "bitwarden.fullname" . }}-web
{{- end -}}

{{/*
Name of Webhook components
*/}}
{{- define "bitwarden.webhook" -}}
{{ template "bitwarden.fullname" . }}-webhook
{{- end -}}

{{/*
Name of Dataprotection volume
*/}}
{{- define "bitwarden.dataprotection" -}}
{{ template "bitwarden.fullname" . }}-dataprotection
{{- end -}}

{{/*
Name of Licenses volume
*/}}
{{- define "bitwarden.licenses" -}}
{{ template "bitwarden.fullname" . }}-licenses
{{- end -}}

{{/*
Name of MSSQL Backups volume
*/}}
{{- define "bitwarden.mssqlBackups" -}}
{{ template "bitwarden.fullname" . }}-mssqlbackups
{{- end -}}

{{/*
Name of MSSQL Data volume
*/}}
{{- define "bitwarden.mssqlData" -}}
{{ template "bitwarden.fullname" . }}-mssqldata
{{- end -}}

{{/*
Name of MSSQL Log volume
*/}}
{{- define "bitwarden.mssqlLog" -}}
{{ template "bitwarden.fullname" . }}-mssqllog
{{- end -}}

{{/*
Name of the Secret Provider Class
*/}}
{{- define "bitwarden.secretProviderClass" -}}
{{ template "bitwarden.fullname" . }}-secretproviderclass
{{- end -}}
