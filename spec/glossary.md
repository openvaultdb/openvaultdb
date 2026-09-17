# Glossary

## Purpose

Provide shared terms for architecture, security, schema, storage, and review discussions.

## Key Concepts

| Term | Definition |
|---|---|
| Vault | A user-owned data store plus schemas, permissions, audit log, and metadata. |
| Principal | An actor such as a user, application, AI agent, extension, CLI session, or storage provider. |
| Application | Software requesting access to vault data or schema operations. |
| ModelSpec | Independent open specification language for application data models consumed by OpenVaultDB for logical schemas. |
| AI agent | A delegated principal that can act on behalf of a user or application with explicit limits. |
| Capability | A scoped, auditable authorization to perform specific operations on specific resources. |
| Permission grant | A user-approved assignment of capabilities to a principal. |
| Collection | A named group of records governed by a schema version and permissions. |
| Record | A stored data item with identity, schema version metadata, and audit-relevant change history. |
| Schema | A versioned ModelSpec definition plus OpenVaultDB-owned permission, audit, and storage metadata. |
| Projection | Mapping from a logical ModelSpec model to a backend, API, query, or language representation. |
| Migration | A planned transition of schema, data, permissions, indexes, storage format, or encryption state. |
| Checkpoint | Durable migration progress metadata that allows resume or rollback decisions. |
| Provider | A storage backend or synchronization service that stores vault data and metadata. |
| Database | The unit a local OVDB server serves at `/v1/databases/{id}`: one storage location (for example an inGitDB folder or a SQLite file) described by a manifest. Used in local onboarding copy; see Open Questions for its relation to Vault. |
| Local server (OVDB server) | One per-user OVDB process serving registered databases, the web console and the local API at `http://ovdb.localhost:6832` by default. See [decision 0007](decisions/0007-local-ovdb-server-and-web-address.md). |
| Context | The database and path an `ovdb` command uses when none is given, remembered per project or as a global default. See [decision 0008](decisions/0008-database-context-scope.md). |
| Path | A location inside a database written like a file path, alternating collection and record id: `/lists/to-buy/items/42`. |
| Audit log | Append-only record of security-relevant events and user-visible decisions. |

## Normative Requirements

- Specifications MUST use these terms consistently unless a local definition is explicitly stated.
- Capability and permission MUST NOT be used interchangeably.
- Provider trust MUST mean the assumptions about a backend, not a guarantee that the backend is safe.

## MVP Behavior

The MVP uses a GitHub/InGitDB-backed vault, registered principals, and CLI-mediated permission grants.

## Risks

- Ambiguous terms can hide security gaps.
- Users may interpret provider support as provider trust.
- "AI agent" may cover both local tools and remote hosted systems with different risks.

## Open Questions

- Should "workspace" be a first-class term separate from vault?
- Should records expose stable global IDs or vault-local IDs only?
- How do Vault and Database relate? Local onboarding (2026-09-17, [idea](ideas/ovdb-onboarding-and-configuration.md)) uses *database* because the implemented API (`/v1/databases/{id}`) and DataTug (`databaseId`) do, while this glossary and `openvaultdb-com` decision 0003 (In Review, Host / Vault / Namespace) use *vault* for the user-owned unit apps connect to. Candidate reconciliation: a vault is what a person grants apps access to; a database is what a server stores and serves; a vault may map to one database.

## Acceptance Criteria

- Every major specification uses terms from this glossary.
- Terms that affect permissions, audit, or migrations are defined before use.

## Related Specifications

- [security/permissions-model.md](security/permissions-model.md)
- [security/capability-model.md](security/capability-model.md)
- [schema/schema-model.md](schema/schema-model.md)
- [storage/storage-backends.md](storage/storage-backends.md)
