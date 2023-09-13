#!/bin/bash -ex

. $(dirname $0)/setenv.sh

for service in "${DPSRV_SERVICES[@]}"; do
	cd $DPSRV_HOME/$service
	docker compose down
	cd $OLDPWD
done
