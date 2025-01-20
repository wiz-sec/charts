{{- define "helmVersion" -}}
{{- if and .Values.mockCapabilities .Values.mockCapabilities.helmVersion .Values.mockCapabilities.helmVersion.version -}}
{{ .Values.mockCapabilities.helmVersion.version }}
{{- else -}}
{{ .Capabilities.HelmVersion.Version }}
{{- end -}}
{{- end -}}

{{- define "wiz-common.requireHelm36" -}}
{{- if not (semverCompare ">=3.6.0" (include "helmVersion" .)) -}}
{{- fail (printf "This chart requires Helm client version 3.6.0 or higher. Found %s" (include "helmVersion" .) ) -}}
{{- end -}}
{{- end -}}