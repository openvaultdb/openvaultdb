# Risky Assumptions

## Purpose

Make architecture assumptions visible before they become implicit dependencies.

## Key Concepts

- Assumption: a statement believed true enough to proceed.
- Risk: the consequence if an assumption is wrong.
- Mitigation: the current constraint or test that reduces the risk.

## Normative Requirements

- Risky assumptions MUST be reviewed before implementation relies on them.
- Assumptions that affect user data loss, confidentiality, or permission escalation MUST have a mitigation.
- Accepted assumptions SHOULD later become decisions or requirements.

## MVP Behavior

The MVP assumes a local machine can provide a useful security boundary only when combined with vault encryption, explicit approvals, least-privilege capabilities, and audit logs.

## Risks

| Assumption | Risk if False | Mitigation |
|---|---|---|
| Users can evaluate concise permission prompts. | Users approve broad or destructive access. | Use narrow capabilities and risk labels. |
| Local encrypted storage is sufficient for MVP learning. | MVP ignores synchronization risks too long. | Keep provider model documented but out of MVP. |
| AI agents can be constrained by capability scopes. | Agents may cause damage through valid but confused actions. | No implicit AI write access and require audit entries. |
| Migrations can be made resumable and auditable. | Interrupted migrations corrupt vault state. | Require checkpoints and idempotence. |
| Git-backed history is dangerous for secrets. | Deleted secrets remain recoverable. | Treat Git backend as restricted and non-MVP. |
| Permission caches can be made safe. | Stale grants survive revocation. | Require grant versions and online revocation checks against local authority. |

## Open Questions

- Which assumptions should be converted into formal ADRs first?
- What user research is needed for approval prompt comprehension?

## Acceptance Criteria

- Each high-risk area has a named mitigation or is marked out of MVP.
- Fable 5 receives assumptions as review input, not hidden context.

## Related Specifications

- [security/trust-model.md](security/trust-model.md)
- [security/permissions-model.md](security/permissions-model.md)
- [schema/migrations.md](schema/migrations.md)
- [storage/git-backend.md](storage/git-backend.md)
