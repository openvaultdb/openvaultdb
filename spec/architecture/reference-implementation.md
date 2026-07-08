# Reference Implementation

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the scope, structure, and quality requirements for the OpenVaultDB reference implementation: the canonical open-source server that powers both `api.openvaultdb.com` and self-hosted deployments.

## Scope

The reference implementation includes:

| Component | Language | Notes |
|---|---|---|
| Server | Go | Core server binary |
| CLI (`ovdb`) | Go | Operator and developer tooling |
| Go SDK | Go | Application SDK |
| TypeScript SDK | TypeScript | Application SDK |
| Core plugins | Go | SQLite, GitHub, Firestore, local audit, builtin auth |
| Docker Compose | YAML | Local development and evaluation |
| Kubernetes Helm chart | YAML | Production deployment |
| Integration tests | Go | Compatibility test suite |

## Repository Structure (Proposed)

```
openvaultdb/
├── cmd/
│   ├── ovdb/         # CLI binary
│   └── ovdbserver/   # Server binary
├── internal/
│   ├── server/       # HTTP server, routing, middleware
│   ├── vault/        # Vault service
│   ├── schema/       # Schema service
│   ├── migration/    # Migration service
│   ├── audit/        # Audit service
│   └── auth/         # Authentication and authorization
├── plugin/
│   ├── interface/    # Plugin interface definitions
│   ├── storage/
│   │   ├── sqlite/
│   │   ├── github/
│   │   └── firestore/
│   ├── identity/
│   │   ├── builtin/
│   │   └── oidc/
│   ├── billing/
│   │   ├── disabled/
│   │   └── stripe/
│   ├── audit/
│   │   └── local/
│   └── backup/
│       └── local/
├── sdk/
│   ├── go/
│   └── ts/
├── spec/             # This specification set
├── fable-brief/      # Fable review briefs
├── examples/
│   ├── todo-app/
│   └── sneat-integration/
├── deploy/
│   ├── docker-compose.yml
│   └── helm/
└── test/
    ├── compatibility/
    └── integration/
```

> **Open question**: Should SDK code live in this monorepo or in separate repositories (openvaultdb-go, openvaultdb-ts)? Monorepo simplifies cross-cutting changes; separate repos simplify versioning for SDK consumers.

## Language Choice

**Go** for the server and CLI.

Rationale:
- Single binary deployment; no runtime dependencies.
- Strong concurrency model for handling concurrent migrations and requests.
- Good ecosystem for cloud storage clients (GCP, AWS, GitHub).
- Consistent with many self-hosted infrastructure tools.

> **Alternative**: Rust. Better memory safety properties; harder to find contributors; longer development time.
> **Alternative**: TypeScript/Node.js. Easier for web developers to contribute; worse deployment story for self-hosting.

## Quality Requirements

| Requirement | Target (Draft) |
|---|---|
| Test coverage (unit) | >80% for core services |
| Compatibility test suite | All plugin interfaces covered |
| Migration rollback | Tested for every migration type |
| Security test matrix | All threat scenarios have a test |
| Performance | 1000 req/s read on SQLite backend (local, single-user) |
| Memory footprint | <100MB idle for single-user deployment |
| Startup time | <2s cold start |

> **Note**: Performance targets are draft estimates. Real targets require benchmarking.

## Versioning and Stability

Proposed versioning scheme:
- Major version (X.0.0): breaking changes to plugin interfaces or API.
- Minor version (0.X.0): new features, backward-compatible.
- Patch version (0.0.X): bug fixes, security patches.

Plugin interface stability:
- Plugin interfaces in `plugin/interface/` follow the same versioning.
- Breaking plugin interface changes require a major version bump.
- Third-party plugin authors must pin to a major version range.

> **Open question**: Should plugin interfaces be versioned independently from the server? (e.g., StorageProvider v2, IdentityProvider v1)

## MVP Implementation Scope (Draft)

For the first reference implementation release:

**In scope:**
- Server with SQLite storage plugin
- GitHub storage plugin
- Builtin identity plugin (username/password)
- OIDC identity plugin (Google)
- Local file audit plugin
- Core API (vault, app, grant, schema, migration)
- CLI (`ovdb server`, `ovdb vault`, `ovdb app`, `ovdb migration`)
- Go SDK
- Docker Compose
- Unit and integration tests

**Out of scope for MVP:**
- Firestore storage plugin (planned for v0.2)
- Stripe billing plugin (planned for v0.2)
- TypeScript SDK (planned for v0.3)
- Kubernetes Helm chart (planned for v0.2)
- Full-text search plugin
- Multi-region deployment

## Compliance Test Suite

The reference implementation includes a compatibility test suite that any implementation can run to verify:
- API correctness
- Plugin interface compliance
- Migration correctness
- Security behavior (token rejection, revocation propagation, etc.)

> **This test suite is the technical foundation for third-party provider compatibility claims.**

## Open Questions

1. Monorepo or separate repositories for SDKs?
2. Should the reference implementation include a web UI, or is CLI-first sufficient for MVP?
3. How should the compliance test suite be run against third-party implementations?
4. What CI/CD pipeline is required before the first release?
5. Should the server support hot-reload of plugin configuration?

## Risks

- Monorepo may slow iteration; but premature split creates coordination overhead.
- Go is a good choice, but it narrows the contributor base compared to TypeScript/Python.
- Performance targets may be unrealistic for some storage backends (GitHub API rate limits).
- Without a web UI, non-technical users cannot use the reference implementation directly.

## Related Specifications

- [overview.md](overview.md)
- [plugin-model.md](plugin-model.md)
- [../open-source/self-hosting.md](../open-source/self-hosting.md)
- [../deployment/docker-compose.md](../deployment/docker-compose.md)
- [../cli/commands.md](../cli/commands.md)
- [../testing/plugin-test-matrix.md](../testing/plugin-test-matrix.md)
