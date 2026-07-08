# Specifications

Implementation-independent specifications for OpenVaultDB.

## Contents

| Path | Purpose |
|---|---|
| [vision.md](vision.md) | Project intent, principles, and review posture. |
| [glossary.md](glossary.md) | Shared vocabulary for vault, schema, permission, and storage concepts. |
| [open-questions.md](open-questions.md) | Cross-cutting unresolved questions. |
| [risky-assumptions.md](risky-assumptions.md) | Assumptions that could invalidate the architecture. |
| [decision-log.md](decision-log.md) | Current high-level decisions before formal ADRs. |
| [security/](security/README.md) | Trust, threat, permission, capability, AI-agent, and audit models. |
| [schema/](schema/README.md) | Schema definition, versioning, and migration behavior. |
| [storage/](storage/README.md) | Local-first and backend trust assumptions. |
| [cli/](cli/README.md) | CLI behavior and command surface. |
| [api/](api/README.md) | Application and agent API model. |
| [mvp/](mvp/README.md) | Conservative local-first encrypted vault MVP. |
| [testing/](testing/README.md) | Security and migration test matrices. |
| [rfcs/](rfcs/README.md) | Proposal process for material changes. |
| [decisions/](decisions/README.md) | Architectural decision record index. |
| [features/](features/README.md) | SpecScore feature specifications. |
| [ideas/](ideas/README.md) | SpecScore pre-spec ideas. |

## Normative Guidance

- Specifications MUST distinguish decisions, assumptions, open questions, and requirements.
- Security-sensitive behavior MUST reference [security/threat-model.md](security/threat-model.md).
- Schema-changing behavior MUST reference [schema/migrations.md](schema/migrations.md).
- MVP implementation work SHOULD reference [mvp/local-first-encrypted-vault.md](mvp/local-first-encrypted-vault.md).

## Open Questions

- Which requirements should be promoted into executable conformance tests first?
- Which formal ADRs should replace the provisional [decision-log.md](decision-log.md)?
