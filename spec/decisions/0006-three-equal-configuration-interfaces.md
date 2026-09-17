---
format: https://specscore.md/decision-specification
status: Draft
---
# Decision: Three equal configuration interfaces over one shared capability layer

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,cli,tui,web-ui,architecture,parity
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

The `ovdb` binary (repository `openvaultdb/ovdb`) is today a flat Cobra command set:
`init`, `serve`, `status`, `databases`, `token`, `cloud`, `self-update`. There is no
local configuration state, no terminal UI, no embedded web assets and no onboarding.
Every client command addresses a server through a hard-coded loopback default.

OpenVaultDB's audience is split. People who live in a terminal expect a CLI and a guided
terminal flow; people who do not expect a browser page; AI agents need deterministic,
non-interactive commands with machine-readable output. The founder asked for three
configuration interfaces that are *equal*: a Cobra CLI, a Bubble Tea terminal UI (TUI)
and a Vue 3 + TypeScript + Vite + Tailwind web UI embedded in the Go binary, with strict
parity. [Reference implementation](../architecture/reference-implementation.md) still
carries the open question "should the reference implementation include a web UI, or is
CLI-first sufficient for MVP?"

Three presentations of the same product drift apart quickly when each owns its own
logic: validation differs, errors are worded differently, one interface gains an option
the others lack, and tests have to be written three times.

## Decision

1. **One capability layer.** All onboarding and configuration behaviour lives in plain Go
   services inside `ovdb` (working name `internal/setup`): local state, database
   registry, server lifecycle, provider catalogue, database context, demo, AI skills,
   explore-data hand-off and telemetry. Services take injected dependencies (filesystem,
   clock, process runner, HTTP client, environment) and return typed results.
2. **Three thin presentations.** The Cobra CLI, the Bubble Tea TUI and the local web
   console only collect input and render results. None of them may implement a rule the
   others cannot reach. The web console reaches the services through a local API mounted
   by the OVDB server under `/api/local/v1/`.
3. **One error vocabulary.** Every service error is a typed value
   `{code, message, reason?, hint}` where `code` is from a closed list, `message` says
   what failed, `reason` says why, and `hint` names the next action (usually a command
   and, where it exists, the matching TUI/web action). All three presentations render
   the same fields with the same wording.
4. **Single-writer rule.** When the local OVDB server is running it is the only process
   that mutates OVDB configuration and data. CLI and TUI then call the services through a
   `setup.Client` that implements the same Go interface over the local API. When the
   server is not running, configuration commands execute the same services in-process.
   Data commands always go through the server (see
   [decision 0007](0007-local-ovdb-server-and-web-address.md)).
5. **Strict parity with explicit exceptions.** Every user-visible capability MUST be
   reachable from the CLI, the TUI and the web console, and MUST be usable by an AI agent
   through the CLI. A capability may be missing from an interface only when the
   [configuration parity feature](../features/configuration-parity/README.md) lists it as
   an exception with a rationale. An exception without a rationale is a defect.
6. **Web stack.** Vue 3, TypeScript, Vite and Tailwind CSS, no component framework, a
   small OVDB component set, source in `web/`, built assets embedded with
   `//go:embed all:dist` and a "not built" fallback page so `go install` works without a
   Node toolchain. Releases and CI build the assets with pnpm.
7. **TUI stack.** `charm.land/bubbletea/v2` and `charm.land/lipgloss/v2`, one root model
   multiplexing screens, model-level unit tests (the `ingitdb-cli` pattern). The TUI is
   launched only when stdout is a terminal and `OVDB_NON_INTERACTIVE` is not set.

## Rationale

- A shared service layer turns "parity" from a review discipline into a structural
  property: an option exists once, so it exists everywhere or visibly nowhere.
- One typed error shape means the TUI, web console and CLI give the same explanation and
  the same next step, which matters more to first-run success than any single screen.
- Running the same acceptance table against the in-process service and the HTTP client
  proves both transports behave identically with one set of tests.
- The single-writer rule avoids two processes rewriting the same YAML files or committing
  to the same inGitDB working tree at once, which is otherwise a real risk when a person
  uses the web console while an agent drives the CLI.
- Embedding the web console keeps OVDB a single binary with a single install step, which
  matches the existing Homebrew cask and GoReleaser distribution.
- The chosen TUI and embedding patterns are already used in the fleet (`ingitdb-cli`
  TUI; `wb` embedded dashboard), so they carry known tests, release hooks and pitfalls.
- This closes the reference implementation's web-UI open question: a web UI is part of
  the MVP, as one of three equal interfaces rather than as the primary one.

## Declined Alternatives

### CLI-first, with TUI and web as later wrappers that shell out to the CLI

Shelling out makes every UI action a subprocess with text parsing, loses typed errors and
makes progress reporting awkward. It also invites UI-only shortcuts once the wrappers
grow. Rejected because it makes parity depend on parsing output rather than sharing code.

### Web console as the primary interface, CLI and TUI as secondary

The web console needs a running server; agents and scripted setups do not want one just
to create a database. Rejected because it makes the least automatable interface the
source of truth.

### Separate web application repository served by its own process

Mirrors `openvaultdb-todo-demo` (separate frontend and backend processes). It adds a
second install step, CORS configuration and version skew between UI and binary. Rejected
for the first-run experience.

### A component framework (Vuetify, PrimeVue, Element Plus) for the web console

Speeds up form building but adds a large dependency and a visual identity that is not
OVDB's. The console has roughly ten screens; a handful of owned components is cheaper to
keep consistent with the TUI's wording and layout. Rejected for MVP.

### Per-interface validation with shared test fixtures only

Keeps presentations independent but still duplicates logic. Rejected because the parity
requirement is about behaviour, and duplicated behaviour drifts even when fixtures agree.

## Consequences at Decision Time

- `ovdb` is restructured from a flat `main` package into internal packages (services,
  CLI, TUI, local API, web assets). Existing commands and flags stay backward compatible
  when their target flags are given explicitly; `ovdb status`, `ovdb databases` and
  `ovdb databases create` without `--url`/`--addr` change their default from "call the
  local server" to "report or change the local setup", which release notes must call out.
- Every new capability requires an entry in the capability matrix and either an
  implementation in all interfaces or a documented exception.
- The binary gains a Node-built asset pipeline for releases and CI; `go install` still
  works but serves a "web console not built into this binary" page.
- A local API surface (`/api/local/v1/`) becomes a maintained, versioned contract between
  the server and the web console, and between the server and CLI/TUI clients.
- The reference implementation's open question on a web UI is closed.
- Cost: three presentations to design and test for every capability; mitigated by the
  shared services and the parity test strategy.

## Observed Consequences

None observed yet.

## Affected Features

- [First-run onboarding](../features/first-run-onboarding/README.md) — defines the shared information architecture rendered by TUI and web.
- [Configuration parity](../features/configuration-parity/README.md) — owns the capability matrix, exceptions and parity tests.
- [Local server and web console](../features/local-server-and-web-console/README.md) — mounts the local API and embedded assets.
- [Database setup and storage choices](../features/database-setup-and-providers/README.md) — first capability exposed through all three interfaces.
- [Telemetry consent](../features/telemetry-consent/README.md) — settings parity across CLI, TUI and web.

---
*This document follows the https://specscore.md/decision-specification*
