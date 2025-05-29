#!/usr/bin/env bash
set -euET -o pipefail # BASAD
shopt -s inherit_errexit

# or stdout
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/null}"
GIT_ROOT="${GIT_ROOT:-$(git rev-parse --show-toplevel)}"
pushd "$GIT_ROOT" >/dev/null || exit 1

CHANGED_FILES="$(git diff --name-only HEAD^ HEAD)"
CHANGED_CHART_DIRS="$(echo "$CHANGED_FILES" | grep -Eo '^[^.][^/]+' | sort -u)"
echo "changes: ${CHANGED_CHART_DIRS}"
CHANGES_MATRIX=()
for change in $CHANGED_CHART_DIRS; do
	CHANGES_MATRIX+=("$(
		jq -ncM '$ARGS.named' \
			--arg chart "$change" \
			--arg version "$(yq .version "$change/Chart.yaml")"
	)")
done
echo "CHANGES_MATRIX: ${CHANGES_MATRIX[*]}"
if [[ -n "${CHANGES_MATRIX[*]}" ]]; then
	# https://stackoverflow.com/questions/26808855/how-to-format-a-bash-array-as-a-json-array
	MATRIX="$(printf '%s\n' "${CHANGES_MATRIX[@]}" | sort -u | jq -sc .)"
	echo "charts_matrix=${MATRIX}" >>"$GITHUB_OUTPUT"
fi
if [[ -n "${MATRIX}" ]]; then
	echo "any_changed=true" >>"$GITHUB_OUTPUT"
else
	echo "any_changed=false" >>"$GITHUB_OUTPUT"
fi
