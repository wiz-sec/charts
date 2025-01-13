{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-sensor.name" -}}
{{- coalesce .Values.global.nameOverride .Values.nameOverride .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wiz-sensor.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-sensor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-sensor.labels" -}}
{{- $imageparts:= split "@" .Values.image.tag }}
{{- $dsimageparts:= split "@" .Values.image.diskScanTag }}
helm.sh/chart: {{ include "wiz-sensor.chart" . }}
image/tag: {{ $imageparts._0 }}
dsimage/tag: {{ $dsimageparts._0 }}
{{ include "wiz-sensor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if (coalesce .Values.global.commonLabels .Values.commonLabels .Values.daemonset.commonLabels) }}
{{- range $key, $value := (coalesce .Values.global.commonLabels .Values.commonLabels .Values.daemonset.commonLabels) }}
{{ $key }}: {{ tpl $value $ | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wiz-sensor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-sensor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "wiz-sensor.serviceAccountName" -}}
{{- default (include "wiz-sensor.fullname" .) .Values.serviceAccount.name }}
{{- end }}

{{/*
Secrets
*/}}
{{- define "wiz-sensor.imagePullSecretName" -}}
{{- default (printf "%s-imagepullkey" (include "wiz-sensor.fullname" .)) .Values.imagePullSecret.name }}
{{- end }}

{{- define "wiz-sensor.imagePullSecretList" -}}
{{- if .Values.global.imagePullSecrets -}}
{{- .Values.global.imagePullSecrets | toYaml | nindent 8 }}
{{- else -}}
- name: {{ include "wiz-sensor.imagePullSecretName" . }}
{{- end -}}
{{- end }}

{{- define "wiz-sensor.secretName" -}}
{{- if .Values.apikey -}}
{{- default (printf "%s-apikey" (include "wiz-sensor.fullname" .)) .Values.apikey.name }}
{{- else -}}
{{- coalesce .Values.global.wizApiToken.secret.name .Values.wizApiToken.secret.name .Values.wizApiToken.name (printf "%s-apikey" (include "wiz-sensor.fullname" .)) }}
{{- end -}}
{{- end }}

{{- define "wiz-sensor.proxySecretName" -}}
{{ coalesce .Values.global.httpProxyConfiguration.secretName .Values.httpProxyConfiguration.secretName (printf "%s-%s" .Release.Name "proxy-configuration") }}
{{- end }}

{{- define "wiz-sensor.diskScanConfigName" -}}
{{ coalesce .Values.diskScan.configName (printf "%s-%s" .Release.Name "disk-scan-config") }}
{{- end }}

{{/*
TODO: Backward compatibility - remove
*/}}
{{- define "wiz-sensor.createSecret" -}}
{{- if .Values.apikey -}}
{{- default true .Values.apikey.create -}}
{{- else if (hasKey .Values.wizApiToken "createSecret") -}}
{{- .Values.wizApiToken.createSecret -}}
{{- else if (hasKey .Values.wizApiToken.secret "create") -}}
{{- .Values.wizApiToken.secret.create -}}
{{- else -}}
true
{{- end -}}
{{- end -}}

{{- define "wiz-sensor.imagePullSecretValue" -}}
{{- if (coalesce .Values.global.image.registry .Values.image.registry) }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" (coalesce .Values.global.image.registry .Values.image.registry) (printf "%s:%s" (required "A valid username for image pull secret required" .Values.imagePullSecret.username) .Values.imagePullSecret.password | b64enc) | b64enc }}
{{- else }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.repository (printf "%s:%s" (required "A valid username for image pull secret required" .Values.imagePullSecret.username) .Values.imagePullSecret.password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
log levels
*/}}
{{- define "wiz-sensor.fileLogLevel" -}}
{{- if .Values.debug }}
{{- "debug" -}}
{{- else }}
{{- default "info" .Values.logLevel -}}
{{- end }}
{{- end }}

{{- define "wiz-sensor.stdoutLogLevel" -}}
{{- if .Values.debug }}
{{- "debug" -}}
{{- else }}
{{- default "error" .Values.logLevel -}}
{{- end }}
{{- end }}

{{- define "validate.values" -}}
{{- if .Values.exposeMetrics }}
{{- if .Values.hostNetwork }}
{{- fail "Cannot set hostNetwork to true when exposeMetrics is set to true" }}
{{- end }}
{{- end }}
{{- end }}