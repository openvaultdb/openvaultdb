---
format: https://specscore.md/decision-specification
status: Draft
---

# Decision: Canonical Specification Repository

**Status:** Draft
**Date:** 2026-07-08
**Owner:** codex
**Tags:** repository,specification
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

OpenVaultDB already has related repositories for website, Go, TypeScript, demo, and backstage work. A separate specifications repository would split public attention, architectural review, and future implementation history.

The project needs one public location for GitHub stars, contributors, architecture documentation, security model, SpecScore reports, implementation-independent specifications, and the future reference implementation.

## Decision

The main `openvaultdb/openvaultdb` repository is the canonical public home for OpenVaultDB specifications and future reference implementation work.

## Rationale

Keeping specifications in the main repository makes architecture first-class rather than a side project. It also gives future implementation work a stable place to cite requirements, decisions, test matrices, and review artifacts.

This decision intentionally avoids a separate `openvaultdb-specs` repository so contributors, Fable reviewers, and users see the specification-first posture from the project root.

## Declined Alternatives

### Separate specifications repository

This would isolate review materials from future implementation and split public project gravity.

### Keep specifications only in implementation repositories

This would couple implementation-independent requirements to language-specific repositories and make cross-language consistency harder.

## Consequences at Decision Time

- The root README and `spec/` tree become public contributor entry points.
- SpecScore configuration belongs in the main repository.
- Existing sibling repositories should eventually link back to this repository for canonical architecture.
- The main repository must avoid production code until security and architecture review gates are complete.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
