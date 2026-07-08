# Migration Test Matrix

## Purpose

Define review-ready migration test scenarios.

## Key Concepts

- Plan test: validates migration proposal content.
- Execution test: validates checkpoint, progress, and completion.
- Recovery test: validates resume or rollback after interruption.
- Permission test: validates authorization during schema evolution.

## Normative Requirements

- Migration tests MUST cover destructive schema changes, field renames, permission broadening, storage backend migration, Git-backed history, operator plugin/provider behavior, AI-triggered migrations, and future encryption/key-rotation migrations.
- Tests MUST verify progress and audit events where applicable.

## MVP Behavior

| ID | Scenario | Expected Result | Related Specs |
|---|---|---|---|
| MIG-001 | Add optional field. | Plan is low risk and resumable. | [../schema/schema-model.md](../schema/schema-model.md) |
| MIG-002 | Rename field. | Plan preserves source/target mapping and validates data. | [../schema/migrations.md](../schema/migrations.md) |
| MIG-003 | Delete field. | Explicit destructive approval required. | [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md) |
| MIG-004 | Broaden field permission label. | Migration-style plan and approval required. | [../security/permissions-model.md](../security/permissions-model.md) |
| MIG-004B | Bulk revoke grants or narrow permission labels in a way that breaks apps. | Migration-style plan and approval required. | [../security/permissions-model.md](../security/permissions-model.md) |
| MIG-005 | Future encryption key rotation is proposed. | Rejected as post-MVP unless explicit encryption mode exists. | [../schema/migrations.md](../schema/migrations.md) |
| MIG-006 | Kill process mid-batch. | Resume from checkpoint or require rollback. | [../schema/data-migrations.md](../schema/data-migrations.md) |
| MIG-007 | AI-agent-initiated migration uses an authenticated app principal. | Plan identifies the authenticated principal and required approval, without separate AI identity. | [../security/ai-agent-access.md](../security/ai-agent-access.md) |
| MIG-008 | Git-backed InGitDB vault migration runs with user-selected repository policy. | Plan reports repository visibility, branch-protection status, and restore path without blocking on policy. | [../storage/git-backend.md](../storage/git-backend.md) |
| MIG-009 | User-installable extension transform. | Rejected as out of MVP; future RFC required. | [../mvp/non-goals.md](../mvp/non-goals.md) |
| MIG-010 | Backend migration local to future provider. | Plan requires provider trust review. | [../storage/provider-trust.md](../storage/provider-trust.md) |

## Risks

- Rollback expectations may differ by migration class.
- Progress metrics may be unavailable for streaming or future encrypted backends.

## Open Questions

- Which migration classes require preflight backup?
- How should quarantine behavior be tested?

## Acceptance Criteria

- Test rows cover plan, approval, execution, progress, audit, resume, and rollback behavior.
- Each high-risk migration class has a denial or approval scenario.

## Related Specifications

- [../schema/migrations.md](../schema/migrations.md)
- [../schema/data-migrations.md](../schema/data-migrations.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
