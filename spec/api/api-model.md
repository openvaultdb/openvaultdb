# API Model

## Purpose

Define the implementation-independent API behavior for applications and AI agents.

## Key Concepts

- Registration API: establish principal identity and requested metadata.
- Capability check: authorization step before every protected operation.
- Schema API: declare, inspect, diff, and propose schema changes.
- Record API: read, query, write, delete, and export data.
- Migration API: propose, inspect, approve, execute, monitor, resume, and rollback migrations.

## Normative Requirements

- API calls MUST authenticate the principal and authorize against current capability state.
- Protected operations MUST fail closed when grant state is unavailable or stale.
- API errors MUST distinguish authentication failure, authorization denial, validation failure, conflict, and migration-required states.
- APIs MUST expose migration plans as data before execution.
- APIs MUST NOT allow AI agents to self-approve high-risk operations.

## MVP Behavior

The MVP API may be local-only and CLI-mediated, but the model assumes future application bindings for Go, TypeScript, and other languages.

## Risks

- Localhost APIs can be called by unintended processes.
- Embedded libraries can blur application and vault authority.
- Error messages can leak resource existence.
- Language bindings can drift from the canonical capability model.

## Open Questions

- What transport provides the safest MVP boundary?
- Should application bindings be generated from an API schema?
- How are API compatibility and schema compatibility versioned together?

## Acceptance Criteria

- Every API endpoint or function maps to required capabilities.
- Authorization decisions use current grant state or validated freshness.
- Migration APIs expose all fields required by [../schema/migrations.md](../schema/migrations.md).

## Related Specifications

- [../security/capability-model.md](../security/capability-model.md)
- [../security/permissions-model.md](../security/permissions-model.md)
- [../schema/schema-model.md](../schema/schema-model.md)
- [../cli/commands.md](../cli/commands.md)
