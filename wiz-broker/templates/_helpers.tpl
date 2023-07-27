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
Deployment name.
*/}}
{{- define "wiz-broker.deploymentName" -}}
{{ printf "%s-agent" .Release.Name }}
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
{{- if .Values.global.broker.createSecret }}
ConnectorId: {{ required "A valid .Values.global.wizConnector.connectorId entry required!" .Values.global.wizConnector.connectorId | quote}}
TunnelToken: {{ required "A valid .Values.global.wizConnector.connectorToken entry required!" .Values.global.wizConnector.connectorToken | quote }}
TunnelDomain: {{ required "A valid .Values.global.wizConnector.targetDomain entry required!" .Values.global.wizConnector.targetDomain | quote }}
TunnelServerDomain: {{ required "A valid .Values.global.wizConnector.tunnelServerDomain entry required!" .Values.global.wizConnector.tunnelServerDomain | quote }}
TunnelServerPort: {{ required "A valid .Values.global.wizConnector.tunnelServerPort entry required!" .Values.global.wizConnector.tunnelServerPort | quote }}
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