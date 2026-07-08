# Non-Goals

## Purpose

Define what OpenVaultDB will not attempt in the initial MVP.

## Key Concepts

- Non-goal: intentionally excluded scope.
- Deferral: important future work excluded until a reviewed model exists.
- Risk containment: avoiding features that expand the threat model too early.

## Normative Requirements

- The MVP MUST NOT include cloud synchronization.
- The MVP MUST NOT support implicit AI write access.
- The MVP MUST NOT support unreviewed third-party extensions.
- The MVP MUST NOT treat Git-backed storage as approved for vault data.
- The MVP MUST NOT optimize for multi-device collaboration before local trust and migration models are validated.

## MVP Behavior

The MVP remains local, explicit, auditable, and CLI-first.

## Risks

- Users may expect sync and collaboration from a database-like product.
- Excluding extensions may limit early ecosystem feedback.
- Non-goals can be forgotten unless enforced by review.

## Open Questions

- Which non-goals should become explicit repository issues after Fable review?
- What criteria allow cloud sync to enter scope?

## Acceptance Criteria

- MVP planning documents cite this file when rejecting out-of-scope work.
- Future RFCs must update this file when a non-goal becomes proposed scope.

## Related Specifications

- [local-first-encrypted-vault.md](local-first-encrypted-vault.md)
- [roadmap.md](roadmap.md)
- [../storage/git-backend.md](../storage/git-backend.md)
- [../security/ai-agent-access.md](../security/ai-agent-access.md)
