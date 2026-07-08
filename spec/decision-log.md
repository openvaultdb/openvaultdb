# Decision Log

## Purpose

Record provisional project decisions before they are promoted to formal architectural decision records.

## Key Concepts

- Decision: chosen direction with known tradeoffs.
- Status: Proposed, Accepted, Superseded, or Rejected.
- Review trigger: condition that requires revisiting a decision.

## Normative Requirements

- Decisions that affect security boundaries MUST be reviewed by Fable 5 before implementation.
- Accepted decisions SHOULD be promoted into [decisions/](decisions/README.md).
- A superseded decision MUST identify its replacement.

## MVP Behavior

| Decision | Status | Rationale | Review Trigger |
|---|---|---|---|
| Use the main `openvaultdb` repository as the canonical public specification home. | Accepted | Centralizes stars, contributors, architecture, and future implementation. | Repository strategy changes. |
| Start with a local-first encrypted vault MVP. | Proposed | Reduces provider trust and sync complexity during security validation. | Fable rejects local-first scope. |
| Require explicit application registration. | Proposed | Prevents ambient access by installed software. | Application onboarding proves unusable. |
| Use capability-based permissions. | Proposed | Enables narrow, auditable grants and revocation semantics. | Capability model cannot express common app workflows. |
| Provide no implicit AI write access. | Proposed | Confused or compromised agents are expected. | A safe delegation model is proven and reviewed. |
| Treat Git-backed storage as non-MVP. | Proposed | Git history can retain deleted secrets and metadata. | A safe redaction/encryption model is specified. |
| Make migrations reviewable, checkpointed, and auditable. | Proposed | Schema evolution is a core trust boundary. | Migration complexity blocks MVP. |

## Risks

- Provisional decisions may be mistaken for final approval.
- Some decisions require usability validation as much as security review.

## Open Questions

- Which decisions need formal ADRs before implementation starts?
- Should rejected alternatives be tracked in ADRs or RFCs?

## Acceptance Criteria

- Reviewers can see current direction without reading every specification.
- Every decision links to detailed specifications before implementation begins.

## Related Specifications

- [decisions/README.md](decisions/README.md)
- [mvp/roadmap.md](mvp/roadmap.md)
- [security/capability-model.md](security/capability-model.md)
- [schema/migrations.md](schema/migrations.md)
