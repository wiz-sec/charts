{{- define "wiz-common.requireHelm310" -}}

{{/* We don't want to use (and .Values.mockCapabilities .Values.mockCapabilities.helmVersion ...) since it breaks in old helm versions */}}
  {{- $helmVersion := .Capabilities.HelmVersion.Version }}
  {{- if .Values.mockCapabilities -}}
    {{- if .Values.mockCapabilities.helmVersion -}}
      {{- if .Values.mockCapabilities.helmVersion.version -}}
        {{- $helmVersion = .Values.mockCapabilities.helmVersion.version -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}

  {{/* Parse the version string and reconstruct a clean version with just major.minor.patch */}}
  {{- $parsedVersion := semver $helmVersion }}
  {{- $cleanVersion := printf "%d.%d.%d" $parsedVersion.Major $parsedVersion.Minor $parsedVersion.Patch }}

  {{- if not (semverCompare ">=3.10.0" $cleanVersion) }}
    {{- printf "WARNING: This chart is intended for Helm client version 3.10.0 or higher. Found %s\n" $helmVersion | quote }}
  {{- end -}}
{{- end -}}
