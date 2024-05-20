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
{{ $index }}: {{ tpl $content $ | quote }}
{{- end }}
{{- end }}
{{- if .Values.global.commonLabels }}
{{- range $index, $content := .Values.global.commonLabels }}
{{ $index }}: {{ tpl $content $ | quote }}
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

{{/*
Secrets names
*/}}

{{- define "wiz-kubernetes-connector.apiTokenSecretName" -}}
{{- $nameOverride := coalesce .Values.global.wizApiToken.secret.name  .Values.wizApiToken.secret.name .Values.global.nameOverride .Values.nameOverride }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wiz-kubernetes-connector.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (.Values.httpProxyConfiguration.secretName) (printf "%s-proxy-configuration" .Release.Name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.connectorSecretName" -}}
{{ coalesce (index .Values "wiz-broker" "wizConnector.secretName") (printf "%s-connector" .Release.Name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.clusterReaderToken" -}}
{{ printf "%s-token" .Values.clusterReader.serviceAccount.name }}
{{- end }}

{{- define "wiz-kubernetes-connector.brokerEnabled" -}}
{{ index .Values "wiz-broker" "enabled" }}
{{- end }}

{{/*
Input parameters
*/}}
{{- define "wiz-kubernetes-connector.apiServerEndpoint" -}}
  {{- if and .Values.autoCreateConnector.enabled (not "wiz-kubernetes-connector.brokerEnabled") }}
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

{{- define "helpers.calculateHash" -}}
{{- $list := . -}}
{{- $hash := printf "%s" $list | sha256sum -}}
{{- $hash := $hash | trimSuffix "\n" -}}
{{- $hash -}}
{{- end -}}

{{- define "wiz-kubernetes-connector.wizApiTokenHash" -}}
{{ include "helpers.calculateHash" (list .Values.global.wizApiToken.clientId .Values.global.wizApiToken.clientToken .Values.global.wizApiToken.secret.name .Values.wizApiToken.clientId .Values.wizApiToken.clientToken .Values.wizApiToken.secret.name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.proxyHash" -}}
{{ include "helpers.calculateHash" (list .Values.global.httpProxyConfiguration.httpProxy .Values.global.httpProxyConfiguration.httpsProxy .Values.global.httpProxyConfiguration.noProxyAddress .Values.global.httpProxyConfiguration.secretName .Values.httpProxyConfiguration.httpProxy .Values.httpProxyConfiguration.httpsProxy .Values.httpProxyConfiguration.noProxyAddress .Values.httpProxyConfiguration.secretName) }}
{{- end }}

{{- define "wiz-kubernetes-connector.brokerHash" -}}
{{ include "helpers.calculateHash" (list "wiz-kubernetes-connector.brokerHash" (index .Values "wiz-broker" "wizConnector.targetIp")) }}
{{- end }}
