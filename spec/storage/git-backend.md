# Git Backend

## Purpose

Define the Git-backed storage posture for the first OpenVaultDB MVP backend.

## Key Concepts

- InGitDB: the first OpenVaultDB storage target, using a Git repository layout generated from ModelSpec.
- Git history: immutable or replicated commit objects that can retain deleted content and support point-in-time restore.
- Secret retention: accidental persistence of data thought deleted.
- Merge conflict: divergent history requiring reconciliation.
- Public remote risk: accidental push of vault material to public repositories.

## Normative Requirements

- InGitDB/Git-backed storage SHOULD be the first MVP backend.
- The MVP Git backend MAY store plaintext vault data and MUST document that repository access exposes vault contents.
- A Git backend MUST address deleted-secret retention, history rewriting limits, remote exposure, merge conflicts, optional branch protection, and key rotation before production use.
- Git-backed migration MUST include provider-trust and audit-log implications.
- OpenVaultDB MUST NOT require a particular GitHub repository visibility or branch-protection policy for MVP.
- Users or hosters decide whether to use private repositories, branch protection, force-push restrictions, or deletion restrictions.
- Git history MAY be used for accidental recovery, but it MUST NOT be treated as a confidentiality control.

## MVP Behavior

The MVP targets an InGitDB repository layout first. SQLite is the second backend target and Firestore is the third. GitHub repository visibility and branch protection are user or hoster policy choices. Data is not encrypted by OpenVaultDB in the MVP.

## Risks

- Deleted secrets may remain in local or remote Git history.
- Public remotes can make mistakes irreversible.
- Merge conflict resolution can corrupt structured state.
- Commit metadata can leak activity patterns.
- Git restore helps recover accidental writes or deletes, but it does not prevent data exposure.

## Open Questions

- Should future encrypted chunks be content-addressed, randomized, or avoided?

## Acceptance Criteria

- The MVP Git backend documents its repository layout, optional branch-protection settings, plaintext-data risk, and recovery workflow.
- Public push accidents are treated as a first-class threat.
- Conflict resolution is specified before implementation.

## Related Specifications

- [provider-trust.md](provider-trust.md)
- [storage-backends.md](storage-backends.md)
- [../security/threat-model.md](../security/threat-model.md)
- [../mvp/non-goals.md](../mvp/non-goals.md)
