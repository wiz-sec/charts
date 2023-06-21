#!/bin/bash

# Path to the Chart.yaml file
CHART_FILE="${PACKAGE}/Chart.yaml"

# Read the current version from Chart.yaml
CURRENT_VERSION=$(grep -oP 'version: \K(.*)' $CHART_FILE)

# Extract major, minor, and patch versions
MAJOR_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f1)
MINOR_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f2)
PATCH_VERSION=$(echo $CURRENT_VERSION | cut -d'.' -f3)

# Increment the patch version by one
NEW_PATCH_VERSION=$((PATCH_VERSION + 1))

# Construct the new version string
NEW_VERSION="${MAJOR_VERSION}.${MINOR_VERSION}.${NEW_PATCH_VERSION}"

# Replace the version in Chart.yaml
sed -i "s/version: ${CURRENT_VERSION}/version: ${NEW_VERSION}/" $CHART_FILE

echo "Chart version updated from ${CURRENT_VERSION} to ${NEW_VERSION}"
