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


{{- define "wiz-outpost-lite.encryptionSecretName" -}}
{{- coalesce .Values.encryption.secretName (printf "wiz-encryption-key-%s" .Values.agent.outpostId ) }}
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

{{- define "wiz-outpost-lite.runners" -}}
{{- $runnerValues := dict }}
{{- range $runner, $values := $.Values.runners }}

{{/* e.g. containerRegistry -> container-registry */}}
{{- $runner = $runner | kebabcase }}
{{- $runnerID := get $values "runnerID" | default $runner }}

{{/* Get module type based on runner name - using a variable since we can't define a template inside another template */}}
{{- $moduleType := "" }}
{{- if hasPrefix "rem-" $runner -}}
  {{- $moduleType = "remediation" }}
{{- else if eq $runner "container-registry" -}}
  {{- $moduleType = "container-registry" }}
{{- else if eq $runner "datascan" -}}
  {{- $moduleType = "datascan" }}
{{- else if hasPrefix "vcs-" $runner -}}
  {{- $moduleType = "vcs" }}
 {{- else if eq $runner "databricks" -}}
  {{- $moduleType = "databricks" }}
{{- else -}}
  {{- fail (printf "Invalid runner name: %s. Runner name must start with 'rem-', 'vcs-', or be 'container-registry', 'datascan', or 'databricks'" $runner) -}}
{{- end }}

{{/* e.g. remediation-aws-rds-003 -> outpost-lite-runner-remediation
container-registry -> outpost-lite-runner-container-registry
*/}}
{{- $imageName := "" }}
{{- if eq $moduleType "remediation" }}
  {{- $imageName = "outpost-lite-runner-remediation" }}
{{- else }}
  {{- $imageName = dig "image" "name" (printf "outpost-lite-runner-%s" $runner) $values }}
{{- end }}

{{- $values = deepCopy $values }}

{{/* Unify with module specific values */}}
{{- $values = mergeOverwrite (deepCopy (get $.Values.modules $moduleType)) $values }}
{{- $values = merge $values (dict "image" (dict "name" $imageName)) }}

{{/* Unify with global values */}}
{{- $values = mergeOverwrite (deepCopy (omit $.Values "runners")) $values }}

{{/* Overwrite openshift values if runner set openshift to true */}}
{{- if and $values.openshift }}
{{- $values = merge $values $.Values.openshiftOverrides }}
{{- end }}

{{- if hasKey $values "containerSecurityContextOverride"}}
{{- $values = set $values "containerSecurityContext" $values.containerSecurityContextOverride }}
{{- end }}

{{- if hasKey $values "podSecurityContextOverride"}}
{{- $values = set $values "podSecurityContext" $values.podSecurityContextOverride }}
{{- end }}

{{/* Generate final values be used inside a "with" statement */}}
{{- $values = dict "runner" $runner "runnerID" $runnerID "Values" $values -}}

{{- $runnerValues = set $runnerValues $runner $values }}
{{- end }} {{/* range */}}

{{ $runnerValues | toJson }}
{{- end }} {{/* define */}}
