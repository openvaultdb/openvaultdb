# Open Questions

## Purpose

Track unresolved questions that should be answered before implementation commitments become hard to reverse.

## Key Concepts

- Blocking question: unresolved issue that can invalidate MVP architecture.
- Review question: issue suitable for Fable 5 architecture or security review.
- Product question: issue requiring human usability or business judgment.

## Normative Requirements

- A blocking question MUST name the affected specification.
- A decision that resolves an open question SHOULD be recorded in [decision-log.md](decision-log.md) or [decisions/](decisions/README.md).
- Implementation MUST NOT depend on an unanswered blocking question without an explicit temporary assumption.

## MVP Behavior

The MVP proceeds only after the trust model, permission model, AI write-access policy, migration approval flow, and backup/rollback expectations are reviewed.

## Risks

- Open questions can become hidden assumptions if not linked to decisions.
- Deferring user-experience questions can create unsafe approval flows.

## Open Questions

| Question | Type | Related Specs |
|---|---|---|
| What passphrase recovery or reset model is acceptable for MVP? | Blocking | [security/trust-model.md](security/trust-model.md), [mvp/local-first-encrypted-vault.md](mvp/local-first-encrypted-vault.md) |
| Should AI-agent initiated calls require additional audit identity beyond normal application principal identity? | Review | [security/ai-agent-access.md](security/ai-agent-access.md) |
| How should destructive migrations present risk to non-expert users? | Blocking | [schema/user-visible-migration-flow.md](schema/user-visible-migration-flow.md) |
| What InGitDB/GitHub repository layout and branch protection rules are mandatory for MVP? | Blocking | [storage/git-backend.md](storage/git-backend.md) |
| What is the minimum audit-log export format for external review? | Review | [security/audit-log.md](security/audit-log.md) |
| Which permission changes require migration-style planning? | Review | [schema/migrations.md](schema/migrations.md), [security/permissions-model.md](security/permissions-model.md) |
| How should third-party extensions be sandboxed or banned in the MVP? | Product | [security/threat-model.md](security/threat-model.md), [mvp/non-goals.md](mvp/non-goals.md) |

## Acceptance Criteria

- Each Fable 5 review brief points to the relevant open questions.
- No MVP production code starts until blocking questions have explicit decisions or temporary constraints.

## Related Specifications

- [risky-assumptions.md](risky-assumptions.md)
- [decision-log.md](decision-log.md)
- [../fable-brief/00-project-context.md](../fable-brief/00-project-context.md)
