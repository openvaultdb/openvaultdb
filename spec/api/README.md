# API Specifications

## Purpose

Index API specifications for applications and agents.

## Key Concepts

- APIs are authorization boundaries, not convenience wrappers.
- Applications and AI agents are distinct principals.
- Capability checks happen before protected operations.
- Migration APIs expose plans before execution.

## Contents

| Path | Purpose |
|---|---|
| [api-model.md](api-model.md) | Principal registration, capability checks, schemas, records, migrations, and audit APIs. |

## Normative Requirements

- API specifications MUST map protected operations to capabilities.
- API specifications MUST preserve the security model used by the CLI.

## MVP Behavior

The MVP may expose only local or CLI-mediated APIs until transport and process-boundary risks are reviewed.

## Risks

- Local APIs can be reached by unintended processes.
- Language bindings can drift from canonical authorization rules.

## Open Questions

- Should the MVP API be local IPC, HTTP over localhost, embedded library calls, or multiple profiles?

## Acceptance Criteria

- API behavior can be reviewed independently of a specific language binding.
- API operations do not bypass grants, audit, or migration approvals.

## Related Specifications

- [api-model.md](api-model.md)
- [../security/capability-model.md](../security/capability-model.md)
