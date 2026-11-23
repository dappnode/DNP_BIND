# Dappnode Bind Core Package

🌐 This package acts as the DNS proxy for the Dappnode Packages. It is required to access the services provided by the Dappnode Packages from the host machine connected to the Dappnode.

## Testing

`./e2e/run.sh` builds the package image and tests it end to end on an isolated Docker network with mock Dappnode services: the forwarding rules, the `.eth` fallback to `my.dappnode` from the Dappnode patch, and the cloaking rules that `entrypoint.sh` writes from the global envs or the Dappmanager API. It needs Docker with Compose and internet access; set `E2E_SKIP_INTERNET=1` to skip the public DNS check, `E2E_SKIP_BUILD=1` to reuse an existing image, or `E2E_KEEP=1` to leave the containers running.
