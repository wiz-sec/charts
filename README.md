# Wiz Kubernetes Helm Charts



## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

### OCI registry (recommended)

Charts are published as OCI artifacts to `oci://public-registry.wiz.io/charts`.
No `helm repo add` is needed - reference the chart directly:

```console
# Inspect. With no version, Helm resolves the highest semver tag automatically.
helm show chart oci://public-registry.wiz.io/charts/wiz-kubernetes-connector

# Download, e.g. wiz-kubernetes-connector-4.0.7.tgz
helm pull oci://public-registry.wiz.io/charts/wiz-kubernetes-connector --destination .

# Install
helm install wiz-kubernetes-connector oci://public-registry.wiz.io/charts/wiz-kubernetes-connector
```

### Verifying chart signatures

Charts in the OCI registry are signed with [cosign](https://github.com/sigstore/cosign):

```console
curl -sO https://downloads.wiz.io/charts/wiz-charts-cosign.pub
cosign verify --key wiz-charts-cosign.pub public-registry.wiz.io/charts/wiz-kubernetes-connector:4.0.7
```

`cosign` does not resolve "latest semver" - a bare reference means the literal `:latest`
tag, which the charts do not publish. Use the version from Helm's `Pulled: ...:<version>`
output, or list the available tags:

```console
crane ls public-registry.wiz.io/charts/wiz-kubernetes-connector
```

### Helm repository

The charts are also served from a traditional Helm repository. Once Helm is set up
properly, add the repo as follows:

```console
helm repo add wiz-sec https://wiz-sec.github.io/charts
```

You can then run `helm search repo wiz-sec` to see the charts.

## Helm charts build status

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/wiz-sec/charts/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/img/gh/wiz-sec/charts/tree/master.svg?style=shield)
