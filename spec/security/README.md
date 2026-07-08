# Security Specifications

## Purpose

Index OpenVaultDB security specifications.

## Key Concepts

- Trust is minimized, explicit, and documented.
- Permissions are capability-based and auditable.
- AI agents are delegated principals, not trusted users.
- Storage providers are assumed compromiseable.

## Contents

| Path | Purpose |
|---|---|
| [trust-model.md](trust-model.md) | Trust boundaries, principals, and ownership. |
| [threat-model.md](threat-model.md) | Expected adversaries and abuse cases. |
| [permissions-model.md](permissions-model.md) | Grant, revoke, cache, and approval behavior. |
| [capability-model.md](capability-model.md) | Capability shape and enforcement expectations. |
| [ai-agent-access.md](ai-agent-access.md) | Delegated AI-agent access and write constraints. |
| [audit-log.md](audit-log.md) | Append-only security event model. |

## Normative Requirements

- Security behavior MUST be testable through acceptance criteria or test matrices.
- Specifications MUST NOT claim safety without naming the attacker model and residual risk.

## MVP Behavior

The MVP uses explicit app registration, scoped capabilities, no special AI privileges, provider/hoster-managed access recovery, and append-only audit logging. It does not encrypt vault data.

## Risks

- Approval fatigue could undermine least privilege.
- Stale permission caches can outlive revocation.
- Audit logs may reveal sensitive metadata.

## Open Questions

- Which audit events are mandatory for all implementations?
- Should extensions be banned entirely in the MVP?

## Acceptance Criteria

- Each security spec names purpose, risks, open questions, acceptance criteria, and related specs.
- Fable 5 can review trust, threat, permission, AI, and audit models independently.

## Related Specifications

- [../testing/security-test-matrix.md](../testing/security-test-matrix.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
