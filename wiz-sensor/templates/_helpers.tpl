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
Sensor image tag
*/}}
{{- define "wiz-sensor.imageTag" -}}
{{- coalesce .Values.image.tag .Chart.AppVersion }}
{{- end }}

{{/*
Disk scanner image tag
*/}}
{{- define "wiz-sensor.diskScanTag" -}}
{{ .Values.image.diskScanTag | default (printf "v%s" .Chart.Annotations.diskScanAppVersion) }}
{{- end }}

{{/*
Windows sensor image tag
*/}}
{{- define "wiz-sensor.windowsTag" -}}
{{ .Values.image.windowsTag | default (printf "v%s" .Chart.Annotations.windowsAppVersion) }}
{{- end }}

{{/*
Common labels shared between Linux and Windows
Includes standard Helm labels and user-defined common labels from Values
*/}}
{{- define "wiz-sensor.commonLabels" -}}
helm.sh/chart: {{ include "wiz-sensor.chart" . }}
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
Linux labels
*/}}
{{- define "wiz-sensor.labels" -}}
{{ include "wiz-sensor.commonLabels" . }}
{{- $imageparts:= split "@" (include "wiz-sensor.imageTag" .) }}
{{- $dsimageparts:= split "@" (include "wiz-sensor.diskScanTag" .) }}
image/tag: {{ $imageparts._0 }}
dsimage/tag: {{ $dsimageparts._0 }}
{{- if .Values.gkeAutopilot }}
autopilot.gke.io/no-connect: "true"
cloud.google.com/matching-allowlist: {{ .Values.gkeAutopilotAllowlist }}
{{- end }}
{{- end }}

{{/*
Windows labels
*/}}
{{- define "wiz-sensor.windowsLabels" -}}
{{ include "wiz-sensor.commonLabels" . }}
{{- $imageparts:= split "@" (include "wiz-sensor.windowsTag" .) }}
os: windows
image/tag: {{ $imageparts._0 }}
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
{{- if (or .Values.global.wizApiToken.wizApiTokensVolumeMount .Values.wizApiToken.wizApiTokensVolumeMount) }}
false
{{- else if .Values.apikey -}}
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

{{/*
Registry Helpers
*/}}
{{- define "wiz-sensor.knownRegistries" -}}
{{- list "wizio.azurecr.io" "wiziosensor.azurecr.io" "registry.wiz.io" "wizfedramp.azurecr.us" | toJson -}}
{{- end -}}

{{/*
Kubernetes version for semver comparisons
*/}}
{{- define "wiz-sensor.kubeVersion" -}}
{{- printf "%s.%s" (regexReplaceAll "[^0-9]" .Capabilities.KubeVersion.Major "") (regexReplaceAll "[^0-9]" .Capabilities.KubeVersion.Minor "") -}}
{{- end -}}

{{/*
Rule Validation
*/}}
{{- define "validate.values" -}}
{{- if .Values.exposeMetrics }}
{{- if .Values.hostNetwork }}
{{- fail "Cannot set hostNetwork to true when exposeMetrics is set to true" }}
{{- end }}
{{- end }}

{{- if .Values.fixedDefsVersion }}
{{- if not (regexMatch "^[0-9]+\\.[0-9]+\\.[0-9]+$" .Values.fixedDefsVersion) }}
{{- fail "fixedDefsVersion must be in major.minor.patch format (e.g. 1.2.3)" }}
{{- end }}
{{- end }}


{{- if .Values.gkeAutopilot }}
{{- if empty .Values.image.sha256 }}
{{- if not (has .Values.image.registry (include "wiz-sensor.knownRegistries" . | fromJsonArray)) }}
{{- fail "When using gkeAutopilot with a private repo, make sure to set the image.sha256 value to a specific version" }}
{{- end }}
{{- end }}
{{- end }}

{{- if and .Values.gkeAutopilot .Values.diskScan.enabled }}
{{- fail "diskScan is not supported on GKE Autopilot" }}
{{- end }}

{{- if .Values.gkeAutopilot }}
{{- $limits := .Values.daemonset.resources.limits }}
{{- if .Values.apiSecurity.enabled }}
{{- $limits = .Values.daemonset.resources.apiSecurityLimits }}
{{- end }}
{{- if not $limits }}
{{- fail "gkeAutopilot requires resource limits to be defined (daemonset.resources.limits or daemonset.resources.apiSecurityLimits when apiSecurity is enabled)" }}
{{- end }}
{{- end }}

{{- end }}
