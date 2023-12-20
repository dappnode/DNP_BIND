#!/bin/sh

# Function to fetch environment variables
fetch_env() {
    local env_var_name=$1
    local env_var_value=""
    local retries=30  # Number of retries
    local wait_time=1 # Wait time between retries

    for i in $(seq 1 $retries); do
        echo "Fetching $env_var_name (attempt $i)"
        env_var_value=$(curl -s "my.dappnode/global-envs/$env_var_name")

        if [ -n "$env_var_value" ]; then
            echo "$env_var_value"
            return 0
        fi

        sleep $wait_time
    done

    echo "Error: Failed to fetch $env_var_name after $retries attempts."
    return 1
}

# Start DNS server in background right away
/app/dnscrypt-proxy &

pid=$!

# Fetch required environment variables

if [ -n "${_DAPPNODE_GLOBAL_DOMAIN}" ]; then
    domain=${_DAPPNODE_GLOBAL_DOMAIN}
    echo "Using existing domain: $domain"
else
    fetched_domain=$(fetch_env "DOMAIN")

    if [ $? -eq 0 ]; then
        domain=$fetched_domain
    else
        echo "Failed to fetch DOMAIN"
        kill $pid
        exit 1
    fi
fi

if [ -n "${_DAPPNODE_GLOBAL_INTERNAL_IP}" ]; then
    internal_ip=${_DAPPNODE_GLOBAL_INTERNAL_IP}
    echo "Using existing domain: $domain"
else
    fetched_internal_ip=$(fetch_env "INTERNAL_IP")

    if [ $? -eq 0 ]; then
        internal_ip=$fetched_internal_ip
    else
        echo "Failed to fetch INTERNAL_IP"
        kill $pid
        exit 1
    fi
fi

echo "$domain $internal_ip" >cloaking-rules.txt

kill $pid
wait $pid

/app/dnscrypt-proxy
