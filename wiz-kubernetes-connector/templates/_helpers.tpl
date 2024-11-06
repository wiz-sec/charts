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

{{- define "wiz-kubernetes-connector.wizConnectorSecretData" -}}
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

{{- define "wiz-kubernetes-connector.apiTokenSecretName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (.Values.wizApiToken.secret.name) (printf "%s-api-token" .Release.Name) }}
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
{{ include "helpers.calculateHash" (list .Values.wizApiToken.clientId .Values.wizApiToken.clientToken .Values.wizApiToken.secret.name) }}
{{- end }}

{{- define "wiz-kubernetes-connector.proxyHash" -}}
{{ include "helpers.calculateHash" (list .Values.httpProxyConfiguration.httpProxy .Values.httpProxyConfiguration.httpsProxy .Values.httpProxyConfiguration.noProxyAddress .Values.httpProxyConfiguration.secretName) }}
{{- end }}

{{- define "wiz-kubernetes-connector.brokerHash" -}}
{{ include "helpers.calculateHash" (list "wiz-kubernetes-connector.brokerHash" (index .Values "wiz-broker" "wizConnector.targetIp")) }}
{{- end }}

{{- define "wiz-kubernetes-connector.entrypoint" -}}
{{- if .Values.autoCreateConnector.istio.enabled -}}
- "sh"
- "-c"
{{- else -}}
- "wiz-broker"
{{- end -}}
{{- end }}

{{- define "wiz-kubernetes-connector.argsListCreateConnector" -}}
create-kubernetes-connector
--api-server-endpoint
{{ include "wiz-kubernetes-connector.apiServerEndpoint" . | trim | quote }}
--secrets-namespace
{{ .Release.Namespace | quote }}
--service-account-token-secret-name
{{ include "wiz-kubernetes-connector.clusterReaderToken" . | quote }}
--output-secret-name
{{ include "wiz-kubernetes-connector.connectorSecretName" . | trim | quote }}
--is-on-prem={{ include "wiz-kubernetes-connector.brokerEnabled" . | trim}}
{{- with .Values.autoCreateConnector.connectorName }}
--connector-name
{{ . | quote }}
{{- end }}
{{- with .Values.autoCreateConnector.clusterFlavor }}
--service-type
{{ . | quote }}
{{- end }}
{{- with (coalesce .Values.global.clusterExternalId .Values.autoCreateConnector.clusterExternalId) }}
--cluster-external-id
{{ . | quote }}
{{- end }}
{{- with (coalesce .Values.global.subscriptionExternalId .Values.autoCreateConnector.subscriptionExternalId) }}
--subscription-external-id
{{ . | quote }}
{{- end }}
{{- with (coalesce .Values.global.clusterTags .Values.autoCreateConnector.clusterTags) }}
--cluster-tags
{{ . | toJson | quote }}
{{- end }}
{{- with (coalesce .Values.global.subscriptionTags .Values.autoCreateConnector.subscriptionTags) }}
--subscription-tags
{{ . | toJson | quote }}
{{- end }}
--wait={{ and (include "wiz-kubernetes-connector.brokerEnabled" . | trim) .Values.autoCreateConnector.waitUntilInitialized }}
{{- end }}

{{- define "wiz-kubernetes.pre-istio-sidecar" -}}
{{- printf "sleep %d" (int (.Values.autoCreateConnector.istio.sleepBeforeJobSecs | default 15)) -}}
{{- end -}}

{{- define "wiz-kubernetes.post-istio-sidecar" -}}
{{- printf "curl --max-time 2 -s -f -XPOST http://127.0.0.1:%d/quitquitquit" (int (.Values.autoCreateConnector.istio.proxySidecarPort | default 15000)) -}}
{{- end -}}

{{- define "wiz-kubernetes-connector.generateArgsCreate" -}}
{{- $args := include "wiz-kubernetes-connector.argsListCreateConnector" . | splitList "\n" -}}
{{- if .Values.autoCreateConnector.istio.enabled -}}
{{- $first := include "wiz-kubernetes.pre-istio-sidecar" . -}}
{{- $last := include "wiz-kubernetes.post-istio-sidecar" . -}}
{{- $argsWithIstio := printf "%s &&\nwiz-broker %s &&\n%s" $first (join " \n" $args) $last -}}
  - >
    {{- printf "%s" $argsWithIstio | nindent 2 }}
{{- else -}}
{{- range $arg := $args }}
- {{ $arg }}
{{- end }}
{{- end -}}
{{- end }}

{{- define "wiz-kubernetes-connector.generate-args-list-delete" -}}
delete-kubernetes-connector
--input-secrets-namespace
{{ .Release.Namespace | quote }}
--input-secret-name
{{ include "wiz-kubernetes-connector.connectorSecretName" . | trim | quote }}
|| true
{{- end }}

{{- define "wiz-kubernetes-connector.argsListDeleteConnector" -}}
{{- $args := include "wiz-kubernetes-connector.generate-args-list-delete" . | splitList "\n" -}}
{{- $output := "kuku" }}
{{- if .Values.autoCreateConnector.istio.enabled -}}
{{- $first := include "wiz-kubernetes.pre-istio-sidecar" . -}}
{{- $last := include "wiz-kubernetes.post-istio-sidecar" . -}}
{{- $output = printf "%s &&\nwiz-broker %s &&\n%s" $first (join " \n" $args) $last -}}
{{- else -}}
{{- $output = printf "wiz-broker %s" (join " \n" $args) -}}
{{- end -}}
  - >
    {{- printf "%s" $output | nindent 2 }}
{{- end }}

{{- define "wiz-broker.image" -}}
{{- if .Values.global.isFedRamp -}}
publicregistryfedrampwizio.azurecr.us/wiz-app/wiz-broker-fips:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
{{- end -}}

{{- define "wiz-broker.clientEndpoint" -}}
{{- $clientEndpoint := coalesce .Values.global.wizApiToken.clientEndpoint .Values.wizApiToken.clientEndpoint | quote -}}
{{- if and (empty $clientEndpoint) .Values.global.isFedRamp -}}
  "fedramp"
{{- else -}}
  {{ $clientEndpoint }}
{{- end -}}
{{- end -}}
