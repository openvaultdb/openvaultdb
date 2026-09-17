---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Configuration parity

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/configuration-parity?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

The normative capability matrix for OVDB onboarding and configuration across the CLI, the
TUI, the web console and AI agents, the documented exceptions with their reasons, how
parity is tested, and the four canonical journeys every increment is checked against.

Decision: [0006 three equal configuration interfaces](../../decisions/0006-three-equal-configuration-interfaces.md).

## Problem

"Equal interfaces" is easy to promise and hard to keep. Without one list of capabilities
and a test that fails when an interface misses one, the web console will lag the CLI, the
TUI will gain a shortcut nobody else has, and agents will hit a step only a human can do.

## Behavior

### Capability matrix

AI agents use the CLI non-interactively with `--json`; the agent column shows the form
they use. "—" means a documented exception below.

| # | Capability | CLI | TUI | Web console | AI agent |
|---|---|---|---|---|---|
| 1 | Guided first run | `ovdb` (non-TTY: status + next commands) | Home | Home | `ovdb status --json` |
| 2 | Whole-setup status | `ovdb status` | Home status line | Home status line | `ovdb status --json` |
| 3 | Start server | `ovdb server start` | Start the OVDB server | — (E1) | `ovdb server start` |
| 4 | Server status | `ovdb server status` | OVDB server | OVDB server | `ovdb server status --json` |
| 5 | Stop server | `ovdb server stop` | OVDB server | OVDB server (confirm) | `ovdb server stop` |
| 6 | Open web console | `ovdb open` | OVDB server › Open in browser | — (E2) | `ovdb open --print-url` |
| 7 | Change server port | `ovdb config set server.port` | Settings | Settings | same as CLI |
| 8 | List and filter storage choices | `ovdb engines --filter` | Create/Connect picker | Create/Connect picker | `ovdb engines --json` |
| 9 | Create database (inGitDB, SQLite) | `ovdb databases create` | Create a database | Create a database | same as CLI, after asking the person |
| 10 | Connect existing database | `ovdb databases connect` | Connect an existing database | Connect an existing database | same as CLI, after asking |
| 11 | List databases | `ovdb databases` | Databases | Databases | `ovdb databases --json` |
| 12 | Remove database registration | `ovdb databases remove` | Databases | Databases | same as CLI, after asking |
| 13 | Choose current database | `ovdb use`, `ovdb use --global` | Databases › Use in this project | Databases › Use as default (E3) | `--db` on each command (preferred) or `ovdb use` |
| 14 | Show current database | `ovdb use`, `ovdb pwd` | Home status line | Home status line | `ovdb pwd --json` |
| 15 | Navigate paths | `ovdb cd`, `ovdb pwd` | — (E4) | — (E4) | same as CLI |
| 16 | Read and write records | `ovdb list/get/set/add/delete` | — (E4) | — (E4; TODO app for demo data) | same as CLI with `--json` |
| 17 | Install TODO demo | `ovdb demo install` | Try a demo | Try a demo | `ovdb demo install --yes` |
| 18 | Open TODO app | `ovdb demo open` | Result › Open TODO app | Result › Open TODO app | `ovdb demo open --print-url` |
| 19 | Demo status | `ovdb demo status` | Home status line | Home status line | `ovdb demo status --json` |
| 20 | List AI skills | `ovdb skills list` | AI agent skills | AI agent skills | `ovdb skills list --json` |
| 21 | Install AI skill | `ovdb skills install` | AI agent skills / demo Result | AI agent skills / demo Result | `--yes` only relaying the person's explicit yes (E5) |
| 22 | Uninstall AI skill | `ovdb skills uninstall` | AI agent skills | AI agent skills | same as CLI, after asking |
| 23 | Explore data: choose tool | `ovdb explore` | Explore data | Explore data | `ovdb explore --json` |
| 24 | Prepare DataTug CLI connection | `ovdb explore datatug-cli` | DataTug CLI | DataTug CLI (show and copy) | same as CLI |
| 25 | Run DataTug CLI now | `ovdb explore datatug-cli --run` | Run it now | — (E6) | same as CLI |
| 26 | DataTug.app guidance | `ovdb explore datatug-app` | DataTug.app | DataTug.app | same as CLI |
| 27 | Telemetry status | `ovdb telemetry status` | Settings | Settings | `ovdb telemetry status --json` |
| 28 | Turn telemetry on or off | `ovdb telemetry enable/disable` | Settings, one-time prompt | Settings, one-time prompt | only relaying the person's answer (E5) |

#### REQ: matrix-is-normative

Every capability in the matrix MUST be implemented in every interface cell that is not a
documented exception, using the same shared service and message catalogue. Adding a
user-visible onboarding or configuration capability MUST add a row to this matrix in the
same change.

### Documented exceptions

| Id | Exception | Rationale |
|---|---|---|
| E1 | The web console cannot start the server | The page is served by the server; if it is reachable, the server is running. The page shows how to start it again after a stop. |
| E2 | The web console has no "open web console" action | It is already open. |
| E3 | Web console sets the *global default*, TUI sets the *project context* | The browser has no working directory, so it cannot know a project; the TUI runs in one. Both show which scope they changed. |
| E4 | Path navigation and record commands are CLI and agent only | They exist for scripts and agents; a data browser is out of scope and DataTug is the exploration tool. The TODO app covers the demo data. |
| E5 | Agents may run consent-type commands only as a relay | Skills and telemetry consent are human decisions; the command cannot tell a relayed answer from an assumed one, so the rule is enforced in skill instructions and `--yes` requirements. |
| E6 | The web console cannot run DataTug | A browser page must not run programs on the person's computer through the local server; it shows the commands to copy. |

#### REQ: exceptions-need-rationale

An interface MAY lack a capability only through an exception listed in this table with a
rationale. Code MUST reference the exception id, and the parity test MUST fail for a
missing capability without a matching exception.

### Parity test strategy

#### REQ: capability-registry

`ovdb` MUST contain a capability registry: for each matrix row, its id, the CLI command,
the TUI screen id, the web route and local API endpoint, and exception ids. A test MUST
verify that each CLI command, TUI screen, web route and endpoint named in the registry
exists, and MUST generate a matrix document that is compared with the committed copy.

#### REQ: one-acceptance-table-two-transports

Service acceptance tests MUST be written once as a table and run against both the
in-process services and the `setup.Client` HTTP implementation talking to a real local
server in a temporary OVDB home, with identical expected results and errors.

#### REQ: presentation-tests

Each capability MUST have: CLI tests for text and `--json` output and exit codes; TUI
model tests that reach it by key messages and assert on the rendered view; web unit tests
for its components and a browser test for its route against a real `ovdb` server. Tests
MUST assert catalogue keys, not duplicated literal strings.

#### REQ: increments-keep-parity

A capability MUST NOT be visible outside the preview gate in any interface until all its
non-exception cells are implemented and tested. Increments MAY land partially behind
`OVDB_PREVIEW=1`.

### Canonical journeys

Every increment that touches onboarding MUST keep these four journeys passing: automated
where stated, and run manually by a person on at least one OS per increment and on Linux,
macOS and Windows before the preview gate is removed.

#### REQ: journey-a-terminal

**Journey A — terminal.** In a terminal with a fresh OVDB home, a person runs `ovdb`,
chooses Create a database, keeps inGitDB and the suggested location, names it `notes`,
chooses Use in this project on the Result, answers the telemetry prompt, and quits. Then
`ovdb add /items '{"title":"Hello"}'` and `ovdb list /items` work without `--db`.
Automated: TUI model-driven script plus CLI assertions.

#### REQ: journey-b-web

**Journey B — web.** With the server started by `ovdb open` (by the person or an agent),
a person on `http://ovdb.localhost:6832` who never used the TUI creates a database, sets
it as default, turns telemetry off in Settings, and opens Explore data; each step shows
the same wording as the TUI. Automated: browser test against a real server.

#### REQ: journey-c-agent

**Journey C — AI agent.** With `ovdb` installed and the storage skill installed, an agent
in a project with no OVDB setup runs `ovdb status --json`, offers the three setup paths
and the demo, and on "set it up for you" creates a database, selects it for the project,
stores and reads a record — without any command waiting for input and without changing
the telemetry state. Automated: a non-interactive command script with stdin closed;
manual: a live agent session.

#### REQ: journey-d-todo-demo

**Journey D — TODO demo.** A person chooses Try a demo (TUI or web), opens the TODO app,
installs the TODO AI skill after the consent step, asks an agent to "add bananas and
coffee to my shopping list", sees both items appear in the open app, then chooses Explore
data › DataTug CLI and sees the prepared command. Automated: CLI install, browser test of
the app with CLI-made changes; manual: the live agent step.

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
**When** a developer removes the web route for "Remove database registration" without adding an exception
**Then** the parity test fails naming capability 12 and the web console

### AC: registry-doc-in-sync (verifies REQ:capability-registry)

**Given** a registry change that adds a capability
**When** the tests run without regenerating the committed matrix document
**Then** the test fails and shows the difference

### AC: transports-agree (verifies REQ:one-acceptance-table-two-transports)

**Given** the service acceptance table including creation conflicts, port conflicts, demo reinstall and telemetry changes
**When** it runs in-process and over HTTP
**Then** both produce identical results and error codes, reasons and hints

### AC: presentation-coverage (verifies REQ:presentation-tests)

**Given** the capability registry
**When** the coverage check lists tests per capability and interface
**Then** every non-exception cell has at least one CLI, TUI or web test as appropriate, and no test asserts a catalogue string by literal

### AC: gate-hides-incomplete (verifies REQ:increments-keep-parity)

**Given** an increment where Connect an existing database exists in CLI and TUI but not yet in the web console
**When** OVDB runs without `OVDB_PREVIEW`
**Then** `ovdb --help` does not list `databases connect`, and the TUI Home is not shown

### AC: journey-a-passes (verifies REQ:journey-a-terminal)

**Given** a fresh OVDB home and a terminal
**When** Journey A is executed by its automated script and manually
**Then** every step completes, and the final `ovdb list /items` shows "Hello" with the database taken from the project context

### AC: journey-b-passes (verifies REQ:journey-b-web)

**Given** a fresh OVDB home and `ovdb open`
**When** Journey B runs in the browser test and manually
**Then** the database exists, `ovdb pwd` in a directory without project context reports it from the global default, telemetry is `disabled`, and screen texts match the catalogue

### AC: journey-c-passes (verifies REQ:journey-c-agent)

**Given** stdin closed and `CLAUDECODE=1`
**When** the Journey C command script runs
**Then** every command exits within its timeout, the record round-trips, and `ovdb telemetry status --json` still reports `not_asked`

### AC: journey-d-passes (verifies REQ:journey-d-todo-demo)

**Given** a fresh OVDB home
**When** Journey D runs with the agent step simulated by two `ovdb add` commands in the automated test, and with a live agent manually
**Then** Bananas and Coffee appear in the open TODO app within 3 seconds, and Explore data shows the DataTug CLI command for `todo`

## Open Questions

- Should the web console gain a read-only data browser later, removing part of E4, or
  should that remain DataTug's role?
- Is a pseudo-terminal end-to-end test for Journey A worth its flakiness on Windows, or are
  model-level tests plus the manual run enough?

---
*This document follows the https://specscore.md/feature-specification*
