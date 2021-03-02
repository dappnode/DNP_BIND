#!/bin/ash

if [ ! -f "cloaking-rules.txt" ]; then
    INTERNAL_IP=""
    DOMAIN=""
    echo "Trying to fetch domain and internal IP..."
    for i in {1..30}; do
        if [ -z $INTERNAL_IP  ]; then
            INTERNAL_IP=$(curl -s http://my.dappnode/global-envs/INTERNAL_IP)
        fi

        if [ -z $DOMAIN ]; then
            DOMAIN=$(curl -s http://my.dappnode/global-envs/DOMAIN)
        fi
        
        if [ -z $INTERNAL_IP ] || [ -z $DOMAIN ]; then
            echo "Retrying in one second..."
            sleep 1
        else
            echo "Done, found $DOMAIN, $INTERNAL_IP"
            break
        fi
    done

    echo "$DOMAIN $INTERNAL_IP" > cloaking-rules.txt # Failure mode is creation of empty file, but DNS proxy will still start
fi

dnscrypt-proxy -config ./dnscrypt-proxy.toml