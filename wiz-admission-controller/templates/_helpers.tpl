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


{{- define "wiz-kubernetes-audit-log-collector.name" -}}
{{- if .Values.kubernetesAuditLogsWebhook.nameOverride }}
{{- .Values.kubernetesAuditLogsWebhook.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := "wiz-audit-logs-collector" }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-admission-controller-manager.name" -}}
{{- if .Values.wizManager.nameOverride }}
{{- .Values.wizManager.nameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := "wiz-admission-controller-manager" }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 52 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 52 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "wiz-hpa-enforcer.name" -}}
{{- printf "%s-hpa" (include "wiz-admission-controller.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "wiz-hpa-audit-logs.name" -}}
{{- printf "%s-hpa" (include "wiz-kubernetes-audit-log-collector.name" .) | trunc 63 | trimSuffix "-" }}
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

{{- define "wiz-hpa-enforcer.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
app.kubernetes.io/name: {{ include "wiz-hpa-enforcer.name" . }}
{{- end }}

{{- define "wiz-hpa-audit-logs.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
app.kubernetes.io/name: {{ include "wiz-hpa-audit-logs.name" . }}
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

{{- define "helpers.calculateHash" -}}
{{- $list := . -}}
{{- $hash := printf "%s" $list | sha256sum -}}
{{- $hash := $hash | trimSuffix "\n" -}}
{{- $hash -}}
{{- end -}}

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

{{/*
This function dump the value of a variable and fail the template execution.
Use for debug purpose only.
*/}}
{{- define "helpers.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
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

{{- define "autoUpdate.deployments" -}}
{{- $list := list -}}
{{- if eq (include "wiz-admission-controller.isEnforcerEnabled" . | trim | lower) "true" }}
{{- $list = append $list (include "wiz-admission-controller.fullname" . ) -}}
{{- end -}}
{{- if .Values.kubernetesAuditLogsWebhook.enabled -}}
{{- $list = append $list (include "wiz-kubernetes-audit-log-collector.name" . ) -}}
{{- end -}}
{{- $list | toJson -}}
{{- end -}}

{{/*
Clean the list of deployments for the auto-update flag, removing quotes and brackets
*/}}
{{- define "autoUpdate.deployments.arg" -}}
{{- $deployments := include "autoUpdate.deployments" .  -}}
{{- $deployments = replace "[" "" $deployments -}}
{{- $deployments = replace "]" "" $deployments -}}
{{- $deployments = replace "\"" "" $deployments -}}
- "--update-deployments={{ $deployments }}"
{{- end -}}

{{- define "spec.common.commandArgs" -}}
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

{{- define "spec.common.envVars" -}}
{{- if not .Values.wizApiToken.usePodCustomEnvironmentVariablesFile }}
- name: WIZ_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "wiz-admission-controller.secretApiTokenName" . | trim }}
      key: clientId
      optional: false
- name: WIZ_CLIENT_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "wiz-admission-controller.secretApiTokenName" . | trim }}
      key: clientToken
      optional: false
{{- end }}
- name: WIZ_ENV
  value: {{ include "wiz-admission-controller.clientEndpoint" . }}
{{- if or .Values.global.httpProxyConfiguration.enabled .Values.httpProxyConfiguration.enabled }}
- name: HTTP_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ include "wiz-admission-controller.proxySecretName" . | trim }}
      key: httpProxy
      optional: false
- name: HTTPS_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ include "wiz-admission-controller.proxySecretName" . | trim }}
      key: httpsProxy
      optional: false
- name: NO_PROXY
  valueFrom:
    secretKeyRef:
      name: {{ include "wiz-admission-controller.proxySecretName" . | trim }}
      key: noProxyAddress
      optional: false
{{- end }}
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
{{- end -}}

{{- define "wiz-admission-controller.image" -}}
{{- if .Values.global.isFedRamp -}}
publicregistryfedrampwizio.azurecr.us/wiz-app/wiz-admission-controller-fips:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- else -}}
{{ coalesce .Values.global.image.registry .Values.image.registry }}/{{ coalesce .Values.global.image.repository .Values.image.repository }}:{{ .Values.image.tag | default .Chart.AppVersion }}
{{- end -}}
{{- end -}}

{{- define "wiz-admission-controller.clientEndpoint" -}}
{{- $clientEndpoint := coalesce .Values.global.wizApiToken.clientEndpoint .Values.wizApiToken.clientEndpoint | quote -}}
{{- if and (empty $clientEndpoint) .Values.global.isFedRamp -}}
  "fedramp"
{{- else -}}
  {{ $clientEndpoint }}
{{- end -}}
{{- end -}}
