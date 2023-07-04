#!/bin/bash
set -e

git config user.email "circleci@wiz.io"
git config user.name "CircleCI"

# Reset all changes from another jobs
git checkout master
git reset --hard origin/master

# Path to the Chart.yaml file
CHART_FILE="Chart.yaml"

# Read the current version from Chart.yaml
CURRENT_VERSION=$(helm show chart . | grep version | cut -d " " -f 2 | tr -d '[:space:]')

# Extract major, minor, and patch versions
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f1)
MINOR_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f2)
PATCH_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f3 | cut -d'-' -f1)
if [[ $CURRENT_VERSION == *-* ]]; then
    SUFFIX_VERSION="-$(echo $CURRENT_VERSION | cut -d'.' -f3 | cut -d'-' -f2)"
else
    SUFFIX_VERSION=""
fi

# Increment the patch version by one
NEW_PATCH_VERSION=$((PATCH_VERSION + 1))

# Construct the new version string
NEW_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${NEW_PATCH_VERSION}${SUFFIX_VERSION}"

# Replace the version in Chart.yaml
awk '{gsub("version: '${CURRENT_VERSION}'", "version: '${NEW_VERSION}'"); print}' $CHART_FILE > tmp && mv tmp $CHART_FILE
echo "Chart version updated from ${CURRENT_VERSION} to ${NEW_VERSION}"

git add $CHART_FILE
git commit -m "CircleCI: Update $(basename "$PWD") chart patch version from ${CURRENT_VERSION} to ${NEW_VERSION}"
git push
