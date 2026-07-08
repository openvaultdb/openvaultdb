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

- [spec/](spec/README.md): implementation-independent specifications.
- [spec/security/](spec/security/README.md): trust, threat, permission, capability, AI-agent, and audit models.
- [spec/schema/](spec/schema/README.md): schema definition, versioning, and migration behavior.
- [spec/storage/](spec/storage/README.md): local-first and backend trust assumptions.
- [spec/cli/](spec/cli/README.md): CLI workflows and command surface.
- [spec/api/](spec/api/README.md): application and agent API model.
- [spec/mvp/](spec/mvp/README.md): conservative local-first MVP scope.
- [spec/testing/](spec/testing/README.md): security and migration test matrices.
- [spec/rfcs/](spec/rfcs/README.md): future proposal process.
- [spec/decisions/](spec/decisions/README.md): architectural decision record index.
- [fable-brief/](fable-brief/00-project-context.md): focused review briefs for the Fable 5 architecture/security sprint.

## Contribution Workflow

1. Start with the relevant specification.
2. Separate assumptions, decisions, open questions, normative requirements, and informative guidance.
3. Add or update tests in the relevant matrix when a requirement changes.
4. Run `specscore spec lint --caller codex`.
5. Fix lint errors before requesting review.

Implementation PRs are expected to cite the specification sections they implement. Security-sensitive behavior SHOULD include a threat-model note and at least one acceptance criterion.

## Roadmap

1. Fable 5 review of trust, permissions, schema evolution, and MVP scope.
2. Resolve blocking open questions and record decisions.
3. Define executable compliance tests for the MVP.
4. Build a CLI-first local encrypted vault reference implementation.
5. Validate provider-trust and synchronization models before adding cloud sync.

## License

OpenVaultDB is licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
