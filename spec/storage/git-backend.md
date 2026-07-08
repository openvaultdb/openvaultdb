# Git Backend

## Purpose

Document risks and constraints for any future Git-backed vault storage.

## Key Concepts

- Git history: immutable or replicated commit objects that can retain deleted content.
- Secret retention: accidental persistence of data thought deleted.
- Merge conflict: divergent history requiring reconciliation.
- Public remote risk: accidental push of vault material to public repositories.

## Normative Requirements

- Git-backed storage MUST NOT be part of the MVP.
- A Git backend MUST NOT store plaintext vault data.
- A Git backend MUST address deleted-secret retention, history rewriting limits, remote exposure, merge conflicts, and key rotation before approval.
- Git-backed migration MUST include provider-trust and audit-log implications.

## MVP Behavior

No Git backend is implemented. Git is used only for project source and specifications.

## Risks

- Deleted secrets may remain in local or remote Git history.
- Public remotes can make mistakes irreversible.
- Merge conflict resolution can corrupt encrypted or structured state.
- Commit metadata can leak activity patterns.

## Open Questions

- Is Git ever appropriate for encrypted vault blobs?
- Can content-addressed encrypted chunks avoid meaningful history leaks?
- Should Git support be limited to non-secret schema and spec data?

## Acceptance Criteria

- Any future Git backend RFC explains why Git history does not violate user expectations.
- Public push accidents are treated as a first-class threat.
- Conflict resolution is specified before implementation.

## Related Specifications

- [provider-trust.md](provider-trust.md)
- [storage-backends.md](storage-backends.md)
- [../security/threat-model.md](../security/threat-model.md)
- [../mvp/non-goals.md](../mvp/non-goals.md)
