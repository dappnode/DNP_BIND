# Dappnode Bind Core Package

🌐 This package acts as the DNS proxy for the Dappnode Packages. When connected to DAppNode, all DNS requests from your device are first sent to this package. It resolves DAppNode-specific domains locally and forwards all other DNS queries to the configured upstream DNSCrypt resolvers, ensuring secure and private name resolution for both DAppNode services and general internet browsing.

## Environment Variables

### PUBLIC_RESOLVERS_OVERRIDE

The `PUBLIC_RESOLVERS_OVERRIDE` environment variable allows you to customize the DNSCrypt resolvers used by the package. By default, the package uses a curated list of reliable public resolvers:
- scaleway-fr
- commons-host
- dnscrypt.me
- cloudflare

You can override these defaults by providing a comma-separated list of resolver names. For example:
```
PUBLIC_RESOLVERS_OVERRIDE=quad9,adguard-dns,google
```

#### DNSCrypt Features

The DNS proxy in this package uses DNSCrypt-proxy with the following security features enabled:

- **DNSCrypt and DNS-over-HTTPS (DoH)**: Supports both DNSCrypt and DoH protocols for encrypted DNS queries
- **No-logging Policy**: Only uses resolvers that pledge not to log user queries
- **No-filter Policy**: Uses resolvers that don't enforce their own blocklists
- **IPv4 Support**: Compatible with IPv4 networks
- **TCP/UDP Support**: Uses UDP by default for better performance, with TCP fallback available

The proxy is configured to handle up to 250 simultaneous client connections and listens on all interfaces (0.0.0.0:53).

For a full list of available public resolvers that can be used with `PUBLIC_RESOLVERS_OVERRIDE`, visit: https://dnscrypt.info/public-servers
