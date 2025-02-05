{{- define "wiz-common.renderResources" -}}
{{/*
  This function:
    - Takes a list of two items:
        1) The local resources object
        2) The global resources object
    - If the local object has any "requests" or "limits", it returns them
      under a `resources` key.
    - Otherwise, it returns the global object under a `resources` key.
    - If neither is set, it returns an empty string.
    - The caller should handle final indentation using `| nindent <x>`.
*/}}

{{- $local := index . 0 -}}
{{- $global := index . 1 -}}

{{- $hasLocalResources := or (hasKey $local "limits") (hasKey $local "requests") }}
{{- $hasGlobalResources := or (hasKey $global "limits") (hasKey $global "requests") }}

{{- if $hasLocalResources }}
resources:
  {{- toYaml $local | nindent 2 }}
{{- else if $hasGlobalResources }}
resources:
  {{- toYaml $global | nindent 2 }}
{{- end }}
{{- end }}
