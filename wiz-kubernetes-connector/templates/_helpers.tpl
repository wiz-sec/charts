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
TunnelServerPort: {{ int (required "A valid .Values.wizConnector.tunnelServerPort entry required!" .Values.wizConnector.tunnelServerPort) }}
TargetIp: {{ required "A valid .Values.wizConnector.targetIp entry required!" .Values.wizConnector.targetIp | quote }}
TargetPort: {{ int (required "A valid .Values.wizConnector.targetPort entry required!" .Values.wizConnector.targetPort) }}
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
- "wiz-broker"
{{- end }}

{{- define "wiz-kubernetes-connector.argsListCreateConnector" -}}
create-kubernetes-connector
--api-server-endpoint
{{ include "wiz-kubernetes-connector.apiServerEndpoint" . | trim | quote }}
--secrets-namespace
{{ .Release.Namespace | quote }}
{{- if .Values.refreshToken.enabled }}
--service-account-namespace
{{ .Release.Namespace | quote }}
--service-account-name
{{ .Values.clusterReader.serviceAccount.name | quote }}
{{- else }}
--service-account-token-secret-name
{{ include "wiz-kubernetes-connector.clusterReaderToken" . | quote }}
{{- end }}
--output-secret-name
{{ include "wiz-kubernetes-connector.connectorSecretName" . | trim | quote }}
--is-on-prem={{ include "wiz-kubernetes-connector.brokerEnabled" . | trim}}
{{- with (coalesce .Values.global.clusterDisplayName .Values.autoCreateConnector.connectorName) }}
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

{{- define "wiz-kubernetes-connector.generateArgsCreate" -}}
{{- $args := include "wiz-kubernetes-connector.argsListCreateConnector" . | splitList "\n" -}}
{{- range $arg := $args }}
- {{ $arg }}
{{- end }}
{{- end }}

{{- define "wiz-kubernetes-connector.generate-args-list-delete" -}}
delete-kubernetes-connector
--input-secrets-namespace
{{ .Release.Namespace | quote }}
--input-secret-name
{{ include "wiz-kubernetes-connector.connectorSecretName" . | trim | quote }}
{{- end }}

{{- define "wiz-kubernetes-connector.argsListDeleteConnector" -}}
{{- $args := include "wiz-kubernetes-connector.generate-args-list-delete" . | splitList "\n" -}}
{{- range $arg := $args }}
- {{ $arg }}
{{- end }}
{{- end }}

{{- define "wiz-kubernetes-connector.generate-args-list-refresh" -}}
refresh-token
--input-secrets-namespace
{{ .Release.Namespace | quote }}
--input-secret-name
{{ include "wiz-kubernetes-connector.connectorSecretName" . | trim | quote }}
--service-account-namespace
{{ .Release.Namespace | quote }}
--service-account-name
{{ .Values.clusterReader.serviceAccount.name | quote }}
{{- end }}

{{- define "wiz-kubernetes-connector.argsListRefreshConnector" -}}
{{- $args := include "wiz-kubernetes-connector.generate-args-list-refresh" . | splitList "\n" -}}
{{- range $arg := $args }}
- {{ $arg }}
{{- end }}
{{- end }}

{{- define "wiz-broker.image" -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ coalesce .Values.global.image.tag .Values.image.tag | default .Chart.AppVersion }}{{ coalesce .Values.global.image.tagSuffix .Values.image.tagSuffix }}
{{- end -}}

{{- define "kubeVersion" -}}
{{- if and .Values.mockCapabilities .Values.mockCapabilities.kubeVersion .Values.mockCapabilities.kubeVersion.version -}}
{{ .Values.mockCapabilities.kubeVersion.version }}
{{- else -}}
{{ .Capabilities.KubeVersion.Version }}
{{- end -}}
{{- end -}}

{{- define "wiz-kubernetes-connector.isWizApiTokenSecretEnabled" -}}
  {{- if and (.Values.wizApiToken.secret.create)
            (eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true")
            (.Values.autoCreateConnector.enabled) }}
    true
  {{- else }}
    false
  {{- end }}
{{- end }}

{{- define "wiz-kubernetes-connector.isWizApiClientVolumeMountEnabled" -}}
{{- if eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true" -}}
true
{{- else -}}
false
{{- end }}
{{- end }}

{{- define "wiz-kubernetes-connector.spec.common.volumeMounts" -}}
{{- if eq (include "wiz-kubernetes-connector.isWizApiClientVolumeMountEnabled" . | trim | lower) "true" }}
- name: {{ include "wiz-common.volumes.apiClientName" . }}
  mountPath: /var/{{ include "wiz-common.volumes.apiClientName" . }}
  readOnly: true
{{- end -}}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.volumeMount" . | trim }}
{{- end -}}
{{- end -}}

{{- define "wiz-kubernetes-connector.spec.common.volumes" -}}
{{- if eq (include "wiz-kubernetes-connector.isWizApiClientVolumeMountEnabled" . | trim | lower) "true" }}
- name: {{ include "wiz-common.volumes.apiClientName" . | trim }}
  secret:
    secretName: {{ include "wiz-kubernetes-connector.apiTokenSecretName" . | trim }}
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.volume" (list (include "wiz-kubernetes-connector.proxySecretName" . | trim )) | trim }}
{{- end -}}
{{- end -}}

{{- define "wiz-kubernetes-connector.spec.common.envVars" -}}
{{- if not .Values.wizApiToken.usePodCustomEnvironmentVariablesFile }}
- name: CLI_FILES_AS_ARGS
{{- $wizApiTokensPath := "" -}}
{{- if coalesce .Values.global.wizApiToken.wizApiTokensVolumeMount .Values.wizApiToken.wizApiTokensVolumeMount }}
  {{- $wizApiTokensPath = coalesce .Values.global.wizApiToken.wizApiTokensVolumeMount .Values.wizApiToken.wizApiTokensVolumeMount -}}
{{- else }}
  {{- $wizApiTokensPath = printf "/var/%s" (include "wiz-common.volumes.apiClientName" .) -}}
{{- end }}
  value: "{{ $wizApiTokensPath }}/clientToken,{{ $wizApiTokensPath }}/clientId"
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.env" . | trim }}
{{- end }}
{{- if .Values.global.logLevel }}
- name: LOG_LEVEL
  value: {{ .Values.global.logLevel }}
{{- end }}
{{- with .Values.global.podCustomEnvironmentVariables }}
{{ toYaml . }}
{{- end }}
{{- with .Values.autoCreateConnector.podCustomEnvironmentVariables }}
{{ toYaml . }}
{{- end }}
{{- if .Values.autoCreateConnector.podCustomEnvironmentVariablesFile }}
- name: CLI_ENV_FILE
  value: {{ .Values.autoCreateConnector.podCustomEnvironmentVariablesFile }}
- name: USE_CLI_ENV_FILE
  value: "true"
{{- end }}
- name: WIZ_ENV
  value: {{ coalesce .Values.global.wizApiToken.clientEndpoint .Values.wizApiToken.clientEndpoint | quote }}
{{- if .Values.global.awsPrivateLink.enabled }}
- name: USE_WIZ_PRIVATE_LINK_ENDPOINTS
  value: "true"
{{- end }}
{{- if (or .Values.global.istio.enabled .Values.autoCreateConnector.istio.enabled) }}
- name: WIZ_ISTIO_PROXY_ENABLED
  value: "true"
- name: WIZ_ISTIO_PROXY_PORT
  value: {{ coalesce .Values.global.istio.proxySidecarPort .Values.autoCreateConnector.istio.proxySidecarPort | quote }}
{{- end }}
- name: WIZ_USE_HATUNNEL
  value: {{ ternary "1" "0" .Values.global.useHATunnel | quote }}
{{- if .Values.global.useHATunnel }}
- name: WIZ_BROKER_HEARTBEAT_DISABLE_CLUSTER_ID
  value: "1"
{{- end }}
{{- end }}
