#!/bin/bash -ex

ns=kafka
helm install kafka -n $ns --create-namespace oci://registry-1.docker.io/bitnamicharts/kafka
