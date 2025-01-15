{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-network-analyzer.name" -}}
{{- $nameOverride := coalesce .Values.global.nameOverride .Values.nameOverride }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-network-analyzer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-network-analyzer.labels" -}}
helm.sh/chart: {{ include "wiz-network-analyzer.chart" . }}
{{ include "wiz-network-analyzer.selectorLabels" . }}
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
{{- define "wiz-network-analyzer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-network-analyzer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create Wiz Network Analyzer properties to use
*/}}


{{/*
Secrets names
*/}}

{{- define "wiz-network-analyzer.apiTokenSecretName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (.Values.wizApiToken.secret.name) (printf "%s-na-api-token" .Release.Name) }}
{{- end }}

{{- define "wiz-network-analyzer.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (.Values.httpProxyConfiguration.secretName) (printf "%s-na-proxy-configuration" .Release.Name) }}
{{- end }}

{{- define "wiz-network-analyzer.caSecretName" -}}
{{ coalesce (.Values.caCertificate.secretName) (printf "%s-na-ca" .Release.Name) }}
{{- end }}

{{/*
Input parameters
*/}}
{{- define "wiz-network-analyzer.apiServerEndpoint" -}}
  {{- $url := urlParse .Values.apiServerEndpoint}}
  {{- if not (and $url.host $url.scheme) }}
    {{- fail "Invalid URL format for .Values.apiServerEndpoint" }}
  {{- else }}
    {{ printf "%s" .Values.apiServerEndpoint }}
  {{- end }}
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

{{- define "wiz-network-analyzer.wizApiTokenHash" -}}
{{ include "helpers.calculateHash" (list .Values.wizApiToken.clientId .Values.wizApiToken.clientToken .Values.wizApiToken.secret.name) }}
{{- end }}

{{- define "wiz-network-analyzer.proxyHash" -}}
{{ include "helpers.calculateHash" (list .Values.httpProxyConfiguration.httpProxy .Values.httpProxyConfiguration.httpsProxy .Values.httpProxyConfiguration.noProxyAddress .Values.httpProxyConfiguration.secretName) }}
{{- end }}

{{- define "wiz-network-analyzer.entrypoint" -}}
{{- if .Values.istio.enabled -}}
- "sh"
- "-c"
{{- else -}}
- "wiz-network-analyzer"
{{- end -}}
{{- end }}

{{- define "wiz-network-analyzer.argsList" -}}
analyze
--output
/tmp
{{- if .Values.outpostId }}
--outpost-id
"{{ .Values.outpostId }}"
{{- end }}
--region
{{ .Values.wizRegion }}
{{- if and .Values.caCertificate.enabled }}
--proxy-ca-dir
/usr/local/share/ca-certificates
{{- end }}
{{- end }}

{{- define "wiz-kubernetes.pre-istio-sidecar" -}}
{{- printf "sleep %d" (int (.Values.istio.sleepBeforeJobSecs | default 15)) -}}
{{- end -}}

{{- define "wiz-kubernetes.post-istio-sidecar" -}}
{{- printf "curl --max-time 2 -s -f -XPOST http://127.0.0.1:%d/quitquitquit" (int (.Values.istio.proxySidecarPort | default 15000)) -}}
{{- end -}}

{{- define "wiz-network-analyzer.generateArgs" -}}
{{- $args := include "wiz-network-analyzer.argsList" . | trim | splitList "\n" -}}
{{- if .Values.istio.enabled -}}
{{- $first := include "wiz-kubernetes.pre-istio-sidecar" . | trim -}}
{{- $last := include "wiz-kubernetes.post-istio-sidecar" . | trim -}}
{{- $argsWithIstio := printf "%s &&\nwiz-network-analyzer %s &&\n%s" $first (join " \n" $args) $last -}}
  - >
    {{- printf "%s" $argsWithIstio | nindent 2 }}
{{- else -}}
{{- range $arg := $args }}
- {{ $arg | trim }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-network-analyzer.image" -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ coalesce .Values.global.image.tag .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
