---
format: https://specscore.md/idea-specification
status: Draft
---
# Idea: Generalize OVDB sign-in to multiple federated providers, Sneat.co first

**Status:** Draft
**Date:** 2026-10-15
**Owner:** alex
**Promotes To:** —
**Supersedes:** —
**Related Ideas:** —
**Parent Decision:** [0005 OpenVaultDB is an independent and isolated project](../decisions/0005-openvaultdb-is-an-independent-and-isolated-project.md)

## Problem Statement

How might OpenVaultDB turn the Sneat.co sign-in it already has into the first of several federated providers, as decision 0005 requires, so that a DataTug user signs in as a registered OVDB client with an identity OVDB owns, OVDB never trusts arbitrary issuers, and the public demo databases stay easy to reach?

## Context

This Idea is the concrete path of [decision 0005](../decisions/0005-openvaultdb-is-an-independent-and-isolated-project.md) (Approved 2026-09-16) for one case. 0005 already rules that OVDB owns its identity, that Sneat Co. MAY be registered as one of the first federated providers with no special standing, that provider subjects map to OVDB-issued principals through a translation layer, and that consumers are registered clients. This Idea does not re-decide any of that and does not edit or supersede 0005. No related Idea exists (the only one is `ovdb-onboarding-and-configuration`), and `spec/open-questions.md` and `spec/risky-assumptions.md` hold no identity-provider item, so nothing is duplicated; the questions below are new.

Triggered by DataTug, which opens the public OVDB demo databases hosted on Neon (project OpenVaultDB: northwind, chinook, sakila, pubs, employees, adventureworks, each with a `*_reader` role) and had to ask whether users must sign in to see them.

**Founder rulings (2026-10-15):**

1. Public read-only access to the OVDB-cloud demo databases is **intended**.
2. Whether sign-in is required for them is an **OVDB-level** decision, not DataTug's: the OVDB server knows nothing about DataTug except its UI.
3. Recommendation, **not yet ruled**: anonymous read-only browsing with caps; sign-in for anything that creates value (save, add a database, higher limits, private sources).

**Observed state of Neon** (read-only inspection with the neon CLI; nothing changed): `block_public_connections=false`, no IP allow list, one `*_reader` role per database. Reader privileges are **not verified**. A Neon-direct reader connection string cannot be gated by any app, so abuse control (rate limits, connection caps, statement timeouts) has to live in Neon or the OVDB proxy, never in sign-in.

**What the code does today** (read 2026-10-15, repos under `~/projects/openvaultdb` and `sneat-co/ovdb`):

- The OVDB Go server (`openvaultdb-go/pkg/auth/middleware.go`) accepts only opaque OVDB bearer tokens: the owner token, or an application grant looked up by SHA-256 hash in a grants store (`pkg/auth/store.go`, `TokenTTL` one hour). It has no JWT or Firebase code. `/ovdb/*`, `/.well-known/openvaultdb`, `/authorize` and `/token` are public paths; everything else gets `401` with `WWW-Authenticate: Bearer realm="openvaultdb"` and body `{"error":{"code":"unauthorized",…}}`. Capabilities are strings such as `records:read` (`pkg/auth/auth.go`).
- OVDB Cloud (`cloud/`) **already uses the Sneat.co Firebase project for sign-in**: `cloud/public/firebase-auth.js` initialises Firebase with `projectId: "sneat-eur3-1"` (`authDomain: auth.sneat.co`), and `cloud/README.md` says `/device` authenticates with "the shared Sneat Co. Firebase identity", that the verified `sneat-eur3-1` UID is used directly as the Sneat Co. `userID`, and that Firebase authorization is verified by the Sneat Co. backend (`github.com/sneat-co/ovdb/backend`; the verification code itself was not read for this Idea). The credential issued is an OVDB token, not a Sneat token, with revocable digests in Sneat Firestore (default one year).
- The `ovdb` CLI logs in with the OAuth device flow against that cloud (`ovdb/cloud.go`, `strongo/deviceauth`, `/oauth/device/code`, `/oauth/token`, `/oauth/userinfo`, `/oauth/revoke`) and keeps the token in the keyring or a credential file.
- The public demo traffic is not authenticated: the Worker forwards `/v1/*` and `/ovdb/*` to a Cloud Run service deployed `--allow-unauthenticated`, behind per-IP rate limits (`cloud/src/ovdb-limits.ts`: 60 queries and 300 reads per minute, keyed by IPv4 or IPv6 /64) and a 10 s query timeout (`cloud/README.md`). The Northwind Neon route runs queries `READ ONLY` with `statement_timeout` 10 s as `northwind_reader`.
- `sneat-co/ovdb` already distinguishes Firebase anonymous sign-in, but to *deny* it: `backend/api4ovdb/http_writable_sandbox.go` (`hasAnonymousFirebaseProvider`) rejects anonymous users from writable demo sandboxes with 403 `access_denied`. That is a precedent for requiring a registered user for value-creating features, not for an anonymous browse tier.

**Gaps between decision 0005 and the current implementation.** The README of `cloud/` itself calls the independent identity cutover "a separate stage", so these are expected, not defects:

| 0005 says | Today | Evidence |
|-----------|-------|----------|
| Identity is owned by OVDB; Sneat is one federated provider with no special standing | Sneat.co Firebase `sneat-eur3-1` is the only identity, and OVDB has no identity project of its own | `cloud/public/firebase-auth.js`; `cloud/README.md` |
| Provider subjects map to OVDB-issued principals (translation layer) | The verified Firebase UID is used directly as the Sneat Co. `userID` | `cloud/README.md`; `spec/features/cloud-cli-device-login/README.md` ("Hosted identity and collaboration boundary", approval rule on `sneat-eur3-1`) |
| 0004 is superseded | The device-login feature spec still cites 0004 and describes the Sneat-rooted model, so it is stale against 0005 | `spec/features/cloud-cli-device-login/README.md` |
| Consumers are registered clients | The device flow has registered clients and scopes, which already fits | `spec/features/cloud-cli-device-login/README.md`; `github.com/sneat-co/ovdb/backend` |
| OVDB runs its own identity deployment | Not started; 0005 leaves open whether it is a hosted identity service or its own OIDC issuer | 0005, Consequences |
| A translation layer is a maintained component | Absent. The Go data server has no principal-mapping code | `openvaultdb-go/pkg/auth/` |

**Is DataTug's Firebase project `sneat-eur3-1`? OPEN.** The founder believes DataTug uses a different project; two sessions could not confirm it from `datatug-apps`, and I found no config either. If it is `sneat-eur3-1`, a DataTug user can already sign in through the device flow and the CLI and mod only need to use it. If it differs, the issuer-allowlist design below applies.

## Recommended Direction

Follow 0005: treat external sign-in as **identity only**. OVDB verifies a token from a trusted external issuer, maps the provider subject to an **OVDB-issued principal** through the translation layer, and then issues or honours its own grants and tokens, extending the existing token and capability model rather than replacing it. A provider's token never carries OVDB authority. DataTug signs in as a **registered OVDB client**, using the existing device flow for the CLI and mod.

Federated provider #1 is Sneat.co, accepting Firebase ID tokens: a JWT signed by Google, checked for signature (algorithm pinned to RS256, keys fetched only from Google's fixed JWKS URL with `kid` handling), expiry, `iss` = `https://securetoken.google.com/<project-id>`, `aud` = `<project-id>`, non-empty `sub` and `auth_time` not in the future, against an **explicit allowlist of trusted issuers**. Only Sneat.co's project is trusted at the start; arbitrary Firebase projects never are. The Firebase Admin SDK is one project per app instance, so either run one instance per trusted project or verify the JWT directly (this re-implements what the Admin SDK does, so it must be validated, not assumed simpler). Tokens whose `firebase.sign_in_provider` is `anonymous` are rejected wherever an account is required. The provider key is **(issuer, uid)**, because one person has a different uid in each Firebase project; the OVDB principal id is separate and OVDB-issued, which replaces today's direct use of the Firebase UID. Linking a Sneat identity to an existing OVDB account happens only when the token has `email_verified` true and the user explicitly confirms from an **already-authenticated OVDB session**, never by automatic merge (an email asserted by a provider alone is an account-takeover vector). Existing records keyed by the bare `sneat-eur3-1` UID must be mapped onto the new principal ids by a one-off migration, which the open questions track. Revocation lag up to the ID-token lifetime (about one hour) is accepted.

Where the verification lives is the first thing to settle. Today it lives in the Sneat backend behind the cloud Worker (`cloud/README.md`; the device-login spec requires issuer and audience to match `sneat-eur3-1`), and the Worker "contains no authorization business state". Moving it behind OVDB's own identity is the cutover stage 0005 implies. The lowest-cost path is a client trading a provider ID token at an OVDB Cloud endpoint for an OVDB token, which is what the device flow already does for the CLI. A direct verifier in the OVDB server is the alternative if the server must stand alone, for example self-hosted `openvaultdb-go`. Both read the same issuer allowlist. This Idea does not decide between them.

Access policy for the public demos follows the unratified recommendation: anonymous read-only browsing within caps, sign-in for saving, adding databases, higher limits and private sources. The caps live where they can actually be enforced: Worker rate limits for the HTTP path, and Neon or the OVDB proxy for the Neon-direct path (connection caps, statement timeouts, role privileges).

Client side, DataTug CLI, the Claude Code mod and web pass the token through the environment or the OS keychain, never argv or an interactive prompt. On `401` or `403` they show a plain "sign in to OVDB" message with the sign-in command instead of a generic connection error.

## Alternatives Considered

- **Token exchange through a Sneat endpoint that mints OVDB custom tokens.** Lost: Sneat would need an OVDB service-account key, coupling two systems the founder wants independent (decision 0005). Note that the existing device flow is the reverse direction, OVDB asking the Sneat backend to verify, and is not this alternative.
- **A shared GitHub login for both products.** Lost: it leaves two sign-ins in the user's life and ties identity to a code host that many DataTug users do not use.
- **Merging the two Firebase projects, or issuing OVDB identities inside Sneat's project.** Lost: it needs a user migration and keeps OVDB's identity inside a consumer's project, which 0005 declines. If DataTug is found to use `sneat-eur3-1` already, the migration part is moot.
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
- **Existing Features affected:** [Cloud CLI device login](../features/cloud-cli-device-login/README.md) (still cites superseded 0004); [Sneat.app Space Export to GitHub](../features/sneat-space-export/README.md) (named in 0005); the OVDB token and capability model (`openvaultdb-go` `pkg/auth`, and the auth spec in this repo if present) and OVDB Cloud device authorization would be extended.
- **Dependencies:** DataTug's Claude Code mod and CLI client changes (outside this repo); Neon configuration and proxy limits for demo databases; decision 0005 (parent; its identity cutover stage is the prerequisite for a true translation layer).

## Open Questions

- Anonymous caps: what are they (queries per minute, rows per query, statement timeout, connection count), who enforces them for the HTTP path versus Neon-direct, and where are they documented? Today's only numbers are the Worker's per-IP limits.
- Where does Sneat-token verification live: the existing Sneat backend behind the cloud Worker, or a verifier inside the OVDB server for stand-alone deployments?
- **Is DataTug's own Firebase project the same as `sneat-eur3-1`?** The founder believes not; unconfirmed. If the same, what is still missing besides CLI and mod use of the device flow? If different, DataTug's project must be added to the issuer allowlist or DataTug must sign in through Sneat.co.
- Migration: how do existing bare-UID `userID` records map to OVDB-issued principals and to `(issuer, uid)` provider keys?
- Sequencing: does the translation layer and OVDB identity cutover (0005) come before this, or does Sneat-as-provider ship first on today's UID-as-userID model with a migration later?
- Account-linking UX: when does the prompt appear, what if the email is unverified or shared, and how does a user unlink?
- The `401` contract for DataTug (today's `unauthorized` code and `WWW-Authenticate: Bearer realm="openvaultdb"` are the baseline): error code and body for "sign in required" versus "token expired" versus "forbidden"; how a client learns the sign-in URL or command (for example in `WWW-Authenticate` or the discovery document); whether anonymous callers get `401` or a degraded `200`.
- Provider-plugin shape for later providers: static allowlist file versus registry, per-provider claim mapping (email verified, subject), and how an issuer is added or removed without a release.
- Are the Neon `*_reader` roles safe to leave publicly reachable, and does the founder want Neon's public access to stay open or move behind the OVDB proxy?
- Ruling needed from the founder: ratify or change the anonymous-browse, sign-in-for-value recommendation.

---
*This document follows the https://specscore.md/idea-specification*
