# Provider Discovery

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define how Sneat (and other applications) discover, validate, and connect to OpenVaultDB provider endpoints.

## Discovery Use Cases

| Use Case | Description |
|---|---|
| User selects a known provider | User picks from a curated list (api.openvaultdb.com, sneat.cloud) |
| User enters a custom URL | User types `https://vault.example.com` |
| Application references a provider | Application config includes a provider URL |
| Redirect from OpenVaultDB Cloud | User is redirected from `api.openvaultdb.com` after OAuth |

## Provider Discovery Protocol (Draft)

When a user enters a custom URL, the client performs the following checks:

### Step 1: Fetch Well-Known Metadata

```
GET {base_url}/.well-known/openvaultdb-configuration
```

Proposed response:

```json
{
  "openvaultdb_version": "0.1",
  "server_version": "0.1.0",
  "base_url": "https://vault.example.com",
  "display_name": "Example Vault",
  "auth_methods": ["oidc", "passkey", "api_key"],
  "oidc_issuer": "https://accounts.example.com",
  "capabilities": {
    "storage_backends": ["github", "sqlite"],
    "billing": false,
    "search": false
  },
  "registration": "open",  // open | invite | disabled
  "documentation_url": "https://vault.example.com/docs"
}
```

> **Note**: This well-known endpoint should be independent of authentication (publicly accessible).

### Step 2: Validate TLS Certificate

- Certificate must be valid and not expired.
- Certificate must match the hostname.
- Self-signed certificates: warn user; do not block (for self-hosted and development use).

> **Risk**: Users may accept self-signed certificate warnings for malicious endpoints. Client should show a clear warning for self-signed certs.

### Step 3: Compatibility Check

Client checks `openvaultdb_version` in the well-known metadata against the minimum supported version.

| Result | Action |
|---|---|
| Compatible version | Proceed |
| Newer version | Warn: "This provider uses a newer version. Some features may not work." |
| Incompatible version | Error: "This provider is not compatible. Please contact the provider." |
| Missing well-known | Error: "This URL does not appear to be an OpenVaultDB endpoint." |

### Step 4: User Confirmation

Before adding the provider, display to the user:
- Provider display name
- Base URL
- Supported auth methods
- Whether registration is open

User confirms before proceeding.

## Sneat Curated Provider List (Draft)

Sneat may maintain a curated list of known providers with pre-verified compatibility:

| Provider | URL | Notes |
|---|---|---|
| OpenVaultDB Cloud | `https://api.openvaultdb.com` | Official; always up to date |
| Sneat Cloud (OpenVaultDB mode) | `https://vault.sneat.cloud` | Operated by Sneat |

> **Open question**: Should Sneat maintain a curated list? This requires ongoing maintenance and creates a gatekeeping responsibility.

## Authentication Flow After Discovery

After provider discovery, the user authenticates with the provider using one of the supported auth methods:

1. If `oidc` is supported: initiate OIDC flow with the provider's OIDC issuer.
2. If `passkey` is supported and the user has a registered passkey: use passkey.
3. If `api_key` is supported: user enters API key (for advanced users).

After authentication:
- Client stores the access token and refresh token for this provider.
- Client stores provider metadata for future connections.

## Health Checks

Ongoing health checks after initial connection:

| Check | Frequency | Failure Behavior |
|---|---|---|
| `GET /health` | Every 30s (proposed) | Mark provider as degraded; retry |
| Token refresh | Before expiry | If fails: mark provider as offline |
| Well-known metadata refresh | Daily | Update capabilities cache |

> **Open question**: Should health checks be the client's responsibility or should the server push health status?

## Provider Failure

If a provider becomes unavailable:

1. Mark provider as offline in Sneat.
2. Display "Storage provider offline" indicator on affected Spaces.
3. If offline-first is implemented: allow reads from local cache; queue writes.
4. If offline-first is not implemented: show read-only or error state.
5. When provider recovers: resume normal operation; replay queued writes.

> **Risk**: Write queue replay on provider recovery may conflict with writes from other clients. Conflict resolution strategy TBD.

## Reconnecting a Provider

If a user's credentials expire or are revoked:

1. Sneat detects 401 response from provider.
2. Sneat prompts user to re-authenticate.
3. User completes authentication flow.
4. New tokens stored; normal operation resumes.

## Open Questions

1. What is the minimum OpenVaultDB API version that Sneat supports?
2. Should Sneat cache provider metadata offline (for reconnection)?
3. How should Sneat handle a provider that changes its base URL?
4. Should the well-known endpoint be standardized (proposed to OpenVaultDB spec)?
5. How should deep links work for cross-provider Space references?

## Risks

- Malicious providers at custom URLs could phish for user credentials.
- Provider URL changes break existing Space connections.
- Stale provider metadata causes feature compatibility issues.
- Self-signed certificate warnings are ignored by users.

## Acceptance Criteria

- Sneat correctly validates a real OpenVaultDB endpoint.
- Invalid endpoints (wrong URL, incompatible version) show clear errors.
- Self-signed certificate warning is displayed prominently.
- Provider reconnection flow works without losing Space data.

## Related Specifications

- [space-storage-selection.md](space-storage-selection.md)
- [migration-flow.md](migration-flow.md)
- [../api/endpoints.md](../api/endpoints.md)
- [../security/trust-model.md](../security/trust-model.md)
