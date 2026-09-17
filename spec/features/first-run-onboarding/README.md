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

The first thing a person sees when they run `ovdb` or open the web console: one question,
"What would you like to do?", four clear options, and after every action a plain statement
of what happened and what to do next. Non-interactive callers (AI agents, scripts) get a
compact status and the same next options as data instead of a prompt.

Originating idea: [OVDB onboarding and configuration](../../ideas/ovdb-onboarding-and-configuration.md)
(Draft; `Source Ideas` is set once approved). Architecture:
[decision 0006](../../decisions/0006-three-equal-configuration-interfaces.md). Machine
contracts (error envelope, JSON, exit codes, copy catalogue) are defined in
[configuration parity](../configuration-parity/README.md).

## Problem

Today `ovdb` prints Cobra help, `ovdb serve` fails unless the user knows the manifest format,
and nothing explains what OpenVaultDB is for. An AI agent that runs `ovdb` learns nothing
actionable. Every drop-off in the first minutes is a lost user.

## Behavior

### Information architecture

TUI and web console render the same screens with the same copy keys; the CLI exposes the same
actions as commands.

| Screen | Purpose | CLI equivalent |
|---|---|---|
| Home | Welcome, status line, "What would you like to do?" | `ovdb status` |
| Try a demo | Install and open the TODO demo | `ovdb demo install`, `ovdb demo open` |
| Create a database | Choose storage, name, location | `ovdb databases create` |
| Connect an existing database | Register an inGitDB folder, SQLite file or manifest file | `ovdb databases connect` |
| OVDB server | Start (TUI), status, open in browser, port | `ovdb server …`, `ovdb open` |
| Databases | List, choose current, remove registration, Browse data | `ovdb databases`, `ovdb use`, `ovdb list` |
| Explore data | DataTug guidance | `ovdb explore` |
| AI agent skills | Offer and install skills | `ovdb skills …` |
| Settings | Telemetry, server port | `ovdb telemetry …`, `ovdb config …` |
| Result / Problem | What happened and next; what failed, why, what to do | command output |

#### REQ: home-menu-options

Home MUST ask "What would you like to do?" and offer, in order: **Try a demo**, **Create a
database**, **Connect an existing database**, **Start the OVDB server**, then a secondary
group: **Browse data**, **Explore data**, **AI agent skills**, **Settings**. In the web
console the fourth option MUST read **OVDB server** and show its state. Browse data and
Explore data MUST be disabled with "Create or connect a database first" when none exists.

#### REQ: home-status-line

Home MUST show one status line: server state and address, number of databases (and how many
need attention, which the running server reports), and the current database with its scope.

#### REQ: copy-from-catalogue

All onboarding copy MUST come from `copy/en.json` as defined in configuration parity.

### Copy principles

- Say what the person gets, not how it works: "Keep your data in a folder on this computer".
- One question per screen; short options with one line of help each.
- After an action: what happened, where it is, what next. After a failure: what failed, why,
  what to do — never only a code.
- Every next action shows its command so terminals and agents can repeat it.
- Use "database", "OVDB server", "storage"; avoid "vault", "mount", "manifest", "provider"
  outside advanced notes.
- No promises about features that do not work yet.

### Example copy: Home

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
    Use data you already have in a folder, SQLite file or manifest file.
  Start the OVDB server
    Open the web console at http://ovdb.localhost:6832

  Browse data · Explore data · AI agent skills · Settings

↑/↓ choose · Enter select · ? help · q quit
```

### Results and problems

#### REQ: after-action-result

Every successful action MUST end on a Result screen (TUI/web) or output (CLI) with a
past-tense title, key facts (name, location, address) and 2–4 next actions taken from the
server's `next` list, each showing its command. With `--json` they appear in `next`.

#### REQ: problem-pattern

Every failure MUST render the error envelope as a title "Couldn't <action>", a "Why" line
from `reason`, and "What you can do" from `next`, including at least one command; exit code
`1`.

Example (port conflict; TUI and CLI):

```
Couldn't start the OVDB server

Why: Port 6832 is already used by another program.

What you can do:
  • Use port 6833 instead            ovdb server start --port 6833
  • Keep port 6833 for next time     ovdb config set server.port 6833
```

### Launching `ovdb`

#### REQ: bare-ovdb-launches-tui

With `OVDB_PREVIEW=1`, no subcommand, stdin and stdout terminals and `OVDB_NON_INTERACTIVE`
unset, `ovdb` MUST start the TUI on Home.

#### REQ: bare-ovdb-non-interactive

With `OVDB_PREVIEW=1`, no subcommand and any TUI condition false, `ovdb` MUST NOT wait for
input; it MUST print a compact status followed by the `next` entries below and exit `0`.

| Next entry | Command |
|---|---|
| Set up in the terminal | `ovdb` (in a terminal) |
| Open web setup | `ovdb open` |
| Set up with commands | `ovdb databases create <name>` |
| Try the demo | `ovdb demo install --yes` |
| Install the OpenVaultDB skill for your AI assistant (ask the person first) | `ovdb skills install openvaultdb --yes` |

#### REQ: never-block-without-terminal

No command MUST prompt when stdin is not a terminal or `OVDB_NON_INTERACTIVE=1`. Commands that
need confirmation MUST fail with `confirmation_required` naming the flag (`--yes`).

### Status

#### REQ: status-command

With `OVDB_PREVIEW=1`, `ovdb status` MUST read state files without starting a server and
report: version, locations, server state (running, addresses, version), databases (id,
engine, location, mount state from the running server or "unknown (server not running)"),
current context and scope, demo installed, installed
OVDB skills, telemetry state, and `next` (the entries above that still apply). `--json` MUST
equal `GET /api/local/v1/status`. Without the gate, and whenever `--url` is given, `ovdb
status` MUST behave as today.

### Telemetry question

#### REQ: telemetry-asked-after-first-success

The TUI and web console MUST ask about telemetry at most once, on the Result of the first
successful action while the state is `not asked`, as a dismissible secondary prompt; see
[telemetry consent](../telemetry-consent/README.md).

### Usability

#### REQ: tui-keyboard-and-size

The TUI MUST support arrows and `j`/`k`, Enter, Esc/Backspace back, `q` quit on Home, `?`
help; render without truncated options at 80×24; stay usable (no line wider than the window,
selected item visible) at 60×20; below that show "Make the window a little bigger".

#### REQ: web-accessibility-basics

The web console MUST be keyboard operable with visible focus, use semantic headings and
buttons, meet WCAG 2.1 AA contrast, work at 360 px width and follow the OS light/dark
preference.

### Rollout gate

#### REQ: preview-gate

Until founder approval, `OVDB_PREVIEW=1` MUST gate bare-`ovdb` TUI launch, changed defaults of
existing commands (`status`, `databases`, `databases create`, `serve`, `token`; `init` only
gains engines in its help) and help visibility of new commands. New commands remain callable when hidden. Removing the gate
MUST be one isolated change with release notes for the changed defaults.

## Dependencies

- local-server-and-web-console
- database-setup-and-providers
- todo-demo
- telemetry-consent
- configuration-parity

## Acceptance Criteria

### AC: home-shows-options (verifies REQ:home-menu-options, REQ:home-status-line)

**Given** a fresh setup with no databases
**When** the person opens the TUI with `OVDB_PREVIEW=1 ovdb` and the web console via `ovdb open`
**Then** both show the same status facts, the question, the four primary options in order (web shows "OVDB server"), and Browse data and Explore data disabled with "Create or connect a database first"

### AC: result-lists-next-actions (verifies REQ:after-action-result, REQ:copy-from-catalogue)

**Given** a person creates `notes` in the TUI, in the web console and with `ovdb databases create notes --json`
**When** each succeeds
**Then** all show "Created database notes", its location, and the same next actions with commands, and the JSON contains the same `next` list

### AC: problem-shows-why-and-fix (verifies REQ:problem-pattern)

**Given** port 6832 held by a non-OVDB program
**When** the person starts the server from the TUI and with `ovdb server start`
**Then** both show "Couldn't start the OVDB server", the reason naming port 6832 and the `--port 6833` fix, and the CLI exits `1`

### AC: tty-launches-tui (verifies REQ:bare-ovdb-launches-tui, REQ:preview-gate)

**Given** a terminal session
**When** `OVDB_PREVIEW=1 ovdb` runs, and `ovdb` runs without the variable
**Then** the first opens the TUI on Home and the second prints today's help

### AC: agent-gets-next-not-prompt (verifies REQ:bare-ovdb-non-interactive, REQ:never-block-without-terminal)

**Given** `OVDB_PREVIEW=1` and stdin and stdout redirected
**When** `ovdb` runs, and `ovdb demo install` runs without `--yes`
**Then** `ovdb` prints the status and all five next entries and exits `0` within one second; `demo install` exits `1` with `confirmation_required` naming `--yes`; neither waits for input

### AC: status-covers-whole-setup (verifies REQ:status-command)

**Given** `OVDB_PREVIEW=1`, a running server, the demo installed, a project context `todo`, and telemetry not asked
**When** `ovdb status --json` runs, and `ovdb status --url http://127.0.0.1:6832` runs
**Then** the first equals the local API status body with context scope `project`; the second behaves as today

### AC: status-unchanged-without-gate (verifies REQ:preview-gate, REQ:status-command)

**Given** no `OVDB_PREVIEW` and a legacy `ovdb serve` on 6832
**When** `ovdb status`, `ovdb databases` and `ovdb databases create x --owner-token T` run
**Then** each calls the server exactly as today

### AC: telemetry-question-is-late-and-once (verifies REQ:telemetry-asked-after-first-success)

**Given** telemetry `not asked`
**When** the person installs the demo in the TUI, dismisses the prompt, then creates a database
**Then** the prompt appears only on the demo Result and not after the second action

### AC: tui-sizes (verifies REQ:tui-keyboard-and-size)

**Given** TUI model tests at 80×24, 60×20 and 50×15
**When** Home, Create database and Result render
**Then** no option is truncated at 80×24, no line exceeds the width and the selection is visible at 60×20, and 50×15 shows "Make the window a little bigger"

### AC: web-keyboard-and-contrast (verifies REQ:web-accessibility-basics)

**Given** the web console at 360 px and 1280 px in light and dark mode
**When** a person completes Try a demo with the keyboard only and an automated accessibility check runs
**Then** every step is reachable with visible focus and the check reports no contrast or label violations

## Open Questions

- Should Home for returning users lead with their databases instead of the question?
- Which languages beyond English does `copy/en.json` need first?

---
*This document follows the https://specscore.md/feature-specification*
