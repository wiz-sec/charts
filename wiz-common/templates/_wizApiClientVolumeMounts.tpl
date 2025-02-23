{{- define  "wiz-common.volumes.apiClientName" -}}
api-client
{{- end -}}

{{- define "wiz-common.isWizApiClientVolumeMountEnabled" -}}
  {{- $usePodCustomEnvironmentVariablesFile := index . 0 -}}
  {{- $wizApiTokensVolumeMount := index . 1 -}}
  {{- if or $usePodCustomEnvironmentVariablesFile $wizApiTokensVolumeMount }}
    false
  {{- else }}
    true
  {{- end }}
{{- end }}
