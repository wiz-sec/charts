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

{{- define "wiz-admission-controller-manager.name" -}}
{{- if .Values.wizManager.nameOverride }}
{{- .Values.wizManager.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $suffix := "-manager" -}}
{{- $maxLength := int (sub 52 (len $suffix)) -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-admission-controller.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-admission-controller.labels" -}}
helm.sh/chart: {{ include "wiz-admission-controller.chart" . }}
{{ include "wiz-admission-controller.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
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
Wiz manager selector labels
*/}}
{{- define "wiz-admission-controller-manager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-admission-controller-manager.name" . }}
{{- end }}

{{- define "wiz-admission-controller-enforcement.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-enforcement.selectorLabels" . }}
{{- end }}

{{- define "wiz-kubernetes-audit-log-collector.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-kubernetes-audit-log-collector.selectorLabels" . }}
{{- end }}

{{- define "wiz-admission-controller-manager.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-manager.selectorLabels" . }}
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
  {{- if or .Values.opaWebhook.enabled .Values.imageIntegrityWebhook.enabled .Values.debugWebhook.enabled }}
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

{{- define  "wiz-admission-controller.volumes.proxyName" -}}
proxy
{{- end -}}

{{- define "wiz-admission-controller.isWizApiTokenSecretEnabled" -}}
  {{- if and (.Values.wizApiToken.secret.create) (eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true") }}
    true
  {{- else }}
    false
  {{- end }}
{{- end }}

{{- define "wiz-admission-controller.spec.common.volumeMounts" -}}
{{- if eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true" -}}
- name: {{ include "wiz-common.volumes.apiClientName" . }}
  mountPath: /var/{{ include "wiz-common.volumes.apiClientName" . }}
  readOnly: true
{{- end -}}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
- name: {{ include "wiz-admission-controller.volumes.proxyName" . }}
  mountPath: /var/{{ include "wiz-admission-controller.volumes.proxyName" . }}
  readOnly: true
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.spec.common.volumes" -}}
{{- if eq (include "wiz-common.isWizApiClientVolumeMountEnabled" (list .Values.wizApiToken.usePodCustomEnvironmentVariablesFile .Values.wizApiToken.wizApiTokensVolumeMount) | trim | lower) "true" -}}
- name: {{ include "wiz-common.volumes.apiClientName" . | trim }}
  secret:
    secretName: {{ include "wiz-admission-controller.secretApiTokenName" . | trim }}
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
- name: {{ include "wiz-admission-controller.volumes.proxyName" . | trim }}
  secret:
    secretName: {{ include "wiz-admission-controller.proxySecretName" . | trim }}
{{- end -}}
{{- end -}}


{{- define "wiz-admission-controller.spec.common.envVars" -}}
{{- if not .Values.wizApiToken.usePodCustomEnvironmentVariablesFile }}
- name: CLI_FILES_AS_ARGS
{{- $wizApiTokensPath := "" -}}
{{- if .Values.wizApiToken.wizApiTokensVolumeMount }}
  {{- $wizApiTokensPath = .Values.wizApiToken.wizApiTokensVolumeMount -}}
{{- else }}
  {{- $wizApiTokensPath = printf "/var/%s" (include "wiz-common.volumes.apiClientName" .) -}}
{{- end }}
  value: "{{ $wizApiTokensPath }}/clientToken,{{ $wizApiTokensPath }}/clientId"
{{- end }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
- name: CLI_FILES_AS_ENV_VARS
  value: "/var/{{ include "wiz-admission-controller.volumes.proxyName" . }}/http_proxy,/var/{{ include "wiz-admission-controller.volumes.proxyName" . }}/https_proxy,/var/{{ include "wiz-admission-controller.volumes.proxyName" . }}/no_proxy"
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
{{- end -}}
{{- if (or .Values.opaWebhook.customErrorMessage .Values.customErrorMessage) }}
- name: WIZ_MISCONFIGURATION_CUSTOM_ERROR_MESSAGE
  value:  "{{ coalesce .Values.opaWebhook.customErrorMessage .Values.customErrorMessage }}"
{{- end -}}
{{- if  .Values.opaWebhook.enabled }}
- name: WIZ_MISCONFIGURATION_WEBHOOK_CONFIG
  value: |
  {{ .Values.opaWebhook | toJson | nindent 4 }}
{{- end -}}
{{- if .Values.imageIntegrityWebhook.enabled }}
- name: WIZ_IMAGE_INTEGRITY_WEBHOOK_CONFIG
  value: |
  {{ .Values.imageIntegrityWebhook | toJson | nindent 4 }}
{{- end -}}
{{- if .Values.kubernetesAuditLogsWebhook.enabled }}
- name: WIZ_KUBERNETES_AUDIT_LOG_WEBHOOK_CONFIG
  value: |
  {{ .Values.kubernetesAuditLogsWebhook | toJson | nindent 4 }}
{{- end -}}
{{- if coalesce .Values.global.clusterDisplayName .Values.clusterDisplayName }}
- name: WIZ_CLUSTER_NAME
  value: {{ coalesce .Values.global.clusterDisplayName .Values.clusterDisplayName | quote }}
{{- end }}
{{- end -}}

{{- define "wiz-admission-controller.image" -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
