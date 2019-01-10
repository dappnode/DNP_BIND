FROM alpine

RUN apk --no-cache add bind dnscrypt-proxy supervisor && \
    mkdir -p /var/bind/log

COPY bind /etc/bind/

COPY supervisord.conf .
COPY dnscrypt-proxy.toml .

EXPOSE 53/udp

CMD supervisord