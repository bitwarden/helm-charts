{{/* vim: set filetype=mustache: */}}

{{/*
Expand the name of the chart.
*/}}
{{- define "bitwarden.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bitwarden.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "bitwarden.fullname" -}}
{{- $name := .Chart.Name -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Generate basic labels
*/}}
{{- define "bitwarden.labels" -}}
app.kubernetes.io/name: {{ template "bitwarden.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ template "bitwarden.chart" . }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end -}}
{{- end -}}

{{/*
The name of the service account to use
*/}}
{{- define "bitwarden.serviceAccountName" -}}
{{- default (include "bitwarden.fullname" .) .Values.serviceAccountName -}}
{{- end -}}

{{/*
The database connection string for RDS
*/}}
{{- define "bitwarden.rdsConnectionString" -}}
{{ printf "Data Source=tcp:%s,%v;Initial Catalog=vault;Persist Security Info=False;User ID=%s;Password=%s;MultipleActiveResultSets=False;Connect Timeout=30;Encrypt=True;TrustServerCertificate=True"
   .Values.rdsHostname
   .Values.rdsPort
   .Values.rdsUser
   .Values.rdsPassword }}
{{- end -}}
