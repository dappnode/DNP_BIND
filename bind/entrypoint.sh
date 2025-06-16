#!/bin/sh

# Start DNS server in background right away
/app/dnscrypt-proxy &

pid=$!

# Initialize domain and internal_ip variables
domain=""
internal_ip=""

# Fetch domain and internal_ip from Dappmanager API
fetch_envs() {
    local wait_time=10 # Wait time between retries

    while true; do
        response=$(curl -s http://dappmanager.dappnode/global-envs)

        if [ $? -eq 0 ]; then
            domain=$(echo $response | jq -r '.DOMAIN')
            internal_ip=$(echo $response | jq -r '.INTERNAL_IP')

            if [ -n "$domain" ] && [ -n "$internal_ip" ]; then
                break
            fi
        else
            echo "[ERROR] Failed to fetch data. Retrying in $wait_time seconds..."
        fi

        sleep $wait_time
    done
}

# Check if both domain and internal_ip are available as global environment variables
if [ -n "${_DAPPNODE_GLOBAL_DOMAIN}" ] && [ -n "${_DAPPNODE_GLOBAL_INTERNAL_IP}" ]; then
    domain=${_DAPPNODE_GLOBAL_DOMAIN}
    internal_ip=${_DAPPNODE_GLOBAL_INTERNAL_IP}

    echo "[INFO] Using domain($domain) and internal ip ($internal_ip) from global envs."
else
    echo "[INFO] Fetching domain and internal ip from Dappmanager API..."
    fetch_envs
fi

# Only write to cloaking-rules.txt if both domain and internal_ip are available
if [ -n "$domain" ] && [ -n "$internal_ip" ]; then
    echo "$domain $internal_ip" >cloaking-rules.txt
    echo "pwa.${domain} https.dappnode.private" >>cloaking-rules.txt # Add PWA domain to cloaking rules

    kill $pid
    wait $pid

    /app/dnscrypt-proxy
else
    touch cloaking-rules.txt
    echo "[ERROR] Missing domain or internal IP. Cloaking rules not updated. Dyndns domain will not be forwarded to internal IP."
fi
