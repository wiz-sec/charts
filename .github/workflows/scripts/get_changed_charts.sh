#!/usr/bin/env bash
set -euET -o pipefail # BASAD
shopt -s inherit_errexit

# or stdout
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"
GIT_ROOT="${GIT_ROOT:-$(git rev-parse --show-toplevel)}"
pushd "$GIT_ROOT" >/dev/null || exit 1

OCI_PUBLISHED_CHARTS=(
	wiz-admission-controller
	wiz-broker
	wiz-common
	wiz-kubernetes-connector
	wiz-kubernetes-integration
	wiz-network-analyzer
	wiz-sensor
)

function is_oci_published() {
	local candidate="$1" chart
	for chart in "${OCI_PUBLISHED_CHARTS[@]}"; do
		[[ "$chart" == "$candidate" ]] && return 0
	done
	return 1
}

CHANGED_FILES="$(git diff --name-only HEAD^ HEAD)"
CHANGED_CHART_DIRS="$(echo "$CHANGED_FILES" | sed -nE 's#^([^./][^/]*)/.*#\1#p' | sort -u)"
echo "changes: ${CHANGED_CHART_DIRS}"
CHANGES_MATRIX=()
for change in $CHANGED_CHART_DIRS; do
	if [[ ! -f "$change/Chart.yaml" ]]; then
		echo "skipping $change: not a chart directory"
		continue
	fi
	if is_oci_published "$change"; then
		echo "skipping $change: published to the OCI registry, not to GHCR"
		continue
	fi
	CHANGES_MATRIX+=("$(
		jq -ncM '$ARGS.named' \
			--arg chart "$change" \
			--arg version "$(yq .version "$change/Chart.yaml")"
	)")
done
echo "CHANGES_MATRIX: ${CHANGES_MATRIX[*]-}"
MATRIX="[]"
if [[ -n "${CHANGES_MATRIX[*]-}" ]]; then
	# https://stackoverflow.com/questions/26808855/how-to-format-a-bash-array-as-a-json-array
	MATRIX="$(printf '%s\n' "${CHANGES_MATRIX[@]}" | sort -u | jq -sc .)"
fi
echo "charts_matrix=${MATRIX}" >>"$GITHUB_OUTPUT"
if [[ "$(jq -r 'length' <<<"$MATRIX")" -gt 0 ]]; then
	echo "any_changed=true" >>"$GITHUB_OUTPUT"
else
	echo "any_changed=false" >>"$GITHUB_OUTPUT"
fi
