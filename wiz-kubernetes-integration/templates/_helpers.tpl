{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-kubernetes-integration.name" -}}
{{- default .Chart.Name .Values.global.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wiz-kubernetes-integration.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.global.nameOverride }}
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
{{- define "wiz-kubernetes-integration.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-kubernetes-integration.labels" -}}
helm.sh/chart: {{ include "wiz-kubernetes-integration.chart" . }}
{{ include "wiz-kubernetes-integration.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Values.global.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.global.commonLabels }}
{{- range $index, $content := .Values.global.commonLabels }}
{{ $index }}: {{ tpl $content $ | quote }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-kubernetes-integration.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-kubernetes-integration.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "wiz-kubernetes-integration.secretApiTokenName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (printf "%s-api-token" .Release.Name) }}
{{- end }}

{{- define "wiz-kubernetes-integration.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (printf "%s-%s" .Release.Name "proxy-configuration") }}
{{- end }}
