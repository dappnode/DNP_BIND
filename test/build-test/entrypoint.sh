#!/bin/sh

check_domain()
{
    DOMAIN=$1
    EXPECTED_IP=$2
    IP=$(dig "$DOMAIN" +short)
    if [ "$IP" = "$EXPECTED_IP" ]; then
        echo "resolved $DOMAIN to: $IP"
    else
        echo "Error $DOMAIN resolves to: $IP"
#        exit 1
    fi
}

echo "nameserver 172.33.1.2" > /etc/resolv.conf
cat /etc/resolv.conf
echo "ADDRESS:"$(dig @172.33.1.2 ethchain.dnp.dappnode.eth +short)
ping www.google.es -c 1
#ping dotbitkittypix.bit -c 1
check_domain my.ethchain.dnp.dappnode.eth 172.33.1.6
check_domain ethchain.dappnode.eth 172.33.1.3
check_domain ethchain.eth 172.33.1.3
check_domain ethchain.dnp.dappnode.eth 172.33.1.3
check_domain dappnode.io 104.198.14.52
check_domain dotbitkittypix.bit 192.185.225.13

