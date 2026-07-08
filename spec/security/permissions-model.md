# Permissions Model

## Purpose

Define how principals receive, use, cache, and lose access to vault resources.

## Key Concepts

- Grant: user-approved assignment of capabilities to a principal.
- Scope: collection, record set, field, operation, time, or migration boundary.
- Revocation: removal or narrowing of an active grant.
- Permission cache: derived authorization state held for performance.
- Permission migration: planned change to grants or permission-relevant schema labels.

## Normative Requirements

- Permissions MUST be deny-by-default.
- Grants MUST be explicit, scoped, time-bounded where useful, and auditable.
- A grant MUST identify the principal, requested capabilities, resources, risk level, approval time, and approving user context.
- Permission caches MUST include a grant version or equivalent invalidation mechanism.
- Revocation MUST invalidate future authorization decisions and SHOULD terminate active sessions where practical.
- Permission broadening MUST require fresh approval.
- Permission migrations MUST use the migration approval workflow.

## MVP Behavior

Applications register with the vault and request capabilities. The CLI presents requested scopes and risk. The user approves, denies, narrows, or revokes grants. AI agents receive separate delegated grants and do not inherit application write access by default.

## Risks

- Users may approve broad scopes to avoid friction.
- Field-level permissions can become inconsistent during schema migration.
- Long-lived offline grants can outlive user intent.
- Stale caches can allow access after revocation.

## Open Questions

- What is the MVP minimum for field-level grants?
- Should grants require expiration by default?
- How should active long-running operations respond to revocation?

## Acceptance Criteria

- A stale permission cache cannot authorize access after a grant version changes.
- A migration that broadens access is blocked until approved.
- Audit records can reconstruct who approved each grant and why it was used.

## Related Specifications

- [capability-model.md](capability-model.md)
- [ai-agent-access.md](ai-agent-access.md)
- [../schema/migrations.md](../schema/migrations.md)
- [audit-log.md](audit-log.md)
