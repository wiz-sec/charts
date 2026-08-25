# Golden-file tests — per-component scheduling

These golden files pin the rendered output of the enforcement
(`deploymentenforcement.yaml`) and audit-log (`deploymentauditlogs.yaml`)
deployments for the `enforcement.*` / `auditLogs.*` scheduling change, so any
future edit that alters `affinity` / `nodeSelector` / `tolerations` behavior is
caught in review.

## Run

```bash
helm dependency build ..            # from this dir: build wiz-common into ../charts
./render-golden.sh                  # regenerate expected/*.golden.yaml (after an intended change)
./render-golden.sh --check          # verify no drift (CI)
```

Two values are normalized so the goldens capture scheduling behavior only:
`rollme.webhookCert` (sha256 of a freshly self-signed webhook cert, random each
render) and the chart version from `Chart.yaml` (so a version bump is not
flagged as drift).

## Scenarios

| Scenario | Input | What it proves |
| --- | --- | --- |
| `default` | no overrides | Both deployments inherit the shared default `nodeAffinity` (linux/arm64/amd64). Must stay byte-identical to the pre-change chart. |
| `existing-customer` | HA via the shared `affinity` block only | A customer configured today via the shared block renders **identically** on the new chart (no per-component fields set) — the upgrade is a no-op. Also captures the pre-existing leak this PR fixes: the shared `podAntiAffinity` lands in **both** deployments. |
| `per-component` | `enforcement.affinity` + `auditLogs.nodeSelector`/`tolerations` | The fix: the enforcer gets its own HA `podAntiAffinity`; the audit-log collector gets its own `nodeSelector`/`tolerations`. Neither rule leaks into the other deployment. |

## Behavior summary (from the golden files)

`existing-customer` (shared block — leak): the enforcer's `podAntiAffinity`
(`app.kubernetes.io/name: wiz-admission-controller`) appears in **both**
deployments, so audit-log pods anti-affine against enforcer pods.

`per-component` (fix — no leak):

```
enforcement deployment            audit-log deployment
  affinity:                         nodeSelector:
    nodeAffinity: [os=linux]          dedicated: audit-logs
    podAntiAffinity:                affinity:
      wiz.io/component:               nodeAffinity: [os/arch]   # default, inherited
        admission-controller-enforcer tolerations:
      topologyKey: hostname            - key: dedicated ...
```

## Upgrade no-op proof (existing customers)

Rendering `existing-customer` on `master` vs this branch, with the chart version
held constant and the nondeterministic cert annotation normalized:

```
$ diff before.yaml after.yaml
>>> IDENTICAL — existing customers' manifests are unchanged on upgrade.
```
