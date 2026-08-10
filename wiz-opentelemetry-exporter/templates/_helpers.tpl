{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-opentelemetry-exporter.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Fully qualified app name.
*/}}
{{- define "wiz-opentelemetry-exporter.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := include "wiz-opentelemetry-exporter.name" . }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart name and version as used by the chart label.
*/}}
{{- define "wiz-opentelemetry-exporter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-opentelemetry-exporter.labels" -}}
helm.sh/chart: {{ include "wiz-opentelemetry-exporter.chart" . }}
{{ include "wiz-opentelemetry-exporter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $index, $content := .Values.commonLabels }}
{{ $index }}: {{ tpl $content $ | quote }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wiz-opentelemetry-exporter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-opentelemetry-exporter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Wiz API token secret name
*/}}
{{- define "wiz-opentelemetry-exporter.apiTokenSecretName" -}}
{{ coalesce .Values.wizApiToken.secret.name (printf "%s-otel-exporter-api-token" .Release.Name) }}
{{- end }}

{{/*
Image reference
*/}}
{{- define "wiz-opentelemetry-exporter.image" -}}
{{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
