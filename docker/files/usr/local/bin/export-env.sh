#!/bin/sh -x

export SECRET_ENV=$(cat <<_EOT_
    ezsso ezsso/rc/secrets/dating/.env
_EOT_
)

echo "$SECRET_ENV" | while read secret_env_rule; do
	read -r secret_env_ns secret_env_file secret_env_xform <<< "${secret_env_rule}"
	secret_path=$SECRET_ENV_DIR/$(echo $file | sed "s#$SECRET_FILES_DIR/*##g")
	secret_name=$(echo $secret_path| sed $secret_files_xform | sed 's#/#-#g' | tr A-Z a-z)
	exit
                kubectl -n $secret_files_ns create secret generic $secret_name --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
		exit 
done

