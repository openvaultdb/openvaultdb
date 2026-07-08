# Fable 5 Brief: MVP Scope Review

## Current Proposal

The MVP is a local-first encrypted vault with CLI-first workflows, explicit app registration, capability grants, append-only audit logs, versioned schemas, and planned migrations. It excludes cloud sync, implicit AI writes, unreviewed extensions, Git-backed vault data, and multi-device collaboration.

## Key Risks

- A narrow MVP may miss integration needs from applications and agents.
- A broad MVP could invalidate the security model before review.
- CLI-only workflows may not represent eventual user approval needs.
- Local backup and recovery expectations may be under-specified.

## Unresolved Questions

- What minimal API should exist alongside the CLI?
- What key recovery behavior is acceptable for a first release?
- Which conformance tests block MVP release?
- What happens to sibling repositories once this repo becomes canonical?

## Expected Fable Review

Decide whether the MVP is scoped correctly for trustworthy implementation and identify any required pre-implementation decisions.

## Related Specification Files

- [../spec/mvp/local-first-encrypted-vault.md](../spec/mvp/local-first-encrypted-vault.md)
- [../spec/mvp/non-goals.md](../spec/mvp/non-goals.md)
- [../spec/mvp/roadmap.md](../spec/mvp/roadmap.md)
- [../spec/storage/local-first.md](../spec/storage/local-first.md)
- [../spec/cli/openvaultdb-cli.md](../spec/cli/openvaultdb-cli.md)
