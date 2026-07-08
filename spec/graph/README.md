# OpenVaultDB Domain Graph

GraphSpec domain model for OpenVaultDB, derived from the topical
specifications under [`../`](../README.md) and the vault model notes
(Host -> Vault -> Namespace). Modules are bounded contexts; each module
owns its artifacts by placement and declares outbound dependencies via
`dependsOn`. Structure lives in ModelSpec sources under each module's
`models/` directory.

Validate with `specscore graph lint`.

## Modules

| Module | Summary |
|---|---|
| [common](modules/common/README.md) | Shared ModelSpec components and vocabularies (models only). |
| [identity](modules/identity/README.md) | Principals: users, applications, AI agents, service accounts. |
| [vaults](modules/vaults/README.md) | Hosts, vaults, namespaces, collections, and records. |
| [schema](modules/schema/README.md) | ModelSpec consumption, schema versions, and projections. |
| [access](modules/access/README.md) | Capabilities, grants, delegation, and registration. |
| [audit](modules/audit/README.md) | Append-only audit log. |
| [migration](modules/migration/README.md) | Migration plans, approval, execution, and checkpoints. |
| [storage](modules/storage/README.md) | Storage backends and provider integrity. |

## Open Questions

None at this time.
