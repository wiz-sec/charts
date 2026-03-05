# Wiz TLS Customizations — Upstream Sync Guide

This `templates/wiz/` folder contains all Wiz-specific TLS logic for the flux2 chart.
It implements `controlPlaneTLS` support (HTTPS for source-controller, CA trust for consumers).

## How It Works

- `tls.tpl` defines named helper templates (all no-ops when `controlPlaneTLS.enabled` is false)
- `source-controller-server-cert.yaml` generates a server certificate signed by the control plane CA
- The upstream templates call these helpers via `{{ include }}` lines at specific injection points
- The `wiz-outpost-common` library chart (dependency in `Chart.yaml`) provides the shared cert generation helpers

## Upstream Sync Checklist

When syncing with the upstream fluxcd-community chart:

1. **Pull upstream changes** into the template files
2. **Keep this `templates/wiz/` folder intact** — upstream has no equivalent, so it never conflicts
3. **Re-add the `include` lines** listed below if they were overwritten
4. **Keep `controlPlaneTLS` block** at the end of `values.yaml`
5. **Keep `wiz-outpost-common` dependency** in `Chart.yaml`
6. **Verify** with `helm template` (see Verification section below)

## Include Lines to Preserve

### `source-controller.yaml`

| Where | What to add |
|-------|-------------|
| Inside `{{- with .Values.sourceController.annotations }}` block, after `{{ toYaml . \| nindent 8 }}` | `{{- include "wiz.controlplane-tls-ca-hash-annotation" $ \| nindent 8 }}` |
| In the `--storage-adv-addr=` argument, add scheme prefix after `=` | `{{ include "flux2.wiz-tls-scheme" . }}` (inline, e.g. `--storage-adv-addr={{ include "flux2.wiz-tls-scheme" . }}source-controller...`) |
| After the `sourceController.extraEnv` block | `{{- include "flux2.wiz-source-controller-env" . \| nindent 8 }}` |
| After the `sourceController.volumeMounts` block | `{{- include "flux2.wiz-source-controller-vmounts" . \| nindent 8 }}` |
| After the main container's volumeMounts (before priorityClassName) | `{{- include "flux2.wiz-source-controller-proxy-sidecar" . \| nindent 6 }}` |
| After the `sourceController.volumes` block | `{{- include "flux2.wiz-source-controller-vols" . \| nindent 6 }}` |

### `source-controller-service.yaml`

| Where | What to add |
|-------|-------------|
| Replace the hardcoded `http`/`80` port block | `{{- include "flux2.wiz-source-controller-service-port" . \| nindent 2 }}` |

### `helm-controller.yaml`

| Where | What to add |
|-------|-------------|
| Inside `{{- with .Values.helmController.annotations }}` block, after `{{ toYaml . \| nindent 8 }}` | `{{- include "wiz.controlplane-tls-ca-hash-annotation" $ \| nindent 8 }}` |
| After the `helmController.extraEnv` block | `{{- include "flux2.wiz-consumer-env" . \| nindent 8 }}` |
| After the `helmController.volumeMounts` block | `{{- include "flux2.wiz-consumer-vmounts" . \| nindent 8 }}` |
| After the `helmController.volumes` block | `{{- include "flux2.wiz-consumer-vols" . \| nindent 6 }}` |

### `kustomize-controller.yaml`

| Where | What to add |
|-------|-------------|
| Inside `{{- with .Values.kustomizeController.annotations }}` block, after `{{ toYaml . \| nindent 8 }}` | `{{- include "wiz.controlplane-tls-ca-hash-annotation" $ \| nindent 8 }}` |
| After the `kustomizeController.extraEnv` block | `{{- include "flux2.wiz-consumer-env" . \| nindent 8 }}` |
| After the `kustomizeController.volumeMounts` block | `{{- include "flux2.wiz-consumer-vmounts" . \| nindent 8 }}` |
| After the `kustomizeController.extraSecretMounts` volumes block | `{{- include "flux2.wiz-consumer-vols" . \| nindent 6 }}` |

## Verification

After syncing, render the chart with TLS both enabled and disabled:

```bash
# Should produce identical output to pre-sync (no TLS artifacts)
helm template flux2 charts/charts/flux2 --set git.path=./test

# Should include HTTPS proxy env vars, ports, certs, and CA mounts
helm template flux2 charts/charts/flux2 --set git.path=./test --set controlPlaneTLS.enabled=true
```

Check for:
- Source-controller deployment: `PROXY_TLS_CERT`, `PROXY_TLS_KEY` env vars, port 9443, `/mnt/secrets` mount
- Source-controller service: port 443 targeting `https`
- Helm/kustomize controller deployments: `SSL_CERT_DIR` env var, `/mnt/secrets` mount with CA cert
- `--storage-adv-addr` uses `https://` prefix when TLS is enabled
