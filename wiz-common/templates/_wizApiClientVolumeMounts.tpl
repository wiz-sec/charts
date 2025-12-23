{{- define  "wiz-common.volumes.apiClientName" -}}
api-client
{{- end -}}

{{- define "wiz-common.isWizApiClientVolumeMountEnabled" -}}
  {{- $usePodCustomEnvironmentVariablesFile := index . 0 -}}
  {{- $wizApiTokensVolumeMount := index . 1 -}}
  {{- $globalWizApiTokensVolumeMount := index . 2 -}}
  {{- if or $usePodCustomEnvironmentVariablesFile (coalesce $wizApiTokensVolumeMount $globalWizApiTokensVolumeMount "") }}
    false
  {{- else }}
    true
  {{- end }}
{{- end }}
