---
format: https://specscore.md/feature-specification
status: Implementing
---

# Feature: Cloud CLI device login

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/cloud-cli-device-login?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/cloud-cli-device-login?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/cloud-cli-device-login?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/cloud-cli-device-login?op=request-change) |
**Status:** Implementing
**Source Ideas:** —

## Summary

Authenticate first-party command-line clients through a browser-approved OAuth 2.0 device authorization flow.

## Problem

First-party command-line clients need a safe way to authenticate to OpenVaultDB
Cloud without asking a user to copy a long-lived bearer token into a terminal,
embedding a client secret in a public binary, or running a temporary callback
server that may be blocked by the user's environment.

The solution also needs to be reusable by other Go command-line products,
including InGitDB and Sneat Co. CLIs, without coupling shared protocol and
credential code to OpenVaultDB, Cobra, Firebase, or a particular cloud host.

## Behavior

### End-to-end journey

1. **Start — request a device authorization.** The user runs
   `ovdb cloud login`. The CLI requests an OAuth 2.0 Device Authorization Grant,
   prints the one-time code and complete verification URL, and attempts to open
   that URL in the default browser.
   - **Observable good result:** the terminal always shows a usable code and
     URL. If no browser opens, the CLI remains polling and tells the user to
     open the printed URL manually; no second command is required.
2. **Middle — authenticate and decide in the browser.** The page at
   `https://cloud.openvaultdb.com/device` resolves the code, authenticates the
   person through the shared Sneat Co. Firebase identity, discloses that
   OpenVaultDB is a Sneat Co. product, and displays the requesting client plus
   each requested scope before any grant.
   - **Observable good result:** the browser actor sees `OpenVaultDB CLI`, the
     exact `account:read` scope, the account being used, and distinct Approve
     and Deny actions. The waiting terminal does not receive a token before
     approval.
3. **End — issue and store one revocable credential.** On approval, the CLI's
   next permitted poll exchanges the device code exactly once. The CLI validates
   the issued token through `/oauth/userinfo`, stores it in the operating-system
   keyring, and reports the account, host, scopes, expiry, and storage class.
   - **Observable good result:** `ovdb cloud status` independently checks the
     token with OpenVaultDB Cloud and reports the signed-in account. The token is
     never printed.

### Divergent epilogues

- **Deny:** the browser confirms that no access was granted; the waiting CLI
  exits with an access-denied error and stores no credential.
- **Expiry or interruption:** a device code expires after ten minutes and the
  CLI exits without a credential. A new login creates a new code.
- **Browser-launch failure:** the manual URL remains visible and the same CLI
  process can complete after browser approval.
- **Re-login:** the new token is stored first, then the prior token is revoked.
  Failure to revoke the prior token is reported as a warning without discarding
  the newly working login.
- **Logout:** `ovdb cloud logout` revokes the remote token before deleting the
  local credential. If remote revocation fails, the credential is retained so
  the user can retry and the CLI does not falsely report logout.
- **Headless plaintext storage:** only an explicit `--insecure-storage` flag
  selects an unencrypted JSON file. The CLI warns before login and the directory
  and file are created with modes `0700` and `0600`; there is no automatic
  fallback from the OS keyring.

### Protocol and service boundaries

| Component | Responsibility |
|---|---|
| `github.com/strongo/deviceauth` | Product-neutral RFC 8628 login UX, best-effort browser launch, OS keyring storage, and explicitly selected plaintext storage. |
| `github.com/sneat-co/ovdb/backend` | Registered clients and scopes, device-grant state machine, Firebase-authenticated decisions, Firestore/DALgo persistence, token validation, and revocation. |
| `github.com/sneat-co/sneat-go` | Wire and configure the OpenVaultDB backend module, Firebase middleware, runtime secrets, and internal routes in the shared Sneat Co. API host. |
| `github.com/openvaultdb/cloud` | Static browser approval page, stable public OAuth routes, Cloudflare edge rate limits, and an authenticated proxy to the OpenVaultDB backend. It owns no authorization or token state. |
| `github.com/openvaultdb/ovdb` | `cloud login`, `cloud status`, and `cloud logout`; OpenVaultDB endpoints and user-facing output. |
| This specification | Product behavior, security invariants, and reusable ownership boundary. |

The initial registered public client is `ovdb-cli`, named `OpenVaultDB CLI`,
with `account:read`. Future clients get distinct client registrations and may
reuse the shared Go module without sharing tokens or product policy.

### Hosted identity and collaboration boundary

OpenVaultDB Cloud uses the verified `sneat-eur3-1` Firebase UID directly as the
Sneat Co. `userID`; it does not introduce a second OpenVaultDB account ID. The
device token remains an OpenVaultDB credential bound to the authenticated user,
registered client, scopes, expiry, and revocation state. It is not accepted as
a general Sneat Co. API token.

A Sneat Co. Space is a collaborative grant subject independently of whether it
is presented by `sneat.work`, `sneat.app`, or an extension mini-app. Products,
extensions, services, and CLIs are registered clients rather than Spaces or
users, and receive no ambient access from the surface in which they run.

A contact without a linked Sneat Co. `userID` can be the target of a pending
invitation but not active authenticated access. The long-lived device token
does not snapshot Space memberships or roles; resource authorization evaluates
current membership and the current OpenVaultDB grant. Contact invitation and
resource-grant endpoints are outside this device-login feature.

See
[Decision 0004](../../decisions/0004-sneat-co-identity-and-space-principals.md).

The OpenVaultDB Cloud service exposes:

| Method and path | Purpose |
|---|---|
| `POST /oauth/device/code` | Create a ten-minute pending grant and return RFC 8628 device/user codes. |
| `GET /api/device-authorization` | Resolve a user code to its client and requested scopes for display. |
| `POST /api/device-authorization/decision` | Verify a Firebase ID token and atomically approve or deny a pending grant. |
| `POST /oauth/token` | Enforce polling intervals and exchange an approved device code once. |
| `GET /oauth/userinfo` | Validate current expiry and revocation state and report the account and grant. |
| `POST /oauth/revoke` | Idempotently revoke a bearer token. |
| `GET /.well-known/oauth-authorization-server` | Publish authorization-server endpoint metadata. |

### Security invariants

- Device codes, user codes, and bearer tokens use cryptographic randomness.
- The OpenVaultDB backend stores keyed HMAC-SHA-256 lookup identifiers in
  Firestore through DALgo, never raw device codes, user codes, or access tokens.
- The backend and Cloudflare Worker share a separate proxy secret. Every
  internal device-auth route requires that secret so callers cannot bypass the
  Worker's public rate limits by addressing the shared Sneat Co. API directly.
- User codes are short-lived and public code creation, lookup, and polling are
  protected by Cloudflare rate-limit bindings.
- Approval requires a currently valid Firebase ID token whose issuer and
  audience match the shared Sneat Co. Firebase project `sneat-eur3-1`; its
  subject is stored directly as the Sneat Co. `userID`.
- The first-party CLI access token is opaque, capability-scoped, revocable, and
  valid for at most one year. Every authenticated API use checks the backend
  token record for expiry and revocation.
- The public CLI has no client secret. All production traffic uses HTTPS; HTTP
  host overrides are accepted only for loopback development.
- Device exchange is atomic and single-use, including concurrent requests.
- Sensitive responses are marked `no-store`; the approval page denies framing,
  sends no referrer, and limits scripts, connections, and Firebase frames with
  Content Security Policy.

## Acceptance Criteria

1. `ovdb cloud login` prints the code and URL before attempting browser launch,
   opens the complete verification URL when possible, and completes after
   approval. **Verifies:** shared module device-flow tests and the CLI
   login/status/logout journey test.
2. Browser launch failure leaves a manual path and does not cancel polling.
   **Verifies:** shared module browser-fallback test.
3. The approval page shows the registered client, exact requested scopes,
   signed-in Sneat Co. account, and OpenVaultDB's Sneat Co. product relationship
   before distinct approve/deny actions. **Verifies:** Worker asset/security
   test plus human smoke test after deployment.
4. Pending, excessive polling, denial, expiry, approval, exchange replay, and
   concurrent exchange have RFC-compatible terminal behavior. **Verifies:**
   isolated backend state-machine and Firestore-adapter tests.
5. Approval accepts only a verified `sneat-eur3-1` Firebase identity and returns
   that identity's subject as the OpenVaultDB Cloud `userID`; unknown clients,
   unregistered scopes, and unauthenticated decisions fail. **Verifies:**
   isolated backend API, identity, and negative-path tests.
6. Raw codes and tokens are absent from Firestore and the issued token can
   authenticate `/oauth/userinfo`, then fails immediately after revocation.
   **Verifies:** backend persistence and revocation tests.
7. Default credential storage is the operating-system keyring. Plaintext
   storage requires `--insecure-storage`, warns the user, and uses protected
   filesystem modes. **Verifies:** shared credential-store tests and CLI journey
   test.
8. `ovdb cloud logout` retains the local credential on remote revocation
   failure and removes it only after successful revocation. **Verifies:** CLI
   journey test.
9. The shared module imports no OpenVaultDB or command-framework package and a
   future registered InGitDB or Sneat Co. CLI can provide its own endpoints,
   scopes, and commands. **Verifies:** module dependency review and independent
   module build.
10. The OpenVaultDB backend passes architecture, build, test, coverage, vet, and
    lint gates. The Cloud Worker passes generated-binding type checking,
    isolated proxy/runtime tests, and Wrangler's dry-deployment build; `ovdb`
    passes tests, race detection, vetting, and a cross-module local build.
    **Verifies:** repository validation gates before landing.

## Open Questions

None at this time.

---
*This document follows the https://specscore.md/feature-specification*
