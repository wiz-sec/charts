{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-admission-controller.name" -}}
{{- $nameOverride := coalesce .Values.global.nameOverride .Values.nameOverride }}
{{- default .Chart.Name $nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wiz-admission-controller.fullname" -}}
{{- if .Values.global.fullnameOverride }}
{{- .Values.global.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := coalesce .Values.global.nameOverride .Values.nameOverride .Chart.Name }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller-enforcer.name" -}}
{{- (include "wiz-admission-controller.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wiz-kubernetes-audit-log-collector.name" -}}
{{- if .Values.kubernetesAuditLogsWebhook.nameOverride }}
{{- .Values.kubernetesAuditLogsWebhook.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-audit-log-collector" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}
{{- end }}

{{- define "wiz-sensor-inject.name" -}}
{{- if .Values.sensorInject.nameOverride }}
{{- .Values.sensorInject.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-sensor-inject" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}
{{- end }}

{{- define "wiz-debug-webhook.name" -}}
{{- if .Values.debugWebhook.nameOverride }}
{{- .Values.debugWebhook.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-debug" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller-manager.name" -}}
{{- if .Values.wizManager.nameOverride }}
{{- .Values.wizManager.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-manager" -}}
{{- $maxLength := int (sub 52 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller-uninstall.name" -}}
{{- if .Values.wizUninstallJob.nameOverride }}
{{- .Values.wizUninstallJob.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-uninstall" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.wiz-hpa-enforcer.name" -}}
{{- $suffix := "-hpa" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-admission-controller.fullname" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}

{{- define "wiz-admission-controller.wiz-hpa-audit-logs.name" -}}
{{- $suffix := "-hpa" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-kubernetes-audit-log-collector.name" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}

{{- define "wiz-admission-controller.wiz-hpa-debug.name" -}}
{{- $suffix := "-hpa" -}}
{{- $maxLength := int (sub 63 (len $suffix)) -}}
{{- printf "%s%s" (include "wiz-debug-webhook.name" . | trunc $maxLength | trimSuffix "-") $suffix -}}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
App version for the admission controller
*/}}
{{- define "wiz-admission-controller.appVersion" -}}
{{- coalesce .Values.global.image.tag .Values.image.tag | default .Chart.AppVersion }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-admission-controller.labels" -}}
helm.sh/chart: {{ include "wiz-admission-controller.chart" . }}
{{ include "wiz-admission-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ include "wiz-admission-controller.appVersion" . | quote }}
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
Wiz admission controller webhook server selector labels
*/}}
{{- define "wiz-admission-controller.selectorLabels" -}}
app.kubernetes.io/chartName: {{ .Chart.Name | trunc 63 }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Wiz admission controller enforcement webhook server selector labels
*/}}
{{- define "wiz-admission-controller-enforcement.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-admission-controller.name" . }}
{{- end }}

{{/*
Wiz kubernetes audit logs webhook server selector labels
*/}}
{{- define "wiz-kubernetes-audit-log-collector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-kubernetes-audit-log-collector.name" . }}
{{- end }}

{{/*
Wiz sensor webhook server selector labels
*/}}
{{- define "wiz-sensor-webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-sensor-inject.name" . }}
{{- end }}

{{/*
Wiz debug webhook server selector labels
*/}}
{{- define "wiz-debug-webhook.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-debug-webhook.name" . }}
{{- end }}

{{/*
Wiz manager selector labels
*/}}
{{- define "wiz-admission-controller-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-admission-controller-manager.name" . }}
{{- end }}

{{/*
Wiz uninstall selector labels
*/}}
{{- define "wiz-admission-controller-uninstall.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-admission-controller-uninstall.name" . }}
{{- end }}


{{- define "wiz-admission-controller-enforcement.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-enforcement.selectorLabels" . }}
{{- end }}

{{- define "wiz-kubernetes-audit-log-collector.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-kubernetes-audit-log-collector.selectorLabels" . }}
{{- end }}

{{- define "wiz-sensor-webhook.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-sensor-webhook.selectorLabels" . }}
{{- end }}

{{- define "wiz-debug-webhook.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-debug-webhook.selectorLabels" . }}
{{- end }}

{{- define "wiz-admission-controller-manager.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-manager.selectorLabels" . }}
{{- end }}

{{- define "wiz-admission-controller-uninstall.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-uninstall.selectorLabels" . }}
{{- end }}

{{/*
Wiz Horizontal Pod Autoscaler labels
*/}}

{{- define "wiz-admission-controller.wiz-admission-controller.wiz-hpa-enforcer.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
app.kubernetes.io/name: {{ include "wiz-admission-controller.wiz-hpa-enforcer.name" . }}
{{- end }}

{{- define "wiz-admission-controller.wiz-hpa-audit-logs.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
app.kubernetes.io/name: {{ include "wiz-admission-controller.wiz-hpa-audit-logs.name" . }}
{{- end }}

{{- define "wiz-admission-controller.wiz-hpa-debug.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
app.kubernetes.io/name: {{ include "wiz-admission-controller.wiz-hpa-debug.name" . }}
{{- end }}


{{/*

{{/*
Create the name of the service account to use
*/}}
{{- define "wiz-admission-controller.serviceAccountName" -}}
{{ coalesce (.Values.serviceAccount.name) (include "wiz-admission-controller.fullname" .) }}
{{- end }}

{{- define "wiz-admission-controller.manager.serviceAccountName" -}}
{{ coalesce (.Values.wizManager.serviceAccount.name) (include "wiz-admission-controller-manager.name" .) }}
{{- end }}


{{- define "wiz-admission-controller.secretApiTokenName" -}}
{{ coalesce (.Values.global.wizApiToken.secret.name) (.Values.wizApiToken.secret.name) (printf "%s-%s" .Release.Name "api-token") }}
{{- end }}

{{- define "wiz-admission-controller.secretServerCert" -}}
{{- if .Values.webhook.secret.name }}
{{- .Values.webhook.secret.name }}
{{- else }}
{{- include "wiz-admission-controller.fullname" . }}-cert
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.opaCliParams.policies" -}}
{{- if .Values.opaWebhook.policies }}
{{- range .Values.opaWebhook.policies }}
- "--policy={{ . }}"
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.imageIntegrityCliParams.policies" -}}
{{- if .Values.imageIntegrityWebhook.policies }}
{{- range .Values.imageIntegrityWebhook.policies }}
- "--image-integrity-policy={{ . }}"
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.sensorApiKeySecretName" -}}
  {{- $secretName := coalesce .Values.sensorInject.apiKeySecret.name .Values.global.wizApiToken.secret.name .Values.wizApiToken.secret.name -}}
  {{- if not (empty $secretName) -}}
    {{- $secretName -}}
  {{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.sensorCliParams" -}}
{{- if .Values.sensorInject.enabled }}
- "--sensor-api-key-secret-name={{ required "one of sensorInject.apiKeySecret.name or wizApiToken.secret.name or global.wizApiToken.secret.name is required when sensorInject.enabled is true" ( include "wiz-admission-controller.sensorApiKeySecretName" .) }}"
- "--sensor-registry-secret-name={{ required "sensorInject.registrySecret.name is required when sensorInject.enabled is true" .Values.sensorInject.registrySecret.name }}"
{{- if .Values.sensorInject.image }}
- "--sensor-image={{ .Values.sensorInject.image }}"
{{- end }}
{{- if .Values.sensorInject.excludedContainers }}
{{- range .Values.sensorInject.excludedContainers }}
- "--sensor-excluded-containers={{ . }}"
{{- end }}
{{- end }}
{{- if .Values.sensorInject.stdoutLogLevel }}
- "--sensor-stdout-log-level={{ .Values.sensorInject.stdoutLogLevel }}"
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.imageRegistryClient.pullSecrets" -}}
{{- if .Values.imageRegistryClient.pullSecrets }}
{{- range .Values.imageRegistryClient.pullSecrets }}
- "--registry-image-pull-secret={{ . }}"
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller.imageRegistryClient.credentialHelpersSecrets" -}}
{{- if .Values.imageRegistryClient.credentialHelpers }}
{{- range .Values.imageRegistryClient.credentialHelpers }}
- "--registry-credential-helper={{ . }}"
{{- end }}
{{- end }}
{{- end }}


{{- define "wiz-admission-controller.proxySecretName" -}}
{{ coalesce (.Values.global.httpProxyConfiguration.secretName) (.Values.httpProxyConfiguration.secretName) (printf "%s-%s" .Release.Name "proxy-configuration") }}
{{- end }}

{{- define "wiz-admission-controller.proxyHash" -}}
{{ include "helpers.calculateHash" (list .Values.global.httpProxyConfiguration.httpProxy .Values.global.httpProxyConfiguration.httpsProxy .Values.global.httpProxyConfiguration.noProxyAddress .Values.global.httpProxyConfiguration.secretName .Values.httpProxyConfiguration.httpProxy .Values.httpProxyConfiguration.httpsProxy .Values.httpProxyConfiguration.noProxyAddress .Values.httpProxyConfiguration.secretName) }}
{{- end }}

{{- define "wiz-admission-controller.wizApiTokenHash" -}}
{{ include "helpers.calculateHash" (list .Values.global.wizApiToken.clientId .Values.global.wizApiToken.clientToken .Values.global.wizApiToken.secret.name .Values.wizApiToken.clientId .Values.wizApiToken.clientToken .Values.wizApiToken.secret.name) }}
{{- end }}

{{- define "wiz-admission-controller.certManagerInject" -}}
{{- if .Values.webhook.createSelfSignedCert -}}
{{- printf "%s/%s-cert" .Release.Namespace (include "wiz-admission-controller.fullname" .) -}}
{{- else -}}
{{- .Values.webhook.injectCaFrom -}}
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.resources" -}}
{{- if hasKey .Values "resources" }}
{{- toYaml .Values.resources }}
{{- else -}}
{{- if .Values.hpa.enabled }}
requests:
    cpu: 500m
    memory: 300Mi
{{- else }}
{}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.isEnforcerEnabled" -}}
  {{- if or .Values.opaWebhook.enabled .Values.imageIntegrityWebhook.enabled }}
    true
  {{- else }}
    false
  {{- end }}
{{- end }}

{{- define "wiz-admission-controller.hpaBehavior" -}}
{{- if hasKey .Values.hpa "behavior" }}
{{- toYaml .Values.hpa.behavior }}
{{- else -}}
scaleUp:
  stabilizationWindowSeconds: 300
scaleDown:
  stabilizationWindowSeconds: 300
  policies:
  - type: Pods
    value: 1
    periodSeconds: 300
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.autoUpdate.deployments" -}}
{{- $list := list -}}
{{- if eq (include "wiz-admission-controller.isEnforcerEnabled" . | trim | lower) "true" }}
{{- $list = append $list (include "wiz-admission-controller-enforcer.name" . ) -}}
{{- end -}}
{{- if .Values.kubernetesAuditLogsWebhook.enabled -}}
{{- $list = append $list (include "wiz-kubernetes-audit-log-collector.name" . ) -}}
{{- end -}}
{{- if .Values.sensorInject.enabled -}}
{{- $list = append $list (include "wiz-sensor-inject.name" . ) -}}
{{- end -}}
{{- if .Values.debugWebhook.enabled -}}
{{- $list = append $list (include "wiz-debug-webhook.name" . ) -}}
{{- end -}}
{{- $list | toJson -}}
{{- end -}}

{{/*
Clean the list of deployments for the auto-update flag, removing quotes and brackets
*/}}
{{- define "wiz-admission-controller.wiz-admission-controller.autoUpdate.deployments.arg" -}}
{{- $deployments := include "wiz-admission-controller.autoUpdate.deployments" .  -}}
{{- $deployments = replace "[" "" $deployments -}}
{{- $deployments = replace "]" "" $deployments -}}
{{- $deployments = replace "\"" "" $deployments -}}
- "--update-deployments={{ $deployments }}"
{{- end -}}

{{- define "wiz-admission-controller.spec.common.commandArgs" -}}
# Cluster identification flags
{{- with (coalesce .Values.global.clusterExternalId .Values.webhook.clusterExternalId .Values.opaWebhook.clusterExternalId) }}
- --cluster-external-id
- {{ . | quote }}
{{- end }}
{{- with (coalesce .Values.global.subscriptionExternalId .Values.webhook.subscriptionExternalId) }}
- --subscription-external-id
- {{ . | quote }}
{{- end }}
{{- with (coalesce .Values.global.clusterTags .Values.webhook.clusterTags) }}
- --cluster-tags
- {{ . | toJson | quote }}
{{- end }}
{{- with (coalesce .Values.global.subscriptionTags .Values.webhook.subscriptionTags) }}
- --subscription-tags
- {{ . | toJson | quote }}
{{- end }}
{{- end -}}

{{- define "spec.admissionControllerRunner.commandArgs" -}}
# Server flags
- "--port={{ .Values.service.targetPort }}"
- "--tls-private-key-file=/var/server-certs/tls.key"
- "--tls-cert-file=/var/server-certs/tls.crt"
- "--readiness-port={{ .Values.healthPort }}"
# Kubernetes API server flags
- "--namespace-cache-ttl={{ .Values.kubernetesApiServer.cacheNamespaceLabelsTTL }}"
{{- end -}}

{{- define "wiz-admission-controller.isWizApiTokenSecretEnabled" -}}
  {{- if and (.Values.wizApiToken.secret.create) (eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true") }}
    true
  {{- else }}
    false
  {{- end }}
{{- end }}

{{- define "wiz-admission-controller.isWizApiClientVolumeMountEnabled" -}}
{{- if eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true" -}}
true
{{- else -}}
false
{{- end }}
{{- end }}


{{- define "wiz-admission-controller.spec.common.volumeMounts" -}}
{{- if eq (include "wiz-admission-controller.isWizApiClientVolumeMountEnabled" . | trim | lower) "true" }}
- name: {{ include "wiz-common.volumes.apiClientName" . }}
  mountPath: /var/{{ include "wiz-common.volumes.apiClientName" . }}
  readOnly: true
{{- end -}}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.volumeMount" . | trim }}
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.spec.common.volumes" -}}
{{- if eq (include "wiz-admission-controller.isWizApiClientVolumeMountEnabled" . | trim | lower) "true" }}
- name: {{ include "wiz-common.volumes.apiClientName" . | trim }}
  secret:
    secretName: {{ include "wiz-admission-controller.secretApiTokenName" . | trim }}
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.volume" (list (include "wiz-admission-controller.proxySecretName" . | trim )) | trim }}
{{- end -}}
{{- end -}}


{{- define "wiz-admission-controller.spec.common.envVars" -}}
{{- if not .Values.wizApiToken.usePodCustomEnvironmentVariablesFile }}
- name: CLI_FILES_AS_ARGS
{{- $wizApiTokensPath := "" -}}
{{- if coalesce .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount }}
  {{- $wizApiTokensPath = coalesce .Values.wizApiToken.wizApiTokensVolumeMount .Values.global.wizApiToken.wizApiTokensVolumeMount -}}
{{- else }}
  {{- $wizApiTokensPath = printf "/var/%s" (include "wiz-common.volumes.apiClientName" .) -}}
{{- end }}
  value: "{{ $wizApiTokensPath }}/clientToken,{{ $wizApiTokensPath }}/clientId"
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
{{ include "wiz-common.proxy.env" . | trim }}
{{- if or .Values.global.httpProxyConfiguration.clientCertificate .Values.httpProxyConfiguration.clientCertificate }}
- name: WIZ_HTTP_PROXY_CLIENT_CERT_PATH
  value: "{{ include "wiz-common.proxy.dir" . }}/clientCertificate"
{{- end }}
{{- end }}
- name: WIZ_ENV
  value: {{ coalesce .Values.global.wizApiToken.clientEndpoint .Values.wizApiToken.clientEndpoint | quote }}
{{- if .Values.logLevel }}
- name: LOG_LEVEL
  value: {{ .Values.logLevel }}
{{- end }}
{{- with .Values.podCustomEnvironmentVariables }}
{{ toYaml . }}
{{- end }}
{{- with .Values.global.podCustomEnvironmentVariables }}
{{ toYaml . }}
{{- end }}
{{- if .Values.podCustomEnvironmentVariablesFile }}
- name: CLI_ENV_FILE
  value: {{ .Values.podCustomEnvironmentVariablesFile }}
- name: USE_CLI_ENV_FILE
  value: "true"
{{- end }}
- name: WIZ_RUNTIME_METADATA_POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: WIZ_RUNTIME_METADATA_NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: K8S_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: WIZ_TERMINATION_GRACE_PERIOD
  value: "{{ .Values.global.podTerminationGracePeriodSeconds }}s"
{{- if .Values.global.istio.enabled }}
- name: WIZ_ISTIO_PROXY_ENABLED
  value: "true"
- name: WIZ_ISTIO_PROXY_PORT
  value: "{{ .Values.global.istio.proxySidecarPort }}"
{{- end }}
- name: WIZ_CHART_VERSION
  value: "{{ .Chart.Version}}"
{{- if (or .Values.imageIntegrityWebhook.customErrorMessage .Values.customErrorMessage) }}
- name: WIZ_IMAGE_INTEGRITY_CUSTOM_ERROR_MESSAGE
  value:  "{{ coalesce .Values.imageIntegrityWebhook.customErrorMessage .Values.customErrorMessage }}"
{{- if (or .Values.imageIntegrityWebhook.customErrorMessageMode .Values.customErrorMessageMode) }}
- name: WIZ_IMAGE_INTEGRITY_CUSTOM_ERROR_MESSAGE_MODE
  value:  "{{ coalesce .Values.imageIntegrityWebhook.customErrorMessageMode .Values.customErrorMessageMode }}"
{{- end -}}
{{- end -}}
{{- if (or .Values.opaWebhook.customErrorMessage .Values.customErrorMessage) }}
- name: WIZ_MISCONFIGURATION_CUSTOM_ERROR_MESSAGE
  value:  "{{ coalesce .Values.opaWebhook.customErrorMessage .Values.customErrorMessage }}"
{{- if (or .Values.opaWebhook.customErrorMessageMode .Values.customErrorMessageMode) }}
- name: WIZ_MISCONFIGURATION_CUSTOM_ERROR_MESSAGE_MODE
  value:  "{{ coalesce .Values.opaWebhook.customErrorMessageMode .Values.customErrorMessageMode }}"
{{- end -}}
{{- end -}}
{{- if coalesce .Values.global.clusterDisplayName .Values.clusterDisplayName }}
- name: WIZ_CLUSTER_NAME
  value: {{ coalesce .Values.global.clusterDisplayName .Values.clusterDisplayName | quote }}
{{- end }}
{{- end -}}

{{- define "wiz-admission-controller.image" -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ include "wiz-admission-controller.appVersion" . }}
{{- end -}}
