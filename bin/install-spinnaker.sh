#!/bin/bash -ex

# Install Spinnaker from https://www.opsmx.com/blog/how-to-install-spinnaker-into-kubernetes-using-helm-charts/

ns=opsmx-oss

helm repo add spinnaker https://opsmx.github.io/spinnaker-helm/
helm repo update

kubectl create namespace $ns

helm install oss-spin spinnaker/spinnaker -n $ns --timeout 30m --wait
while ! kubectl -n $ns get pods | tail -n +2 | awk '{ print $3 }' | egrep -v '(Running|Completed)'; do
	echo "Waiting for $ns to come up"
	sleep 5
done

kubectl -n $ns port-forward svc/spin-deck 9000

