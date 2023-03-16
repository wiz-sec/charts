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
Create the name of the service account to use
*/}}
{{- define "wiz-broker.serviceAccountName" -}}
{{- default (include "wiz-broker.name" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Create the name of the service account to use for rbac
*/}}
{{- define "wiz-broker.rbacServiceAccountName" -}}
{{- default (printf "%s-%s" (include "wiz-broker.name" .) "rbac") .Values.rbacServiceAccount.name }}
{{- end }}

{{/*
Create Wiz connector properties to use
*/}}
{{- define "wiz-broker.wizConnectorID" -}}
{{ required "A valid .Values.wizConnector.connectorId entry required!" .Values.wizConnector.connectorId }}
{{- end }}

{{- define "wiz-broker.wizConnectorSecretData" -}}
CONNECTOR_ID: {{ include "wiz-broker.wizConnectorID" . | quote}}
CONNECTOR_TOKEN: {{ required "A valid .Values.wizConnector.connectorToken entry required!" .Values.wizConnector.connectorToken | quote }}
TARGET_DOMAIN: {{ required "A valid .Values.wizConnector.targetDomain entry required!" .Values.wizConnector.targetDomain | quote }}
TARGET_IP: {{ required "A valid .Values.wizConnector.targetIp entry required!" .Values.wizConnector.targetIp | quote }}
TARGET_PORT: {{ required "A valid .Values.wizConnector.targetPort entry required!" .Values.wizConnector.targetPort | quote }}
TUNNEL_SERVER_ADDR: {{ required "A valid .Values.wizConnector.tunnelServerAddress entry required!" .Values.wizConnector.tunnelServerAddress | quote }}
TUNNEL_SERVER_PORT: {{ required "A valid .Values.wizConnector.tunnelServerPort entry required!" .Values.wizConnector.tunnelServerPort | quote }}
DISABLE_CUSTOM_TLS_FIRST_BYTE: "true"
{{- if .Values.wizConnector.httpProxy }}
HTTP_PROXY: {{ .Values.wizConnector.httpProxy | quote}}
{{- end }}

{{- end }}
