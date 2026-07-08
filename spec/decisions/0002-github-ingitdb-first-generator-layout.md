---
format: https://specscore.md/decision-specification
status: Approved
---

# Decision: GitHub InGitDB First Generator Layout

**Status:** Approved
**Date:** 2026-07-08
**Owner:** codex
**Tags:** storage,github,ingitdb,generator
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

OpenVaultDB needs a first backend generator target for ModelSpec. The selected
direction is a GitHub repository using InGitDB layout. The generator needs a concrete
initial repository layout so implementation and review can proceed.

## Decision

The first GitHub/InGitDB generator emits:

```text
vault/
├── meta.json
├── schema/
│   ├── current.modelspec.json
│   └── v{N}.modelspec.json
├── collections/
│   ├── {collection}/
│   │   ├── {record_id}.json
│   │   └── _index.json
├── audit/
│   └── {year}/{month}/{day}.ndjson
├── grants/
│   └── current.json
└── migrations/
    ├── checkpoints/
    │   └── {migration_id}.json
    └── history.json
```

Records are stored as one JSON file per record initially.

Current and historical ModelSpec AST serializations are stored under `schema/`.

Audit events are append-only NDJSON under date paths.

Grants and migration checkpoints are separate metadata areas.

Batching and Git tree API optimization are future work after rate-limit testing.

## Rationale

One file per record is simple, reviewable, and aligns with Git-backed storage
expectations. Separating schema, collections, audit, grants, and migrations keeps
storage responsibilities clear and avoids mixing user records with vault metadata.

The layout is not optimized for high-throughput workloads, but it is appropriate for a
first generator and architecture review.

## Declined Alternatives

### Batched record files first

Deferred because batching complicates partial updates, conflict handling, and
checkpoint recovery.

### Git tree API optimization first

Deferred because it is an implementation optimization rather than a layout decision.

### Store schema beside each collection

Rejected because current and historical ModelSpec versions are vault-level schema
metadata and should remain under a dedicated `schema/` area.

## Consequences at Decision Time

GitHub API rate limits remain a known risk for large vaults.

The first implementation can focus on correctness, reviewability, and migration
checkpointing before optimizing batch behavior.

## Observed Consequences

None observed yet.

## Affected Features

None at this time.

---
*This document follows the https://specscore.md/decision-specification*
