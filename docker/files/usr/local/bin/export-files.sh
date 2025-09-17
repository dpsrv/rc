#!/bin/sh -e

[ -n "$SECRET_FILES" ] || exit 0

echo "$SECRET_FILES" | while read secret_files_rule; do
	[ -n "$secret_files_rule" ] || continue

	secret_files_rule_file=/tmp/$(basename $0).secret_files_rule.$$
	echo "$secret_files_rule" > $secret_files_rule_file
	read -r secret_files_ns secret_files_path secret_files_xform < $secret_files_rule_file
	rm $secret_files_rule_file

	(
		if [ -d $SECRET_FILES_DIR/$secret_files_path ]; then
			find $SECRET_FILES_DIR/$secret_files_path ! -type d
		else
			echo $SECRET_FILES_DIR/$secret_files_path
		fi
	) | while read file; do
		[ -e "$file" ] || continue
		if [[ "$file" =~ '\.envsubst$' ]]; then
			rendered=${file%.envsubst}
			cat $file | envsubst > $rendered
			file=$rendered
		fi
		secret_path=$(echo $file | sed "s#$SECRET_FILES_DIR/*##g")
		secret_name=$(echo $secret_path| sed $secret_files_xform | sed 's#[^-a-zA-Z0-9][^a-zA-Z0-9]*#-#g' | tr A-Z a-z)
		kubectl -n $secret_files_ns create secret generic $secret_name --from-file=$file \
			--dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged || true
	done
done

