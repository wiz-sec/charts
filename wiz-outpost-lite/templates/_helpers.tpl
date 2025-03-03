{{/*
Expand the name of the chart.
*/}}
{{- define "wiz-outpost-lite.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
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
Get module name for a runner
*/}}
{{- define "wiz-outpost-lite.getModule" -}}
{{- $runner := . }}
{{- $runnerConfig := get $.Values.runners $runner | default dict }}
{{- $module := get $runnerConfig "module" | default "" }}
{{- if $module }}
  {{- $module }}
{{- else }}
  {{/* Fallback to determine module from runner name for backward compatibility */}}
  {{- if hasPrefix "remediation-" $runner -}}
    remediation
  {{- else if hasPrefix "vcs-" $runner -}}
    vcs
  {{- else if hasPrefix "container-registry" $runner -}}
    container-registry
  {{- else -}}
    {{- fail (printf "Unknown module for %s" $runner) -}}
  {{- end -}}
{{- end -}}
{{- end }}

{{/*
Helper function to get the appropriate pod security context.
If podSecurityContextOverride is defined, it takes precedence.
*/}}
{{- define "wiz-outpost-lite.podSecurityContext" -}}
{{- $runner := .runner }}
{{- $module := include "wiz-outpost-lite.getModule" $runner }}
{{- $runnerConfig := get $.Values.runners $runner | default dict }}
{{- $moduleConfig := get $.Values.modules $module | default dict }}
{{- $defaultConfig := $.Values.defaults | default dict }}

{{/* Check for override at runner level */}}
{{- if hasKey $runnerConfig "podSecurityContextOverride" }}
  {{- toYaml $runnerConfig.podSecurityContextOverride }}
{{/* Check for override at module level */}}
{{- else if hasKey $moduleConfig "podSecurityContextOverride" }}
  {{- toYaml $moduleConfig.podSecurityContextOverride }}
{{/* Check for override at default level */}}
{{- else if hasKey $defaultConfig "podSecurityContextOverride" }}
  {{- toYaml $defaultConfig.podSecurityContextOverride }}
{{/* Use regular security context with precedence: runner > module > default */}}
{{- else if hasKey $runnerConfig "podSecurityContext" }}
  {{- toYaml $runnerConfig.podSecurityContext }}
{{- else if hasKey $moduleConfig "podSecurityContext" }}
  {{- toYaml $moduleConfig.podSecurityContext }}
{{- else if hasKey $defaultConfig "podSecurityContext" }}
  {{- toYaml $defaultConfig.podSecurityContext }}
{{- else }}
  {{/* Fallback to top-level podSecurityContext for backward compatibility */}}
  {{- toYaml $.Values.podSecurityContext | default dict }}
{{- end }}
{{- end }}

{{/*
Helper function to get the appropriate container security context.
If containerSecurityContextOverride is defined, it takes precedence.
*/}}
{{- define "wiz-outpost-lite.containerSecurityContext" -}}
{{- $runner := .runner }}
{{- $module := include "wiz-outpost-lite.getModule" $runner }}
{{- $runnerConfig := get $.Values.runners $runner | default dict }}
{{- $moduleConfig := get $.Values.modules $module | default dict }}
{{- $defaultConfig := $.Values.defaults | default dict }}

{{/* Check for override at runner level */}}
{{- if hasKey $runnerConfig "containerSecurityContextOverride" }}
  {{- toYaml $runnerConfig.containerSecurityContextOverride }}
{{/* Check for override at module level */}}
{{- else if hasKey $moduleConfig "containerSecurityContextOverride" }}
  {{- toYaml $moduleConfig.containerSecurityContextOverride }}
{{/* Check for override at default level */}}
{{- else if hasKey $defaultConfig "containerSecurityContextOverride" }}
  {{- toYaml $defaultConfig.containerSecurityContextOverride }}
{{/* Use regular security context with precedence: runner > module > default */}}
{{- else if hasKey $runnerConfig "containerSecurityContext" }}
  {{- toYaml $runnerConfig.containerSecurityContext }}
{{- else if hasKey $moduleConfig "containerSecurityContext" }}
  {{- toYaml $moduleConfig.containerSecurityContext }}
{{- else if hasKey $defaultConfig "containerSecurityContext" }}
  {{- toYaml $defaultConfig.containerSecurityContext }}
{{- else }}
  {{/* Fallback to top-level containerSecurityContext for backward compatibility */}}
  {{- toYaml $.Values.containerSecurityContext | default dict }}
{{- end }}
{{- end }}

{{/*
Merge values from different sources using the new hierarchical structure
*/}}
{{- define "wiz-outpost-lite.mergedRunnerValues" -}}
{{- $runner := .runner }}
{{- $module := include "wiz-outpost-lite.getModule" $runner }}
{{- $defaultConfig := $.Values.defaults | default dict }}
{{- $moduleConfig := get $.Values.modules $module | default dict }}
{{- $runnerConfig := get ($.Values.runners) $runner | default dict }}

{{/* Merge in the correct order to ensure proper precedence */}}
{{- $mergedValues := dict }}
{{- $mergedValues = merge $mergedValues (deepCopy $defaultConfig) }}
{{- $mergedValues = merge $mergedValues (deepCopy $moduleConfig) }}
{{- $mergedValues = merge $mergedValues (deepCopy $runnerConfig) }}

{{/* Add top-level values for backward compatibility */}}
{{- $topLevelValues := omit $.Values "runners" "modules" "defaults" }}
{{- $mergedValues = merge $mergedValues (deepCopy $topLevelValues) }}

{{- $mergedValues | toJson }}
{{- end }}

{{- define "wiz-outpost-lite.runners" -}}
{{- $runnerValues := dict }}
{{- range $runner, $values := $.Values.runners }}

{{/* e.g. containerRegistry -> container-registry */}}
{{- $runner = $runner | kebabcase }}
{{- $runnerID := get $values "runnerID" | default $runner }}
{{- $module := include "wiz-outpost-lite.getModule" $runner }}

{{/* Get merged values for this runner */}}
{{- $mergedValues := include "wiz-outpost-lite.mergedRunnerValues" (dict "runner" $runner "Values" $.Values) | fromJson }}

{{/* Unify with global .Values to be used inside a "with" statement */}}
{{- $values = dict "runner" $runner "runnerID" $runnerID "Values" $mergedValues -}}
{{- $runnerValues = set $runnerValues $runner $values }}
{{- end }} {{/* range */}}

{{ $runnerValues | toJson }}
{{- end }} {{/* define */}}
