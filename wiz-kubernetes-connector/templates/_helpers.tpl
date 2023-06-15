{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-kubernetes-connector.name" -}}
{{- $nameOverride := coalesce .Values.global.nameOverride .Values.nameOverride }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-kubernetes-connector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-kubernetes-connector.labels" -}}
helm.sh/chart: {{ include "wiz-kubernetes-connector.chart" . }}
{{ include "wiz-kubernetes-connector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.commonLabels }}
{{- range $index, $content := .Values.commonLabels }}
{{ $index }}: {{ tpl $content $ }}
{{- end }}
{{- end }}
{{- if .Values.global.commonLabels }}
{{- range $index, $content := .Values.global.commonLabels }}
{{ $index }}: {{ tpl $content $ }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wiz-kubernetes-connector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-kubernetes-connector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create Wiz connector properties to use
*/}}

{{- define "wiz-kubernetes-connector.wizConnectorSecretData" -}}
{{- if not .Values.autoCreateConnector.enabled }}
CONNECTOR_ID: {{ required "A valid .Values.wizConnector.connectorId entry required!" .Values.wizConnector.connectorId | quote}}
CONNECTOR_TOKEN: {{ required "A valid .Values.wizConnector.connectorToken entry required!" .Values.wizConnector.connectorToken | quote }}
TARGET_DOMAIN: {{ required "A valid .Values.wizConnector.targetDomain entry required!" .Values.wizConnector.targetDomain | quote }}
TARGET_IP: {{ required "A valid .Values.wizConnector.targetIp entry required!" .Values.wizConnector.targetIp | quote }}
TARGET_PORT: {{ required "A valid .Values.wizConnector.targetPort entry required!" .Values.wizConnector.targetPort | quote }}
{{- end }}
{{- end }}

{{/*
Secrets names
*/}}

{{- define "wiz-kubernetes-connector.apiTokenSecretName" -}}
{{- $nameOverride := coalesce .Values.global.nameOverride .Values.nameOverride }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wiz-kubernetes-connector.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (.Values.httpProxyConfiguration.secretName) (printf "%s-proxy-configuration" .Release.Name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.connectorSecretName" -}}
{{ coalesce (.Values.wizConnector.secretName) (printf "%s-connector" .Release.Name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.clusterReaderToken" -}}
{{ printf "%s-token" .Values.clusterReader.serviceAccount.name }}
{{- end }}

{{/*
Input parameters
*/}}
{{- define "wiz-kubernetes-connector.apiServerEndpoint" -}}
  {{- if and .Values.autoCreateConnector.enabled (not .Values.broker.enabled) }}
    {{- required "A valid .Values.autoCreateConnector.apiServerEndpoint entry required!" .Values.autoCreateConnector.apiServerEndpoint -}}
  {{- else -}}
    {{ if .Values.autoCreateConnector.apiServerEndpoint }}
      {{- $url := urlParse .Values.autoCreateConnector.apiServerEndpoint}}
      {{- if not (and $url.host $url.scheme) }}
        {{- fail "Invalid URL format for .Values.autoCreateConnector.apiServerEndpoint" }}
      {{- else }}
        {{ printf "%s" .Values.autoCreateConnector.apiServerEndpoint }}
      {{- end }}
    {{ else }}
      {{ printf "https://kubernetes.default.svc.cluster.local" }}
    {{- end -}}
  {{- end -}}
{{- end }}

{{/*
This function dump the value of a variable and fail the template execution.
Use for debug purpose only.
*/}}
{{- define "helpers.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}
