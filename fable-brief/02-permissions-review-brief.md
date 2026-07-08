# Fable 5 Brief: Permissions Review

## Current Proposal

OpenVaultDB uses deny-by-default capability-based permissions. Applications and AI agents are distinct principals. Grants are explicit, scoped, auditable, revocable, and checked against current grant state or freshness metadata. Permission broadening requires approval and permission migrations use the migration workflow.

## Key Risks

- Capability scopes may be too hard for users to understand.
- Offline or cached grants may survive revocation.
- Delegation can hide the true actor.
- Field-level permissions can drift during schema changes.

## Unresolved Questions

- Should grants expire by default?
- What field-level permission model is required for MVP?
- How should active operations respond to revocation?
- Should signed capability tokens exist, or should grants remain local rows only?

## Expected Fable Review

Review whether the model prevents confused-deputy behavior, stale authorization, and AI-agent overreach without making ordinary app access unusable.

## Related Specification Files

- [../spec/security/permissions-model.md](../spec/security/permissions-model.md)
- [../spec/security/capability-model.md](../spec/security/capability-model.md)
- [../spec/security/ai-agent-access.md](../spec/security/ai-agent-access.md)
- [../spec/schema/migrations.md](../spec/schema/migrations.md)
