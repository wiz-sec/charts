{{/*
WIZ: Control plane TLS helpers for flux2 chart.

All templates are no-ops when controlPlaneTLS is not configured or disabled.
See UPSTREAM-SYNC.md in this directory for maintenance instructions.
*/}}

{{/* ---- Shared ---- */}}

{{- define "flux2.labels" -}}
app.kubernetes.io/part-of: flux
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}

{{/*
Pod annotations for source-controller: merges user annotations with the server cert hash annotation.
Outputs the full annotations: block, or nothing if both are empty.
*/}}
{{- define "flux2.wiz-source-controller-pod-annotations" -}}
{{- $tlsAnnotation := include "wiz.controlplane-tls-server-cert-hash-annotation" . -}}
{{- if or .Values.sourceController.annotations $tlsAnnotation -}}
annotations:
  {{- with .Values.sourceController.annotations }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $tlsAnnotation }}
  {{- . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* ---- Source-controller (server side) ---- */}}

{{/*
URL scheme prefix for --storage-adv-addr. Outputs "https://" when TLS is enabled, empty otherwise.
*/}}
{{- define "flux2.wiz-tls-scheme" -}}
{{- if include "wiz.controlplane-tls-active" . -}}https://{{- end -}}
{{- end -}}

{{/*
Env var so source-controller trusts the control plane CA (for git-proxy).
*/}}
{{- define "flux2.wiz-source-controller-env" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: SSL_CERT_DIR
  value: "/etc/ssl/certs:/mnt/ca"
{{- end }}
{{- end -}}

{{/*
Volume mount for CA certificate on the main source-controller container.
*/}}
{{- define "flux2.wiz-source-controller-vmounts" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: control-plane-tls-ca
  mountPath: /mnt/ca/
  readOnly: true
{{- end }}
{{- end -}}

{{/*
Projected volumes: server cert+key (for HTTPS proxy sidecar) and CA cert (to trust git-proxy).
*/}}
{{- define "flux2.wiz-source-controller-vols" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: control-plane-tls-server
  projected:
    sources:
      {{- include "wiz.controlplane-tls-volume-sources" (dict "root" . "server" true "client" false) | nindent 6 }}
- name: control-plane-tls-ca
  projected:
    sources:
      {{- include "wiz.controlplane-tls-volume-sources" (dict "root" . "server" false "client" false) | nindent 6 }}
{{- end }}
{{- end -}}

{{/*
HTTPS reverse proxy sidecar container for source-controller.
Terminates TLS on port 9443 and forwards to the storage HTTP server on port 9090.
*/}}
{{- define "flux2.wiz-source-controller-proxy-sidecar" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: https-proxy
  image: {{ template "template.image" .Values.sourceController }}
  {{- if .Values.sourceController.imagePullPolicy }}
  imagePullPolicy: {{ .Values.sourceController.imagePullPolicy }}
  {{- else }}
  imagePullPolicy: IfNotPresent
  {{- end }}
  command: ["/usr/local/bin/https-proxy"]
  args:
  - --tls-cert=/mnt/secrets/CONTROL_PLANE_SERVER_CERT
  - --tls-key=/mnt/secrets/CONTROL_PLANE_SERVER_KEY
  ports:
  - containerPort: 9443
    name: https
    protocol: TCP
  - containerPort: 9444
    name: proxy-health
    protocol: TCP
  readinessProbe:
    httpGet:
      path: /healthz
      port: 9444
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop:
      - ALL
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  volumeMounts:
  - name: control-plane-tls-server
    mountPath: /mnt/secrets/
    readOnly: true
{{- end }}
{{- end -}}

{{/* ---- Service ---- */}}

{{/*
Service port for source-controller: HTTPS (443→https) when TLS is active, HTTP (80→http) otherwise.
*/}}
{{- define "flux2.wiz-source-controller-service-port" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: https
  port: 443
  protocol: TCP
  targetPort: https
{{- else }}
- name: http
  port: 80
  protocol: TCP
  targetPort: http
{{- end }}
{{- end -}}

{{/*
Pod annotations for helm-controller: merges user annotations with the CA hash annotation.
Outputs the full annotations: block, or nothing if both are empty.
*/}}
{{- define "flux2.wiz-helm-controller-pod-annotations" -}}
{{- $tlsAnnotation := include "wiz.controlplane-tls-ca-hash-annotation" . -}}
{{- if or .Values.helmController.annotations $tlsAnnotation -}}
annotations:
  {{- with .Values.helmController.annotations }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $tlsAnnotation }}
  {{- . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/*
Pod annotations for kustomize-controller: merges user annotations with the CA hash annotation.
Outputs the full annotations: block, or nothing if both are empty.
*/}}
{{- define "flux2.wiz-kustomize-controller-pod-annotations" -}}
{{- $tlsAnnotation := include "wiz.controlplane-tls-ca-hash-annotation" . -}}
{{- if or .Values.kustomizeController.annotations $tlsAnnotation -}}
annotations:
  {{- with .Values.kustomizeController.annotations }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
  {{- with $tlsAnnotation }}
  {{- . | nindent 2 }}
  {{- end }}
{{- end }}
{{- end -}}

{{/* ---- Consumer controllers (helm-controller, kustomize-controller) ---- */}}

{{/*
Env vars so consumer controllers trust the control plane CA.
SSL_CERT_DIR tells Go's crypto/x509 where to find CA certs.
*/}}
{{- define "flux2.wiz-consumer-env" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: SSL_CERT_DIR
  value: "/etc/ssl/certs:/mnt/ca"
{{- end }}
{{- end -}}

{{/*
Volume mount for CA certificate (consumers only need the CA to verify the server).
*/}}
{{- define "flux2.wiz-consumer-vmounts" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: control-plane-tls-ca
  mountPath: /mnt/ca/
  readOnly: true
{{- end }}
{{- end -}}

{{/*
Projected volume containing only the CA cert (no server or client certs).
*/}}
{{- define "flux2.wiz-consumer-vols" -}}
{{- if include "wiz.controlplane-tls-active" . }}
- name: control-plane-tls-ca
  projected:
    sources:
      {{- include "wiz.controlplane-tls-volume-sources" (dict "root" . "server" false "client" false) | nindent 6 }}
{{- end }}
{{- end -}}

