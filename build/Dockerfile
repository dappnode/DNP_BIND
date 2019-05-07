FROM alpine

RUN apk --no-cache add bind dnscrypt-proxy supervisor && \
    mkdir -p /var/bind/log

COPY bind /etc/bind/
COPY bind /config/
COPY entrypoint.sh /usr/bin/


COPY supervisord.conf .
COPY dnscrypt-proxy.toml .

EXPOSE 53/udp

ENTRYPOINT [ "entrypoint.sh" ]