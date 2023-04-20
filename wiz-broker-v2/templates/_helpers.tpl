{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-broker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-broker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-broker.labels" -}}
helm.sh/chart: {{ include "wiz-broker.chart" . }}
{{ include "wiz-broker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{- range $index, $content := .Values.commonLabels }}
{{ $index }}: {{ tpl $content $ }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wiz-broker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-broker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create Wiz broker properties to use
*/}}

{{- define "wiz-broker.wizConnectorSecretData" -}}
{{- if not .Values.global.autoCreateConnector }}
CONNECTOR_ID: {{ required "A valid .Values.global.wizConnector.connectorId entry required!" .Values.global.wizConnector.connectorId | quote}}
CONNECTOR_TOKEN: {{ required "A valid .Values.global.wizConnector.connectorToken entry required!" .Values.global.wizConnector.connectorToken | quote }}
TARGET_DOMAIN: {{ required "A valid .Values.global.wizConnector.targetDomain entry required!" .Values.global.wizConnector.targetDomain | quote }}
TARGET_IP: {{ required "A valid .Values.global.wizConnector.targetIp entry required!" .Values.global.wizConnector.targetIp | quote }}
TARGET_PORT: {{ required "A valid .Values.global.wizConnector.targetPort entry required!" .Values.global.wizConnector.targetPort | quote }}
{{- end }}
{{- end }}

{{/*
Secrets names
*/}}

{{- define "wiz-broker.apiTokenSecretName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (printf "%s-api-token" .Release.Name) }}
{{- end }}

{{- define "wiz-broker.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (printf "%s-proxy-configuration" .Release.Name) }}
{{- end }}

{{- define "wiz-broker.connectorSecretName" -}}
{{ coalesce (.Values.global.wizConnector.secretName) (printf "%s-connector" .Release.Name) }}
{{- end }}