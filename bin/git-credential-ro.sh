#!/bin/sh
ACTION=$1

if [ -z "$ACTION" ]; then
	echo "Usage: $0 <action>"
	echo " e.g.: $0 get"
	exit 1
fi

if [ "$ACTION" != "get" ]; then
	echo "$ACTION not supported."
	exit 1
fi

FILE=$HOME/.git-credentials
REGEX='^([^:]+)://([^:]+):([^@]+)@?([A-Za-z0-9.-]+(:[0-9]+)?)(/[^ ]*)?'

cat $FILE|while read line; do
	if [[ "$line" =~ $REGEX ]]; then
		echo "${BASH_REMATCH[1]}"
		echo "${BASH_REMATCH[4]}"
		echo "${BASH_REMATCH[2]}"
		echo "${BASH_REMATCH[3]}"
		echo
	fi
done

