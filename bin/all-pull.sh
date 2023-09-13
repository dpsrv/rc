#!/bin/bash -e

. $(dirname $0)/setenv.sh

ls -1d $DPSRV_HOME/*/.git | while read dir; do
	dir=${dir%.git}
	cd $dir
	echo "Pulling ${PWD##*/}"
	git pull
	cd $OLDPWD
done
