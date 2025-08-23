#!/bin/sh

SWD=$(dirname $0)

$SWD/sync-git.sh
$SWD/export-files.sh
$SWD/export-env.sh

