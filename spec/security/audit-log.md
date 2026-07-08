# Audit Log

## Purpose

Define the append-only record of security-relevant events.

## Key Concepts

- Audit event: structured record of an action, decision, denial, or state transition.
- Actor chain: user, app, agent, extension, and provider context involved in an event.
- Tamper evidence: ability to detect removal, reorder, or alteration of audit entries.
- Redaction: controlled omission or masking of sensitive payload data.

## Normative Requirements

- The audit log MUST be append-only at the logical model level.
- Events MUST include timestamp, event type, actor, subject resource, outcome, and correlation ID.
- Grants, revocations, denied access, high-risk approvals, migrations, key events, exports, and destructive writes MUST be audited.
- Audit entries MUST avoid storing plaintext secrets or unnecessary record payloads.
- Audit export MUST preserve event order and integrity metadata.
- Implementations SHOULD make local tampering detectable, even if total device compromise remains out of scope.

## MVP Behavior

The MVP stores an audit log with hash chaining or equivalent tamper-evidence, accessible through CLI inspection and export commands. Audit-log confidentiality depends on repository and hoster access controls because MVP data is not encrypted by OpenVaultDB.

## Risks

- Audit metadata can reveal sensitive user behavior.
- Excessive redaction can make investigations useless.
- Local attackers may delete the entire vault and audit log.
- Clock changes can weaken event ordering.

## Open Questions

- Should audit events use monotonic counters in addition to wall-clock time?
- What is the minimum export format for third-party review?
- How long should audit events be retained by default?

## Acceptance Criteria

- A reviewer can reconstruct permission grant, use, revocation, and migration history.
- Audit entries do not include full secret values or unnecessary record bodies.
- Tamper-evidence failure is visible to the user and blocks high-risk operations until acknowledged.

## Related Specifications

- [permissions-model.md](permissions-model.md)
- [ai-agent-access.md](ai-agent-access.md)
- [../cli/commands.md](../cli/commands.md)
- [../testing/security-test-matrix.md](../testing/security-test-matrix.md)
