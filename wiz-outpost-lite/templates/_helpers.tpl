{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-outpost-lite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wiz-outpost-lite.fullname" -}}
{{ $name := "" }}
{{- if .Values.fullnameOverride }}
{{- $name = .Values.fullnameOverride }}
{{- else }}
{{- $name = default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- $name = .Release.Name }}
{{- else }}
{{- $name = printf "%s-%s" .Release.Name $name }}
{{- end }}
{{- end }}
{{- if .runner }}
{{- $name = printf "%s-%s" $name .runner }}
{{- end }}
{{- $name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wiz-outpost-lite.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "wiz-outpost-lite.labels" -}}
helm.sh/chart: {{ include "wiz-outpost-lite.chart" . }}
{{ include "wiz-outpost-lite.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "wiz-outpost-lite.selectorLabels" -}}
app.kubernetes.io/name: {{ include "wiz-outpost-lite.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .runner }}
wiz.io/runner: {{ .runner | quote }}
{{- end }}
{{- end }}

{{/*
Determine runner type from runner name
*/}}
{{- define "wiz-outpost-lite.runnerType" -}}
{{- if hasPrefix "remediation-" . -}}
remediation-runner
{{- else if hasPrefix "vcs-" . -}}
vcs-runner
{{- else if hasPrefix "container-registry" . -}}
container-registry-runner
{{- else -}}
{{- fail (printf "Unknown runner type for %s" .) -}}
{{- end -}}
{{- end }}

{{/*
Merge values from different sources:
1. Default values (from values.yaml)
2. Runner type specific values (from container-registry-runner, vcs-runner, remediation-runner)
3. Runner instance specific values (from runners.container-registry, runners.vcs-scheduled, etc.)
*/}}
{{- define "wiz-outpost-lite.mergedRunnerValues" -}}
{{- $runner := .runner }}
{{- $runnerType := include "wiz-outpost-lite.runnerType" $runner }}
{{- $defaultValues := omit $.Values "runners" "container-registry-runner" "vcs-runner" "remediation-runner" }}
{{- $runnerTypeValues := get $.Values $runnerType | default dict }}
{{- $runnerInstanceValues := get ($.Values.runners) $runner | default dict }}
{{/* Important: merge in the correct order to ensure runner instance values take precedence */}}
{{- $mergedValues := merge (deepCopy $runnerInstanceValues) (deepCopy $runnerTypeValues) (deepCopy $defaultValues) }}
{{- $mergedValues | toJson }}
{{- end }}

{{- define "wiz-outpost-lite.runners" -}}
{{- $runnerValues := dict }}
{{- range $runner, $values := $.Values.runners }}

{{/* e.g. containerRegistry -> container-registry */}}
{{- $runner = $runner | kebabcase }}
{{- $runnerID := get $values "runnerID" | default $runner }}
{{- $runnerType := include "wiz-outpost-lite.runnerType" $runner }}

{{/* Get merged values for this runner */}}
{{- $mergedValues := include "wiz-outpost-lite.mergedRunnerValues" (dict "runner" $runner "Values" $.Values) | fromJson }}

{{/* Unify with global .Values to be used inside a "with" statement */}}
{{- $values = dict "runner" $runner "runnerID" $runnerID "Values" $mergedValues -}}
{{- $runnerValues = set $runnerValues $runner $values }}
{{- end }} {{/* range */}}

{{ $runnerValues | toJson }}
{{- end }} {{/* define */}}
