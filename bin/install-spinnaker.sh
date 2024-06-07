#!/bin/bash -ex

# Install Spinnaker from https://www.opsmx.com/blog/how-to-install-spinnaker-into-kubernetes-using-helm-charts/

ns=opsmx-oss

helm repo add spinnaker https://opsmx.github.io/spinnaker-helm/
helm repo update

kubectl create namespace $ns

helm install oss-spin spinnaker/spinnaker -n $ns --wait
kubectl -n $ns get pods

exit
kubectl -n $ns port-forward svc/spin-deck 9000

