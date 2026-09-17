---
format: https://specscore.md/decision-specification
status: Approved
---
# Decision: Opt-in product telemetry with PostHog

**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Tags:** telemetry,privacy,onboarding,ai-agents
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

Onboarding decisions need evidence about where people stop. OpenVaultDB is about data
ownership, so collecting that evidence must never feel like a breach. `ovdb` has no
telemetry. `specscore-cli/internal/telemetry` (opt-out, closed event struct, ldflags key,
EU endpoint) is the fleet precedent, but it only enqueues into `posthog-go`, which batches
every 5 s, so short CLI processes can exit before sending. `datatug-cli` sends events with
no opt-out. The founder chose PostHog EU, key via GitHub secret `POSTHOG_KEY`, opt-in, no
sensitive data, funnel telemetry from MVP, and that an agent never consents on the user's
behalf.

## Decision

1. **Opt-in.** States `not asked`, `enabled`, `disabled`. Nothing is sent unless `enabled`.
   `OVDB_TELEMETRY=0`, `DO_NOT_TRACK=1` and detected CI force it off, evaluated in the
   **process that sends** the event.
2. **Who sends.** CLI and TUI send their own events after reading the consent state; the
   server sends events originating in the web console. The server's environment therefore
   never overrides a CLI user's `DO_NOT_TRACK`.
3. **How it sends.** No PostHog SDK: a small sender POSTs one batch to the EU capture
   endpoint synchronously at the end of a command (or TUI/web step) with a 2-second
   timeout; failures are silent. Builds without an injected key report
   `unavailable in this build`.
4. **Ask once, late and lightly** in the TUI and web console, after the first successful
   action; the CLI never prompts.
5. **Pre-consent buffer** in memory only (TUI process, web page), sent if the person turns
   telemetry on in that session, discarded otherwise.
6. **Closed data model.** A closed Go struct with allowlisted properties (channel, step,
   option, engine id, success, error code, duration, version, OS, architecture, anonymous
   install id). One test marshals every event and fails on any forbidden key or value.
   Never collected: database names or ids, paths, URLs, connection details, record data,
   queries, schemas, tokens, free text. GeoIP enrichment disabled.
7. **Agents never consent on their own.** `ovdb telemetry enable` in a terminal asks for
   confirmation; without a terminal it requires `--confirmed-by-user` and otherwise prints
   what is collected and exits `1`. Skills tell agents to ask the person and never infer
   consent. This cannot be cryptographically enforced, and the decision says so.

## Rationale

- Opt-in is the only default consistent with a data-ownership product and EU expectations.
- Evaluating opt-outs in the sending process makes a person's own environment decisive,
  even when a long-running server was started by someone else.
- A synchronous, bounded batch send actually delivers CLI events; an SDK with a background
  queue does not in short-lived processes.
- A closed struct plus one serialization test makes new properties a reviewed change.
- `--confirmed-by-user` lets agents relay a person's explicit answer (which the founder
  allows) while making silent enabling an explicit, visible act.

## Declined Alternatives

### Opt-out telemetry

Contradicts the product promise and the founder's instruction. Declined.

### No telemetry during the preview

Suggested in review to cut scope. Declined: the founder wants funnel data from MVP; scope
was reduced instead (no SDK, no fuzzing).

### `posthog-go` SDK with an asynchronous queue

Drops events from processes that exit within the batch interval. Declined.

### Refuse `telemetry enable` in any non-terminal environment

Stronger, but blocks the founder-approved path where an agent runs the command after the
person decides. Declined in favour of `--confirmed-by-user`.

### Persist pre-consent events to disk

Stores behavioural data about someone who has not agreed. Declined.

## Consequences at Decision Time

- `ovdb` gains a sender package, `ovdb telemetry` commands, TUI and web settings, and
  consent in `config.yaml`.
- Release builds need `POSTHOG_KEY` in `ldflags`; until then builds report unavailable.
- Commands with telemetry on may take up to 2 s longer when PostHog is unreachable.
- Data skews to people who opt in; analysis must say so.

## Observed Consequences

- 2026-09-17 (increment 9 phase A adversarial review, `ovdb` PR #22, open, not yet landed):
  (a) disabling GeoIP enrichment does not stop the sending process's IP address from reaching
  PostHog — PostHog records it from the TCP connection regardless. `ovdb` sends a fixed
  `"$ip": "0.0.0.0"` placeholder property on every event (PostHog's own documented mechanism,
  its "Hiding customer IP address" tutorial), but PostHog still stores the real connection
  address unless the EU project's own **"Discard client IP data"** setting is turned on. That
  project setting MUST be confirmed on, a founder/ops action against the PostHog project itself,
  before any `POSTHOG_KEY` ships in a release build — not merely before telemetry is turned on.
  Until it is confirmed, copy MUST NOT call the statistics "anonymous" or say no "addresses" are
  collected without that qualification; see [telemetry consent](../features/telemetry-consent/README.md).
  (b) `.github/workflows/release.yml` does not forward a `POSTHOG_KEY` secret into the
  goreleaser build environment (the same gap `specscore-cli` has for `POSTHOG_WRITE_KEY`), so a
  release build ships key-less (`unavailable in this build`) until a shared `strongo/cicd`
  change forwards release-time secrets to product release workflows; this is a release
  precondition alongside the PostHog project setting, not a code change in `ovdb` itself.
  (c) an agent harness can attach a pseudo-terminal to `ovdb telemetry enable`, so `isTerminal`
  alone cannot tell a person from an agent relaying on their behalf; the CLI now takes the
  non-terminal `--confirmed-by-user` path whenever the sending process detects an agent channel
  (`DetectChannel(...) == agent`), even with a terminal attached. (d) a TUI session that
  buffered pre-consent events must not send them merely because another process (for example an
  agent) enabled telemetry while it was open; only that session's own Turn on releases what it
  buffered, and exit always discards the rest — sharper than decision point 5's original
  wording, which read as "enabled in that session" without saying whose action enables it.
- 2026-09-17 (final review before landing, `ovdb` PR #22 branch `ovdb-inc-9-telemetry` head
  `07b6fe9`, review-final.md, verdict FIXES-NEEDED then SHIP-BEHIND-GATE; M1/M2/M3/M5 and
  L1/L5/L6 fixed on the branch before this fold): (a) the phase-A review also found (F4, plan
  implementation-amendments table, not one of the lettered points above) that an instance-secret
  caller could set the recorded deciding `channel` to any value, so it wasn't independent
  evidence; the fix that landed for it between phase A and this review over-corrected by
  deriving `channel` from the credential alone instead, so every instance-secret caller — TUI
  and agent included — was recorded as `cli` (M1). The deciding channel is fixed again, this
  time by having an instance-secret caller **declare** which local process it is
  (`cli`, `tui` or `agent`, a validated enum the server checks; a console session's channel
  stays hard-coded to `web`, and a bearer caller declaring `web` is refused). This keeps the
  same unenforceable-by-cryptography limitation the decision already names (a caller can still
  misreport which local process it is) while restoring the distinction the audit trail needs.
  (b) point (a) above overstated what PostHog's "Discard client IP data" setting controls
  (L6, per PostHog's own docs): sending the fixed `"$ip": "0.0.0.0"` on every event means
  PostHog *stores* that placeholder on the event regardless of the project setting — a passed
  `$ip` is used as given, never replaced by the connection address, on the stored event. The
  connection's real address still reaches PostHog's edge with every request, which is why the
  project setting remains a release precondition — in case any pipeline or transformation reads
  the raw connection address instead of the event's `$ip` property — but "PostHog stores it
  only if the project keeps client IP data" was not an accurate description of the risk and has
  been reworded in [telemetry consent](../features/telemetry-consent/README.md#REQ:ip-handling-and-release-precondition)
  and its copy. (c) every web console action that observes telemetry (create, connect, demo
  install, explore, skill install) previously waited for the synchronous PostHog send before
  its own HTTP response could finish, because `WriteJSON` sets no `Content-Length` and the
  final chunk isn't written until the handler returns — so a slow or hanging endpoint held up
  the console UI by up to 2 s on every observed action (M5). The server now hands each batch to
  a small bounded background queue (16 batches, one worker, each batch still bounded by the 2 s
  send timeout) instead of sending inline; on shutdown it waits for queued batches, bounded to
  2 s. The CLI and TUI are unaffected — they always flushed at command/process exit, which is
  when the 2 s bound is expected. (d) `GET /api/local/v1/status` and `ovdb status --json` now
  carry `telemetry: {state, sending, reason, reason_text}` (M2); it was previously absent
  despite [first-run onboarding](../features/first-run-onboarding/README.md#REQ:status-command)
  already listing "telemetry state" as a status field group, so agents reading `ovdb status
  --json` first (as the storage skill tells them to) could not see the state without a second
  command. (e) at 80×24, the prompt's "What's collected?" details pushed "Never collected" and
  the key footer off screen with nothing to scroll to (M3); the Result now shows the prompt and
  its lists in place of the normal body while details are open. (f) a Result that ran no action
  ("the TODO demo is already installed") no longer offers the prompt, and Enter no longer
  answers or dismisses it by accident; Esc dismisses to "decide later" without asking again
  that session (L5), matching a sharper reading of `REQ:consent-prompt-placement` than the
  original "ask only once, after the first successful action" wording, which did not
  distinguish an action from a Result that changed nothing. (g) `onboarding_completed` is now
  recorded (with `step`) when the person reaches Done on any interface's Result, and `databases`
  was added to the shared `option`/`step` enum for the Home option of that name — both were
  specified but unimplemented (L1).

## Affected Features

- [Telemetry consent](../features/telemetry-consent/README.md) — states, parity, events and copy.
- [First-run onboarding](../features/first-run-onboarding/README.md) — when consent is asked.
- [AI agent skills](../features/ai-agent-skills/README.md) — agents relay, never infer, consent.

---
*This document follows the https://specscore.md/decision-specification*
