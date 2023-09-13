#!/bin/bash -e

. $(dirname $0)/setenv.sh

ls -1d $DPSRV_HOME/*/.git | while read dir; do
	dir=${dir%.git}
	cd $dir
	echo "Pushing ${PWD##*/}"
	git commit -a -m updated && git push || true
	cd $OLDPWD
done
