#!/usr/bin/env bash
# End-to-end tests for the BIND package image.
#
# Builds the package image with the root docker-compose.yml (which also runs
# the Go tests for the Dappnode patch), starts it on an isolated network next
# to mock Dappnode services, and checks the Dappnode-specific behaviour:
#   - forwarding rules for .dappnode, .dappnode.private and .eth
#   - the patched .eth fallback (CNAME my.dappnode, forward_fallback_ttl)
#   - entrypoint cloaking rules from global envs and from the Dappmanager API
#
# Environment:
#   E2E_SKIP_BUILD=1     reuse the existing image instead of rebuilding it
#   E2E_SKIP_INTERNET=1  skip the check that needs public DNS resolvers
#   E2E_KEEP=1           leave the containers running after the tests
#   E2E_NET=a.b.c        first three octets of the test subnet (default 172.29.53)

set -euo pipefail

cd "$(dirname "$0")"

export E2E_NET="${E2E_NET:-172.29.53}"
BIND_ENVS="$E2E_NET.2"
BIND_API="$E2E_NET.3"
HTTPS_IP="$E2E_NET.21"
ENS_SITE_IP="$E2E_NET.22"
PACKAGE_IP="$E2E_NET.23"

ENVS_DOMAIN=e2e-envs.dyndns.dappnode.io
ENVS_INTERNAL_IP=192.168.77.10
API_DOMAIN=e2e-api.dyndns.dappnode.io
API_INTERNAL_IP=192.168.77.20

# Unique names keep the proxy cache from answering a check with a stale result.
RUN_ID="$(date +%s)$$"

passed=0
failed=0

pass() { passed=$((passed + 1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
fail() { failed=$((failed + 1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ -z "${2:-}" ] || printf '%s\n' "$2" | sed 's/^/       /'; }
section() { printf '\n%s\n' "$1"; }

compose() { docker compose "$@"; }

cleanup() {
    status=$?
    if [ "$status" -ne 0 ] || [ "$failed" -ne 0 ]; then
        section "Container logs"
        compose logs --no-color bind-envs bind-api dappmanager 2>/dev/null | tail -n 80 || true
    fi
    if [ -z "${E2E_KEEP:-}" ]; then
        compose down --volumes --remove-orphans >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# dig_answer SERVER NAME [TYPE] prints "TYPE TTL DATA" for each answer record.
dig_answer() {
    compose exec -T client dig +noall +answer +tries=1 +time=3 "@$1" "$2" "${3:-A}" |
        awk '{ print $4, $2, $5 }'
}

# dig_status SERVER NAME [TYPE] prints the response code, e.g. NOERROR.
dig_status() {
    compose exec -T client dig +tries=1 +time=3 "@$1" "$2" "${3:-A}" |
        sed -n 's/.*status: \([A-Z]*\),.*/\1/p'
}

# expect_answer DESCRIPTION EXPECTED SERVER NAME [TYPE] compares "TYPE DATA".
expect_answer() {
    local description=$1 expected=$2 actual
    shift 2
    actual=$(dig_answer "$@" | awk '{ print $1, $3 }' || true)
    if [ "$actual" = "$expected" ]; then
        pass "$description"
    else
        fail "$description" "expected: $expected"$'\n'"actual:   ${actual:-<no answer>}"
    fi
}

# logs_contain SERVICE TEXT checks the service logs for a fixed string. The logs
# are captured first: grep -q exiting early would fail the pipe under pipefail.
logs_contain() {
    local logs
    logs=$(compose logs --no-color "$1")
    grep -qF -- "$2" <<<"$logs"
}

# wait_for_answer SECONDS EXPECTED SERVER NAME [TYPE] polls until it matches.
wait_for_answer() {
    local deadline=$((SECONDS + $1)) expected=$2
    shift 2
    while [ "$SECONDS" -lt "$deadline" ]; do
        [ "$(dig_answer "$@" 2>/dev/null | awk '{ print $1, $3 }')" = "$expected" ] && return 0
        sleep 1
    done
    return 1
}

section "Building the package image"
cd ..
if [ -z "${E2E_SKIP_BUILD:-}" ]; then
    docker compose build
fi
BIND_IMAGE=$(docker compose config --images)
export BIND_IMAGE
cd e2e
echo "Using $BIND_IMAGE"

section "Starting the test network (Dappmanager stays down for now)"
compose down --volumes --remove-orphans >/dev/null 2>&1 || true
compose up --detach --build --wait client https ens-site package
compose up --detach bind-envs bind-api

if ! wait_for_answer 90 "A $PACKAGE_IP" "$BIND_ENVS" e2e-pkg.dappnode; then
    fail "bind-envs answers DNS queries within 90s"
    exit 1
fi

section "Forwarding rules (forwarding-rules.txt)"
expect_answer ".dappnode names go to Docker's embedded DNS" \
    "A $PACKAGE_IP" "$BIND_ENVS" e2e-pkg.dappnode
expect_answer ".dappnode.private names go to Docker's embedded DNS" \
    "A $PACKAGE_IP" "$BIND_ENVS" e2e-pkg.dappnode.private
expect_answer "known .eth names are answered by the local resolver" \
    "A $ENS_SITE_IP" "$BIND_ENVS" e2e-known.eth

section "Forwarding fallback (dappnode-forwarding.patch)"
unknown_eth="e2e-unknown-$RUN_ID.eth"
answer=$(dig_answer "$BIND_ENVS" "$unknown_eth" A || true)
if [ "$answer" = "CNAME 600 my.dappnode." ]; then
    pass "unknown .eth names fall back to a CNAME to my.dappnode with a 600s TTL"
else
    fail "unknown .eth names fall back to a CNAME to my.dappnode with a 600s TTL" \
        "expected: CNAME 600 my.dappnode."$'\n'"actual:   ${answer:-<no answer>}"
fi
status=$(dig_status "$BIND_ENVS" "e2e-unknown-sub.$unknown_eth" A || true)
answer=$(dig_answer "$BIND_ENVS" "e2e-unknown-sub.$unknown_eth" A | awk '{ print $1, $3 }' || true)
if [ "$status" = NOERROR ] && [ "$answer" = "CNAME my.dappnode." ]; then
    pass "the fallback also covers ENS subdomains"
else
    fail "the fallback also covers ENS subdomains" "status: ${status:-<none>}, answer: ${answer:-<none>}"
fi
answer=$(dig_answer "$BIND_ENVS" e2e-known.eth A || true)
if [ "$(echo "$answer" | wc -l | tr -d ' ')" = 1 ] && [[ "$answer" == "A "*" $ENS_SITE_IP" ]]; then
    pass "successful .eth answers are not mixed with the fallback"
else
    fail "successful .eth answers are not mixed with the fallback" "actual: $answer"
fi
status=$(dig_status "$BIND_ENVS" "e2e-unknown-$RUN_ID.dappnode" A || true)
answer=$(dig_answer "$BIND_ENVS" "e2e-unknown-$RUN_ID.dappnode" A || true)
if [ "$status" != NOERROR ] && [ -z "$answer" ]; then
    pass "rules without a fallback keep negative answers ($status)"
else
    fail "rules without a fallback keep negative answers" "status: ${status:-<none>}, answer: ${answer:-<none>}"
fi

section "Cloaking rules from global envs (entrypoint.sh)"
expect_answer "the Dappnode domain resolves to the internal IP" \
    "A $ENVS_INTERNAL_IP" "$BIND_ENVS" "$ENVS_DOMAIN"
expect_answer "pwa.<domain> resolves to the https package via https.dappnode.private" \
    "A $HTTPS_IP" "$BIND_ENVS" "pwa.$ENVS_DOMAIN"
expect_answer "other subdomains of the Dappnode domain resolve to the internal IP" \
    "A $ENVS_INTERNAL_IP" "$BIND_ENVS" "e2e-pkg.$ENVS_DOMAIN"
if logs_contain bind-envs "Using domain($ENVS_DOMAIN) and internal ip ($ENVS_INTERNAL_IP) from global envs."; then
    pass "the entrypoint reports the global envs it used"
else
    fail "the entrypoint reports the global envs it used"
fi

section "Cloaking rules from the Dappmanager API (entrypoint.sh)"
if wait_for_answer 30 "A $PACKAGE_IP" "$BIND_API" e2e-pkg.dappnode; then
    pass "DNS is served while the Dappmanager API is unreachable"
else
    fail "DNS is served while the Dappmanager API is unreachable"
fi
if logs_contain bind-api "[ERROR] Failed to fetch data. Retrying"; then
    pass "the entrypoint retries while the Dappmanager API is unreachable"
else
    fail "the entrypoint retries while the Dappmanager API is unreachable"
fi
answer=$(dig_answer "$BIND_API" "$API_DOMAIN" A | awk '{ print $1, $3 }' || true)
if [ "$answer" != "A $API_INTERNAL_IP" ]; then
    pass "the domain is not cloaked before the Dappmanager answers"
else
    fail "the domain is not cloaked before the Dappmanager answers"
fi

compose up --detach --wait dappmanager
# The entrypoint polls every 10 seconds, then restarts the proxy.
if wait_for_answer 45 "A $API_INTERNAL_IP" "$BIND_API" "$API_DOMAIN"; then
    pass "the domain from /global-envs resolves to the internal IP"
else
    fail "the domain from /global-envs resolves to the internal IP"
fi
expect_answer "pwa.<domain> from /global-envs resolves to the https package" \
    "A $HTTPS_IP" "$BIND_API" "pwa.$API_DOMAIN"
expect_answer "forwarding still works after the proxy restart" \
    "A $PACKAGE_IP" "$BIND_API" e2e-pkg.dappnode
answer=$(dig_answer "$BIND_API" "e2e-unknown-api-$RUN_ID.eth" A || true)
if [ "$answer" = "CNAME 600 my.dappnode." ]; then
    pass "the .eth fallback still works after the proxy restart"
else
    fail "the .eth fallback still works after the proxy restart" "actual: ${answer:-<no answer>}"
fi
if logs_contain dappmanager "url:/global-envs"; then
    pass "the entrypoint read /global-envs from dappmanager.dappnode"
else
    fail "the entrypoint read /global-envs from dappmanager.dappnode"
fi
answer=$(dig_answer "$BIND_ENVS" "$API_DOMAIN" A | awk '{ print $1, $3 }' || true)
if [ "$answer" != "A $API_INTERNAL_IP" ]; then
    pass "each instance only cloaks its own domain"
else
    fail "each instance only cloaks its own domain"
fi

section "Public DNS through the configured resolvers"
if [ -n "${E2E_SKIP_INTERNET:-}" ]; then
    echo "  SKIP E2E_SKIP_INTERNET is set"
else
    status=$(dig_status "$BIND_ENVS" example.com A || true)
    answer=$(dig_answer "$BIND_ENVS" example.com A || true)
    if [ "$status" = NOERROR ] && grep -q '^A ' <<<"$answer"; then
        pass "public names resolve through the encrypted upstream resolvers"
    else
        fail "public names resolve through the encrypted upstream resolvers" "status: ${status:-<none>}, answer: ${answer:-<none>}"
    fi
fi

section "Container health"
for service in bind-envs bind-api; do
    if logs_contain "$service" "[FATAL]"; then
        fail "$service logged no fatal errors" "$(compose logs --no-color "$service" | grep '\[FATAL\]')"
    else
        pass "$service logged no fatal errors"
    fi
done

printf '\n%d passed, %d failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
