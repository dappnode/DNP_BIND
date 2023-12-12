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
    exit 1
}

# Start DNS server in background right away
/app/dnscrypt-proxy &

pid=$!

# Fetch required environment variables

if [ -n "${_DAPPNODE_GLOBAL_DOMAIN}" ]; then
    domain=${_DAPPNODE_GLOBAL_DOMAIN}
    echo "Using existing domain: $domain"
else
    domain=$(fetch_env "DOMAIN")
fi

if [ -n "${_DAPPNODE_GLOBAL_INTERNAL_IP}" ]; then
    internal_ip=${_DAPPNODE_GLOBAL_INTERNAL_IP}
    echo "Using existing domain: $domain"
else
    internal_ip=$(fetch_env "INTERNAL_IP")
fi

echo "$domain $internal_ip" >cloaking-rules.txt

kill $pid
wait $pid

/app/dnscrypt-proxy
