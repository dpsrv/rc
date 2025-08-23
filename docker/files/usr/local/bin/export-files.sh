#!/bin/sh -x

EXPORT_FILES=$(cat <<_EOT_
    dpsrv/rc/secrets/letsencrypt/live/domain/=s#^dpsrv/rc/secrets/#dpsrv#g
    dpsrv/rc/secrets/mongo/conf/=s#^dpsrv/rc/secrets/#dpsrv#g
_EOT_
)

for export_file in $EXPORT_FILES; do
	read -r file xform <<< "${export_file//=/ }"
	echo "$file $xform"
	#EXPORT_FILES_DIR
	continue
        dir=/mnt/data/dpsrv/rc/secrets/$secrets

        find $dir ! -type d | while read file; do
                secret=${file#/mnt/data/dpsrv/rc/secrets/}
                secret=${secret//\//-}
                secret=$(echo $secret|tr A-Z a-z)
                kubectl -n $ns create secret generic $secret --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
        done
done

