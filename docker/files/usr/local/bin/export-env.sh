#!/bin/sh -ex

[ -n "$SECRET_ENV" ] || exit 0

echo "$SECRET_ENV" | while read secret_env_rule; do

	secret_env_rule_file=/tmp/$(basename $0).$$.secret_env_rule
	echo "$secret_env_rule" > $secret_env_rule_file
	read -r secret_env_ns secret_env_file secret_env_xform < $secret_env_rule_file
	rm $secret_env_rule_file

	secret_env_path=$SECRET_ENV_DIR/$secret_env_file
	cat $secret_env_path | while read secret_env; do
		[ -n "$secret_env" ] || continue
		secret_env_file=/tmp/$(basename $0).$$.secret_env
		echo "${secret_env/=/ }" > $secret_env_file
		read -r secret_name secret_value < $secret_env_file
		rm $secret_env_file
		[ -n "$secret_value" ] || continue
		secret_value=$(eval echo "$secret_value")

		[ -z "$secret_env_xform" ] || secret_name=$(echo $secret_name | sed $secret_env_xform)
		secret_name=$(echo $secret_name | tr A-Z_ a-z-)

		kubectl -n $secret_env_ns create secret generic $secret_name "--from-literal=$secret_name=$secret_value" \
			--dry-run=client -o yaml | envsubst | kubectl apply -f - | grep -v unchanged
	done
done

