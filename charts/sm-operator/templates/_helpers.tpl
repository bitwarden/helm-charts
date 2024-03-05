{{/*
Expand the name of the chart.
*/}}
{{- define "sm-operator.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sm-operator.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sm-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sm-operator.labels" -}}
helm.sh/chart: {{ include "sm-operator.chart" . }}
{{ include "sm-operator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sm-operator.fullLabels" -}}
{{ include "sm-operator.labels" . }}
app.kubernetes.io/created-by: {{ include "sm-operator.name" . }}
app.kubernetes.io/part-of: {{ include "sm-operator.name" . }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "sm-operator.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sm-operator.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "sm-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sm-operator.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the keys secret
*/}}
{{- define "sm-operator.configmap" -}}
{{ template "sm-operator.fullname" . }}-config-map
{{- end -}}
