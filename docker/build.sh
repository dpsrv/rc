#!/bin/bash -e

SWD=$(dirname $0)

image=$(yq 'select(.metadata.name == "rc-refresh")  | .spec.jobTemplate.spec.template.spec.containers[] | select(.name == "pull") |  .image' $SWD/../k8s/03-job-refresh.yaml)

docker build -t $image .

docker push $image

while read -u 3 node_id; do 
	ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n root@$node_id.$DPSRV_DOMAIN "k3s ctr images ls|awk '{ print \$1 }'|grep '$image\$' | xargs -L1 k3s ctr images rm " &
done 3< <(kubectl get nodes -o json|jq -r '.items[].metadata.name')
wait
