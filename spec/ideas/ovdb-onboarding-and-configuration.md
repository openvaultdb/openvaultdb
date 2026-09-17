---
format: https://specscore.md/idea-specification
status: Draft
---
# Idea: OpenVaultDB onboarding, configuration and AI storage experience

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Promotes To:** —
**Supersedes:** —
**Related Ideas:** —

## Problem Statement

How might we make OpenVaultDB easy to discover, set up, try and understand — from a
terminal, a browser or an AI agent — so that a newcomer stores and sees their own
structured data within minutes and knows what to do next?

## Context

- The `ovdb` binary (`openvaultdb/ovdb`) can already serve inGitDB, SQLite, Firestore,
  MySQL and PostgreSQL databases over HTTP on `127.0.0.1:6832`, create inGitDB databases
  at runtime and manage scoped tokens. But first use requires knowing the manifest format
  and server flags: bare `ovdb serve` fails with "no databases", `ovdb init --engine`
  lists only two engines, there is no background server, no remembered database, no CLI
  for records, no terminal UI and no web UI.
- AI agents are becoming a main entry point. An agent that meets `ovdb` today gets no
  guidance, and any interactive prompt would hang it.
- Existing demos are not first-run material: `openvaultdb-todo-demo` needs a clone and
  three processes; Sneat's Listus demo needs a cloud login, a Sneat Space and a tunnel.
- DataTug (the ecosystem's data exploration tool) has a read-only OpenVaultDB source, but
  connecting it needs a descriptor file, environment variables and a principal flag;
  DataTug.app has no way to open an OVDB database.
- Hub specifications leave related gaps open: the reference implementation's "web UI or
  CLI-first?" question, no glossary term for the served *database* (the hub says *vault*),
  no browser trust boundary for a loopback server, and `localhost:8080` as the only
  documented server address.
- Founder brief (2026-09-16) sets binding choices: three equal interfaces (Cobra, Bubble
  Tea, Vue 3 + TypeScript + Vite + Tailwind embedded), `http://ovdb.localhost:6832`,
  HTTP for MVP, a built-in TODO demo superseding `openvaultdb-todo-demo`, Listus stays
  Sneat's, PostHog EU opt-in telemetry that agents never consent to, and new flows hidden
  behind a preview gate until reviewed.

## Recommended Direction

Build onboarding as **one capability layer with three thin presentations**. Go services
run inside the local server and own state, validation, next actions and one error envelope;
the CLI, the TUI and an embedded web console call them over one authenticated HTTP transport
and render them with the same words from `copy/en.json`. A capability matrix with a registry
test keeps them equal, and justified gaps are written down as exceptions
([decision 0006](../decisions/0006-three-equal-configuration-interfaces.md)).

Centre everything on **one local OVDB server per user** at `http://ovdb.localhost:6832`,
started in the background on demand, serving all registered databases, the web console,
the TODO app and a local API. It always authenticates (an instance secret for CLI and TUI,
one-time login links for browsers) and is hardened against cross-site attacks, while legacy
`ovdb serve` stays unchanged ([decision 0007](../decisions/0007-local-ovdb-server-and-web-address.md)).
Apps, agents and the web see the same data at once, and a read-only Browse data view lets
people see their own data without a terminal.
Remember the working database **per project** rather than per machine, so parallel agents
do not interfere, and give agents a tiny filesystem-like vocabulary: `use`, `cd`, `pwd`,
`list`, `get`, `set`, `add`, `delete` ([decision 0008](../decisions/0008-database-context-scope.md)).

Make the first success tangible: a **built-in TODO demo** (To buy, To watch) stored as
readable files, a small web app on the same origin, and an optional TODO AI skill that
changes the lists while the app updates ([decision 0010](../decisions/0010-built-in-todo-demo.md)).
Ship an **OpenVaultDB storage skill** that offers terminal, browser and "I'll do it for you"
setup as equals. Hand exploration to DataTug honestly, and measure onboarding with
**opt-in** telemetry whose data model cannot carry user data
([decision 0009](../decisions/0009-opt-in-product-telemetry.md)).

## Alternatives Considered

- **CLI-first, UIs later.** Cheapest now, but leaves non-terminal users out and makes the
  UIs wrappers that drift. Lost to the founder's equal-interfaces requirement and to the
  shared-services design, which makes equality cheaper than retrofitting.
- **Web console as the single guided flow, CLI unchanged.** Friendly for browser users,
  but agents cannot use a browser flow and every setup would need a server first. Lost
  because agents are a primary audience.
- **Documentation and templates only (a quick-start guide, sample manifests).** No code
  risk, but it keeps the manifest-first learning curve and gives agents nothing reliable
  to call. Lost on time-to-first-success.

## MVP Scope

One job: **a newcomer, human or agent, goes from installed binary to their own data
stored, seen in an app and readable by an agent in under five minutes**, through any of
the three interfaces. Concretely: first-run Home with four options; background local
server with authenticated web console; create inGitDB/SQLite and connect an existing
inGitDB folder or SQLite file from a truthful catalogue; project-scoped context, minimal data
commands and read-only Browse data; TODO demo with web app; storage and TODO skills with
explicit install consent; Explore data guidance for DataTug; opt-in telemetry with parity;
everything (including changed defaults of existing commands) behind `OVDB_PREVIEW=1` until
the founder approves, starting with an increment 0 of spikes, then vertical increments that
each keep parity and the four canonical journeys passing.

## Not Doing (and Why)

- Redesigning record CRUD, access control, schemas or bulk operations — onboarding needs
  thin verbs over the existing API, not a new data model.
- A hosted cloud onboarding or account flow — local-first product; cloud login exists
  separately.
- Local HTTPS and certificates — adds trust-store changes without protecting loopback
  traffic.
- Record editing, querying, or a schema or admin UI in the web console or TUI — read-only
  Browse data is in scope; apps and agents edit, DataTug owns querying.
- Full DataTug integration (new DataTug.app routes, nested DTQL) — owned by other
  repositories; recorded as external dependencies.
- A comprehensive storage skill covering tokens, ACLs and schemas — MVP teaches setup and
  the small verb set.
- Every storage engine in guided flows (GitHub-hosted inGitDB, provisioning database
  servers) — only engines the binary really supports, and only local creation.
- Remote OVDB servers as contexts — the context keeps a reserved `server` field.
- Guided connect for Firestore, MySQL and PostgreSQL without a manifest — their connection
  details live in the server's environment and error paths can leak secrets; they connect
  through `ovdb init` plus Connect with a manifest file instead.
- A per-storage-folder lock — one server per OVDB home is the only writer; other tools writing
  the same folder (another home, legacy `ovdb serve`, editors) are out of scope.
- Running DataTug from OVDB, `ovdb skills uninstall`, skill refresh after self-update, and
  stopping the server from the web console — cut to keep the first release small.
- A login item or OS service so the server runs without any terminal or agent — deferred.
- Marketplace publication of skills — follow-up once the preview gate is removed.

## Key Assumptions to Validate

| Tier | Assumption | How to validate |
|------|------------|-----------------|
| Must-be-true | Browsers on Windows, macOS and Linux resolve `ovdb.localhost` to loopback | Manual check in Chrome, Firefox, Safari, Edge; fallback address always printed |
| Must-be-true | A detached background server can be started and stopped reliably on all three OSes | Lifecycle tests in CI on all three runners |
| Must-be-true | Agents can complete setup using only non-interactive commands | Journey C scripted with stdin closed, plus a live agent run |
| Must-be-true | Same-origin serving of the TODO app avoids CORS and token friction | Journey D browser test |
| Should-be-true | Project root (Git root or cwd) is the scope people and agents expect | Observe Journey A/C sessions; watch for "wrong database" reports |
| Should-be-true | People will opt in to telemetry often enough to inform decisions | Opt-in rate after the preview gate is removed |
| Should-be-true | DataTug CLI works against a local OVDB server with a read-only token created by `ovdb token create` | First increment runs `datatug query run` end-to-end |
| Should-be-true | A one-time login link is an acceptable step before the web console | Journey B observations; landing-page visits without a session |

## SpecScore Integration

- **New Features this would create:**
  [first-run-onboarding](../features/first-run-onboarding/README.md),
  [local-server-and-web-console](../features/local-server-and-web-console/README.md),
  [database-setup-and-providers](../features/database-setup-and-providers/README.md),
  [database-context-navigation](../features/database-context-navigation/README.md),
  [todo-demo](../features/todo-demo/README.md),
  [ai-agent-skills](../features/ai-agent-skills/README.md),
  [explore-data-handoff](../features/explore-data-handoff/README.md),
  [telemetry-consent](../features/telemetry-consent/README.md),
  [configuration-parity](../features/configuration-parity/README.md). They are drafted
  now; their `Source Ideas` will reference this idea once it is approved.
- **Existing Features affected:** none directly. Sneat's `listus-local-demo` (in
  `sneat-co/ovdb`) shares the `ovdb demo` namespace.
- **Dependencies:** decisions 0006–0010; `strongo/cli-helpers` (skillsync,
  daemonlifecycle); `openvaultdb-go` (nested DTQL); `datatug-cli` and `datatug-apps`
  (OVDB source routes).

## Review History

**Round 1 (2026-09-17).** Reviewers: Claude Opus (security and platform), Claude Sonnet (UX,
agents and scope), Claude Opus (requirements and architecture). A Codex review was attempted
but was unavailable because of a usage limit. Verdicts were reconciled by the architect.

| Finding | Verdict | Change or reason |
|---|---|---|
| Unauthenticated local API can write files and agent skills; clickjacking; stored XSS | Accepted (modified) | Local mode always authenticates (instance secret, one-time login link, session cookie, landing page); CSP, frame denial, nosniff, text-only rendering, `http.CrossOriginProtection`, Host allowlist |
| Connection strings leak through mount errors | Accepted | Redaction of all surfaced errors; upstream driver fix listed; guided SQL/Firestore connect deferred |
| Two transports and in-process writes race with auto-start | Accepted | Single transport: all mutations and data via the server; pure reads from files |
| Changed defaults of existing commands not gated; new commands broke `ovdb serve` deployments and Listus | Accepted | `OVDB_PREVIEW` gates changed defaults; legacy `ovdb serve` untouched |
| Required upstream changes unstated | Accepted | External changes table and increment-0 spikes S1–S8 |
| Machine contracts under-specified | Accepted | Error envelope with closed codes and `next[]`, `--json` equals API body with `schema: 1`, endpoint table, `copy/en.json` |
| Exit code 2 for usage errors | Rejected | Keeps `ovdb`'s existing 0/1 contract |
| Web-only users cannot see their own data | Accepted (modified) | Read-only Browse data in TUI and web; editing stays CLI, agents and apps |
| Journey B cold start without a terminal | Accepted (modified) | Journey B starts from a link given by an agent, `ovdb open` or the TUI; login item deferred |
| Skill-less agents never learn setup paths | Accepted | `next` entries in `ovdb status --json` include skill install |
| Shared `cd` path across agents; context lost in sub-folders | Accepted (modified) | Skills use absolute paths and `--db`; walk-up context lookup |
| Telemetry: wrong process environment, undelivered events, unenforced agent consent | Accepted (modified) | Sending process decides; synchronous ≤2 s sender without SDK; `--confirmed-by-user` |
| Cut telemetry during preview | Rejected | Founder wants funnel data from MVP; scope simplified instead |
| Runtime files in roaming profile; pid reuse; Windows reserved ports; `EscapeID` examples | Accepted | Cache-dir runtime files, `OVDB_DATA_HOME`, authenticated stop with start-time check, `port_unavailable`, corrected examples |
| Scope: remote connect UIs, DataTug run-now, skills uninstall and refresh, web stop, per-capability browser tests | Accepted | Deferred or replaced (web stop is exception E2; browser tests per journey) |

**Architect decisions between rounds.** The instance secret is the owner credential and
`ovdb token create|list|revoke` work against the local server (auth store in OVDB home);
`ovdb databases connect --manifest` registers any engine, closing the Firestore/MySQL/PostgreSQL
dead end; the skills command stays `ovdb skills install <skill>` (sync installs every bundle,
but the TODO skill needs its own offer).

**Round 2 (2026-09-17).** Reviewer: a fresh Claude Opus, independent and read-only. Verdict:
ready with fixes; after this round the specifications are approved for planning.

| Finding | Verdict | Change or reason |
|---|---|---|
| Local-mode auth rejected scoped tokens; connect flow undefined | Accepted (modified) | Three credentials (instance secret, session cookie, scoped tokens) with a credential×route table; connect flow on, consent needs a session, form posts exempt from the JSON rule |
| Cross-origin protection blocks third-party browser apps | Accepted (modified) | Applies to cookie-authenticated requests only; bearer requests exempt; apps use `server.cors` origins with tokens |
| Whoever auto-starts the server fixes its environment and sandbox | Accepted | Clients send skill dirs and data home; home/port mismatch error; Windows breakaway; `server_start_failed` with sandbox advice in output and skill |
| Login link dead on the 127.0.0.1 fallback; `SameSite=Strict`; GET consumes codes; no endpoint to mint links | Accepted (modified) | Codes valid on all allowed hosts and both links printed; `SameSite=Lax`, port-named cookie, hashed sessions with 30-day sliding expiry; POST-only exchange; `POST /api/local/v1/login-links` |
| `--json` contract conflicts with data commands | Accepted (modified) | Contract applies to configuration commands; data commands print `/v1` bodies unchanged; error code↔HTTP status and `/v1` mapping table |
| Idea excluded the data browser; stale token wording; `engines --filter`; "may offer" | Accepted | Fixed |
| Needs-attention without a server; legacy-create trigger; header order; link printed on start; `record.EscapeID` and `%`; demo path; CLI resolving `ovdb.localhost` | Accepted | `mounts.json` or "unknown"; only explicit `--addr`; headers outermost; link only from `ovdb open` (10-minute code in transcripts accepted); fixed; `<data home>/demos/todo`; CLI and TUI use 127.0.0.1 |
| Round-1 leftovers: per-storage lock; silent "only database" rung; Windows job objects; server-side skill dirs | Deferred; kept; accepted; accepted | Lock deferred (single writer per home); only-database rung kept but every output names the database; covered by the environment fix |

## Open Questions

- Vocabulary: onboarding copy says *database*, matching the implemented API
  (`/v1/databases/{id}`) and DataTug's `databaseId`; the hub glossary says *vault*, and
  `openvaultdb-com` decision 0003 (In Review) proposes Host / Vault / Namespace. Should
  *database* be the unit a local OVDB server serves and *vault* stay the app-access
  concept, or should one term win?
- Should SQLite gain schemaless support so it is a friendly second choice, or should
  onboarding keep recommending inGitDB only?

---
*This document follows the https://specscore.md/idea-specification*
