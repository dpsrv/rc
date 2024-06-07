#!/bin/bash -ex

# From https://istio.io/latest/docs/setup/install/helm/

ns=istio-system

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace $ns

helm install istio-base istio/base -n $ns --set defaultRevision=default --wait
while ! helm status istio-base -n $ns -o json | jq -r .info.status | grep -q deployed; do
        echo "Waiting for $ns to come up"
        sleep 5
done

helm ls -n $ns

helm install istiod istio/istiod -n $ns --wait

helm ls -n $ns

ingressNS=istio-ingress

kubectl create namespace $ingressNS
helm install istio-ingress istio/gateway -n $ingressNS --wait



