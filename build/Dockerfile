FROM alpine

RUN apk --no-cache add dnscrypt-proxy 

COPY dnscrypt-proxy.toml .
COPY forwarding-rules.txt .

EXPOSE 53/udp

ENTRYPOINT [ "dnscrypt-proxy", "-config", "./dnscrypt-proxy.toml" ]