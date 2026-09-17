---
format: https://specscore.md/decision-specification
status: Draft
---
# Decision: Opt-in product telemetry with PostHog

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Tags:** telemetry,privacy,onboarding,ai-agents
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

The onboarding work needs evidence about where people stop: which first-run option they
choose, which provider, whether the demo opens, where errors happen. OpenVaultDB is a
product about data ownership, so collecting that evidence must never feel like a breach
of the promise. `ovdb` has no telemetry today.

Two precedents exist in the fleet. `specscore-cli/internal/telemetry` confines the
PostHog SDK to one package (enforced by a boundary test), uses a closed `Event` struct,
a per-machine install id, an EU endpoint and a write key injected through `-ldflags`; it
is opt-out. `datatug-cli/pkg/dtlog` sends PostHog events with no opt-out found. The
founder chose PostHog EU with the key supplied later through the GitHub secret
`POSTHOG_KEY`, opt-in consent, no sensitive data, and that an AI agent never consents on
the user's behalf.

## Decision

1. **Opt-in.** Telemetry is disabled until a person explicitly enables it. States:
   `not asked`, `enabled`, `disabled`. `OVDB_TELEMETRY=0`, `DO_NOT_TRACK=1` and detected
   CI environments force it off for that process regardless of the stored state.
2. **Unavailable builds.** A build without an injected PostHog key reports
   `unavailable in this build`; consent can still be recorded, and nothing is sent.
3. **Ask once, late and lightly.** The TUI and web console ask after the first
   successful action, never before it and never blocking it. The CLI never prompts;
   `ovdb telemetry enable|disable|status` exist on all channels.
4. **Pre-consent buffer.** During an interactive TUI or web onboarding session events
   are kept in memory only. They are sent if the person enables telemetry in that
   session, and discarded on decline, on exit or when the session ends. Nothing is
   written to disk before consent.
5. **Closed data model.** Events are a closed set with allowlisted properties only:
   channel (`cli`, `tui`, `web`, `agent`, derived from the environment, never from user
   input), step, option id, provider id from the closed catalogue, success, error
   category from a closed enum, duration in milliseconds, OVDB version, OS and
   architecture, and an anonymous per-machine install id. Never collected: database
   names or ids, paths, repository names, URLs or connection strings, record data,
   queries, schemas, tokens, free text, IP-derived location beyond what PostHog
   receives at transport level (PostHog GeoIP enrichment disabled).
6. **Agents never consent.** No command enables telemetry implicitly. `ovdb telemetry
   enable` run by an agent is valid only as the relay of a person's explicit answer;
   skills instruct agents to ask and to show what is collected, and the command output
   repeats what is and is not collected.
7. **Implementation boundary.** Fork the `specscore-cli` telemetry design: a single
   package imports the PostHog SDK, a boundary test enforces it, events are a closed
   Go struct, the key is injected with `-ldflags`, the endpoint is PostHog EU.

## Rationale

- Opt-in is the only default consistent with a data-ownership product and with EU
  expectations for non-essential analytics.
- Asking after the first success means the question never stands between a person and
  their goal, and the person already knows what OVDB does when deciding.
- Buffering in memory lets the first session's funnel be measured *if* the person agrees,
  without storing anything if they do not.
- A closed struct and allowlist make any new property a reviewed code change, not a
  string added to a map.
- Deriving the channel from the environment gives reliable agent-versus-human data
  without asking agents to self-report.
- Forcing off in CI keeps automated runs from polluting data and from surprising
  maintainers.

## Declined Alternatives

### Opt-out telemetry (as `specscore-cli`)

Gives more data, but contradicts the product promise and the founder's instruction.
Declined.

### No telemetry at all

Private by construction, but leaves onboarding decisions to guesswork. Declined; opt-in
with a narrow schema is a better balance.

### Persist pre-consent events to disk and send after a later consent

More complete funnel data, but it stores behavioural data about a person who has not
agreed. Declined.

### Let agents enable telemetry with a flag during automated setup

Convenient for setup scripts, but it makes consent something an agent can do on a
person's behalf. Declined; agents may only relay an explicit answer.

### Self-hosted analytics endpoint

Stronger data locality, but an operational burden before there is traffic. Declined for
MVP; PostHog EU is the founder's choice.

## Consequences at Decision Time

- `ovdb` gains a telemetry package, a boundary test, `ovdb telemetry` commands, TUI and
  web settings screens, and consent state in `config.yaml`.
- Release builds need the `POSTHOG_KEY` secret wired into GoReleaser `ldflags`; until
  then every build reports `unavailable in this build`.
- Data volume is lower and skewed towards people who opt in; funnel analysis must say so.
- OVDB's bar is stricter than DataTug CLI's current behaviour; the difference is
  recorded as an open question in the telemetry feature.

## Observed Consequences

None observed yet.

## Affected Features

- [Telemetry consent](../features/telemetry-consent/README.md) — states, parity, events and copy.
- [First-run onboarding](../features/first-run-onboarding/README.md) — when consent is asked.
- [AI agent skills](../features/ai-agent-skills/README.md) — agents must not consent.

---
*This document follows the https://specscore.md/decision-specification*
