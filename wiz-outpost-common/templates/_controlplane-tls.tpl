{{/*
Version of the shared cert generation logic. Bump when changing DNS expansion,
cert validity, SAN construction, or any other shared cert generation behavior.
*/}}
{{- define "wiz.controlplane-cert-logic-version" -}}1{{- end -}}

{{/*
Resolves a single serverCerts entry's CN and DNS names via tpl.
Returns a JSON object: {"cn": "...", "dnsNames": ["...", ...]}.
Use fromJson on the result to access the structured data.

Parameters (passed as a dict):
  - certEntry: a single entry from controlPlaneTLS.serverCerts
  - root: the chart's root context ($)
*/}}
{{- define "wiz.controlplane-resolve-cert-entry" -}}
{{- $resolvedDNS := list }}
{{- range $dnsNameTpl := .certEntry.dnsNames }}
  {{- $resolvedDNS = append $resolvedDNS (tpl $dnsNameTpl $.root) }}
{{- end }}
{{- $cn := "" }}
{{- if .certEntry.cn }}
  {{- $cn = tpl .certEntry.cn .root }}
{{- else }}
  {{- $cn = index $resolvedDNS 0 }}
{{- end }}
{{- dict "cn" $cn "dnsNames" $resolvedDNS | toJson }}
{{- end -}}

{{/*
Evaluates whether a serverCerts entry is enabled.
Returns "true" if enabled, empty string if disabled.
Entries without an "enabled" field default to enabled.
The "enabled" field supports tpl expressions (e.g. '{{ .Values.scannerCredProvider.enabled }}').

Parameters (passed as a dict):
  - certEntry: a single entry from controlPlaneTLS.serverCerts
  - root: the chart's root context ($)
*/}}
{{- define "wiz.controlplane-cert-entry-enabled" -}}
{{- if hasKey .certEntry "enabled" -}}
  {{- $val := tpl (toString .certEntry.enabled) .root -}}
  {{- if eq $val "true" -}}true{{- end -}}
{{- else -}}true{{- end -}}
{{- end -}}

{{/*
Generate server certificates from the controlPlaneTLS.serverCerts list.

Reads all configuration from .Values.controlPlaneTLS:
  - serverCerts: list of certs, each with secretName, dnsNames, optional cn, and optional enabled
  - labelTemplate: name of the chart's labels template
  - serverCertGeneration: provisioner lever for forced regeneration (default "1")
  - caSecretName: name of the CA secret
  - caSourceNamespace: (optional) namespace to look up the CA secret

Values in serverCerts support template expressions via tpl (e.g. '{{ include "my.fullname" . }}').
cn defaults to the first resolved dnsNames entry if not specified.
enabled defaults to true if not specified; supports tpl expressions.

Usage:
  {{- include "wiz.controlplane-server-certs" . }}
*/}}
{{- define "wiz.controlplane-server-certs" -}}
{{- if .Values.controlPlaneTLS.enabled }}
{{- $caNamespace := .Values.controlPlaneTLS.caSourceNamespace | default .Release.Namespace }}
{{- $caSecret := lookup "v1" "Secret" $caNamespace .Values.controlPlaneTLS.caSecretName }}
{{- if $caSecret }}
{{- $ca := buildCustomCert (index $caSecret.data "ca.crt") (index $caSecret.data "ca.key") }}
{{- $certHash := include "wiz.controlplane-server-cert-hash" . }}
{{- $labelTemplate := .Values.controlPlaneTLS.labelTemplate }}
{{- $ns := .Release.Namespace }}

{{- range $certEntry := .Values.controlPlaneTLS.serverCerts }}
{{- if include "wiz.controlplane-cert-entry-enabled" (dict "certEntry" $certEntry "root" $) }}

{{- /* Resolve cert entry params (CN + DNS names) via shared helper */ -}}
{{- $certParams := include "wiz.controlplane-resolve-cert-entry" (dict "certEntry" $certEntry "root" $) | fromJson }}
{{- $cn := $certParams.cn }}

{{- $secretName := tpl $certEntry.secretName $ }}

{{- /* Reuse existing cert if the combined hash hasn't changed */ -}}
{{- $existingCert := lookup "v1" "Secret" $ns $secretName }}
{{- $regenerate := true }}
{{- $cert := dict }}
{{- if $existingCert }}
  {{- $existingHash := index $existingCert.metadata.annotations "wiz.io/control-plane-cert-hash" | default "" }}
  {{- if eq $existingHash $certHash }}
    {{- $regenerate = false }}
    {{- $cert = dict "Cert" (index $existingCert.data "tls.crt" | b64dec) "Key" (index $existingCert.data "tls.key" | b64dec) }}
  {{- end }}
{{- end }}

{{- if $regenerate }}
  {{- $dnsNames := list }}
  {{- range $certParams.dnsNames }}
    {{- $dnsNames = append $dnsNames . }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s" . $ns) }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s.svc" . $ns) }}
    {{- $dnsNames = append $dnsNames (printf "%s.%s.svc.cluster.local" . $ns) }}
  {{- end }}
  {{- /*
    IMPORTANT: If you change this call (e.g. validity days, SAN structure):
    - Hardcoded change: bump wiz.controlplane-cert-logic-version
    - Parametrized change: add the new param to the hash dict in wiz.controlplane-server-cert-hash
  */ -}}
  {{- $cert = genSignedCert $cn nil $dnsNames 3650 $ca }}
{{- end }}
---
apiVersion: v1
kind: Secret
metadata:
  name: {{ $secretName }}
  labels:
    {{- include $labelTemplate $ | nindent 4 }}
  annotations:
    wiz.io/control-plane-cert-hash: {{ $certHash | quote }}
type: kubernetes.io/tls
data:
  tls.crt: {{ $cert.Cert | b64enc }}
  tls.key: {{ $cert.Key | b64enc }}
{{- end }}
{{- end }}

{{- else if .Values.controlPlaneTLS.required }}
{{- fail (printf "controlPlaneTLS is required but CA secret '%s' not found in namespace '%s'" .Values.controlPlaneTLS.caSecretName $caNamespace) }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Pod annotation for tracking CA certificate changes.
Triggers pod restart when the CA cert is rotated.
Use on deployments that only mount CA/client certs (not server certs).
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
Computes the combined server certificate hash from all cert inputs.
Returns the sha256 hash string, or empty if the CA ConfigMap is not found.

Inputs hashed: CA cert, commonCertLogicVersion, serverCertGeneration,
and each enabled serverCerts entry's CN + DNS names.

Usage:
  {{- $hash := include "wiz.controlplane-server-cert-hash" . }}
*/}}
{{- define "wiz.controlplane-server-cert-hash" -}}
{{- $ns := .Values.controlPlaneTLS.caSourceNamespace | default .Release.Namespace }}
{{- $caConfigMap := lookup "v1" "ConfigMap" $ns .Values.controlPlaneTLS.caConfigMapName }}
{{- if $caConfigMap }}
{{- $certs := list }}
{{- range $certEntry := .Values.controlPlaneTLS.serverCerts }}
  {{- if include "wiz.controlplane-cert-entry-enabled" (dict "certEntry" $certEntry "root" $) }}
  {{- $certParams := include "wiz.controlplane-resolve-cert-entry" (dict "certEntry" $certEntry "root" $) | fromJson }}
  {{- $certs = append $certs $certParams }}
  {{- end }}
{{- end }}
{{- dict "caHash" (index $caConfigMap.data "ca.crt" | sha256sum) "certLogicVersion" (include "wiz.controlplane-cert-logic-version" .) "serverCertGeneration" .Values.controlPlaneTLS.serverCertGeneration "certs" $certs | toJson | sha256sum }}
{{- end }}
{{- end -}}

{{/*
Pod annotation for tracking server certificate input changes.
Triggers pod restart when any cert input changes: CA rotation, DNS names,
cert logic version, or serverCertGeneration bump.
Use on deployments that mount server certificates.
Replaces controlplane-tls-ca-hash-annotation for these deployments since the
hash already includes the CA.

Usage:
  {{- include "wiz.controlplane-tls-server-cert-hash-annotation" . | nindent 8 }}
*/}}
{{- define "wiz.controlplane-tls-server-cert-hash-annotation" -}}
{{- if .Values.controlPlaneTLS.enabled }}
{{- $hash := include "wiz.controlplane-server-cert-hash" . }}
{{- if $hash }}
wiz.io/control-plane-cert-hash: {{ $hash | quote }}
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
