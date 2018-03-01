FROM alpine

RUN apk update && \
    apk --no-cache add bind && \
    mkdir -p /var/bind/log && \
    rm -rf /var/cache/apk/*

COPY named.conf /etc/bind/named.conf
COPY eth.hosts /etc/bind/eth.hosts

EXPOSE 53/udp

CMD /usr/sbin/named -f -c /etc/bind/named.conf