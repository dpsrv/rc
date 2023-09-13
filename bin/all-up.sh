#!/bin/bash -ex

. $(dirname $0)/setenv.sh

for service in "${DPSRV_SERVICES[@]}"; do
	cd $DPSRV_HOME/$service
	echo "Bringing up ${PWD##*/}"
	docker compose up --build -d
	cd $OLDPWD
done
