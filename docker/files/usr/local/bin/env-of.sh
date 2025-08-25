#!/bin/sh -x

if [ -z "$file" ]; then
	echo "Usage: $0 <env file>"
	echo " e.g.: $0 .env.local"
	exit 1
fi

before=$(mktemp)
after=$(mktemp)

declare -p > $before
source $file
declare -p > $after

diff $before $after

rm $before $after

