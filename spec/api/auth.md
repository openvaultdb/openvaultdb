# Authentication and Authorization

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the authentication and authorization model for OpenVaultDB: identity types, authentication mechanisms, token model, and how capabilities are enforced at the API level.

## Principal Types

| Principal Type | Description | Typical Auth Method |
|---|---|---|
| User | Human vault owner | OIDC, Passkey, API key |
| Application | Registered software | Client credentials (ID + secret) |
| AI Agent | Automated agent delegated by a user | Scoped delegated token |
| Service Account | Server-to-server communication | Client credentials (signed JWT) |

> **Key distinction**: Applications and AI agents are NOT users. They may act on behalf of users, but their access is governed by explicit capability grants — not by user-level permissions.

## Authentication Mechanisms

### OIDC Federation (Proposed: Google, GitHub, Apple, Microsoft)

Flow:
1. User initiates login; server redirects to OIDC provider.
2. User authenticates with provider.
3. Provider redirects to `/v1/auth/oidc/callback` with authorization code.
4. Server exchanges code for ID token; validates signature against provider's JWKS.
5. Server creates or resolves internal user account.
6. Server issues OpenVaultDB access token (short-lived) and refresh token.

> **Risk**: OIDC provider compromise allows impersonation of all users who authenticate through that provider. Account linking (one OpenVaultDB account, multiple OIDC providers) must be handled carefully to prevent account takeover.

### Passkeys (WebAuthn)

Flow:
1. User registers a passkey (FIDO2/WebAuthn credential).
2. Server stores the public key credential.
3. Authentication: server issues challenge; user signs with private key; server verifies.
4. Server issues access token.

> **Assumption**: Passkey support requires a browser or platform authenticator. CLI users without passkey support must use API keys or OIDC.

### API Keys

For programmatic access and CLI use:
- User creates API key via the dashboard or CLI.
- API key is issued once; user stores it securely.
- API key maps to the user principal with configurable scope restrictions.
- API keys can be revoked individually.

> **Risk**: API key theft grants persistent access until revocation. Short-lived API keys with refresh are more secure but more complex.

### Application Credentials (Client Credentials)

For registered applications:
1. Application is registered; server issues client ID and client secret.
2. Application exchanges client credentials for an access token.
3. Access token scope is limited to capabilities granted to the application.

Token lifetime: short-lived (15 minutes, proposed). Refresh via client credentials re-exchange.

> **Open question**: Should applications use rotating client secrets (OAuth 2.0 PKCE) or symmetric keys? Symmetric keys are simpler; PKCE is more appropriate for public clients.

### AI-Agent-Initiated Calls

For the MVP, AI-agent-initiated calls use the same token model as websites,
applications, CLIs, and services:

1. The caller authenticates as a registered principal.
2. The access token includes principal ID, granted capabilities, and expiry.
3. Audit records identify the authenticated principal.
4. Separate AI-agent identity metadata is not required.

Post-MVP profiles may add AI-specific provenance or delegated-agent tokens.

> **Risk**: Confused deputy attack — AI agent is tricked by malicious input into using its token for unauthorized operations. Token scope should be as narrow as possible. See [../security/ai-agent-access.md](../security/ai-agent-access.md).

## Token Model

### Access Token Structure (Draft)

Proposed JWT claims:

```json
{
  "iss": "https://api.openvaultdb.com",
  "sub": "user_123",                      // or app_456, agent_789
  "principal_type": "user",               // user | application | agent | service_account
  "vault_id": "vault_abc",                // null for user tokens (applies to all vaults)
  "capabilities": ["collections:read", "records:write"],
  "delegation_depth": 0,                  // 0 = no further delegation
  "iat": 1700000000,
  "exp": 1700003600,
  "jti": "tok_xyz"
}
```

Token lifetimes (draft):
| Token Type | Access Token TTL | Refresh Token TTL |
|---|---|---|
| User (OIDC) | 15 minutes | 30 days |
| User (Passkey) | 15 minutes | 30 days |
| User (API key) | 1 hour | n/a (re-exchange with key) |
| Application | 15 minutes | 7 days |
| AI Agent | 15 minutes | n/a (no refresh; re-delegate) |

> **Open question**: Should refresh tokens be one-time-use (rotation)? Rotation improves security but complicates concurrent requests.

## Authorization Model

Authorization is enforced at two layers:

### Layer 1: Middleware Token Validation

Every request:
1. Extract Bearer token from `Authorization` header.
2. Validate JWT signature.
3. Check token expiry.
4. Check token revocation (via revocation list or database lookup).
5. Resolve principal from token claims.

> **Revocation check performance**: Full database lookup on every request is expensive. Options:
> - Short-lived tokens (minimize window after revocation)
> - Token revocation list cached in memory (eventual consistency)
> - Redis-based revocation list (near-real-time, requires Redis)

### Layer 2: Capability Enforcement

Per request:
1. Identify the required capability for the operation (e.g., `records:write` for `PUT /records/{id}`).
2. Check the active grant for the principal on the target vault.
3. If grant is valid and includes the required capability: allow.
4. If grant is missing, expired, or revoked: deny with 403.

> **Risk**: Stale grant cache. If grants are cached, revocation takes time to propagate. Cache TTL must be short (proposed: 30 seconds) or bypass cache on revocation signal.

## Capability Taxonomy (Draft)

| Capability | Description |
|---|---|
| `vault:read` | Read vault metadata |
| `vault:write` | Update vault metadata |
| `collections:read` | Read collection definitions |
| `collections:write` | Create/modify collections |
| `records:read` | Read records (all collections in grant) |
| `records:write` | Write records (all collections in grant) |
| `records:delete` | Delete records |
| `schema:read` | Read schema |
| `schema:propose` | Submit schema change proposals |
| `grants:read` | Read active grants |
| `grants:manage` | Create/revoke grants (user-level) |
| `migrations:plan` | Generate migration plans |
| `migrations:execute` | Execute approved migrations |
| `audit:read` | Read audit log |
| `export:create` | Initiate data export |

> **Open question**: Should capabilities be collection-scoped? (e.g., `records:read:contacts` grants read access to the `contacts` collection only) This significantly increases authorization complexity.

## Revocation

Tokens and grants can be revoked:

| Revocation Target | Mechanism | Propagation |
|---|---|---|
| Individual token (by JTI) | Revocation list | Near-real-time (cache TTL) |
| Application credentials | Deregister application | Immediate (server-side check) |
| Grant | Grant revocation API | Cache TTL |
| All tokens for a principal | Emergency revocation | Immediate (nonce-based) |

Emergency revocation changes the principal's nonce; all existing tokens fail validation.

## Account Compromise Recovery

If a user's account is compromised:
1. User triggers emergency revocation (if they can still authenticate).
2. If user cannot authenticate: contact support (out-of-band recovery).
3. After recovery: all grants must be re-reviewed and re-approved.

> **Open question**: What is the out-of-band recovery flow? This is a critical UX and security design decision.

## Open Questions

1. Should refresh tokens use rotation (single-use)?
2. Should capabilities be collection-scoped?
3. What is the acceptable cache TTL for revocation checks? (30s? 5s? 0s?)
4. How should account recovery be handled without trusting a single recovery factor?
5. Should the server support mutual TLS for service-to-service authentication?
6. How should AI agent tokens be scoped to prevent confused deputy attacks?

## Risks

- Short token TTLs improve security but increase authentication load.
- Revocation propagation delay creates a window of unauthorized access.
- OIDC provider compromise allows mass impersonation.
- Passkey platform lock-in (e.g., passkey stored only on one device).
- AI agent token scope too broad; agent acts beyond user intent.

## Acceptance Criteria

- Expired tokens are rejected by the middleware with 401.
- Revoked grants are rejected within the cache TTL.
- AI agent tokens cannot be used beyond their delegation depth.
- Emergency revocation immediately invalidates all existing tokens for a principal.
- OIDC callback validates token signature against the provider's JWKS.

## Related Specifications

- [endpoints.md](endpoints.md)
- [api-model.md](api-model.md)
- [../security/capability-model.md](../security/capability-model.md)
- [../security/permissions-model.md](../security/permissions-model.md)
- [../security/ai-agent-access.md](../security/ai-agent-access.md)
- [../security/trust-model.md](../security/trust-model.md)
