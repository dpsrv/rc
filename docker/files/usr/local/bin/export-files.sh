#!/bin/sh -x

SECRET_FILES=$(cat <<_EOT_
    dpsrv dpsrv/rc/secrets/letsencrypt/live/domain/ s#^dpsrv/rc/secrets/#dpsrv/#g
    dpsrv dpsrv/rc/secrets/mongo/conf/ s#^dpsrv/rc/secrets/#dpsrv/#g
_EOT_
)

echo $SECRET_FILES | while read secret_files_rule; do
	echo $secret_files_rule
	read -r secret_files_ns secret_files_path secret_files_xform <<< "${secret_files_rule}"
	echo "1: $secret_files_ns 2:$secret_files_path 3:$secret_files_xform"
	continue
        find $SECRET_FILES_DIR/$secret_files_path ! -type d | while read file; do
		secret_path=$(echo $file | sed "s#$SECRET_FILES_DIR/*##g")
		secret_name=$(echo $secret_path| sed $secret_files_xform | sed 's#/#-#g' | tr A-Z a-z)
                kubectl -n $secret_files_ns create secret generic $secret --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
        done
done

