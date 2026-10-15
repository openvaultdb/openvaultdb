---
format: https://specscore.md/idea-specification
status: Draft
---
# Idea: OVDB accepts credentials from multiple external auth providers

**Status:** Draft
**Date:** 2026-10-15
**Owner:** alex
**Promotes To:** —
**Supersedes:** —
**Related Ideas:** —

## Problem Statement

How might OpenVaultDB let a person who already has an identity elsewhere, first Sneat.co and later other providers, sign in to OVDB with that identity, without a second sign-up, without OVDB trusting arbitrary issuers, and without making the public demo databases harder to reach than they need to be?

## Context

Triggered by DataTug, which opens the public OVDB demo databases hosted on Neon (project OpenVaultDB: northwind, chinook, sakila, pubs, employees, adventureworks, each with a `*_reader` role) and had to ask whether users must sign in to see them.

**Founder rulings (2026-10-15):**

1. Public read-only access to the OVDB-cloud demo databases is **intended**.
2. Whether sign-in is required for them is an **OVDB-level** decision, not DataTug's: the OVDB server knows nothing about DataTug except its UI.
3. Recommendation, **not yet ruled**: anonymous read-only browsing with caps; sign-in for anything that creates value (save, add a database, higher limits, private sources).

**Observed state of Neon** (read-only inspection with the neon CLI; nothing changed): `block_public_connections=false`, no IP allow list, one `*_reader` role per database. Reader privileges are **not verified**. A Neon-direct reader connection string cannot be gated by any app, so abuse control (rate limits, connection caps, statement timeouts) has to live in Neon or the OVDB proxy, never in sign-in.

**What the code does today** (read 2026-10-15, repos under `~/projects/openvaultdb` and `sneat-co/ovdb`):

- The OVDB Go server (`openvaultdb-go/pkg/auth/middleware.go`) accepts only opaque OVDB bearer tokens: the owner token, or an application grant looked up by SHA-256 hash in a grants store (`pkg/auth/store.go`, `TokenTTL` one hour). It has no JWT or Firebase code. `/ovdb/*`, `/.well-known/openvaultdb`, `/authorize` and `/token` are public paths; everything else gets `401` with `WWW-Authenticate: Bearer realm="openvaultdb"` and body `{"error":{"code":"unauthorized",…}}`. Capabilities are strings such as `records:read` (`pkg/auth/auth.go`).
- OVDB Cloud (`cloud/`) **already uses the Sneat.co Firebase project for sign-in**: `cloud/public/firebase-auth.js` initialises Firebase with `projectId: "sneat-eur3-1"` (`authDomain: auth.sneat.co`), and `cloud/README.md` says `/device` authenticates with "the shared Sneat Co. Firebase identity", that the verified `sneat-eur3-1` UID is used directly as the Sneat Co. `userID`, and that the Firebase ID token is verified by the Sneat Co. backend (`github.com/sneat-co/ovdb/backend`). The credential issued is an OVDB token, not a Sneat token, with revocable digests in Sneat Firestore (default one year).
- The `ovdb` CLI logs in with the OAuth device flow against that cloud (`ovdb/cloud.go`, `strongo/deviceauth`, `/oauth/device/code`, `/oauth/token`, `/oauth/userinfo`, `/oauth/revoke`) and keeps the token in the keyring or a credential file.
- The public demo traffic is not authenticated: the Worker forwards `/v1/*` and `/ovdb/*` to a Cloud Run service deployed `--allow-unauthenticated`, behind per-IP rate limits (`cloud/src/ovdb-limits.ts`: 60 queries and 300 reads per minute, keyed by IPv4 or IPv6 /64) and a 10 s query timeout (`cloud/README.md`). The Northwind Neon route runs queries `READ ONLY` with `statement_timeout` 10 s as `northwind_reader`.
- Anonymous Firebase sign-in is already recognised in `sneat-co/ovdb` (`backend/api4ovdb/http_writable_sandbox.go`, `hasAnonymousFirebaseProvider`), so there is a precedent for an anonymous tier.

**Corrections to the original sketch.** The sketch assumed OVDB had no Firebase integration and that a Sneat login gives no access. In fact the Sneat.co Firebase project is OVDB Cloud's *first-party* identity today, and verification happens in the Sneat backend, not in the OVDB Go server. What does not exist is (a) any path for a *client holding a Firebase ID token* (DataTug) to call the OVDB data API directly, and (b) any second provider. Whether DataTug uses a different Firebase project from `sneat-eur3-1` is **unverified**: the premise came from the requesting session and I found no DataTug Firebase config. If DataTug already signs in against `sneat-eur3-1`, the "different projects" problem disappears and only (a) remains.

## Recommended Direction

Treat external sign-in as **identity only**. OVDB verifies a token from a trusted external issuer, maps it to an OVDB principal, and then issues or honours its own grants and tokens, extending the existing token and capability model rather than replacing it. A provider's token never carries OVDB authority.

For Sneat.co this means accepting Firebase ID tokens: a JWT signed by Google, checked for signature (Google's public keys), expiry, `iss` = `https://securetoken.google.com/<project-id>` and `aud` = `<project-id>`, against an **explicit allowlist of trusted issuers**. Only Sneat.co's project is trusted at the start; arbitrary Firebase projects never are. The Firebase Admin SDK is one project per app instance, so either run one instance per trusted project or verify the JWT directly (the second is simpler and is the plan to validate). The identity key is **(issuer, uid)**, because one person has a different uid in each Firebase project. Linking a Sneat identity to an existing OVDB account happens only through a verified email plus an explicit confirmation by the user, never by automatic merge. Revocation lag up to the ID-token lifetime (about one hour) is accepted.

Where the verification lives is the first thing to settle. Today it lives in the Sneat backend behind the cloud Worker (`cloud/README.md`), and the Worker "contains no authorization business state". The lowest-cost path is to keep that: a client trades a Sneat ID token at an OVDB Cloud endpoint for an OVDB token, which is what the device flow already does for the CLI. A direct verifier in the OVDB server is the alternative if the server must stand alone, for example self-hosted `openvaultdb-go`. Both read the same issuer allowlist. This Idea does not decide between them.

Access policy for the public demos follows the unratified recommendation: anonymous read-only browsing within caps, sign-in for saving, adding databases, higher limits and private sources. The caps live where they can actually be enforced: Worker rate limits for the HTTP path, and Neon or the OVDB proxy for the Neon-direct path (connection caps, statement timeouts, role privileges).

Client side, DataTug CLI, the Claude Code mod and web pass the token through the environment or the OS keychain, never argv or an interactive prompt. On `401` or `403` they show a plain "sign in to OVDB" message with the sign-in command instead of a generic connection error.

## Alternatives Considered

- **Token exchange through a Sneat endpoint that mints OVDB custom tokens.** Lost: Sneat would need an OVDB service-account key, coupling two systems the founder wants independent (decision 0005). Note that the existing device flow is the reverse direction, OVDB asking the Sneat backend to verify, and is not this alternative.
- **A shared GitHub login for both products.** Lost: it leaves two sign-ins in the user's life and ties identity to a code host that many DataTug users do not use.
- **Merging the two Firebase projects.** Lost: it needs a user migration and puts OVDB's identity and blast radius inside Sneat's project. If DataTug is found to use `sneat-eur3-1` already, this alternative becomes moot.
- **Require sign-in for all demo access.** Lost for now: it adds friction to the first query and does nothing for Neon-direct strings, which no application can gate.

## MVP Scope

One job: a DataTug user who is signed in with Sneat.co can use OVDB features that need an account, with the same login, and an anonymous user can still browse the demo databases read-only.

Timebox: a verified issuer allowlist with one entry (Sneat.co), identity keyed by (issuer, uid), one agreed endpoint for presenting a Sneat token, a documented `401` contract, and demo-caps decided and written down. Provider-plugin machinery for a second provider is out of the MVP.

## Not Doing (and Why)

- A second provider (Google, GitHub, Apple, enterprise OIDC) — the allowlist and the (issuer, uid) key keep the door open without paying for a plugin API before there is a second case.
- Automatic merging of accounts across providers — a wrong merge hands one person another's data; linking needs verified email plus consent.
- Accepting Firebase tokens from any project — a Firebase project is cheap to create, so trust has to be per issuer by explicit allowlist.
- Using a provider token as an OVDB grant — authority stays in OVDB's own capabilities and tokens.
- Changing Neon or the `*_reader` roles from this Idea — this Idea records intent; any Neon change is a separate, deliberate task.
- Gating Neon-direct reader strings by sign-in — not possible; abuse control belongs to Neon and the proxy.

## Key Assumptions to Validate

| Tier | Assumption | How to validate |
|------|------------|-----------------|
| Must-be-true | DataTug and OVDB use different Firebase projects today, or DataTug otherwise cannot present a credential OVDB accepts | Read DataTug's Firebase config (CLI, web, mod); compare with `sneat-eur3-1` |
| Must-be-true | The `*_reader` roles are read-only on public demo data only (no write, no other schemas, no `pg_read_server_files` style privileges) | Inspect grants on each Neon role and database |
| Must-be-true | The Neon project can enforce connection caps and statement timeouts on reader roles | Check Neon role settings, pooler limits and plan limits |
| Should-be-true | Verifying Firebase JWTs directly (without the Admin SDK) is sufficient and cheap | Spike a verifier against Google's JWKS with the allowlist; check key-rotation handling |
| Should-be-true | The Sneat backend's existing verification can serve DataTug without new Sneat work | Read `sneat-co/ovdb` backend routes for device and token exchange; list what a direct Sneat-token call would need |
| Might-be-true | ID-token revocation lag of about one hour is acceptable to the founder and users | Founder ruling; confirm no OVDB capability needs faster revocation |

## SpecScore Integration

- **New Features this would create:** TBD at spec time (an external-identity sign-in feature; a public-demo access policy feature).
- **Existing Features affected:** none known; the OVDB token and capability model (`openvaultdb-go` `pkg/auth`, and the auth spec in this repo if present) and OVDB Cloud device authorization would be extended.
- **Dependencies:** DataTug's Claude Code mod and CLI client changes (outside this repo); Neon configuration and proxy limits for demo databases; decision 0005 (OVDB is independent and isolated).

## Open Questions

- Anonymous caps: what are they (queries per minute, rows per query, statement timeout, connection count), who enforces them for the HTTP path versus Neon-direct, and where are they documented? Today's only numbers are the Worker's per-IP limits.
- Where does Sneat-token verification live: the existing Sneat backend behind the cloud Worker, or a verifier inside the OVDB server for stand-alone deployments?
- Which Firebase project does DataTug sign in with today? If it is `sneat-eur3-1`, what is still missing besides a documented way to present the token to the OVDB data API?
- Account-linking UX: when does the prompt appear, what if the email is unverified or shared, and how does a user unlink?
- The `401` contract for DataTug: error code and body for "sign in required" versus "token expired" versus "forbidden"; how a client learns the sign-in URL or command (for example in `WWW-Authenticate` or the discovery document); whether anonymous callers get `401` or a degraded `200`.
- Provider-plugin shape for later providers: static allowlist file versus registry, per-provider claim mapping (email verified, subject), and how an issuer is added or removed without a release.
- Are the Neon `*_reader` roles safe to leave publicly reachable, and does the founder want Neon's public access to stay open or move behind the OVDB proxy?
- Ruling needed from the founder: ratify or change the anonymous-browse, sign-in-for-value recommendation.

---
*This document follows the https://specscore.md/idea-specification*
