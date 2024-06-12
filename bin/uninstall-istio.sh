#!/bin/bash -ex

ns=istio-system
helm uninstall -n $ns istio-ingressgateway
helm uninstall -n $ns istiod
helm uninstall -n $ns istio-base
kubectl delete namespace $ns

