#!/bin/bash -ex

# From https://istio.io/latest/docs/setup/install/helm/

kubectl get crd gateways.gateway.networking.k8s.io &> /dev/null || \
  { kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.1.0" | kubectl apply -f -; }

ns=istio-system

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace $ns

function waitForHelmDeployed() {
	local ns=$1
	local release=$2

	while ! helm -n $ns status $release -o json | jq -r .info.status | grep -q deployed; do
        echo "Waiting for $ns $release to come up"
        sleep 5
	done
	helm -n $ns ls
}

helm -n $ns install istio-base istio/base --set defaultRevision=default --wait
waitForHelmDeployed $ns istio-base

helm -n $ns install istiod istio/istiod --wait
waitForHelmDeployed $ns istiod

helm -n $ns install istio-ingress istio/gateway --wait
waitForHelmDeployed $ns istio-ingress



