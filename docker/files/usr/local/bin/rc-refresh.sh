#!/bin/sh

SWD=$(dirname $0)

cd /mnt/data/dpsrv/rc
git config --global --add safe.directory /mnt/data/dpsrv/rc
git config --global commit.gpgsign false
git config --global user.email 'rc@dpsrv.me'
git config --global user.name 'rc'
git config --global credential.helper 'store --file ~/.git-credentials'

git fetch
fetched=$?
git pull -q

GIT_CHANGES=$(git status --porcelain |awk '{ print $2 }'|grep -v '/$')
if [ -n "$GIT_CHANGES" ]; then
	git add $GIT_CHANGES
	git commit -a -m updated
	git push
fi

ns=dpsrv

[ -e /etc/letsencrypt ] || ln -s /mnt/data/dpsrv/rc/secrets/letsencrypt /etc/letsencrypt

kubectl -n istio-system create secret tls domain-credential \
	--cert=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/fullchain.pem \
	--key=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/privkey.pem \
	--dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged

$SWD/export-files.sh
$SWD/export-env.sh

