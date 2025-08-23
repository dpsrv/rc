#!/bin/sh -x

SECRET_FILES=$(cat <<_EOT_
    dpsrv dpsrv/rc/secrets/letsencrypt/live/domain/ s#^dpsrv/rc/secrets##g
    dpsrv dpsrv/rc/secrets/mongo/conf/ s#^dpsrv/rc/secrets##g
_EOT_
)

echo "$SECRET_FILES" | while read secret_files_rule; do
	read -r secret_files_ns secret_files_path secret_files_xform <<< "${secret_files_rule}"
        find $SECRET_FILES_DIR/$secret_files_path ! -type d | while read file; do
		secret_path=$(echo $file | sed "s#$SECRET_FILES_DIR/*##g")
		secret_name=$(echo $secret_path| sed $secret_files_xform | sed 's#/#-#g' | tr A-Z a-z)
                kubectl -n $secret_files_ns create secret generic $secret_name --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
		exit 
        done
done

