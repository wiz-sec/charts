{{/*
Generate a server certificate signed by the control plane CA.

Parameters (passed as a dict):
  - root: the chart's root context (.)
  - cn: common name for the certificate
  - dnsBase: base DNS name for SAN entries (may differ from cn)
  - labelTemplate: name of the chart's labels template to include
  - secretName: (optional) name of the Secret to create; defaults to controlPlaneTLS.serverSecretName
  - caNamespace: (optional) namespace to look up the CA secret; defaults to Release.Namespace
  - extraDnsBases: (optional) additional base DNS names; each gets the same namespace suffix variants as dnsBase
*/}}
{{- define "wiz.controlplane-server-cert" -}}
{{- if .root.Values.controlPlaneTLS.enabled }}
{{- $secretName := .secretName | default .root.Values.controlPlaneTLS.serverSecretName }}
{{- $caNamespace := .caNamespace | default .root.Release.Namespace }}
{{- $caSecret := lookup "v1" "Secret" $caNamespace .root.Values.controlPlaneTLS.caSecretName }}
{{- if $caSecret }}
{{- $ca := buildCustomCert (index $caSecret.data "ca.crt") (index $caSecret.data "ca.key") }}
{{- $caHash := index $caSecret.data "ca.crt" | b64dec | sha256sum }}
{{- $existingCert := lookup "v1" "Secret" .root.Release.Namespace $secretName }}
{{- $regenerate := true }}
{{- $cert := dict }}

{{- /* Check if existing cert was signed by the same CA */ -}}
{{- if $existingCert }}
  {{- $existingCAHash := index $existingCert.metadata.annotations "wiz.io/control-plane-ca-hash" | default "" }}
  {{- if eq $existingCAHash $caHash }}
    {{- $regenerate = false }}
    {{- $cert = dict "Cert" (index $existingCert.data "tls.crt" | b64dec) "Key" (index $existingCert.data "tls.key" | b64dec) }}
  {{- end }}
{{- end }}

{{- /* Generate new server certificate if needed */ -}}
{{- if $regenerate }}
  {{- $ns := .root.Release.Namespace }}
  {{- $allBases := prepend (.extraDnsBases | default list) .dnsBase }}
  {{- $dnsNames := list }}
  {{- range $allBases }}
    {{- $dnsNames = append $dnsNames . }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s" . $ns) }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s.svc" . $ns) }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s.svc.cluster.local" . $ns) }}
  {{- end }}
  {{- $cert = genSignedCert .cn nil $dnsNames 3650 $ca }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretName }}
  labels:
    {{- include .labelTemplate .root | nindent 4 }}
  annotations:
    wiz.io/control-plane-ca-hash: {{ $caHash | quote }}
type: kubernetes.io/tls
data:
  tls.crt: {{ $cert.Cert | b64enc }}
  tls.key: {{ $cert.Key | b64enc }}
{{- else if .root.Values.controlPlaneTLS.required }}
{{- fail (printf "controlPlaneTLS is required but CA secret '%s' not found in namespace '%s'" .root.Values.controlPlaneTLS.caSecretName $caNamespace) }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Pod annotation for tracking CA certificate changes.
Triggers pod restart when the CA cert is rotated.
Uses caSourceNamespace if set, otherwise falls back to Release.Namespace.
*/}}
{{- define "wiz.controlplane-tls-ca-hash-annotation" -}}
{{- if .Values.controlPlaneTLS.enabled }}
{{- $ns := .Values.controlPlaneTLS.caSourceNamespace | default .Release.Namespace }}
{{- $caConfigMap := lookup "v1" "ConfigMap" $ns .Values.controlPlaneTLS.caConfigMapName }}
{{- if $caConfigMap }}
wiz.io/control-plane-ca-hash: {{ index $caConfigMap.data "ca.crt" | sha256sum | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Returns "true" when control plane TLS is active: enabled AND either required or
the CA ConfigMap already exists in the cluster. Uses caSourceNamespace if set,
otherwise falls back to Release.Namespace.
*/}}
{{- define "wiz.controlplane-tls-active" -}}
{{- $ns := .Values.controlPlaneTLS.caSourceNamespace | default .Release.Namespace }}
{{- if and .Values.controlPlaneTLS.enabled (or .Values.controlPlaneTLS.required (lookup "v1" "ConfigMap" $ns .Values.controlPlaneTLS.caConfigMapName)) }}true{{- end }}
{{- end -}}

{{/*
WIZ_CONTROL_PLANE_TLS env var, set when control plane TLS is active.
*/}}
{{- define "wiz.controlplane-tls-env" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: WIZ_CONTROL_PLANE_TLS
  value: "true"
{{- end }}
{{- end -}}

{{/*
Projected volume sources for control plane TLS certificates.

Parameters (passed as a dict):
  - root: the chart's root context (.)
  - ca: include CA configmap (optional, default true)
  - server: include server cert (optional, default false)
  - client: include client cert (optional, default false)
*/}}
{{- define "wiz.controlplane-tls-volume-sources" -}}
{{- if include "wiz.controlplane-tls-active" .root }}
{{- if or (not (hasKey . "ca")) .ca }}
- configMap:
    name: {{ .root.Values.controlPlaneTLS.caConfigMapName }}
    items:
      - key: ca.crt
        path: CONTROL_PLANE_CA_CERT
{{- end }}
{{- if .server }}
- secret:
    name: {{ .root.Values.controlPlaneTLS.serverSecretName }}
    items:
      - key: tls.crt
        path: CONTROL_PLANE_SERVER_CERT
      - key: tls.key
        path: CONTROL_PLANE_SERVER_KEY
{{- end }}
{{- if .client }}
- secret:
    name: {{ .root.Values.controlPlaneTLS.clientSecretName }}
    items:
      - key: tls.crt
        path: CONTROL_PLANE_CLIENT_CERT
      - key: tls.key
        path: CONTROL_PLANE_CLIENT_KEY
{{- end }}
{{- end }}
{{- end -}}
