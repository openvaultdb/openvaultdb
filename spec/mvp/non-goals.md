# Non-Goals

## Purpose

Define what OpenVaultDB will not attempt in the initial MVP.

## Key Concepts

- Non-goal: intentionally excluded scope.
- Deferral: important future work excluded until a reviewed model exists.
- Risk containment: avoiding features that expand the threat model too early.

## Normative Requirements

- The MVP MUST NOT include general-purpose multi-provider cloud synchronization beyond the first GitHub/InGitDB storage target.
- The MVP MUST NOT give AI agents special privileges beyond the principal and grants used for the call.
- The MVP MUST NOT support user-installable extensions.
- Any future user-installable extension system MUST require an RFC before it exists.
- Operator or hoster configured plugins/providers are separate from user-installable extensions and are covered by [../architecture/plugin-model.md](../architecture/plugin-model.md).
- The MVP MUST NOT optimize for multi-device collaboration before local trust and migration models are validated.

## MVP Behavior

The MVP remains explicit, auditable, CLI-first, and Git-backed through InGitDB/GitHub storage.

## Risks

- Users may expect GitHub-backed storage to provide stronger confidentiality or atomicity than it does.
- Excluding user-installable extensions may limit early ecosystem feedback.
- Confusing operator plugins with user-installable extensions can overstate MVP surface area.
- Non-goals can be forgotten unless enforced by review.

## Open Questions

- Which non-goals should become explicit repository issues after Fable review?
- What criteria allow additional cloud sync providers beyond GitHub/InGitDB to enter scope?

## Acceptance Criteria

- MVP planning documents cite this file when rejecting out-of-scope work.
- Future RFCs must update this file when a non-goal becomes proposed scope.
- User-installable extension proposals are rejected unless accompanied by an RFC.

## Related Specifications

- [local-first-encrypted-vault.md](local-first-encrypted-vault.md)
- [roadmap.md](roadmap.md)
- [../storage/git-backend.md](../storage/git-backend.md)
- [../security/ai-agent-access.md](../security/ai-agent-access.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
