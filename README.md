# OpenVaultDB

OpenVaultDB is a user-controlled private data vault and database layer for applications and AI agents. The project is intended to let users own application data, publish schemas as ModelSpec, grant narrow capabilities, audit access, and move between storage providers without trusting any single application or backend with unchecked authority.

This repository is the public gravity point for OpenVaultDB specifications, architecture review, security model review, SpecScore reports, contributors, and the future reference implementation.

## Goals

- Put user data ownership, permission boundaries, and auditability ahead of convenience.
- Define an implementation-independent vault, schema, permission, storage, and migration model before production code.
- Support hostile or compromised applications, confused AI agents, leaked credentials, stale permission caches, and untrusted storage providers.
- Make schema evolution explicit, reviewable, resumable, reversible where possible, and auditable.
- Consume ModelSpec directly for logical application schemas, migration planning, backend mapping, GraphQL generation, DTQL typing metadata, DALGO metadata, and backend generators.
- Start with a conservative local-first encrypted MVP before cloud synchronization.

## Architecture-First Development

OpenVaultDB is being developed specification-first. Production code MUST NOT outrun the architecture and security model. New implementation work SHOULD reference an approved specification or an explicit RFC in this repository.

Specifications use RFC terminology:

- MUST and MUST NOT are normative requirements.
- SHOULD is a strong recommendation with documented exceptions.
- MAY is optional behavior.
- Informative guidance explains tradeoffs without creating a requirement.

## SpecScore Workflow

This repository is initialized with the SpecScore CLI. SpecScore is a first-class part of the development workflow.

Common commands:

```sh
specscore spec lint --caller codex
specscore spec lint --fix --caller codex
specscore config show --caller codex
```

Before merging specification changes, contributors SHOULD run SpecScore lint and fix every error. Warnings should be resolved or explicitly documented.

## Repository Structure

### Specifications

- [spec/](spec/README.md): implementation-independent specifications (full index).

**Architecture and Cloud**
- [spec/architecture/](spec/architecture/README.md): plugin model, overview, reference implementation scope.
- [spec/cloud/](spec/cloud/README.md): hosted service at `api.openvaultdb.com`, architecture, pricing.
- [spec/open-source/](spec/open-source/README.md): Apache 2.0 strategy, self-hosting, third-party hosting.
- [spec/billing/](spec/billing/README.md): BillingProvider interface and pricing model.

**Security and Data**
- [spec/security/](spec/security/README.md): trust, threat, permission, capability, AI-agent, and audit models.
- [spec/schema/](spec/schema/README.md): schema definition, versioning, and migration behavior.
- [spec/storage/](spec/storage/README.md): storage backends, GitHub provider, Firestore provider.

**API and Deployment**
- [spec/api/](spec/api/README.md): application and agent API model, endpoints, auth.
- [spec/cli/](spec/cli/README.md): CLI workflows and command surface.
- [spec/deployment/](spec/deployment/README.md): Docker Compose and Kubernetes deployment.

**Integrations and Testing**
- [spec/sneat-integration/](spec/sneat-integration/README.md): Sneat Space storage selection and migration.
- [spec/testing/](spec/testing/README.md): security, migration, and plugin test matrices.

**MVP and Process**
- [spec/mvp/](spec/mvp/README.md): conservative local-first MVP scope.
- [spec/rfcs/](spec/rfcs/README.md): future proposal process.
- [spec/decisions/](spec/decisions/README.md): architectural decision record index.

### Fable 5 Review Briefs

- [fable-brief/](fable-brief/00-project-context.md): focused review briefs for the Fable 5 architecture/security sprint.
  - [00-project-context.md](fable-brief/00-project-context.md)
  - [01-security-review-brief.md](fable-brief/01-security-review-brief.md)
  - [02-permissions-review-brief.md](fable-brief/02-permissions-review-brief.md)
  - [03-schema-migration-review-brief.md](fable-brief/03-schema-migration-review-brief.md)
  - [04-mvp-scope-review-brief.md](fable-brief/04-mvp-scope-review-brief.md)
  - [05-plugin-architecture-review-brief.md](fable-brief/05-plugin-architecture-review-brief.md)
  - [06-sneat-integration-review-brief.md](fable-brief/06-sneat-integration-review-brief.md)
  - [07-commercial-model-review-brief.md](fable-brief/07-commercial-model-review-brief.md)

## Contribution Workflow

1. Start with the relevant specification.
2. Separate assumptions, decisions, open questions, normative requirements, and informative guidance.
3. Add or update tests in the relevant matrix when a requirement changes.
4. Run `specscore spec lint --caller codex`.
5. Fix lint errors before requesting review.

Implementation PRs are expected to cite the specification sections they implement. Security-sensitive behavior SHOULD include a threat-model note and at least one acceptance criterion.

## Roadmap

1. **Fable 5 review** of trust, permissions, schema evolution, plugin architecture, Sneat integration, and commercial model.
2. Resolve blocking open questions and record decisions.
3. Define executable compliance tests for the MVP.
4. Build a CLI-first local encrypted vault reference implementation (SQLite + GitHub storage).
5. Launch `api.openvaultdb.com` hosted service (managed Firestore tier).
6. Validate provider-trust and synchronization models before adding additional cloud sync backends.
7. Publish compatibility test suite for third-party hosting providers.
8. Release Go SDK and TypeScript SDK.

## License

OpenVaultDB is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
