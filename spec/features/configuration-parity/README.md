---
format: https://specscore.md/feature-specification
status: Approved
---
# Feature: Configuration parity

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=request-change) |
**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
**Supersedes:** —

## Summary

The normative capability matrix across CLI, TUI, web console and AI agents; the machine
contracts every interface shares (errors, JSON, exit codes, local API, copy); the upstream
changes and increment-0 spikes the work depends on; how parity is tested; and the four
canonical journeys.

Decision: [0006 three equal configuration interfaces](../../decisions/0006-three-equal-configuration-interfaces.md).

## Problem

"Equal interfaces" drift without one list of capabilities, one set of contracts and a test
that fails when an interface misses something. Agents are a primary audience and need
stable JSON; the plan also depends on changes in other repositories that must be proven
before building on them.

## Behavior

### Capability matrix

Agents use the CLI non-interactively with `--json`. "—" is a documented exception.

| # | Capability | CLI | TUI | Web console | AI agent |
|---|---|---|---|---|---|
| 1 | Guided first run | `ovdb` (non-TTY: status + `next`) | Home | Home | `ovdb status --json` |
| 2 | Whole-setup status | `ovdb status` | Home status line | Home status line | `ovdb status --json` |
| 3 | Start server | `ovdb server start` | Start the OVDB server | — (E1) | `ovdb server start` |
| 4 | Server status | `ovdb server status` | OVDB server | OVDB server | `--json` |
| 5 | Stop or restart server | `ovdb server stop`, `ovdb server restart` | OVDB server | — (E2) | same as CLI |
| 6 | Open web console (login link) | `ovdb open` | Open in browser | — (E1) | `ovdb open --print-url` |
| 7 | Change server port | `ovdb config set server.port` | Settings | Settings (next start) | same as CLI |
| 8 | Storage choices | `ovdb engines` | Create/Connect picker | Create/Connect picker | `ovdb engines --json` |
| 9 | Create database (inGitDB, SQLite) | `ovdb databases create` | Create a database | Create a database | same, after asking |
| 10 | Connect existing inGitDB folder or SQLite file | `ovdb databases connect --path` | Connect an existing database | Connect an existing database | same, after asking |
| 10a | Connect with a manifest file (any engine) | `ovdb databases connect --manifest` | Connect with a manifest file | Connect with a manifest file | same, after asking |
| 11 | List databases | `ovdb databases` | Databases | Databases | `--json` |
| 12 | Remove database registration | `ovdb databases remove` | Databases | Databases | same, after asking |
| 12a | Reload databases | `ovdb databases reload <id>\|--all` | Databases (Reload) | Databases (Reload) | same as CLI |
| 13 | Choose current database | `ovdb use`, `ovdb use --global` | Use in this project | Use as default (E3) | `--db` preferred |
| 14 | Show current database | `ovdb use`, `ovdb pwd` | Home status line | Home status line | `ovdb pwd --json` |
| 15 | Browse data (read-only) | `ovdb list`, `ovdb get` | Browse data | Browse data | same as CLI |
| 16 | Navigate paths | `ovdb cd`, `ovdb pwd` | — (E4) | — (E4) | absolute paths instead |
| 17 | Write records | `ovdb set/add/delete` | — (E5) | — (E5; TODO app for demo data) | same as CLI |
| 18 | Install TODO demo | `ovdb demo install` | Try a demo | Try a demo | `--yes` |
| 19 | Open TODO app | `ovdb demo open` | Open TODO app | Open TODO app | `--print-url` |
| 20 | List AI skills | `ovdb skills list` | AI agent skills | AI agent skills | `--json` |
| 21 | Install AI skill | `ovdb skills install` | AI agent skills | AI agent skills | `--yes` relaying the person's yes (E6) |
| 22 | Explore data (DataTug guidance) | `ovdb explore` | Explore data | Explore data | `--json` |
| 23 | Telemetry status | `ovdb telemetry status` | Settings | Settings | `--json` |
| 24 | Turn telemetry on or off | `ovdb telemetry enable/disable` | Settings, one-time prompt | Settings, one-time prompt | `--confirmed-by-user` relaying the answer (E6) |
| 25 | Access tokens and browser app origins | `ovdb token create/list/revoke`, `ovdb config set server.cors` | — (E7) | — (E7; connect-flow consent page) | same as CLI |

#### REQ: matrix-is-normative

Every capability MUST be implemented in every non-exception cell using the same server
service and copy keys. A new user-visible onboarding or configuration capability MUST add a
row in the same change.

### Documented exceptions

| Id | Exception | Rationale |
|---|---|---|
| E1 | Web console cannot start the server or open itself | The page is served by the server; reaching it means it runs and is open. |
| E2 | Web console cannot stop or restart the server | Stopping kills the page's own backend and strands people without a terminal; CLI, TUI and agents can stop it. |
| E3 | Web console sets only the global default | The browser has no working directory; project contexts are set by CLI and TUI ([decision 0008](../../decisions/0008-database-context-scope.md)). |
| E4 | No `cd` in TUI or web | They show a browsable tree; a working directory is a shell concept. |
| E5 | Record editing is CLI, agents and apps only | OVDB is not a database admin tool; DataTug owns exploration, apps own editing. |
| E6 | Agents run consent-type commands only as a relay | Skill installs and telemetry are human decisions; enforced by `--yes`/`--confirmed-by-user` and skill text, not cryptographically. |
| E7 | Access tokens and CORS origins are CLI only | Developer settings for tools and third-party apps; people grant apps access through the connect flow's consent page instead. |

#### REQ: exceptions-need-rationale

An interface MAY lack a capability only through an exception above. Code MUST reference the
exception id, and the parity test MUST fail for a missing cell without one.

### Machine contracts

#### REQ: error-envelope

Every failure MUST be `{"schema":1,"error":{"code","message","reason"?,"next":[{"label","command"?,"action"?}]}}`,
built by the server or the shared Go package, never by a presentation. `code` MUST be one
of: `invalid_argument`, `confirmation_required`, `not_found`, `already_exists`,
`location_not_empty`, `port_in_use`, `port_unavailable`, `server_not_running`,
`server_start_failed`, `server_version_mismatch`, `server_config_mismatch`, `unauthorized`,
`forbidden`, `storage_unavailable`, `schema_required`, `validation_failed`, `unsupported`,
`dependency_missing`, `internal`. `action` names an in-UI remedy (for example `use_port`);
`command` is always runnable.

| Code | Local API HTTP status | `/v1` error codes mapped to it (human output) |
|---|---|---|
| `invalid_argument` | 400 | `bad_request`, `invalid_dtql`, `invalid_key` |
| `confirmation_required` | 400 | — |
| `unauthorized` | 401 | HTTP 401, `invalid_grant` |
| `forbidden` | 403 | `forbidden`, `access_denied` |
| `not_found` | 404 | `not_found` |
| `already_exists` | 409 | `already_exists` |
| `location_not_empty` | 409 | — |
| `server_version_mismatch` | 409 | — |
| `schema_required` | 422 | `schema_validation` when the collection has no declared schema |
| `validation_failed` | 422 | `schema_validation` otherwise |
| `unsupported` | 501 | `not_supported`, `authorization_unsupported` |
| `storage_unavailable` | 503 | `authorization_unavailable`, `git_identity_missing` (local mode only, a write into a Git-backed database with no `git config --global user.name`/`user.email`) |
| `internal` | 500 | `internal` and any unknown code |
| `port_in_use`, `port_unavailable`, `server_not_running`, `server_start_failed`, `server_config_mismatch`, `dependency_missing` | client-side only | — |

#### REQ: json-equals-api

For configuration commands, `--json` output MUST be byte-for-byte the local API response body
(success or error envelope) with top-level `"schema": 1`; pure reads without a server MUST
produce the same schema with `server.state` `not_running` and mount state `unknown`. For data
commands, `--json` MUST print the existing `/v1` response bodies of `list` and `get`, each
record gaining one CLI-added absolute `path` field alongside the server's untouched `key` and
`data`, and the `/v1` error bodies of all five unchanged, and for `set`, `add` and `delete` (no
`/v1` body) exactly `{"key":"<absolute escaped path>"}`, as documented in
[database context and navigation](../database-context-navigation/README.md), while human
output maps `/v1` errors into the envelope using the table above. Only JSON goes to stdout
with `--json`; notices (such as auto-start, or a skipped stale project context) go to stderr.

#### REQ: exit-codes

New commands MUST exit `0` on success and `1` on any failure, including usage errors
(`invalid_argument`) and missing confirmation (`confirmation_required`).

#### REQ: local-api-endpoints

The local API MUST provide at least these endpoints, versioned by the `v1` path segment and
authenticated as in the credential table of
[local server and web console](../local-server-and-web-console/README.md):

| Method and path | Capability |
|---|---|
| `GET /api/local/v1/whoami` | Instance id and version (server identity) |
| `GET /api/local/v1/status` | 1, 2, 14 |
| `GET /api/local/v1/server` | 4 (`--json` body shared by `server start`, `server stop`, `server restart` and `server status`; includes `next`) |
| `GET /api/local/v1/home` | 1 (Home document: status line and ordered options — `label_key`, `web_label_key`, `description_key`, `badge` — plus `next`; shared by TUI and web) |
| `POST /api/local/v1/server/shutdown` | 5 (instance secret only) |
| `POST /api/local/v1/login-links` | 6, 19 (instance secret only) |
| `POST /logout` | Sign out (clears the console session; see [local server and web console](../local-server-and-web-console/README.md#REQ:logout)) |
| `GET /api/local/v1/engines` | 8 (sorted and pinned server-side) |
| `GET/POST /api/local/v1/databases`, `DELETE /api/local/v1/databases/{id}` | 9, 11, 12 |
| `POST /api/local/v1/databases/connect` | 10, 10a |
| `POST /api/local/v1/databases/{id}/reload`, `POST /api/local/v1/databases/reload-all` | 12a |
| `GET/PUT /api/local/v1/context` | 13, 14 (project scope with instance secret only) |
| `GET /api/local/v1/demo`, `POST /api/local/v1/demo/install` | 18, 19 |
| `GET /api/local/v1/skills`, `POST /api/local/v1/skills/install` | 20, 21 |
| `POST /api/local/v1/explore/datatug?db=&collection=` | 22 (POST, not GET: it writes the descriptor, and only when the person actually chooses DataTug CLI — [explore-data-handoff](../explore-data-handoff/README.md#REQ:prepare-datatug-cli-connection)) |
| `GET/PUT /api/local/v1/telemetry`, `POST /api/local/v1/telemetry/events` | 23, 24 |
| `GET/PUT /api/local/v1/config` | 7 (`PUT` response includes `changed`) |
| existing `/v1/databases/{db}/…`, `/v1/tokens` | 15, 17, 25 |

GET handlers MUST have no side effects; POST/PUT bodies MUST be `application/json`.
Requests carry client-resolved values (skill directories, absolute data home) where needed.

#### REQ: copy-catalogue

All user-facing strings MUST come from one `copy/en.json` with `{name}` placeholders,
embedded in Go and imported by the Vue build. Services return copy keys with parameters;
CLI, TUI and web render them. A test MUST fail when a referenced key is missing.

### External changes

The work depends on these upstream changes, owned by the same organisation.

| Repository | Change |
|---|---|
| `openvaultdb/ovdb` | Upgrade to `openvaultdb-go` v0.5.1 or later; auth store at `<OVDB_HOME>/auth.json` instead of the working directory |
| `openvaultdb/openvaultdb-go` | Exported runtime `Mount`/`Unmount` on the server, safe with in-flight requests |
| `openvaultdb/openvaultdb-go` | Tolerant registry scan: one broken manifest does not stop others (`mount.Dir` returns on first error today); failures reported per database |
| `openvaultdb/openvaultdb-go` | Configurable inferred-schema catalogue location (today `<folder>/.ovdb/…` or `<file>.inferred.json`) and no git identity change on mount (`ensureGitIdentity`), so connecting does not write into user storage |
| `openvaultdb/openvaultdb-go` | Nested-collection queries (follow-up; needed for DataTug to show demo items) |
| `strongo/cli-helpers` | Detached process start (lifted from `wb` `internal/process/detach_*`) |
| `strongo/cli-helpers` | Per-skill (per-bundle) install in `skillsync` |
| `dal-go/dalgo2postgres`, `dal-go/dalgo2mysql` | Stop formatting the connection string into errors |

#### REQ: increment-zero-spikes

Increment 0 consists of these spikes. Each MUST be proven, with a pass/fail note and evidence,
before the first increment that depends on it (not all before any increment); a failed spike
MUST change the specification before that increment starts:
S1 `openvaultdb-go` upgrade with Mount/Unmount, tolerant scan and side-effect-free mount;
S2 detached start, authenticated readiness and shutdown on Linux, macOS and Windows;
S3 embedded Vue build through the release pipeline with the `.gitkeep` fallback;
S4 DataTug CLI end-to-end against a local-mode server with a read-only token from `ovdb token create`;
S5 `skillsync` per-skill install;
S6 `copy/en.json` shared by Go and Vite;
S7 credential table, POST login exchange on both hosts, persisted `SameSite=Lax` sessions, cookie-only `http.CrossOriginProtection`, `server.cors`, Host allowlist and CSP;
S8 a founder-run manual check in Safari (macOS) and Edge (Windows): the login link signs in on
`ovdb.localhost` and `127.0.0.1` and the session survives a reload and a server restart.

### Tests

#### REQ: capability-registry

`ovdb` MUST contain a registry listing, per matrix row, the CLI command, TUI screen id, web
route, local API endpoint and exception ids. A test MUST verify that each named command,
screen, route and endpoint exists.

#### REQ: presentation-tests

Each capability MUST have service tests in the server, CLI tests for text, `--json` and
exit codes, and TUI model tests. Web components MUST have unit tests. Browser tests run per
journey plus one smoke test per route, not per capability.

#### REQ: ci-matrix

CI MUST run Go unit tests for lifecycle, paths and context on Ubuntu, macOS and Windows
runners, and Playwright (Chromium) journeys on Linux. Safari, Edge and `*.localhost`
resolution are a manual checklist.

#### REQ: public-cli-parity-accounting

Every named user-facing CLI command MUST remain visible without `OVDB_PREVIEW`. Missing
non-CLI cells MUST remain explicit in the capability matrix as incomplete or as a justified
exception; they gate release-readiness claims, not CLI help. Only the unfinished bare-command
TUI remains preview-gated, and `server run` remains internal.

### Canonical journeys

Each journey has an automated form (CI) and a manual checklist run on at least one OS per
increment and on all three before the gate is removed.

#### REQ: journey-a-terminal

**A — terminal.** A person runs `ovdb`, chooses Create a database, keeps inGitDB and the
suggested location, names it `notes`, chooses Use in this project, answers the telemetry
prompt, and quits. Then `ovdb add /items '{"title":"Hello"}'` and `ovdb list /items` work
without `--db`.

#### REQ: journey-b-web

**B — web.** A person opens a login link given by their AI assistant, by `ovdb open` or by
the TUI's Open in browser (the server is started by whichever gave the link). They create a
database, browse it, set it as default, turn telemetry off in Settings and open Explore
data, seeing the same wording as the TUI. Opening the bare address without a session shows
the landing page with `ovdb open` and "ask your AI assistant". A no-terminal, no-agent cold
start (login item or OS service) is deferred.

#### REQ: journey-c-agent

**C — AI agent.** An agent without any OVDB skill runs `ovdb status --json`, relays the
`next` options (terminal setup, web setup, set up with commands, try the demo, install the
skill), and on "set it up for you" creates a database, selects it for the project, stores
and reads a record with absolute paths — no command waits for input and telemetry stays
`not asked`.

#### REQ: journey-d-todo-demo

**D — TODO demo.** A person chooses Try a demo, opens the TODO app, installs the TODO AI
skill after the consent step, asks an agent to "add tea to my shopping list and Arrival to
my watch list" (items not already in the seed, so a real change is visible), sees both items
appear in the open app, then opens Explore data and reads that DataTug shows the lists but
not their items yet.

## Dependencies

- first-run-onboarding
- local-server-and-web-console
- database-setup-and-providers
- database-context-navigation
- todo-demo
- ai-agent-skills
- explore-data-handoff
- telemetry-consent

## Acceptance Criteria

### AC: missing-cell-fails (verifies REQ:matrix-is-normative, REQ:exceptions-need-rationale, REQ:capability-registry)

**Given** the capability registry
**When** the web route for "Remove database registration" is removed without adding an exception
**Then** the parity test fails naming capability 12 and the web console

### AC: error-envelope-shape (verifies REQ:error-envelope, REQ:json-equals-api, REQ:exit-codes)

**Given** port 6832 held by a non-OVDB program
**When** `ovdb server start --json` runs
**Then** stdout is exactly one JSON object with `schema` 1 and `error.code` `port_in_use`, `next` contains a runnable `ovdb server start --port 6833` entry, and the exit code is `1`

### AC: cli-json-matches-api (verifies REQ:json-equals-api)

**Given** a running server with two databases
**When** `ovdb databases --json` runs and `GET /api/local/v1/databases` is called with the instance secret
**Then** both bodies are identical

### AC: usage-error-exits-one (verifies REQ:exit-codes)

**Given** any new command
**When** it is called with an unknown flag, or without `--yes` where confirmation is required in a non-interactive environment
**Then** it exits `1` with code `invalid_argument` or `confirmation_required`

### AC: endpoints-authenticated (verifies REQ:local-api-endpoints)

**Given** a running local-mode server
**When** each endpoint in the table is called without credentials
**Then** each returns `401` with `unauthorized`, and `PUT /api/local/v1/context` with project scope using only a session cookie is refused

### AC: copy-key-missing-fails (verifies REQ:copy-catalogue)

**Given** a TUI screen and a Vue component each referencing a key absent from `copy/en.json`
**When** the Go and web test suites run
**Then** both fail naming the key

### AC: spikes-recorded (verifies REQ:increment-zero-spikes)

**Given** a feature increment that depends on spikes
**When** that increment starts
**Then** each of its spikes has a recorded pass or fail with evidence, and any failed one has already changed the specification

### AC: tests-per-capability (verifies REQ:presentation-tests)

**Given** the registry
**When** the coverage check lists tests per capability
**Then** every non-exception cell has service, CLI and TUI tests or a web unit test, and each journey has one browser test

### AC: ci-runs-matrix (verifies REQ:ci-matrix)

**Given** a pull request to `ovdb`
**When** CI runs
**Then** lifecycle, path and context tests pass on Ubuntu, macOS and Windows, and the Playwright journeys pass on Linux

### AC: public-cli-reports-incomplete-parity (verifies REQ:public-cli-parity-accounting)

**Given** Connect exists in CLI and TUI but not yet in the web console
**When** OVDB runs without `OVDB_PREVIEW`
**Then** `ovdb databases --help` lists `connect`, the matrix still marks the missing web cell, bare `ovdb` behaves as today, and `ovdb server --help` does not list internal `run`

### AC: journey-a-passes (verifies REQ:journey-a-terminal)

**Given** temporary `OVDB_HOME` and `OVDB_DATA_HOME`
**When** the Journey A TUI model script and CLI assertions run
**Then** `ovdb list /items` shows "Hello" with the database from the project context

### AC: journey-b-passes (verifies REQ:journey-b-web)

**Given** `ovdb open --print-url` in a fresh setup
**When** Playwright opens the link and runs Journey B, and separately opens the bare address
**Then** the database exists and is browsable, `ovdb pwd` outside a project reports it from the global default, telemetry is `disabled`, and the bare address shows the landing page

### AC: journey-c-passes (verifies REQ:journey-c-agent)

**Given** stdin closed, `CLAUDECODE=1` and no skills installed
**When** the Journey C command script runs
**Then** `ovdb status --json` lists the five `next` entries, every command finishes, the record round-trips, and telemetry is still `not_asked`

### AC: journey-d-passes (verifies REQ:journey-d-todo-demo)

**Given** a fresh setup
**When** Journey D runs with the agent step simulated by two `ovdb add` commands (Tea to
`/lists/to-buy/items`, Arrival to `/lists/to-watch/items`)
**Then** Tea and Arrival appear in the open TODO app within 3 seconds, and Explore data for `todo` states that items are not shown in DataTug yet

## Open Questions

- Should the capability matrix live as data (YAML) that generates both the Go registry and
  this table?
- Is a pseudo-terminal end-to-end test for Journey A worth its flakiness on Windows?

---
*This document follows the https://specscore.md/feature-specification*
