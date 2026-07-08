# Fable 5 Brief: Project Context

## Current Proposal

OpenVaultDB is a user-controlled private data vault and database layer for applications and AI agents. This repository is the canonical public home for specifications, architecture documentation, security model, SpecScore workflow, contributors, and project-level decisions.

The proposed MVP is an encrypted vault using InGitDB/GitHub-backed storage first, with explicit application registration, capability-based permissions, append-only audit logging, migration planning, and CLI-first workflows. SQLite is the second backend target and Firestore is third.

## Key Risks

- The permission model may be too complex for users to safely approve.
- GitHub-backed encryption can still fail through key handling, repository visibility, token leakage, Git history retention, backups, logs, or device compromise.
- Schema evolution touches permissions, encryption, storage, and auditability.
- AI-agent delegation can create confused-deputy and prompt-injection paths.

## Unresolved Questions

- What passphrase recovery model is acceptable?
- Do AI-initiated calls require special identity capture beyond normal application principal identity?
- What minimum migration UX makes destructive changes understandable?
- What InGitDB repository protection rules are mandatory?

## Expected Fable Review

Review whether the architecture is scoped tightly enough for a trustworthy MVP and whether any missing security boundary blocks implementation.

## Related Specification Files

- [../spec/vision.md](../spec/vision.md)
- [../spec/mvp/local-first-encrypted-vault.md](../spec/mvp/local-first-encrypted-vault.md)
- [../spec/risky-assumptions.md](../spec/risky-assumptions.md)
- [../spec/open-questions.md](../spec/open-questions.md)
