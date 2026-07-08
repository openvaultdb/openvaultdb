# Testing Specifications

## Purpose

Index test matrices for security and migrations.

## Key Concepts

- Test matrix: requirement-linked scenarios for review and future automation.
- Security test: verifies a trust, permission, audit, or provider assumption.
- Migration test: verifies planning, progress, rollback, and resume behavior.

## Contents

| Path | Purpose |
|---|---|
| [security-test-matrix.md](security-test-matrix.md) | Security scenarios and expected outcomes. |
| [migration-test-matrix.md](migration-test-matrix.md) | Schema and data migration scenarios. |

## Normative Requirements

- Security-sensitive requirements SHOULD have at least one test matrix entry.
- Migration requirements MUST include interruption and stale-permission cases.

## MVP Behavior

The matrices are review artifacts now and should become executable tests during implementation.

## Risks

- Matrix entries can become stale if specs change.
- Tests may focus on happy paths and miss abuse cases.

## Open Questions

- What test runner should host future compliance tests?
- Which matrix entries are mandatory for MVP release?

## Acceptance Criteria

- Fable 5 can map major risks to proposed tests.
- Future implementation can convert rows into automated checks.

## Related Specifications

- [../security/threat-model.md](../security/threat-model.md)
- [../schema/migrations.md](../schema/migrations.md)
