#!/bin/bash -ex

# Install Spinnaker from https://www.opsmx.com/blog/how-to-install-spinnaker-into-kubernetes-using-helm-charts/

helm repo add spinnaker https://opsmx.github.io/spinnaker-helm/
helm repo update
kubectl create namespace opsmx-oss
helm install oss-spin spinnaker/spinnaker -n opsmx-oss --timeout 600s
kubectl -n oss-spin get pods

exit
kubectl -n opsmx-oss port-forward svc/spin-deck 9000

