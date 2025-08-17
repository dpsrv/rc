#!/bin/bash -ex

kubectl run -it --rm --restart=Never dpsrv-tools --serviceaccount=dpsrv-admin --image=maxfortun/private:alpine-tools-2 -- sh
