---
format: https://specscore.md/feature-specification
status: Approved
---
# Feature: Telemetry consent

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/telemetry-consent?op=request-change) |
**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
**Supersedes:** —

## Summary

Onboarding usage statistics carrying a random install id — never a name, database, path or
anything typed — sent to PostHog (EU) only after a person turns them on; the connection's own
IP address still reaches PostHog with every send (`REQ:ip-handling-and-release-precondition`).
The same state, explanation and control exist in the CLI, TUI and web console. AI agents
never turn it on by themselves.

Decision: [0009 opt-in product telemetry](../../decisions/0009-opt-in-product-telemetry.md).

## Problem

Without data, onboarding improvements are guesses; with careless data, a data-ownership
product loses credibility. People need to see exactly what would be sent, decide once, and
change their mind anywhere.

## Behavior

### States

| State | Meaning | Sends |
|---|---|---|
| `not_asked` | Default | No (TUI/web may buffer in memory) |
| `enabled` | Person turned it on | Yes, unless forced off |
| `disabled` | Person turned it off | No |
| forced off | `OVDB_TELEMETRY=0`, `DO_NOT_TRACK` set (not `0`/`false`) or CI detected, in the sending process | No |
| unavailable | Build has no PostHog key | No; state still recorded |

CI detection (final review F5) treats any of `CI`, `GITHUB_ACTIONS`, `GITLAB_CI`, `BUILDKITE`,
`CIRCLECI`, `TF_BUILD` (Azure Pipelines), `TRAVIS` or `APPVEYOR` set to a value other than
empty, `0` or `false` as CI, and the mere presence of `JENKINS_URL`, `TEAMCITY_VERSION`,
`BITBUCKET_BUILD_NUMBER` or `CODEBUILD_BUILD_ID` (their values are build identifiers, not
booleans).

#### REQ: opt-in-state

Telemetry MUST start `not_asked` and send nothing until `enabled`. State, `decided_at` and the
deciding channel MUST be stored in `config.yaml`. An anonymous install id MUST be created on
first enable and removed on disable.

#### REQ: sender-process-decides

Events MUST be sent by the process where the action happened: CLI and TUI send their own
events after reading the consent state; the server sends events for web console actions.
Forced-off conditions MUST be evaluated in that sending process, and `status` MUST name the
reason. Builds without a key report `unavailable in this build`.

#### REQ: parity-of-controls

`ovdb telemetry status [--json]`, `ovdb telemetry enable`, `ovdb telemetry disable`, TUI
Settings and web Settings MUST show the same state, reason, provider (PostHog, EU) and the
collected and never-collected lists from `copy/en.json`, and change the same stored state.

#### REQ: enable-requires-a-person

`ovdb telemetry enable` in a terminal MUST show what is collected and ask for confirmation.
Without a terminal it MUST require `--confirmed-by-user`; otherwise it MUST print what is
collected and exit `1` with `confirmation_required`. No other command, flag, environment
variable or default MUST enable telemetry. `disable` MUST always work without confirmation, even
when `config.yaml` cannot be parsed (it MUST rewrite only the `telemetry` section, or refuse
naming the file to fix, never leave the person unable to opt out). A terminal alone is not
evidence of a person: an agent harness can attach a pseudo-terminal to relay a command, so
whenever the sending process's own [channel detection](#REQ:channel-detection) resolves to
`agent`, `enable` MUST take the non-terminal path and require `--confirmed-by-user` even though
a terminal is attached.

#### REQ: consent-prompt-placement

The TUI and web console MUST ask only once per session, on the Result of the first action that
actually did something while the state is `not_asked` — never on a Result that ran no action,
for example "the TODO demo is already installed" (final review L5) — dismissible, with
**Turn on** and **No thanks** equally prominent and a **What's collected?** link. **No thanks**
MUST set `disabled`, so the person is never asked again. Dismissing without an answer (Esc in
the TUI, closing the prompt in the web console) MUST leave the state `not_asked` — decide
later — and MUST NOT ask again in that session; Enter, the key that otherwise confirms or moves
on, MUST NOT itself answer or dismiss the prompt (final review L5), so a person moving through
Results quickly cannot lose the choice by accident. The CLI MUST never prompt.

#### REQ: pre-consent-buffer

While `not_asked`, the TUI process and the web page MAY keep up to 100 onboarding events in
memory. They MUST be released only by **that same session's own** Turn on (install id assigned
at that moment) — never merely because telemetry became `enabled` on disk through another
process while the session was open, for example an agent relaying the person's answer to
`ovdb telemetry enable --confirmed-by-user` in another terminal. On **No thanks**, dismissal, or
exit or page close without that session's own Turn on, they MUST be discarded. The buffer MUST
never be written to disk; the CLI and the server MUST NOT buffer.

### Data and sending

#### REQ: closed-event-set

Only these events MAY be sent, with only the listed properties plus `channel` (`cli`, `tui`,
`web`, `agent`), `ovdb_version` (semver or `dev`), `os`, `arch`, `install_id`, and the fixed
`$ip` placeholder (`REQ:ip-handling-and-release-precondition`):

| Event | Additional properties |
|---|---|
| `onboarding_started` | — |
| `onboarding_option_selected` | `option` (`demo`, `create`, `connect`, `server`, `browse`, `explore`, `skills`, `settings`, `databases`) |
| `engine_selected` | `engine` |
| `database_created` | `engine`, `success`, `duration_ms` |
| `existing_database_connected` | `engine`, `success`, `duration_ms` |
| `server_started` | `success`, `port_is_default`, `duration_ms` |
| `demo_installed` | `success`, `already_installed` |
| `demo_opened` | `success` |
| `skill_installed` | `skill` (`openvaultdb`, `todo-demo`), `harness` (skillsync harness name), `success` |
| `explore_data_selected` | `target` (`datatug_cli`, `datatug_web`), `datatug_found` |
| `telemetry_consent_changed` | `state` (`enabled` only) |
| `onboarding_completed` | `step` (same options as above), recorded when the person reaches Done on a Result screen in any interface |
| `onboarding_error` | `step`, `error_code` (envelope code) |

Events MUST be a closed Go struct. One test MUST marshal every event with worst-case inputs
and fail if any key is outside the allowlist or any value is not an allowlisted enum, boolean,
number, version or install id. GeoIP enrichment MUST be disabled.

#### REQ: never-collected

Events MUST NOT contain database ids or names, paths, project roots, repository names, URLs,
host names, connection details, record data, queries, schemas, tokens, error messages, free
text, user names or e-mail addresses.

#### REQ: ip-handling-and-release-precondition

Disabling GeoIP enrichment does not stop the sending process's IP address from reaching
PostHog's servers with every request: that is how the connection works, and OVDB cannot change
it. Every event MUST instead carry a fixed `"$ip": "0.0.0.0"` property (PostHog's own documented
mechanism — its "Hiding customer IP address" tutorial and privacy docs: PostHog uses the client
IP address it received only when an event's own `$ip` property is absent), so the address
**stored on the event** is the placeholder, not the real one, independent of any project
setting. Copy MUST NOT call the statistics "anonymous" or claim addresses are "never collected"
without naming this precisely: the person is told their IP address reaches PostHog with each
send, and that OVDB puts a placeholder in the event in its place — not that PostHog "stores it
only if" a project setting is on (final review L6; that framing overstated what the project
setting controls). The EU project's own **"Discard client IP data"** setting remains a release
precondition regardless, in case any pipeline, transformation or export ever reads the raw
connection address rather than the event's stored `$ip` property. This setting, and forwarding
a `POSTHOG_KEY` release secret into the `ovdb` release build (currently absent from
`.github/workflows/release.yml`; needs a `strongo/cicd` change shared with other products, for
example `specscore-cli`'s `POSTHOG_WRITE_KEY`), are both release preconditions: no build MUST
ship an active key before the PostHog project setting is confirmed on
([decision 0009](../../decisions/0009-opt-in-product-telemetry.md) Observed Consequences).

#### REQ: channel-detection

`channel` MUST be derived by the sending process: `web` for web console actions, `tui` for TUI
actions, `agent` when a known agent harness variable is present (for example `CLAUDECODE`,
`CODEX_*`), otherwise `cli`. A web console session's `PUT /api/local/v1/telemetry` request MUST
always be recorded as `web`, whatever the request body says. An instance-secret caller (the
owner's own local CLI, TUI or an agent harness running one of them) instead declares which of
`cli`, `tui` or `agent` it is; the server MUST accept only that validated enum from a bearer
caller and refuse any other value, including `web`, with `invalid_argument` — deriving the
stored channel from the credential alone is not enough, since it recorded every instance-secret
caller (TUI and agent included) as `cli` and lost the distinction `REQ:enable-requires-a-person`
depends on (final review M1, correcting decision 0009's "self-reported and unenforceable"
characterization: the channel is now a validated enum per caller kind, though a caller can still
misreport which local process it is).

#### REQ: bounded-synchronous-sender

A small sender without a PostHog SDK MUST POST one batch to the PostHog EU capture endpoint,
each batch bounded by a 2-second total timeout (connection included) and carrying only
`Content-Type: application/json` and `User-Agent: ovdb`; failures MUST be silent and MUST NOT
change output or exit code. The CLI and TUI MUST flush their own pending batch synchronously,
within that 2-second bound, at command or process exit. The server MUST NOT make a console
action's own HTTP response wait for PostHog: it hands each batch to a small bounded background
queue (capacity 16 batches; a full queue drops the new batch rather than blocking) with one
worker sending batches one at a time, each still bounded by the 2-second timeout, so a slow or
unreachable endpoint never delays what the console shows (final review M5 — the response body
was previously flushed only after the synchronous send completed, chunked-encoding every
observed console action by up to 2 s). On shutdown the server MUST wait for queued batches to
finish sending, bounded to at most 2 seconds, before exiting.

### Example copy

```
Usage statistics

Status: Off (you haven't decided yet)

Help improve OpenVaultDB by sending usage statistics to PostHog (EU). They carry a random
install id, never your name, data or paths.

What's collected
  • Which setup steps you use and whether they succeed
  • Storage type chosen (for example inGitDB), error types, timings
  • OVDB version, operating system, a random install id
  • Your IP address reaches PostHog with each send; OVDB puts a placeholder in the event in
    its place, so the address itself isn't stored on the event

Never collected
  • Your data, database names, file paths, or database and server addresses
  • Queries, schemas, tokens or connection details
  • Anything you type

[ Turn on ]   [ Keep off ]

Change it any time: ovdb telemetry enable / ovdb telemetry disable
```

## Dependencies

- first-run-onboarding
- configuration-parity

## Acceptance Criteria

### AC: nothing-sent-by-default (verifies REQ:opt-in-state)

**Given** a build with a key, a fresh setup and a recording endpoint
**When** the person installs the demo, creates a database and starts the server via CLI
**Then** nothing reaches the endpoint, no install id exists, and status reports `not_asked`

### AC: enable-then-disable (verifies REQ:opt-in-state, REQ:parity-of-controls)

**Given** `not_asked`
**When** telemetry is turned on in the web console, `ovdb telemetry status` runs, and it is turned off in the TUI
**Then** the CLI reports `enabled` with the same collected list, and afterwards the state is `disabled` with no install id

### AC: client-env-wins (verifies REQ:sender-process-decides)

**Given** `enabled`, a server started without `DO_NOT_TRACK`, and a recording endpoint
**When** `DO_NOT_TRACK=1 ovdb demo install --yes` runs
**Then** nothing is sent and `DO_NOT_TRACK=1 ovdb telemetry status` names `DO_NOT_TRACK` as the reason

### AC: unavailable-build (verifies REQ:sender-process-decides)

**Given** a build without a key
**When** the person turns telemetry on in the TUI
**Then** the state is `enabled`, nothing is sent, and every interface shows "unavailable in this build"

### AC: non-tty-enable-needs-confirmation (verifies REQ:enable-requires-a-person)

**Given** stdin not a terminal and `not_asked`
**When** `ovdb telemetry enable` runs, then `ovdb telemetry enable --confirmed-by-user` runs
**Then** the first prints what is collected and exits `1` with `confirmation_required` leaving `not_asked`; the second sets `enabled` with deciding channel recorded

### AC: agent-with-terminal-still-needs-confirmed-by-user (verifies REQ:enable-requires-a-person)

**Given** a detected agent channel (for example `CLAUDECODE=1`) with a real pseudo-terminal attached, answering "y"
**When** `ovdb telemetry enable` runs, then `ovdb telemetry enable --confirmed-by-user` runs
**Then** the first leaves `not_asked` with `confirmation_required` despite the terminal; the second sets `enabled` with channel `agent`

### AC: prompt-once-equal-choices (verifies REQ:consent-prompt-placement)

**Given** the TUI and web console with `not_asked`
**When** the first successful action completes
**Then** one prompt shows Turn on and No thanks with equal weight and a What's collected link

### AC: prompt-skips-no-op-result-and-survives-enter (verifies REQ:consent-prompt-placement)

**Given** the TUI with `not_asked` and the demo already installed
**When** the person installs the demo again (a Result that changes nothing) and presses Enter on it, then creates a database
**Then** no prompt appears on the already-installed Result and Enter does not dismiss anything there; the prompt appears on the database-created Result instead, and pressing Esc there leaves the state `not_asked` without asking again this session

### AC: buffer-flushed-or-dropped (verifies REQ:pre-consent-buffer)

**Given** a recording endpoint and `not_asked`
**When** one TUI session installs the demo and chooses Turn on, and another installs the demo and chooses No thanks
**Then** the first sends `onboarding_started`, `onboarding_option_selected`, `demo_installed`, `telemetry_consent_changed`; the second sends nothing and writes no telemetry file

### AC: buffer-not-released-by-another-process (verifies REQ:pre-consent-buffer)

**Given** a TUI session that buffered `demo_installed` while `not_asked`, and a recording endpoint
**When** a separate agent process runs `ovdb telemetry enable --confirmed-by-user` while the TUI session stays open, and the TUI session then exits without its own Turn on
**Then** the recorder receives the agent's own `telemetry_consent_changed` but nothing the TUI session buffered

### AC: allowlist-enforced (verifies REQ:closed-event-set, REQ:never-collected)

**Given** event construction fed database id `secret-db`, path `/home/ann/private`, a connection string and an error message
**When** the marshal test runs for every event
**Then** none of those strings appear and no key outside the allowlist exists

### AC: ip-placeholder-and-copy (verifies REQ:ip-handling-and-release-precondition)

**Given** a recording endpoint and telemetry enabled
**When** any event is sent, and telemetry status/settings copy is read
**Then** the event's `$ip` property is the fixed placeholder, never the sender's real address, and no shown copy calls the statistics "anonymous" or claims addresses are never collected without naming the IP address behaviour, and no copy claims PostHog stores the real address conditionally on a project setting

### AC: channel-derived (verifies REQ:channel-detection)

**Given** `CLAUDECODE=1` and telemetry enabled
**When** `ovdb demo install --yes` runs, and the same action runs in the web console
**Then** the CLI event has `channel: agent` and the web event `channel: web`

### AC: server-validates-declared-channel (verifies REQ:channel-detection)

**Given** a running server, telemetry `not_asked`, and the instance secret
**When** the TUI turns telemetry on (declaring `tui`), then a separate `CLAUDECODE=1` process runs `ovdb telemetry enable --confirmed-by-user` (declaring `agent`) against the same server, then a bearer request declares `channel: "web"`
**Then** `config.yaml` records `channel: tui` after the first and `channel: agent` after the second, never `cli` for either; the third is refused `invalid_argument` and the stored channel is unchanged

### AC: events-delivered-within-bound (verifies REQ:bounded-synchronous-sender)

**Given** telemetry enabled and a recording endpoint, then an endpoint that never responds
**When** `ovdb databases create notes` runs against each
**Then** the first receives `database_created` before the process exits; the second adds at most 2 s and output and exit code are unchanged

### AC: console-not-blocked-by-send (verifies REQ:bounded-synchronous-sender)

**Given** telemetry enabled in the web console and an endpoint that never responds
**When** the person creates a database from the web console
**Then** the HTTP response with the created database completes immediately (not chunked, not held for up to 2 s), and the endpoint still receives the `database_created` batch shortly after

## Open Questions

- DataTug CLI sends events without an opt-out; should the ecosystem align on OVDB's bar?
- Should crash reports become a separate opt-in channel later?

---
*This document follows the https://specscore.md/feature-specification*
