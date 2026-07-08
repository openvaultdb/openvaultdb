# Capability Model

## Purpose

Define the authorization primitive used by OpenVaultDB.

## Key Concepts

- Capability: a structured authorization with operation, resource, constraints, issuer, subject, and expiry.
- Operation: read, query, write, delete, migrate, export, register, revoke, or administer.
- Constraint: field filter, predicate, rate limit, time window, approval requirement, or record set.
- Delegation: constrained transfer from one principal to another.

## Normative Requirements

- Capabilities MUST be least-privilege and machine-checkable.
- A capability MUST name its subject principal and MUST NOT be transferable unless delegation is explicit.
- Capabilities MUST include resource scope and allowed operations.
- Destructive, export, permission-broadening, key, and migration capabilities MUST be high-risk.
- Capability evaluation MUST consult current grant state or a freshness proof.
- Delegated capabilities MUST be no broader than the source authority.

## MVP Behavior

The MVP supports capabilities for collection read/query, record write, record delete, migration proposal, migration execution after approval, audit-log read, and grant revocation.

## Risks

- Too many capability types can make prompts unreadable.
- Predicate-based scopes can be hard to explain and test.
- Delegation can hide the true actor unless audit records preserve the chain.

## Open Questions

- Should capabilities be represented as signed tokens, local database rows, or both?
- Which operations need interactive approval every time?
- How expressive should predicate scopes be in the MVP?

## Acceptance Criteria

- Every API operation maps to one or more required capabilities.
- AI-agent-initiated actions are audited as actions by the authenticated principal used for the call.
- Capability denial reasons are inspectable for debugging and security review.

## Related Specifications

- [permissions-model.md](permissions-model.md)
- [ai-agent-access.md](ai-agent-access.md)
- [../api/api-model.md](../api/api-model.md)
- [audit-log.md](audit-log.md)
