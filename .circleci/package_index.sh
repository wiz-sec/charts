#!/bin/bash

PACKAGE_VERSION=$(helm show chart ${PACKAGE} | grep version | cut -d " " -f 2)
PACKAGE_FULL_NAME="<< parameters.package >>-${PACKAGE_VERSION}.tgz"

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
git config user.email "circleci@wiz.io"
git config user.name "CircleCI"
git add .
git commit -a -m "CircleCI: Upload << parameters.package >> chart"
git push -u origin gh-pages
