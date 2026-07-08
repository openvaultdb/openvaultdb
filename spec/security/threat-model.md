# Threat Model

## Purpose

Define expected attackers, abuse cases, and security boundaries.

## Key Concepts

- Malicious app: software that requests or abuses vault access.
- Confused agent: AI agent that misinterprets user intent or tool output.
- Compromised provider: backend that leaks, alters, replays, or deletes vault data.
- Leaked credential: token, capability, or key material disclosed to an attacker.
- Interrupted operation: crash, power loss, or process kill during a sensitive write.

## Normative Requirements

- The system MUST defend against malicious applications requesting excessive access.
- The system MUST handle leaked non-key credentials through revocation and grant versioning.
- The system MUST detect or make visible provider replay where feasible.
- The system MUST treat migrations as security-sensitive operations.
- The system MUST record security-relevant denied attempts, approvals, revocations, and migration events.
- The system MUST NOT rely on hidden prompts or unreviewable agent reasoning for authorization.

## MVP Behavior

The MVP focuses on narrow grants, append-only audit events, explicit migration planning, and GitHub/InGitDB provider risks. It does not encrypt vault data.

## Risks

- Full local device compromise can defeat local-only controls.
- Record data, collection names, and access timing may be visible to GitHub, hosters, repository admins, and integrations.
- Git history can preserve deleted secrets because MVP data is not encrypted by OpenVaultDB.
- Permission broadening during migration can become a privilege escalation path.

## Open Questions

- What tamper-evidence level is required for the local audit log?
- Should MVP detect rollback or history-rewrite attacks on the Git-backed vault?
- Which metadata fields must be minimized even without encryption?

## Acceptance Criteria

- Each named attacker has at least one documented mitigation or accepted residual risk.
- Security tests cover malicious apps, confused AI agents, stale permissions, leaked tokens, and interrupted migrations.
- The model states what is out of scope, including total device compromise.

## Related Specifications

- [trust-model.md](trust-model.md)
- [permissions-model.md](permissions-model.md)
- [audit-log.md](audit-log.md)
- [../testing/security-test-matrix.md](../testing/security-test-matrix.md)
