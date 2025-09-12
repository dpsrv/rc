#!/bin/bash -ex

image=$1
if ! docker image inspect $image > /dev/null; then
	echo "$image not found"
	exit 1
fi

tar=/tmp/$(basename $0)/$image
tarDir=$(dirname $tar)

[ -d $tarDir ] || mkdir -p $tarDir

docker save $image -o $tar

k3s ctr images import $tar

rm $tar
