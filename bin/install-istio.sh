#!/bin/bash -ex

# From https://istio.io/latest/docs/setup/install/helm/

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
kubectl create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=default

exit 

wait till deployed

helm ls -n istio-system

helm install istiod istio/istiod -n istio-system --wait

helm ls -n istio-system

kubectl create namespace istio-ingress
helm install istio-ingress istio/gateway -n istio-ingress --wait



