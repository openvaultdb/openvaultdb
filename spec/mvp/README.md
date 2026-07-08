# MVP Specifications

## Purpose

Index conservative local-first MVP specifications.

## Key Concepts

- Local encrypted vault first.
- Explicit application registration.
- Capability-based permissions.
- Append-only audit log.
- CLI-first reviewable workflows.

## Contents

| Path | Purpose |
|---|---|
| [local-first-encrypted-vault.md](local-first-encrypted-vault.md) | MVP scope and behavior. |
| [non-goals.md](non-goals.md) | Explicit exclusions. |
| [roadmap.md](roadmap.md) | Review and implementation sequence. |

## Normative Requirements

- MVP scope MUST remain conservative until Fable review resolves major risks.
- Cloud sync, implicit AI writes, and production ecosystem extensions MUST remain out of MVP.

## MVP Behavior

The MVP is a local encrypted vault controlled through CLI workflows and explicit approvals.

## Risks

- Narrow MVP may miss ecosystem requirements.
- Broad MVP may undermine trust before the model is validated.

## Open Questions

- What minimum developer API is needed alongside the CLI?
- Which feature is the first reference implementation milestone?

## Acceptance Criteria

- MVP scope is reviewable and excludes cloud synchronization.
- Non-goals are clear enough to prevent accidental scope expansion.

## Related Specifications

- [../vision.md](../vision.md)
- [../security/trust-model.md](../security/trust-model.md)
