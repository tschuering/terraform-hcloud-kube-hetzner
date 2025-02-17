---
apiVersion: v1
kind: Namespace
metadata:
  name: traefik
---
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: traefik
  namespace: kube-system
spec:
  chart: traefik
  repo: https://traefik.github.io/charts
  targetNamespace: ${target_namespace}
  bootstrap: true
  valuesContent: |-
    ${values}
