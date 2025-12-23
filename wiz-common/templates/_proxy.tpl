{{- define  "wiz-common.proxy.name" -}}
proxy
{{- end -}}

{{- define "wiz-common.proxy.dir" -}}
/var/{{ include "wiz-common.proxy.name" . }}
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
    - key: clientCertificate
      path: clientCertificate
{{- end -}}

{{- define "wiz-common.proxy.volumeMount" -}}
- name: {{ include "wiz-common.proxy.name" . }}
  mountPath: {{ include "wiz-common.proxy.dir" . }}
  readOnly: true
{{- end -}}

{{- define "wiz-common.proxy.env" -}}
- name: CLI_FILES_AS_ENV_VARS
  value: "{{ include "wiz-common.proxy.dir" . }}/httpProxy,{{ include "wiz-common.proxy.dir" . }}/httpsProxy,{{ include "wiz-common.proxy.dir" . }}/noProxy"
{{- end -}}
