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

OpenVaultDB already has related repositories for website, Go, TypeScript, demo, and backstage work. A separate specifications repository would split public attention, architectural review, and contributor onboarding.

The project needs one public location for GitHub stars, contributors, architecture documentation, security model, SpecScore reports, and implementation-independent specifications.

## Decision

The main `openvaultdb/openvaultdb` repository is the canonical public home for OpenVaultDB specifications, architecture, and project-level review.

## Rationale

Keeping specifications in the main repository makes architecture first-class rather than a side project. It also gives future implementation work a stable place to cite requirements, decisions, test matrices, and review artifacts.

This decision intentionally avoids a separate `openvaultdb-specs` repository so contributors, Fable reviewers, and users see the specification-first posture from the project root.

Related repositories retain their roles:

- `openvaultdb-go`: Go implementation and SDK work.
- `openvaultdb-ts`: TypeScript implementation and SDK work.
- `openvaultdb-todo-demo`: demo application work.
- `openvaultdb-com`: public landing and promotion site.
- `backstage`: internal/private marketing docs and specifications.

## Declined Alternatives

### Separate specifications repository

This would isolate review materials from future implementation and split public project gravity.

### Keep specifications only in implementation repositories

This would couple implementation-independent requirements to language-specific repositories and make cross-language consistency harder.

## Consequences at Decision Time

- The root README and `spec/` tree become public contributor entry points.
- SpecScore configuration belongs in the main repository.
- Implementation repositories should cite this repository for canonical architecture.
- Public landing and internal/private marketing repositories should not become sources of truth for implementation-independent specifications.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
