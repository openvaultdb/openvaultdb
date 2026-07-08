# ModelSpec Integration

## Purpose

Define how OpenVaultDB consumes ModelSpec without making OpenVaultDB dependent on
SpecScore or on any specific backend.

## Key Concepts

- ModelSpec: independent open specification language for application data models,
  authored in HCL and represented semantically as a ModelSpec AST.
- ModelSpec JSON: first machine-readable serialization of the ModelSpec AST,
  identified by top-level `modelspec: "1.0-draft"`.
- Current ModelSpec: model version currently governing stored records.
- Target ModelSpec: model version requested by an application, user, or migration.
- Projection: mapping from a logical ModelSpec model to a backend, API, query, or language representation.
- Advisory mapping hint: optional app-provided projection suggestion that the vault may honor or override.

## Normative Requirements

- Applications MUST publish ModelSpec as the primary logical schema contract for OpenVaultDB.
- The MVP ingestion path MUST accept a ModelSpec JSON AST serialization first while remaining compatible with HCL-authored ModelSpec modules.
- OpenVaultDB MUST load the current ModelSpec and target ModelSpec before planning schema migrations.
- OpenVaultDB MUST use ModelSpec for schema validation, migration planning, backend mapping, GraphQL schema generation, DTQL typing metadata, DALGO metadata, and backend generators.
- The first backend generator SHOULD target a GitHub repository using InGitDB layout.
- OpenVaultDB MUST keep backend choice under vault control.
- OpenVaultDB MAY accept app-provided ModelSpec projection hints, but those hints MUST be advisory and non-authoritative.
- OpenVaultDB MUST NOT treat SpecScore as the owner of ModelSpec semantics.
- OpenVaultDB MUST NOT require SpecScore at runtime unless an implementation explicitly embeds SpecScore validation tooling.
- OpenVaultDB MUST keep permissions, RBAC, OAuth, audit policy, encryption policy, workflows, deployment, and UI outside ModelSpec semantics.

## End-To-End Flow

```text
Application publishes ModelSpec
          |
          v
Vault loads current ModelSpec and target ModelSpec
          |
          v
Vault validates schema and computes semantic diff
          |
          v
Vault plans migration and backend projection
          |
          v
Vault generates backend/API/query/language metadata
          |
          v
Vault enforces writes against ModelSpec-derived validation
```

## Separation Of Concerns

| Concern | Owner | Artifact |
|---|---|---|
| Logical application data model | Application | ModelSpec module |
| Optional backend mapping suggestion | Application | Advisory ModelSpec projection |
| Backend selection | Vault | Vault configuration and policy |
| Final backend mapping | Vault | Projection plan and generated backend schema |
| Runtime validation | Vault | ModelSpec-derived validator |
| Permissions and grants | Vault and user | Capability and permission metadata |
| Audit and approval | Vault and user | Audit log and migration plan |

## MVP Behavior

The MVP accepts application-published ModelSpec via JSON AST serialization, stores
loaded model metadata with the vault schema version, validates writes against the
loaded model, and produces migration plans from current-to-target ModelSpec diffs.

The MVP may support one backend first. The preferred first backend generator is a
GitHub repository using InGitDB layout. The schema contract remains ModelSpec rather
than backend-specific DDL or JSON schema.

## Risks

- Treating projection hints as authoritative would move storage decisions back into applications.
- Confusing SpecScore validation with ModelSpec ownership would couple OpenVaultDB to the wrong project.
- Permission labels can be mistaken for ModelSpec semantics unless OpenVaultDB keeps them separate.
- Backend generators can lose constraints if unsupported target features are not reported.

## Open Questions

- Should ModelSpec validation errors be emitted on stdout, stderr, or both for CLI
  workflows?

## Acceptance Criteria

- An application can publish storage-neutral ModelSpec without selecting a backend.
- The vault can load current and target ModelSpec versions and produce a reviewable migration plan.
- The vault can generate backend metadata while preserving that the vault has final backend authority.
- The first backend generator target is documented as GitHub repository storage using InGitDB layout.
- OpenVaultDB documentation states that it depends on ModelSpec, not SpecScore.

## Related Specifications

- [schema-model.md](schema-model.md)
- [versioning.md](versioning.md)
- [migrations.md](migrations.md)
- [../storage/storage-backends.md](../storage/storage-backends.md)
- [../api/api-model.md](../api/api-model.md)
