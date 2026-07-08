# Fable 5 Brief: MVP Scope Review

## Current Proposal

The MVP is an InGitDB/GitHub-backed vault with CLI-first workflows, explicit app registration, capability grants, append-only audit logs, versioned schemas, and planned migrations. SQLite is second and Firestore is third. It does not encrypt vault data. It excludes general-purpose multi-provider sync, user-installable extensions, and multi-device collaboration beyond the GitHub-backed storage model.

## Key Risks

- A narrow MVP may miss integration needs from applications and agents.
- A broad MVP could invalidate the security model before review.
- CLI-only workflows may not represent eventual user approval needs.
- Hoster/provider recovery expectations may be under-specified.
- GitHub history helps restore accidental changes but can retain secrets and metadata.

## Unresolved Questions

- What minimal API should exist alongside the CLI?
- What hoster/provider recovery behavior must be documented for a first release?
- Which conformance tests block MVP release?
- What warnings should OpenVaultDB show for public repositories or unprotected branches?

## Expected Fable Review

Decide whether the MVP is scoped correctly for trustworthy implementation and identify any required pre-implementation decisions.

## Related Specification Files

- [../spec/mvp/local-first-encrypted-vault.md](../spec/mvp/local-first-encrypted-vault.md)
- [../spec/mvp/non-goals.md](../spec/mvp/non-goals.md)
- [../spec/mvp/roadmap.md](../spec/mvp/roadmap.md)
- [../spec/storage/local-first.md](../spec/storage/local-first.md)
- [../spec/cli/openvaultdb-cli.md](../spec/cli/openvaultdb-cli.md)
