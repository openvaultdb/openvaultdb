# Fable 5 Brief: Permissions Review

## Current Proposal

OpenVaultDB uses deny-by-default capability-based permissions. Websites, applications, CLIs, and AI agents may call the same API, but authorization is based on authenticated principal and granted capabilities. Grants are explicit, scoped, auditable, revocable, and checked against current grant state or freshness metadata. The MVP may support non-expiring or long-lived grants, with one year as a candidate duration.

## Key Risks

- Capability scopes may be too hard for users to understand.
- Offline or cached grants may survive revocation.
- Delegation can hide the true actor.
- Field-level permissions can drift during schema changes.

## Unresolved Questions

- Should grants default to non-expiring, one year, or another long-lived duration?
- What field-level permission model is required for MVP?
- How should active operations respond to revocation?
- Should signed capability tokens exist, or should grants remain local rows only?

## Expected Fable Review

Review whether the model prevents confused-deputy behavior and stale authorization without making ordinary app, website, CLI, service, or AI-agent-initiated access unusable.

## Related Specification Files

- [../spec/security/permissions-model.md](../spec/security/permissions-model.md)
- [../spec/security/capability-model.md](../spec/security/capability-model.md)
- [../spec/security/ai-agent-access.md](../spec/security/ai-agent-access.md)
- [../spec/schema/migrations.md](../spec/schema/migrations.md)
