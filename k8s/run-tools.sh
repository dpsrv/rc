#!/bin/bash -ex

kubectl -n dpsrv run -it --rm --restart=Never dpsrv-tools --overrides='{ "spec": { "serviceAccountName": "dpsrv-admin" } }' --image=maxfortun/private:alpine-tools-2 -- sh
