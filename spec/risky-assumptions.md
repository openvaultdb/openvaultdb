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

The MVP assumes GitHub/private-repository controls, explicit approvals, least-privilege capabilities, and audit logs are sufficient for learning and review. It does not assume vault-data confidentiality from the hoster or storage provider.

## Risks

| Assumption | Risk if False | Mitigation |
|---|---|---|
| Users can evaluate concise permission prompts. | Users approve broad or destructive access. | Use narrow capabilities and risk labels. |
| GitHub-backed InGitDB storage without OpenVaultDB encryption is sufficient for MVP learning. | MVP inherits GitHub API, token, visibility, hoster, and history-retention risks early. | Document private repository and branch-protection options, but leave policy to users or hosters. |
| AI agent calls can be governed by the same capability model as website and application calls. | Agent-originated changes may be hard to investigate if caller identity is collapsed. | MVP audits the authenticated principal only; optional AI provenance is post-MVP. |
| Migrations can be made resumable and auditable. | Interrupted migrations corrupt vault state. | Require checkpoints and idempotence. |
| Git history is useful for recovery. | Deleted secrets remain recoverable and commit metadata can leak activity. | Treat Git history as restore, not privacy. |
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
