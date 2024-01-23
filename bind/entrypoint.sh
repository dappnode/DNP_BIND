#!/bin/sh

# Function to fetch environment variables
fetch_env() {
    local env_var_name=$1
    local env_var_value=""
    local wait_time=10 # Wait time between retries

    while true; do
        echo "Fetching $env_var_name"
        env_var_value=$(curl -s "my.dappnode/global-envs/$env_var_name")

        if [ -n "$env_var_value" ]; then
            echo "$env_var_value"
            return 0
        fi

        sleep $wait_time
    done
}

# Start DNS server in background right away
/app/dnscrypt-proxy &

# Initialize domain and internal_ip variables
domain=""
internal_ip=""

pid=$!

# Fetch required environment variables

if [ -n "${_DAPPNODE_GLOBAL_DOMAIN}" ]; then
    domain=${_DAPPNODE_GLOBAL_DOMAIN}
    echo "Using existing domain: $domain"
else
    fetched_domain=$(fetch_env "DOMAIN" | tail -n 1)
    domain=$fetched_domain
fi

if [ -n "${_DAPPNODE_GLOBAL_INTERNAL_IP}" ]; then
    internal_ip=${_DAPPNODE_GLOBAL_INTERNAL_IP}
    echo "Using existing internal IP: $internal_ip"
else
    fetched_internal_ip=$(fetch_env "INTERNAL_IP" | tail -n 1)
    internal_ip=$fetched_internal_ip
fi

# Only write to cloaking-rules.txt if both domain and internal_ip are available
if [ -n "$domain" ] && [ -n "$internal_ip" ]; then
    echo "$domain $internal_ip" >cloaking-rules.txt

    kill $pid
    wait $pid

    /app/dnscrypt-proxy
else
    echo "[ERROR] Missing domain or internal IP. Cloaking rules not updated. Dyndns domain will not be forwarded to internal IP."
fi
