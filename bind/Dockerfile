FROM golang:1.27.3-alpine3.24 AS builder

ARG UPSTREAM_VERSION

WORKDIR /app/dnscrypt-proxy

ENV SRC_DIR=/app/dnscrypt-proxy/dnscrypt-proxy

# Refresh packages and the certificate bundle before fetching source.
RUN apk upgrade --no-cache && \
    apk add --no-cache git 'ca-certificates>=20261020-r0' && \
    git clone --depth 1 --branch "${UPSTREAM_VERSION}" \
        https://github.com/DNSCrypt/dnscrypt-proxy /app/dnscrypt-proxy

# Apply only the Dappnode changes, retaining upstream fixes in all other code.
COPY custom/patches/dappnode-forwarding.patch /tmp/dappnode-forwarding.patch
RUN git apply --check /tmp/dappnode-forwarding.patch && \
    git apply /tmp/dappnode-forwarding.patch

COPY custom/src/*_test.go ./dnscrypt-proxy/

# Upstream tests exercise unreadable files, so run them without root privileges.
USER nobody
RUN GOCACHE=/tmp/go-build go test -mod=vendor ./dnscrypt-proxy
USER root

RUN cd ${SRC_DIR} && \
    CGO_ENABLED=0 go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/dnscrypt-proxy && \
    chmod +x /usr/local/bin/dnscrypt-proxy

FROM alpine:3.24

WORKDIR /app

# Go uses this trust store for DNS-over-HTTPS and resolver-list downloads.
RUN apk upgrade --no-cache && \
    apk add --no-cache 'ca-certificates>=20261020-r0' curl jq

COPY --from=builder /usr/local/bin/dnscrypt-proxy /app/dnscrypt-proxy

COPY custom/config/dnscrypt-proxy.toml custom/config/forwarding-rules.txt /app/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"]
