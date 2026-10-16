# Wiz Kubernetes Helm Charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.
Please refer to Helm's [documentation](https://helm.sh/docs/) to get started.

The charts are distributed as an [OCI Artifact](https://helm.sh/docs/topics/registries/) as well as via a traditional [Helm Repository](https://helm.sh/docs/topics/chart_repository/).

### Use charts via traditional Helm Repository

Once Helm is set up properly, add the repo as follows:

```console
helm repo add wiz-sec https://wiz-sec.github.io/charts
```

You can then run `helm search repo wiz-sec` to see the charts.

### Use charts directly from the OCI-based registry

As an alternative you can directly use the charts from ghcr.io, which is an OCI-based registry. Please ensure that you use at least Helm v3.8 (or newer).
You can directly install the Wiz Helm charts via the following command:

```console
helm install <release name> oci://ghcr.io/wiz-sec/charts/<chart name> --version <desired version>
```

## Helm charts build status

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/wiz-sec/charts/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/img/gh/wiz-sec/charts/tree/master.svg?style=shield)
