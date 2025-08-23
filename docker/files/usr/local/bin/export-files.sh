for secrets in $EXPORT_SECRETS; do
        dir=/mnt/data/dpsrv/rc/secrets/$secrets

        find $dir ! -type d | while read file; do
                secret=${file#/mnt/data/dpsrv/rc/secrets/}
                secret=${secret//\//-}
                secret=$(echo $secret|tr A-Z a-z)
                kubectl -n $ns create secret generic $secret --from-file=$file \
                        --dry-run=client -o yaml | kubectl apply -f - | grep -v unchanged
        done
done

