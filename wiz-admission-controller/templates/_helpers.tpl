{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-admission-controller.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wiz-admission-controller.fullname" -}}
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
{{- define "wiz-admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-admission-controller.labels" -}}
helm.sh/chart: {{ include "wiz-admission-controller.chart" . }}
{{ include "wiz-admission-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{- range $index, $content := .Values.commonLabels }}
{{ $index }}: {{ tpl $content $ }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Wiz admission controller webhook server selector labels
*/}}
{{- define "wiz-admission-controller.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-admission-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wiz-admission-controller.serviceAccountName" -}}
{{ coalesce (.Values.serviceAccount.name) (include "wiz-admission-controller.fullname" .) }}
{{- end }}

{{- define "wiz-admission-controller.secretApiTokenName" -}}
{{ coalesce (.Values.secret.name) (printf "%s-%s" .Release.Name "api-token") }}
{{- end }}

{{- define "wiz-admission-controller.secretServerCert" -}}
{{ include "wiz-admission-controller.fullname" . }}-cert
{{- end }}

{{- define "wiz-admission-controller.opaCliParams.policies" -}}
{{- if .Values.opaWebhook.policies }}
--policy={{ join " --policy=" .Values.opaWebhook.policies }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.proxySecretName" -}}
{{ coalesce (.Values.httpProxyConfiguration.secretName) (printf "%s-%s" .Release.Name "-proxy-configuration") }}
{{- end }}
