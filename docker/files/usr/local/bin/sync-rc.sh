#!/bin/sh

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

