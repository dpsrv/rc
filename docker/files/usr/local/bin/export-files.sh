#!/bin/sh -x

EXPORT_FILES=$(cat <<_EOT_
    dpsrv/rc/secrets/letsencrypt/live/domain/=s#^dpsrv/rc/secrets/#dpsrv#g
    dpsrv/rc/secrets/mongo/conf/=s#^dpsrv/rc/secrets/#dpsrv#g
_EOT_
)

for secret_file_rule in $SECRET_FILES; do
	read -r secret_path secret_xform <<< "${secret_file_rule//=/ }"
        dir=$EXPORT_FILES_DIR

        find $dir ! -type d | while read file; do
                secret=${file#/mnt/data/dpsrv/rc/secrets/}
                secret=${secret//\//-}
                secret=$(echo $secret|tr A-Z a-z)
                kubectl -n $ns create secret generic $secret --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
        done
done

