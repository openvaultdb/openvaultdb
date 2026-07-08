# Security Test Matrix

## Purpose

Define review-ready security test scenarios.

## Key Concepts

- Scenario: attacker or misuse case.
- Expected result: required system behavior.
- Evidence: audit or state that proves the behavior.

## Normative Requirements

- Tests MUST cover malicious apps, confused AI agents, compromised providers, leaked tokens, stale permission caches, and interrupted operations.
- Security tests SHOULD verify both denial and audit evidence.

## MVP Behavior

| ID | Scenario | Expected Result | Related Specs |
|---|---|---|---|
| SEC-001 | Unregistered app reads collection. | Denied and audited. | [../security/permissions-model.md](../security/permissions-model.md) |
| SEC-002 | App uses revoked grant from cache. | Denied due to grant version mismatch. | [../security/permissions-model.md](../security/permissions-model.md) |
| SEC-003 | AI-agent-initiated call attempts write using a read-only principal. | Denied and attributed to the authenticated principal. | [../security/ai-agent-access.md](../security/ai-agent-access.md) |
| SEC-004 | Leaked non-key token is used after revocation. | Denied. | [../security/capability-model.md](../security/capability-model.md) |
| SEC-005 | Provider replays older vault state. | Detected or surfaced as integrity warning. | [../storage/provider-trust.md](../storage/provider-trust.md) |
| SEC-006 | Audit log entry is modified. | Verification fails and high-risk actions block. | [../security/audit-log.md](../security/audit-log.md) |
| SEC-007 | Export command runs without export capability. | Denied and audited. | [../cli/commands.md](../cli/commands.md) |
| SEC-008 | Permission-broadening migration requested by app. | Requires explicit approval. | [../schema/migrations.md](../schema/migrations.md) |

## Risks

- Some provider and rollback tests require implementation choices.
- Audit verification can be overfit to one storage backend.

## Open Questions

- Which scenarios are release blockers for MVP?
- How should total local device compromise be represented in tests?

## Acceptance Criteria

- Each high-risk security requirement has at least one matrix row before implementation.
- Denials include enough evidence for debugging without leaking secrets.

## Related Specifications

- [../security/threat-model.md](../security/threat-model.md)
- [../security/audit-log.md](../security/audit-log.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
