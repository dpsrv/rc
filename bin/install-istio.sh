#!/bin/bash -ex

# From https://istio.io/latest/docs/setup/install/helm/

ns=istio-system

helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update

kubectl create namespace $ns

function waitForHelmDeployed() {
	local ns=$1
	local release=$2

	while ! helm status -n $ns $release -o json | jq -r .info.status | grep -q deployed; do
        echo "Waiting for $ns $release to come up"
        sleep 5
	done
	helm ls -n $ns
}

helm -n $ns install istio-base istio/base --set defaultRevision=default --wait
waitForHelmDeployed $ns istio-base

helm -ns $ns install istiod istio/istiod --wait
waitForHelmDeployed $ns istiod

ingressNS=istio-ingress
kubectl create namespace $ingressNS

helm install istio-ingress istio/gateway -n $ingressNS --wait
waitForHelmDeployed $ingressNS istio-ingress



