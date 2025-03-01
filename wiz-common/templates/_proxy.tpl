{{- define  "wiz-common.proxy.name" -}}
proxy
{{- end -}}


{{- define "wiz-common.proxy.volume" -}}
{{- $secret := index . 0 -}}
- name: {{ include "wiz-common.proxy.name" . | trim }}
  secret:
    secretName: {{ $secret }}
    items:
    - key: httpProxy
      path: httpProxy
    - key: httpsProxy
      path: httpsProxy
    - key: noProxyAddress
      path: noProxy
{{- end -}}

{{- define "wiz-common.proxy.volumeMount" -}}
- name: {{ include "wiz-common.proxy.name" . }}
  mountPath: /var/{{ include "wiz-common.proxy.name" . }}
  readOnly: true
{{- end -}}

{{- define "wiz-common.proxy.env" -}}
- name: CLI_FILES_AS_ENV_VARS
  value: "/var/{{ include "wiz-common.proxy.name" . }}/httpProxy,/var/{{ include "wiz-common.proxy.name" . }}/httpsProxy,/var/{{ include "wiz-common.proxy.name" . }}/noProxy"
{{- end -}}