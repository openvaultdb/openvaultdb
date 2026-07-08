# Roadmap

## Purpose

Define the review and implementation sequence for the conservative MVP.

## Key Concepts

- Review gate: decision point before implementation.
- Reference implementation: future production code that follows approved specs.
- Compliance test: executable check derived from a specification requirement.

## Normative Requirements

- Fable 5 review MUST happen before production implementation of security-sensitive behavior.
- Blocking open questions MUST be resolved or converted into explicit temporary constraints.
- Implementation milestones SHOULD include matching test matrix entries.

## MVP Behavior

| Phase | Outcome |
|---|---|
| 1. Specification review | Fable reviews trust, permissions, migrations, and MVP scope. |
| 2. Decision hardening | Provisional decisions become ADRs or RFCs. |
| 3. Compliance tests | Security and migration test matrices become executable checks. |
| 4. CLI vault skeleton | Local vault lifecycle, app registration, grants, and audit events. |
| 5. Schema and migration engine | Versioned schemas, migration plans, checkpoints, and progress. |
| 6. API bindings | Minimal app integration after capability model validation. |

## Risks

- Building API bindings before permission semantics are stable can cause churn.
- Delaying usability review can create unsafe approval defaults.

## Open Questions

- What is the first public milestone name?
- Which sibling repositories should be archived, linked, or redirected after this repo becomes canonical?

## Acceptance Criteria

- Each implementation phase references relevant specifications.
- No phase introduces cloud sync or implicit AI writes before review.

## Related Specifications

- [local-first-encrypted-vault.md](local-first-encrypted-vault.md)
- [non-goals.md](non-goals.md)
- [../testing/security-test-matrix.md](../testing/security-test-matrix.md)
- [../testing/migration-test-matrix.md](../testing/migration-test-matrix.md)
