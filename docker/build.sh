#!/bin/bash -ex

SWD=$(dirname $0)

image=$(yq 'select(.metadata.name == "rc-refresh")  | .spec.jobTemplate.spec.template.spec.containers[] | select(.name == "pull") |  .image' $SWD/../k8s/03-job-refresh.yaml)

docker build -t $image .

docker push $image

cached_image=$(k3s ctr images ls|awk '{ print $1 }'|grep "$image\$")
[ -z "$cached_image" ] || k3s ctr images rm $cached_image
