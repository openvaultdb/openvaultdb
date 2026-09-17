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

Build onboarding as **one capability layer with three thin presentations**. Plain Go
services own state, validation and a single typed error vocabulary; the CLI, the TUI and
an embedded web console only render them, with the same words from one message catalogue.
A capability matrix with a registry test keeps them equal, and the few justified gaps are
written down as exceptions ([decision 0006](../decisions/0006-three-equal-configuration-interfaces.md)).

Centre everything on **one local OVDB server per user** at `http://ovdb.localhost:6832`,
started in the background on demand, serving all registered databases, the web console,
the TODO app and a local API, and guarded by Host and Origin checks
([decision 0007](../decisions/0007-local-ovdb-server-and-web-address.md)). CLI data
commands are HTTP clients of it, so apps, agents and the web see the same data at once.
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
server with web console; create inGitDB/SQLite and connect existing storage from a
truthful catalogue; project-scoped context and minimal data commands; TODO demo with web
app; storage and TODO skills with explicit install consent; Explore data hand-off to
DataTug; opt-in telemetry with parity; everything behind `OVDB_PREVIEW=1` until the
founder approves, delivered in vertical increments that each keep parity and the four
canonical journeys passing.

## Not Doing (and Why)

- Redesigning record CRUD, access control, schemas or bulk operations — onboarding needs
  thin verbs over the existing API, not a new data model.
- A hosted cloud onboarding or account flow — local-first product; cloud login exists
  separately.
- Local HTTPS and certificates — adds trust-store changes without protecting loopback
  traffic.
- A built-in data browser in the web console — DataTug is the exploration tool; the TODO
  app covers the demo.
- Full DataTug integration (new DataTug.app routes, nested DTQL) — owned by other
  repositories; recorded as external dependencies.
- A comprehensive storage skill covering tokens, ACLs and schemas — MVP teaches setup and
  the small verb set.
- Every storage engine in guided flows (GitHub-hosted inGitDB, provisioning database
  servers) — only engines the binary really supports, and only local creation.
- Remote OVDB servers as contexts — the context keeps a reserved `server` field.
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
| Should-be-true | DataTug CLI works against a local OVDB server with a placeholder token | First increment runs `datatug query run` end-to-end |
| Might-be-true | Shared multi-user machines are rare enough to defer local authentication | Security review; user reports |

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

## Open Questions

- Vocabulary: onboarding copy says *database*, matching the implemented API
  (`/v1/databases/{id}`) and DataTug's `databaseId`; the hub glossary says *vault*, and
  `openvaultdb-com` decision 0003 (In Review) proposes Host / Vault / Namespace. Should
  *database* be the unit a local OVDB server serves and *vault* stay the app-access
  concept, or should one term win?
- Is loopback without local authentication acceptable for the preview, given shared
  multi-user machines?
- Should SQLite gain schemaless support so it is a friendly second choice, or should
  onboarding keep recommending inGitDB only?

---
*This document follows the https://specscore.md/idea-specification*
