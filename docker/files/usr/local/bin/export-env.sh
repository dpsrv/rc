#!/bin/sh -x

export SECRET_ENV=$(cat <<_EOT_
    dpsrv dpsrv/secrets/redis/redis.env 
_EOT_
)

echo "$SECRET_ENV" | while read secret_env_rule; do
	read -r secret_env_ns secret_env_file secret_env_xform <<< "${secret_env_rule}"
	secret_env_path=$SECRET_ENV_DIR/$secret_env_file
	(
		env -i sh --noprofile --norc ". $secret_env_path"
	)
	exit

	secret_name=$secret_path
	[ -z "$secret_files_xform" ] || secret_name=$(echo $secret_name | sed $secret_files_xform)
	secret_name=$(echo $secret_name | sed 's#/#-#g' | tr A-Z a-z)
	exit
                kubectl -n $secret_files_ns create secret generic $secret_name --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
		exit 
done

