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
        exit 1
    fi
}

# my. domains
check_domain my.ipfs.dnp.dappnode.eth 172.30.0.5
# .dappnode domains
check_domain ipfs.dappnode 172.30.0.5
# other .eth domains
check_domain ipfs.dappnode.eth 172.30.0.7
check_domain ipfs.eth 172.30.0.7


