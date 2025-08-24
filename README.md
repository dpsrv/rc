# rc
> Encrypted secrets require [GIT OpenSSL secrets](https://github.com/maxfortun/git-openssl-secrets).

# Run on apply
```
kubectl create job --from=cronjob/rc-refresh run-once
```
