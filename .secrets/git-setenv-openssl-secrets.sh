export GIT_FILTER_OPENSSL_PREFIX=${GIT_FILTER_OPENSSL_PREFIX:-$HOME/.config/git/openssl-}
export GIT_FILTER_OPENSSL_PASSWORD=${GIT_FILTER_OPENSSL_PASSWORD:-$(cat ${GIT_FILTER_OPENSSL_PREFIX}password)}
export GIT_FILTER_OPENSSL_SALT=${GIT_FILTER_OPENSSL_SALT:-$(cat ${GIT_FILTER_OPENSSL_PREFIX}salt)}

