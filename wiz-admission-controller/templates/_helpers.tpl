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

{{- define "wiz-admission-controller-enforcement.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-admission-controller-enforcement.selectorLabels" . }}
{{- end }}

{{- define "wiz-kubernetes-audit-log-collector.labels" -}}
{{ include "wiz-admission-controller.labels" . }}
{{ include "wiz-kubernetes-audit-log-collector.selectorLabels" . }}
{{- end }}

{{/*

{{/*
Create the name of the service account to use
*/}}
{{- define "wiz-admission-controller.serviceAccountName" -}}
{{ coalesce (.Values.serviceAccount.name) (include "wiz-admission-controller.fullname" .) }}
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
