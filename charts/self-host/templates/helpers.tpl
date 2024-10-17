{{- define "bitwarden.coreVersionDefault" -}}
{{- "2024.10.0" -}}
{{- end -}}
{{- define "bitwarden.webVersionDefault" -}}
{{- "2024.10.2" -}}
{{- end -}}

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
Generate basic labels
*/}}
{{- define "bitwarden.rawPostInstallAnnotations" -}}
"helm.sh/hook": post-install,post-upgrade
"helm.sh/hook-weight": "9"
{{- end -}}

{{/*
Generate basic labels
*/}}
{{- define "bitwarden.rawPreInstallAnnotations" -}}
"helm.sh/hook": pre-install,pre-upgrade
"helm.sh/hook-weight": "0"
{{- end -}}


{{/*
Name of Web components
*/}}
{{- define "bitwarden.web" -}}
{{ template "bitwarden.fullname" . }}-web
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
Name of Webhook components
*/}}
{{- define "bitwarden.webhook" -}}
{{ template "bitwarden.fullname" . }}-webhook
{{- end -}}


{{/*
Name of MSSQL components
*/}}
{{- define "bitwarden.mssql" -}}
{{ template "bitwarden.fullname" . }}-mssql
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
Name of Logs volume
*/}}
{{- define "bitwarden.applogs" -}}
{{ template "bitwarden.fullname" . }}-applogs
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

{{/*
Name of Ingress components
*/}}
{{- define "bitwarden.ingress" -}}
{{ template "bitwarden.fullname" . }}-ingress
{{- end -}}

{{/*
Name of Feature Flag configMap
*/}}
{{- define "bitwarden.featureflags" -}}
{{ template "bitwarden.fullname" . }}-featureflags
{{- end -}}

{{/*
Name of SCIM components
*/}}
{{- define "bitwarden.scim" -}}
{{ template "bitwarden.fullname" . }}-scim
{{- end -}}

{{/*
Name of the keys secret
*/}}
{{- define "bitwarden.keyssecret" -}}
{{ template "bitwarden.fullname" . }}-secretkeys
{{- end -}}
