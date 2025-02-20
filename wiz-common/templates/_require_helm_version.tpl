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

  {{- if not (semverCompare ">=3.10.0" $helmVersion) }}
    {{- fail (printf "This chart requires Helm client version 3.10.0 or higher. Found %s" $helmVersion) }}
  {{- end -}}
{{- end -}}