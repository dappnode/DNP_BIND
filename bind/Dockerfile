FROM golang:1.24.1-alpine3.21 AS builder

ARG UPSTREAM_VERSION

WORKDIR /app/dnscrypt-proxy

ENV SRC_DIR=/app/dnscrypt-proxy/dnscrypt-proxy

# Clone dnscrypt-proxy repo and checkout to the specified version
RUN apk add --no-cache git && \
    git clone https://github.com/DNSCrypt/dnscrypt-proxy /app/dnscrypt-proxy && \
    git checkout ${UPSTREAM_VERSION}

RUN cp -R go.mod go.sum vendor 

# Replace custom src files
COPY custom/src/common.go custom/src/config.go custom/src/proxy.go custom/src/plugin_forward.go ./dnscrypt-proxy/

RUN cd ${SRC_DIR} && \
    CGO_ENABLED=0 go build -mod vendor -ldflags="-s -w" -o /usr/local/bin/dnscrypt-proxy && \
    chmod +x /usr/local/bin/dnscrypt-proxy

FROM alpine:3.21

WORKDIR /app

RUN apk add --no-cache curl jq

COPY --from=builder /usr/local/bin/dnscrypt-proxy /app/dnscrypt-proxy

COPY custom/config/dnscrypt-proxy.toml custom/config/forwarding-rules.txt /app/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

CMD ["/usr/local/bin/entrypoint.sh"] 