#!/bin/sh

SWD=$(dirname $0)

$SWD/sync-rc.sh

ns=dpsrv

[ -e /etc/letsencrypt ] || ln -s /mnt/data/dpsrv/rc/secrets/letsencrypt /etc/letsencrypt

kubectl -n istio-system create secret tls domain-credential \
	--cert=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/fullchain.pem \
	--key=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/privkey.pem \
	--dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged

$SWD/export-files.sh
$SWD/export-env.sh

