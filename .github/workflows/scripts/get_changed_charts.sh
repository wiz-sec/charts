#!/usr/bin/env bash
set -euET -o pipefail # BASAD
shopt -s inherit_errexit

# or stdout
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"
GIT_ROOT="${GIT_ROOT:-$(git rev-parse --show-toplevel)}"
pushd "$GIT_ROOT" >/dev/null || exit 1

# Charts published to oci://public-registry.wiz.io/charts by the ops pipeline
# (.circleci/scripts/publish_external_charts/acr_charts_allowlist.txt). They are
# deliberately kept off public GHCR, and that pipeline creates their GitHub
# Releases once the ACR push verifies. See WZ-139865.
ACR_PUBLISHED_CHARTS=(
	wiz-admission-controller
	wiz-broker
	wiz-common
	wiz-kubernetes-connector
	wiz-kubernetes-integration
	wiz-network-analyzer
	wiz-sensor
)

function is_acr_published() {
	local candidate="$1" chart
	for chart in "${ACR_PUBLISHED_CHARTS[@]}"; do
		[[ "$chart" == "$candidate" ]] && return 0
	done
	return 1
}

CHANGED_FILES="$(git diff --name-only HEAD^ HEAD)"
# Requiring a slash keeps top-level files (README.md, LICENSE) from looking like
# chart directories, and the leading [^.] keeps out .github. A directory still
# only counts once it is confirmed to hold a Chart.yaml below.
CHANGED_CHART_DIRS="$(echo "$CHANGED_FILES" | grep -E '^[^./][^/]*/' | cut -d/ -f1 | sort -u || true)"
echo "changes: ${CHANGED_CHART_DIRS}"
CHANGES_MATRIX=()
for change in $CHANGED_CHART_DIRS; do
	if [[ ! -f "$change/Chart.yaml" ]]; then
		echo "skipping $change: not a chart directory"
		continue
	fi
	if is_acr_published "$change"; then
		echo "skipping $change: published to the ACR, not to GHCR"
		continue
	fi
	CHANGES_MATRIX+=("$(
		jq -ncM '$ARGS.named' \
			--arg chart "$change" \
			--arg version "$(yq .version "$change/Chart.yaml")"
	)")
done
echo "CHANGES_MATRIX: ${CHANGES_MATRIX[*]-}"
MATRIX=""
if [[ -n "${CHANGES_MATRIX[*]-}" ]]; then
	# https://stackoverflow.com/questions/26808855/how-to-format-a-bash-array-as-a-json-array
	MATRIX="$(printf '%s\n' "${CHANGES_MATRIX[@]}" | sort -u | jq -sc .)"
	echo "charts_matrix=${MATRIX}" >>"$GITHUB_OUTPUT"
fi
if [[ -n "${MATRIX}" ]]; then
	echo "any_changed=true" >>"$GITHUB_OUTPUT"
else
	echo "any_changed=false" >>"$GITHUB_OUTPUT"
fi
