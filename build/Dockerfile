FROM alpine

RUN apk --no-cache add dnscrypt-proxy curl

COPY dnscrypt-proxy.toml forwarding-rules.txt entrypoint.sh ./

EXPOSE 53/udp

ENTRYPOINT [ "./entrypoint.sh" ]