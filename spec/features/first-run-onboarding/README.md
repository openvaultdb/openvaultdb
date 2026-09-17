---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: First-run onboarding

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/first-run-onboarding?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/first-run-onboarding?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/first-run-onboarding?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/first-run-onboarding?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

The first thing a person sees when they run `ovdb` or open `http://ovdb.localhost:6832`:
one question, "What would you like to do?", four clear options, and after every action a
plain statement of what happened and what to do next. Non-interactive callers (AI agents,
scripts) get a compact status and the next commands instead of a prompt.

Originating idea: [OVDB onboarding and configuration](../../ideas/ovdb-onboarding-and-configuration.md)
(Draft; `Source Ideas` is set once the idea is approved). Architecture:
[decision 0006](../../decisions/0006-three-equal-configuration-interfaces.md).

## Problem

Today `ovdb` prints Cobra help, `ovdb serve` fails with "no databases" unless the user
already knows the manifest format, and nothing explains what OpenVaultDB is for. A person
must read documentation before they can store one record. An AI agent that runs `ovdb`
learns nothing actionable. Every drop-off in the first minutes is a lost user.

## Behavior

### Information architecture

The TUI and the web console render the same screens with the same wording. The CLI
exposes the same actions as commands.

| Screen | Purpose | Reached from | CLI equivalent |
|---|---|---|---|
| Home | Welcome, status line, "What would you like to do?" | start | `ovdb status` |
| Try a demo | Install and open the TODO demo | Home | `ovdb demo install`, `ovdb demo open` |
| Create a database | Choose storage, name, location | Home | `ovdb databases create` |
| Connect an existing database | Point at existing storage | Home | `ovdb databases connect` |
| OVDB server | Start, stop, open, port | Home | `ovdb server …` |
| Databases | List, choose current, remove registration | Home status line | `ovdb databases`, `ovdb use` |
| Explore data | DataTug hand-off | Home, after demo or create | `ovdb explore …` |
| AI agent skills | Offer and install skills | Home, after demo | `ovdb skills …` |
| Settings | Telemetry, server port | Home | `ovdb telemetry …`, `ovdb config …` |
| Result | What happened + next actions | after any action | command output |
| Problem | What failed, why, what to do | after any failure | error output |

#### REQ: home-menu-options

The Home screen MUST ask "What would you like to do?" and offer, in this order: **Try a
demo**, **Create a database**, **Connect an existing database**, **Start the OVDB
server**, followed by a visually secondary group: **Explore data**, **AI agent skills**,
**Settings**. In the web console the server is necessarily running, so the fourth option
MUST instead read **OVDB server** and show its state. **Explore data** MUST be disabled
with the reason "Create or connect a database first" when no database is registered.

#### REQ: home-status-line

The Home screen MUST show a one-line status above the question: server state and
address, number of databases, and the current database for this context (see
[database context](../database-context-navigation/README.md)).

#### REQ: shared-copy-catalogue

All user-facing strings for onboarding screens, results, problems and next actions MUST
come from one message catalogue in the `ovdb` repository, consumed by the Go services,
the TUI and the web console. A test MUST fail if a TUI or web screen renders a
catalogue-backed string that is missing from the catalogue.

### Copy principles

- Say what the person gets, not how it works: "Keep your data in a folder on this
  computer", not "inGitDB schemaless mount".
- One question per screen. Short options, one line of help under each.
- After an action: what happened, where it is, what to do next.
- After a failure: what failed, why, what to do. Never only an error code.
- Every next action shows its command, so the terminal and agents can repeat it.
- Use "database", "OVDB server", "storage". Avoid "vault", "mount", "manifest",
  "provider" in onboarding copy (see [glossary](../../glossary.md)).
- No promises about features that do not work yet.

### Example copy: Home

TUI (web uses the same text, as cards):

```
OpenVaultDB
A place for your apps and AI agents to keep structured data that you own.

OVDB server: not running · Databases: none

What would you like to do?

> Try a demo
    See a small TODO app and an AI agent share the same data.
  Create a database
    Start fresh, stored on this computer.
  Connect an existing database
    Use data you already have in a folder, file or database server.
  Start the OVDB server
    Open the web console at http://ovdb.localhost:6832

  Explore data · AI agent skills · Settings

↑/↓ choose · Enter select · ? help · q quit
```

### Result and problem pattern

#### REQ: after-action-result

Every successful action MUST end on a Result screen (TUI/web) or result output (CLI)
containing: a title stating what happened in the past tense, the key facts (name,
location, address), and a "What next?" list of 2–4 actions. Each next action MUST include
the equivalent CLI command. The CLI MUST print the same next actions under `Next:`
unless `--json` is set, in which case they appear as a `nextSteps` array.

#### REQ: problem-pattern

Every failure MUST render the typed error from the shared services as: a title
"Couldn't <action>", a "Why" line from `reason`, and a "What you can do" list from
`hint`, including at least one command. With `--json`, the CLI MUST write
`{"error":{"code","message","reason","hint"}}` to stdout and exit non-zero. Exit codes:
`0` success, `1` failure, `2` usage error.

Example (port conflict, shared by TUI and web):

```
Couldn't start the OVDB server

Why: Port 6832 is already used by another program.

What you can do:
  • Use port 6833 instead            ovdb server start --port 6833
  • Keep port 6833 for next time     ovdb config set server.port 6833
  • Find what is using port 6832     see "Port already in use" in the docs
```

### Launching `ovdb`

#### REQ: bare-ovdb-launches-tui

When `ovdb` is run with no subcommand, stdout and stdin are terminals, `OVDB_NON_INTERACTIVE`
is not set, and the preview gate is enabled, `ovdb` MUST start the TUI on the Home screen.

#### REQ: bare-ovdb-non-interactive

When `ovdb` is run with no subcommand and any of the TUI conditions is false, `ovdb` MUST
NOT wait for input. With the preview gate enabled it MUST print a compact status (same
facts as `ovdb status`) followed by suggested next commands and exit `0`. With the gate
disabled it MUST keep today's behaviour (help output).

Example non-interactive output:

```
OpenVaultDB 0.9.0
OVDB server: not running
Databases: none

Get started:
  ovdb demo install --yes      Try the TODO demo
  ovdb databases create notes  Create a database stored on this computer
  ovdb server start            Start the web console at http://ovdb.localhost:6832
  ovdb status --json           Full status for scripts and AI agents
```

#### REQ: never-block-without-terminal

No `ovdb` command MUST ever prompt when stdin is not a terminal or
`OVDB_NON_INTERACTIVE=1`. Commands that need a confirmation MUST fail with a usage error
naming the flag that provides it (for example `--yes`).

### Status

#### REQ: status-command

`ovdb status` MUST report the whole local setup without requiring a running server:
OVDB version, OVDB home, server state (running, address, fallback address, port, pid),
registered databases (id, storage, location), current context and its source, TODO demo
installed or not, installed OVDB skills per agent, telemetry state, and suggested next
steps. `--json` MUST output one JSON object with those fields. When `--url` is given,
`ovdb status` MUST keep its current behaviour of printing `GET <url>/v1/status`.

### Telemetry question

#### REQ: telemetry-asked-after-first-success

The TUI and web console MUST ask the telemetry question at most once, only on the Result
screen of the first successful action while the state is `not asked`, as a secondary,
dismissible prompt that does not hide the next actions. Dismissing it without choosing
keeps `not asked` and it MUST NOT reappear in that session. Details are in
[telemetry consent](../telemetry-consent/README.md).

### TUI and web usability

#### REQ: tui-keyboard-and-size

The TUI MUST support arrow keys and `j`/`k`, Enter to select, Esc or Backspace to go
back, `q` to quit from Home, `?` for help, and MUST render without truncating options at
80×24 and remain usable (scrolling, no overlapping text) down to 60×20; below that it MUST
show "Make the window a little bigger" instead of broken layout.

#### REQ: web-accessibility-basics

The web console MUST be fully keyboard operable with visible focus, use semantic
headings and buttons, meet WCAG 2.1 AA colour contrast, work at 360 px width, and respect
the operating system light/dark preference.

### Rollout gate

#### REQ: preview-gate

Until the founder approves the flow, new onboarding surfaces MUST be gated by
`OVDB_PREVIEW=1`: without it, bare `ovdb` keeps today's behaviour and new commands are
hidden from help but remain callable (so agents, skills and tests work). The web console
is served whenever the new server commands run. Removing the gate MUST be a single,
isolated change.

## Dependencies

- local-server-and-web-console
- database-setup-and-providers
- todo-demo
- telemetry-consent
- configuration-parity

## Acceptance Criteria

### AC: home-shows-four-options (verifies REQ:home-menu-options, REQ:home-status-line)

**Given** a fresh OVDB home with no databases and no server
**When** the person opens the TUI with `OVDB_PREVIEW=1 ovdb` and, separately, opens the web console after `ovdb server start`
**Then** both show the same status line facts, the question "What would you like to do?", the four primary options in the specified order (web shows "OVDB server" as the fourth), and "Explore data" disabled with "Create or connect a database first"

### AC: catalogue-is-single-source (verifies REQ:shared-copy-catalogue)

**Given** the message catalogue and the TUI and web screen tests
**When** a screen references a message key that is not in the catalogue
**Then** the Go test suite or the web unit test suite fails

### AC: result-lists-next-actions-with-commands (verifies REQ:after-action-result)

**Given** a person creates a database named `notes` in the TUI, the web console and with `ovdb databases create notes`
**When** each action succeeds
**Then** each shows "Created database notes", its location, and the same next actions, each with its CLI command, and `--json` output contains a `nextSteps` array with the same commands

### AC: problem-shows-why-and-fix (verifies REQ:problem-pattern)

**Given** port 6832 is held by a non-OVDB process
**When** the person starts the server from the TUI, the web remedy flow and `ovdb server start`, and also runs `ovdb server start --json`
**Then** each shows "Couldn't start the OVDB server", the reason naming port 6832, and fixes including `ovdb server start --port 6833`; the JSON variant prints only the `error` object and exits `1`

### AC: tty-launches-tui (verifies REQ:bare-ovdb-launches-tui, REQ:preview-gate)

**Given** a terminal session with `OVDB_PREVIEW=1`
**When** the person runs `ovdb`
**Then** the TUI opens on Home; without `OVDB_PREVIEW` the same command prints today's help

### AC: agent-gets-status-not-prompt (verifies REQ:bare-ovdb-non-interactive, REQ:never-block-without-terminal)

**Given** `OVDB_PREVIEW=1`, stdin and stdout redirected (as an AI agent tool call runs)
**When** `ovdb` runs, and when `ovdb demo install` runs without `--yes` in the same environment
**Then** `ovdb` prints the compact status and "Get started" commands and exits `0` within one second, and `ovdb demo install` exits `2` with a message naming `--yes`; neither waits for input

### AC: status-covers-whole-setup (verifies REQ:status-command)

**Given** a server running on 6832, the TODO demo installed, a project context set to `todo`, and telemetry not asked
**When** `ovdb status --json` runs, and `ovdb status --url http://127.0.0.1:6832` runs
**Then** the first prints one JSON object with server, databases, context (with source `project`), demo, skills, telemetry and nextSteps; the second prints the server's `/v1/status` JSON as before

### AC: telemetry-question-is-late-and-once (verifies REQ:telemetry-asked-after-first-success)

**Given** telemetry state `not asked`
**When** the person opens the TUI, installs the demo, dismisses the telemetry prompt, then creates a database
**Then** the prompt appears only on the demo Result screen, never before it, and does not reappear after the second action in that session

### AC: tui-sizes (verifies REQ:tui-keyboard-and-size)

**Given** TUI model tests at 120×40, 80×24, 60×20 and 50×15
**When** the Home, Create database and Result screens render
**Then** no option text is truncated at 80×24, content scrolls without overlap at 60×20, and 50×15 shows "Make the window a little bigger"

### AC: web-keyboard-and-contrast (verifies REQ:web-accessibility-basics)

**Given** the web console in a browser at 360 px and 1280 px widths in light and dark mode
**When** a person completes "Try a demo" using only the keyboard and an automated accessibility check runs
**Then** every step is reachable with visible focus and the check reports no contrast or missing-label violations

## Open Questions

- Should the Home screen for returning users lead with their databases (a dashboard)
  instead of the same four options? Recommendation: keep the question, show databases in
  the status line, revisit after telemetry shows returning-user behaviour.
- Which languages beyond English does the message catalogue need first?

---
*This document follows the https://specscore.md/feature-specification*
