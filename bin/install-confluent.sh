#!/bin/bash -ex

export K8S_NS=confluent
kubectl create namespace $K8S_NS

helm repo add confluentinc https://packages.confluent.io/helm
helm repo update

helm upgrade --install confluent-orchestrator confluentinc/cfk-blueprint \
	--set orchestrator.enabled=true \
	--namespace $K8S_NS

helm upgrade --install confluent-operator confluentinc/cfk-blueprint \
	--set operator.enabled=true \
	--namespace $K8S_NS

helm upgrade --install confluent-agent confluentinc/cfk-blueprint \
	--set agent.mode=Local \
	--set agent.enabled=true \
	--namespace $K8S_NS

export K8S_ID=$(kubectl get namespace kube-system -oyaml | grep uid | awk '{ print $2 }')

cat <<_EOT_ | envsubst | kubectl apply -f -
apiVersion: core.cpc.platform.confluent.io/v1beta1
kind: KubernetesCluster
metadata:
  name: control-plane-k8s
  namespace: $K8S_NS
spec:
  k8sID: $K8S_ID
  description: "cpc-controlplane kubernetes cluster"
  k8sClusterDomain: cluster.local
---
apiVersion: core.cpc.platform.confluent.io/v1beta1
kind: CPCHealthCheck
metadata:
  name: control-plane-hc
  namespace: $K8S_NS
spec:
  k8sClusterRef:
    name: control-plane-k8s
    namespace: $K8S_NS
_EOT_


