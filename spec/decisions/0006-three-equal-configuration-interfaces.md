---
format: https://specscore.md/decision-specification
status: Approved
---
# Decision: Three equal configuration interfaces over one shared capability layer

**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,cli,tui,web-ui,architecture,parity
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

The `ovdb` binary (repository `openvaultdb/ovdb`) is a flat Cobra command set: `init`,
`serve`, `status`, `databases`, `token`, `cloud`, `self-update`. It has no local
configuration state, no terminal UI, no embedded web assets and no onboarding, and it
depends on `openvaultdb-go` v0.2.0 (latest v0.5.1).

OpenVaultDB's audience is split: terminal users, browser users, and AI agents that need
deterministic, non-interactive commands with machine-readable output. The founder asked
for three *equal* configuration interfaces — a Cobra CLI, a Bubble Tea TUI and a Vue 3 +
TypeScript + Vite + Tailwind web UI embedded in the binary — with strict parity, and for
the CLI to work over HTTP. [Reference implementation](../architecture/reference-implementation.md)
still asked "web UI, or CLI-first?".

Presentations that each own logic drift: validation differs, errors are worded
differently, one interface gains options the others lack.

## Decision

1. **One capability layer, inside the server.** All onboarding, configuration and data
   behaviour lives in Go services (working name `internal/setup`) that run **only in the
   local OVDB server process**. Services return typed results, computed next actions and
   typed errors; presentations never compute hints, sorting or validation.
2. **One transport.** Every configuration mutation and every data operation from the CLI,
   the TUI and the web console is an authenticated HTTP call to the local server
   (`/api/local/v1/…` and the existing `/v1/…` data API). If the server is not running, the
   CLI and TUI start it in the background, say so in one line, and continue; `--no-start`
   refuses instead. The server holds one exclusive home lock, so it is the only writer.
   Clients resolve environment-dependent inputs (skill directories, data home, telemetry
   opt-outs) and send them with each request.
3. **Pure reads without a server.** `ovdb status`, `ovdb pwd`, `ovdb engines`,
   `ovdb databases`, `ovdb skills list` and `ovdb telemetry status` read state files
   directly through the same Go package the server uses, so status works before anything
   has started.
4. **Machine contracts defined once** (in [configuration parity](../features/configuration-parity/README.md)):
   an error envelope `{code, message, reason?, next[]}` with a closed `code` list; `--json`
   output of configuration commands identical to the local API response body with
   `"schema": 1`, and of data commands identical to the existing `/v1` bodies (writes, which have
   no `/v1` body, print `{"key"}`); exit codes `0`
   success and `1` any failure (the existing `ovdb` contract); one copy catalogue
   `copy/en.json` embedded in Go and imported by the Vue build.
5. **Strict parity with explicit exceptions.** Every user-visible capability is reachable
   from the CLI, the TUI and the web console, and usable by an AI agent through the CLI,
   unless the parity feature lists an exception with a rationale.
6. **Web stack.** Vue 3, TypeScript, Vite, Tailwind CSS, no component framework, source in
   `web/`, assets embedded with `//go:embed all:dist` (tracked `.gitkeep`) and a "not built"
   page so `go install` compiles without Node. Releases and CI build assets with pnpm.
7. **TUI stack.** `charm.land/bubbletea/v2` and `charm.land/lipgloss/v2`, one root model
   multiplexing screens, model-level unit tests (the `ingitdb-cli` pattern), launched only
   when stdin and stdout are terminals, `OVDB_NON_INTERACTIVE` is unset and the preview gate
   is on.

## Rationale

- Services computing everything (including next actions and catalogue order) turn parity
  into a structural property: an option exists once, so it exists everywhere or visibly
  nowhere.
- A single transport matches the founder's "CLI over HTTP", gives one write path, and makes
  the server the single writer by construction — no lock choreography between in-process
  writers and a server that may auto-start mid-operation.
- Allowing pure reads from files keeps `ovdb status` instant and useful for agents on a
  machine where nothing has started yet, without creating a second write path.
- Output identical to API bodies means agents, the web console and tests share one schema.
- Embedding keeps OVDB one binary with one install step, matching the Homebrew cask and
  GoReleaser distribution. The TUI and embedding patterns already exist in the fleet
  (`ingitdb-cli` TUI, `wb` dashboard).
- This closes the reference implementation's web-UI question: the web UI is one of three
  equal interfaces, not the primary one.

## Declined Alternatives

### Two transports of one interface (in-process when no server, HTTP when running)

The first draft of this decision. Declined after review: every mutation gets two code
paths and a "transports agree" test matrix, and there is a race when a CLI writes
in-process while another agent's command auto-starts the server over the same files.

### CLI-first, with TUI and web as wrappers that shell out to the CLI

Every UI action becomes a subprocess with text parsing, losing typed errors and progress.
Declined because parity would depend on parsing output.

### Web console as the primary interface

Agents and scripts cannot use a browser flow. Declined: the least automatable interface
would be the source of truth.

### Separate web application repository and process

Adds a second install step, CORS configuration and version skew between UI and binary.
Declined for first run.

### A component framework (Vuetify, PrimeVue, Element Plus)

Large dependency and a foreign visual identity for about ten screens. Declined for MVP.

### Exit code 2 for usage errors

Would change `ovdb`'s documented two-code contract (`self-update`) and fang's handling.
Declined; usage errors exit `1` with code `invalid_argument`.

## Consequences at Decision Time

- `ovdb` is restructured into internal packages (services, CLI, TUI, local API, web) and
  upgraded to current `openvaultdb-go`; required upstream changes are listed under External
  changes in the parity feature and proven in increment 0.
- Configuration commands need a running server; the first such command pays a background
  start (target under 2 s).
- Existing commands (`status`, `databases`, `databases create`, `serve`, `init`, `token`)
  keep today's behaviour unless `OVDB_PREVIEW=1`; post-gate changes need release notes.
- A versioned local API becomes a maintained contract.
- Every new capability needs a matrix row and either an implementation everywhere or an
  exception.

## Observed Consequences

- 2026-09-17 (increment 1a): The single-transport rule (Decision point 2) has one narrow
  exception, found while building the port-conflict remedy. `ovdb config set` writes directly
  to `config.yaml` under an exclusively held `home.lock` when no server is running, taking the
  lock itself for that single write, because the remedy it offers
  (`ovdb config set server.port <N+1>`) must work precisely when the server cannot start and so
  cannot depend on a server being reachable. When a server is running, `config set` goes through
  it like every other mutation.

## Affected Features

- [First-run onboarding](../features/first-run-onboarding/README.md) — shared information architecture rendered by TUI and web.
- [Configuration parity](../features/configuration-parity/README.md) — capability matrix, machine contracts, external changes, tests.
- [Local server and web console](../features/local-server-and-web-console/README.md) — hosts the services, local API and assets.
- [Database setup and storage choices](../features/database-setup-and-providers/README.md) — first capability exposed through all interfaces.
- [Telemetry consent](../features/telemetry-consent/README.md) — settings parity across CLI, TUI and web.

---
*This document follows the https://specscore.md/decision-specification*
