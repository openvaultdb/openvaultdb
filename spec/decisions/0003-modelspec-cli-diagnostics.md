---
format: https://specscore.md/decision-specification
status: Approved
---

# Decision: ModelSpec CLI Diagnostics

**Status:** Approved
**Date:** 2026-07-08
**Owner:** codex
**Tags:** modelspec,cli,diagnostics
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

OpenVaultDB consumes ModelSpec directly and exposes validation through CLI workflows.
The CLI needs a predictable output contract so humans can read errors and automation
can safely consume structured diagnostics.

## Decision

Human-readable ModelSpec validation errors are emitted on `stderr`.

Structured diagnostic output is emitted on `stdout` only when explicitly requested,
for example with `--format json`.

Validation failures exit non-zero.

Non-error informational output may use `stdout` for human-oriented commands.

## Rationale

This follows conventional linter behavior and avoids mixing prose with machine-readable
output. It also lets shell pipelines redirect structured output without losing
human-readable failures.

## Declined Alternatives

### Emit all diagnostics on stdout

Rejected because it makes automation harder and risks corrupting structured output.

### Emit structured diagnostics on stderr

Rejected because callers commonly capture `stdout` for machine-readable command
results and reserve `stderr` for human-facing failures.

### Emit duplicate diagnostics on stdout and stderr

Rejected because duplication complicates scripts and makes it harder to define a
stable output contract.

## Consequences at Decision Time

CLI commands need to keep progress/error prose separate from structured output modes.

Tests should verify stream behavior for validation failures once CLI implementation
starts.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
