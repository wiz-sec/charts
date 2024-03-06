# Don't delete this folder

The [upstream flux chart](https://github.com/fluxcd-community/helm-charts/tree/main/charts/flux2) doesn't use a crd folder to install the CRDs, but instead installs them through regular template files.
However, this chart also puts two custom resources, a GitRepository and a Kustomization. As such, these two CRDs should reside
here instead of the regular template file, as it promises that they will be installed before the custom resources.

for more information see [this document](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/)
