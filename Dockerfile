FROM alpine:3.18

RUN apk add --no-cache openssl git bash curl bash ca-certificates \
  && curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
  && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
  && rm kubectl
	&& rm -rf /var/cache/apk/*

