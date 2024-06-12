#!/bin/bash -ex

# From https://docs.redpanda.com/current/deploy/deployment-option/self-hosted/kubernetes/local-guide/

helm repo add jetstack https://charts.jetstack.io
helm repo update

helm install cert-manager jetstack/cert-manager  --set installCRDs=true --namespace cert-manager  --create-namespace


helm repo add redpanda https://charts.redpanda.com
helm repo update

ns=redpanda-system
helm install redpanda redpanda/redpanda \
  --version 5.8.8 \
  --namespace $ns \
  --create-namespace \
  --set external.domain=customredpandadomain.local \
  --set statefulset.initContainers.setDataDirOwnership.enabled=true

exit 0

kubectl --namespace $ns rollout status statefulset redpanda --watch
