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

None observed yet.

## Affected Features

- [Telemetry consent](../features/telemetry-consent/README.md) — states, parity, events and copy.
- [First-run onboarding](../features/first-run-onboarding/README.md) — when consent is asked.
- [AI agent skills](../features/ai-agent-skills/README.md) — agents relay, never infer, consent.

---
*This document follows the https://specscore.md/decision-specification*
