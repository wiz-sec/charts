#!/usr/bin/env bash
# Golden-file regression tests for the per-component scheduling change.
#
# Renders templates/deploymentenforcement.yaml + templates/deploymentauditlogs.yaml
# for each scenario in scenarios/ and compares against expected/<scenario>.golden.yaml.
#
#   ./render-golden.sh            # regenerate the golden files (after an intended change)
#   ./render-golden.sh --check    # verify no drift (CI)
#
# Prereqs: helm, and chart deps present (`helm dependency build <chart>`).
#
# Two nondeterministic/version-coupled values are normalized so the goldens
# capture scheduling behavior only:
#   - rollme.webhookCert  (sha256 of a freshly self-signed webhook cert)
#   - the chart version    (from Chart.yaml, so a version bump is not spurious drift)
set -euo pipefail

CHART_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"   # wiz-admission-controller/
TESTS_DIR="$CHART_DIR/tests/golden"
BASE="$TESTS_DIR/_base.values.yaml"
SCEN_DIR="$TESTS_DIR/scenarios"
EXP_DIR="$TESTS_DIR/expected"
DEPLOYMENTS=(-s templates/deploymentenforcement.yaml -s templates/deploymentauditlogs.yaml)
MODE="${1:-regen}"

CHART_VERSION="$(awk '/^version:/{print $2; exit}' "$CHART_DIR/Chart.yaml")"

render() {
  local scenario="$1"
  helm template ac "$CHART_DIR" -f "$BASE" -f "$SCEN_DIR/${scenario}.values.yaml" "${DEPLOYMENTS[@]}" 2>/dev/null \
    | sed -E \
        -e "s/(rollme\.webhookCert:).*/\1 __NONDETERMINISTIC__/" \
        -e "s/wiz-admission-controller-${CHART_VERSION}/wiz-admission-controller-__CHART_VERSION__/g" \
        -e "s/\"${CHART_VERSION}\"/\"__CHART_VERSION__\"/g"
}

mkdir -p "$EXP_DIR"
fail=0
for f in "$SCEN_DIR"/*.values.yaml; do
  name="$(basename "$f" .values.yaml)"
  out="$EXP_DIR/${name}.golden.yaml"
  if [[ "$MODE" == "--check" ]]; then
    if diff -u "$out" <(render "$name") >/dev/null 2>&1; then
      echo "OK:    $name"
    else
      echo "DRIFT: $name  (run tests/golden/render-golden.sh to regenerate)"
      diff -u "$out" <(render "$name") || true
      fail=1
    fi
  else
    render "$name" > "$out"
    echo "wrote  $out"
  fi
done
exit $fail
