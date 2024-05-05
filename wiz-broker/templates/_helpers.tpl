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
Service account name.
*/}}
{{- define "wiz-broker.serviceAccountName" -}}
{{ coalesce (.Values.serviceAccount.name) (printf "%s-wiz-broker-sa" .Release.Name) }}
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
{{ $index }}: {{ tpl $content $ | quote }}
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
{{- if and .Values.wizConnector.createSecret (not .Values.wizConnector.autoCreated) }}
ConnectorId: {{ required "A valid .Values.wizConnector.connectorId entry required!" .Values.wizConnector.connectorId | quote}}
TunnelToken: {{ required "A valid .Values.wizConnector.connectorToken entry required!" .Values.wizConnector.connectorToken | quote }}
TunnelDomain: {{ required "A valid .Values.wizConnector.targetDomain entry required!" .Values.wizConnector.targetDomain | quote }}
TunnelServerDomain: {{ required "A valid .Values.wizConnector.tunnelServerDomain entry required!" .Values.wizConnector.tunnelServerDomain | quote }}
TunnelServerPort: {{ required "A valid .Values.wizConnector.tunnelServerPort entry required!" .Values.wizConnector.tunnelServerPort | quote }}
TargetIp: {{ required "A valid .Values.wizConnector.targetIp entry required!" .Values.wizConnector.targetIp | quote }}
TargetPort: {{ required "A valid .Values.wizConnector.targetPort entry required!" .Values.wizConnector.targetPort | quote }}
{{- if .Values.wizConnector.tunnelClientAllowedDomains }}
TunnelClientAllowedDomains: "{{ range $index, $domain := .Values.wizConnector.tunnelClientAllowedDomains }}{{ if $index }},{{ end }}{{ $domain }}{{ end }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Secrets names
*/}}

{{- define "wiz-broker.apiTokenSecretName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (printf "%s-api-token" .Release.Name) }}
{{- end }}

{{- define "wiz-broker.caCertificateSecretName" -}}
{{ coalesce (.Values.caCertificate.secretName) (printf "%s-ca-certificate" .Release.Name) }}
{{- end }}

{{- define "wiz-broker.mtlsSecretName" -}}
{{- with .Values.mtls }}
{{- if and .createSecret (not (and .certificate .privateKey)) }}
  {{- fail "Both client certificate and private key must be provided" }}
{{- end }}
{{ coalesce (.secretName) (printf "%s-mtls" $.Release.Name) }}
{{- end }}
{{- end }}

{{- define "wiz-broker.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (printf "%s-proxy-configuration" .Release.Name) }}
{{- end }}

{{- define "wiz-broker.connectorSecretName" -}}
{{ coalesce (.Values.wizConnector.secretName) (printf "%s-connector" .Release.Name) }}
{{- end }}
