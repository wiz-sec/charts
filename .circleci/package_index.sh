#!/bin/bash
set -e

PACKAGE_VERSION=$(helm show chart ${PACKAGE} | grep version | cut -d " " -f 2 | tr -d '[:space:]')
PACKAGE_FULL_NAME="${PACKAGE}-${PACKAGE_VERSION}.tgz"
git config user.email "circleci@wiz.io"
git config user.name "CircleCI"

ATTEMPTS=20
SLEEP_INTERVAL=30

for i in $(seq 1 $ATTEMPTS); do
    set +e
    # Try updating package dependencies
    output=$(helm dependency update $PACKAGE 2>&1)
    exit_code=$?
    set -e

    if echo "$output" | grep -q "can't get a valid version"; then
        echo "Attempt $i/$ATTEMPTS: Dependency not available yet. Retrying in $SLEEP_INTERVAL seconds..."
        sleep $SLEEP_INTERVAL
    elif [ $exit_code -eq 0 ]; then
        echo "Dependency update succeeded."
        break
    else
        echo "Error: $output"
        exit 1
    fi
done

if [ $i -eq $ATTEMPTS ]; then
    echo "Failed to update dependencies after $ATTEMPTS attempts with the following error:"
    echo "$output"
    exit 1
fi

# Package the chart with diffs
helm package $PACKAGE

# Commiting the change to master branch locally (will not push)
git add .
git commit -m "package"

# Checking out to gh-pages and taking the packages
git checkout gh-pages
git checkout master $PACKAGE_FULL_NAME

# Indexing and pushing
helm repo index --url https://wiz-sec.github.io/charts/ .
git add .
git commit -a -m "CircleCI: Upload ${PACKAGE} chart"
git push -u origin gh-pages

git checkout master
