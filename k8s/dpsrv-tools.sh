#!/bin/bash -ex

kubectl -n dpsrv \
	run dpsrv-tools \
	--image=maxfortun/private:alpine-tools-2 \
	-it --rm --restart=Never \
	--overrides='{
		"spec": { "serviceAccountName": "dpsrv-admin" }
	}' \
	-- sh
