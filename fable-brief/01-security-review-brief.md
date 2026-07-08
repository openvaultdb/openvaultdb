# Fable 5 Brief: Security Review

## Current Proposal

OpenVaultDB assumes hostile applications, confused AI agents, compromised providers, leaked credentials, stale permission caches, malicious extensions, careless users, and interrupted operations. The MVP minimizes application trust through InGitDB/GitHub-backed storage, explicit registration, capability-scoped grants, revocation, and append-only audit events. It does not encrypt vault data.

## Key Risks

- Stale permission caches may authorize after revocation.
- Provider replay may resurrect old data or grants.
- GitHub repository visibility, token scope, branch protection, and history retention become MVP security risks.
- Audit logs can leak sensitive metadata.
- Hoster/provider account recovery can undermine user ownership.
- Local malware remains a residual risk.

## Unresolved Questions

- What tamper-evidence level is required for MVP audit logs?
- What rollback or history-rewrite detection is required for GitHub-backed storage?
- Which metadata must be minimized even without encryption?
- What local authentication is required for high-risk approvals?

## Expected Fable Review

Validate attacker assumptions, residual risks, required mitigations, and whether MVP exclusions are strict enough.

## Related Specification Files

- [../spec/security/trust-model.md](../spec/security/trust-model.md)
- [../spec/security/threat-model.md](../spec/security/threat-model.md)
- [../spec/security/audit-log.md](../spec/security/audit-log.md)
- [../spec/storage/provider-trust.md](../spec/storage/provider-trust.md)
- [../spec/testing/security-test-matrix.md](../spec/testing/security-test-matrix.md)
