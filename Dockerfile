FROM alpine:3.18

RUN apk add openssl git bash \
	&& rm -rf /var/cache/apk/*

