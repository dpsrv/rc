#!/bin/sh

cd /mnt/data/dpsrv/rc
git config --global --add safe.directory /mnt/data/dpsrv/rc
git config --global commit.gpgsign false
git config --global user.email 'rc@dpsrv.me'
git config --global user.name 'rc'
git config --global credential.helper 'store --file ~/.git-credentials'

git fetch
fetched=$?
echo $fetched
git pull -q

GIT_CHANGES=$(git status --porcelain |awk '{ print $2 }'|grep -v '/$')
if [ -n "$GIT_CHANGES" ]; then
	git add $GIT_CHANGES
	git commit -a -m updated
	git push
fi

ns=dpsrv

[ -e /etc/letsencrypt ] || ln -s /mnt/data/dpsrv/rc/secrets/letsencrypt /etc/letsencrypt

for secrets in $EXPORT_SECRETS; do
	dir=/mnt/data/dpsrv/rc/secrets/$secrets
	find $dir ! -type d | while read file; do
		secret=${file#/mnt/data/dpsrv/rc/secrets/}
		secret=${secret//\//-}
		basename=$(basename $file)
		k8sValue=$(kubectl -n $ns get secret $secret -o json | jq -r ".data[\"$basename\"]" | base64 -d || true)
		if [ -z "$k8sValue" ]; then
			kubectl -n $ns create secret generic $secret --from-file=$file
		else 
			fileValue=$(cat $file)
			if [ "$k8sValue" != "$fileValue" ]; then
				kubectl -n $ns create secret generic $secret --from-file=$file \
					--dry-run=client -o yaml | kubectl replace -f -
			fi
		fi
	done
done

kubectl -n istio-system create secret tls domain-credential \
	--cert=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/fullchain.pem \
	--key=/mnt/data/dpsrv/rc/secrets/letsencrypt/live/domain/privkey.pem \
	--dry-run=client -o yaml | kubectl apply -f -

