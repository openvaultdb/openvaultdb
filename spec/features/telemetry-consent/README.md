---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Telemetry consent

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

Anonymous product usage statistics for onboarding, sent to PostHog (EU) only after a
person turns them on. The same state, the same explanation of what is and is not
collected, and the same on/off control exist in the CLI, the TUI and the web console.
AI agents never turn it on by themselves.

Decision: [0009 opt-in product telemetry](../../decisions/0009-opt-in-product-telemetry.md).

## Problem

Without data, onboarding improvements are guesses. With careless data, a product about
owning your data loses its credibility. People need to see exactly what would be sent,
decide once, and change their mind anywhere.

## Behavior

### States

| State | Meaning | Sends events |
|---|---|---|
| `not_asked` | No decision yet (default) | No; TUI/web may buffer in memory for the current session |
| `enabled` | Person turned it on | Yes, unless forced off |
| `disabled` | Person turned it off | No |
| forced off | `OVDB_TELEMETRY=0`, `DO_NOT_TRACK=1` or CI detected, for that process | No |
| unavailable | Build has no PostHog key | No; state can still be recorded |

#### REQ: opt-in-state

Telemetry MUST start as `not_asked` and MUST send nothing until the stored state is
`enabled`. The stored state MUST live in `config.yaml` with `decided_at`. An anonymous
install id (random UUID) MUST be created only when telemetry is first enabled and MUST be
deleted when it is disabled.

#### REQ: forced-off-and-unavailable

Environment opt-outs and CI detection MUST prevent sending regardless of stored state, and
`status` MUST name the reason. A build without an injected key MUST report
`unavailable in this build` and send nothing.

#### REQ: parity-of-controls

`ovdb telemetry status [--json]`, `ovdb telemetry enable`, `ovdb telemetry disable`, the
TUI Settings screen and the web console Settings page MUST show the same state, reason,
provider (PostHog, EU region), the collected and not-collected lists from the message
catalogue, and MUST change the same stored state.

#### REQ: agents-never-consent

No command other than `ovdb telemetry enable` MUST set `enabled`. `enable` MUST print what
is and is not collected and how to turn it off. Skills MUST tell agents to run it only
after the person explicitly says yes (see [AI agent skills](../ai-agent-skills/README.md)).
No flag of any other command, environment variable or config default MUST enable
telemetry.

#### REQ: consent-prompt-placement

The TUI and web console MUST ask only as specified in
[first-run onboarding](../first-run-onboarding/README.md): once, after the first
successful action, dismissible, with **Turn on** and **No thanks** equally prominent and
a **What's collected?** link. The CLI MUST never prompt.

#### REQ: pre-consent-buffer

While the state is `not_asked`, the TUI process and the web console session MAY buffer
onboarding events in memory (at most 100). On **Turn on** the buffer MUST be sent; on
**No thanks**, on dismissing, on exiting the TUI or when the web session ends (tab closed
or 30 minutes idle) it MUST be discarded. The buffer MUST never be written to disk. The
CLI MUST NOT buffer.

### Data

#### REQ: closed-event-set

Only these events MAY be sent, with only the listed properties plus the common properties
`channel` (`cli`, `tui`, `web`, `agent`), `ovdb_version`, `os`, `arch`, `install_id`:

| Event | Additional properties |
|---|---|
| `onboarding_started` | — |
| `onboarding_option_selected` | `option` (`demo`, `create`, `connect`, `server`, `explore`, `skills`, `settings`) |
| `provider_selected` | `engine` (catalogue id) |
| `database_created` | `engine`, `success`, `duration_ms` |
| `existing_database_connected` | `engine`, `success`, `duration_ms` |
| `server_started` | `success`, `port_is_default` (bool), `duration_ms` |
| `demo_installed` | `success`, `already_installed` (bool) |
| `demo_opened` | `success` |
| `skill_installed` | `skill` (`openvaultdb`, `todo-demo`), `harness` (`claude`, `codex`, `cursor`, `dir`), `success` |
| `explore_data_selected` | `target` (`datatug_cli`, `datatug_web`), `datatug_found` (bool) |
| `telemetry_consent_changed` | `state` (`enabled` only; disabling sends nothing) |
| `onboarding_completed` | `step` (first successful action) |
| `onboarding_abandoned` | `step` (last screen) |
| `onboarding_error` | `step`, `error_category` (closed enum from the shared error codes) |

Events MUST be a closed Go struct; the PostHog SDK MUST be imported by one package only,
enforced by a test; GeoIP enrichment MUST be disabled for the project or per event.

#### REQ: never-collected

Events MUST NOT contain database ids or names, paths, project roots, repository names,
URLs, host names, connection strings or environment variable names, record data, queries,
schemas, tokens, error messages, free text, user names or e-mail addresses. A test MUST
serialize every event type with worst-case inputs and fail if any value outside the
allowlisted enums, booleans, numbers, version and install id appears.

#### REQ: channel-detection

`channel` MUST be derived, never taken from user input: `web` for web console actions,
`tui` for TUI actions, `agent` when a known agent harness environment variable is present
(for example `CLAUDECODE`, `CODEX_*`, `CURSOR_*`), otherwise `cli`.

#### REQ: non-blocking-sending

Sending MUST NOT delay any command by more than 500 ms or change its exit code or output.
Network failures MUST be silent.

### Example copy

Settings page (web) and Settings screen (TUI):

```
Usage statistics

Status: Off (you haven't decided yet)

Help improve OpenVaultDB by sending anonymous usage statistics to PostHog (EU).

What's collected
  • Which setup steps you use and whether they succeed
  • Storage type chosen (for example inGitDB), error categories, timings
  • OVDB version, operating system, a random install id

Never collected
  • Your data, database names, paths or addresses
  • Queries, schemas, tokens or connection details
  • Anything you type

[ Turn on ]   [ Keep off ]

You can change this any time: ovdb telemetry enable / ovdb telemetry disable
```

CLI:

```
$ ovdb telemetry status
Usage statistics: off (not decided)
Provider: PostHog, EU region
Turn on:  ovdb telemetry enable
Details:  ovdb telemetry status --json
```

## Dependencies

- first-run-onboarding
- configuration-parity

## Acceptance Criteria

### AC: nothing-sent-by-default (verifies REQ:opt-in-state)

**Given** a build with a PostHog key, a fresh OVDB home and a recording HTTP transport
**When** the person installs the demo, creates a database and starts the server via CLI
**Then** no request reaches PostHog, no install id exists, and `ovdb telemetry status --json` reports `not_asked`

### AC: enable-then-disable (verifies REQ:opt-in-state, REQ:parity-of-controls)

**Given** state `not_asked`
**When** telemetry is enabled in the web console, `ovdb telemetry status` runs in a terminal, and then it is disabled in the TUI
**Then** the CLI reports `enabled` with the same collected list, and after disabling the state is `disabled` and `config.yaml` no longer contains an install id

### AC: ci-forces-off (verifies REQ:forced-off-and-unavailable)

**Given** state `enabled` and `CI=true`
**When** `ovdb demo install --yes` runs and `ovdb telemetry status` runs
**Then** nothing is sent and status says it is off because a CI environment was detected

### AC: unavailable-build (verifies REQ:forced-off-and-unavailable)

**Given** a build without a PostHog key
**When** the person turns telemetry on in the TUI
**Then** the state is stored as `enabled`, nothing is sent, and every interface shows "unavailable in this build"

### AC: only-enable-command-enables (verifies REQ:agents-never-consent)

**Given** a non-interactive agent environment with state `not_asked`
**When** every command in the capability matrix runs with default flags
**Then** the state is still `not_asked`; only `ovdb telemetry enable` changes it, and its output lists collected and not-collected items

### AC: prompt-once-equal-choices (verifies REQ:consent-prompt-placement)

**Given** the TUI and web console with state `not_asked`
**When** the first successful action completes
**Then** one prompt shows Turn on and No thanks with equal visual weight and a What's collected link, and no CLI command ever shows a prompt

### AC: buffer-flushed-or-dropped (verifies REQ:pre-consent-buffer)

**Given** a recording transport and state `not_asked`
**When** in one TUI session the person installs the demo and chooses Turn on, and in another session installs the demo and chooses No thanks
**Then** the first session sends `onboarding_started`, `onboarding_option_selected`, `demo_installed`, `telemetry_consent_changed`; the second sends nothing and writes no telemetry file

### AC: allowlist-enforced (verifies REQ:closed-event-set, REQ:never-collected)

**Given** event construction fed database id `secret-db`, path `/home/ann/private`, a DSN and an error message
**When** the serialization test runs for every event type
**Then** none of those strings appear in any payload, and a second package importing the PostHog SDK fails the boundary test

### AC: channel-derived (verifies REQ:channel-detection)

**Given** `CLAUDECODE=1` in the environment and telemetry enabled
**When** `ovdb demo install --yes` runs, and the same action runs from the web console
**Then** the CLI event has `channel: agent` and the web event has `channel: web`

### AC: sending-does-not-block (verifies REQ:non-blocking-sending)

**Given** telemetry enabled and a PostHog endpoint that never responds
**When** `ovdb status` runs
**Then** it exits within its normal time plus at most 500 ms with unchanged output and exit code

## Open Questions

- DataTug CLI sends PostHog events with no opt-out today. Should the ecosystem align on
  OVDB's opt-in bar? This is outside OVDB but affects the Explore data hand-off.
- Should crash reports be a separate opt-in channel later?

---
*This document follows the https://specscore.md/feature-specification*
