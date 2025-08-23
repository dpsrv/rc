#!/bin/sh

SWD=$(dirname $0)

$SWD/sync-rc.sh
$SWD/export-files.sh
$SWD/export-env.sh

