# Fable 5 Brief: Plugin Architecture Review

> **Status: Draft — pending Fable 5 architecture and security review.**

## Current Proposal

OpenVaultDB uses a plugin model where all major dependencies (storage, identity, billing, audit, backup, secrets, notifications, search) are replaced via plugin interfaces. Plugins are compiled into or loaded at runtime by the server. Plugin configuration is operator-controlled; users cannot install plugins.

The full plugin interface definitions are in [../spec/architecture/plugin-model.md](../spec/architecture/plugin-model.md).

## Rationale

- Forces no hardcoded dependency on any specific provider.
- Allows self-hosted and third-party deployments to use existing infrastructure (their own identity provider, billing, storage).
- Enables OpenVaultDB Cloud to be an instance of the same codebase as self-hosted deployments.
- Creates a clear extension point for ecosystem development.

## Alternatives Considered

| Alternative | Trade-off |
|---|---|
| Hardcoded GitHub + Firestore support | Simpler initial implementation; locks out third-party hosting |
| Open-core (proprietary plugins for paid tier) | Better commercial protection; undermines open-source trust |
| gRPC plugin protocol (e.g., HashiCorp plugin framework) | Process isolation; language flexibility; significant overhead |
| WASM plugin sandbox | Strong isolation; immature ecosystem; complex toolchain |
| In-process Go interfaces (proposed) | Fast; simple; no process isolation; all plugins run with full trust |

## Trade-offs

| Concern | Current Approach | Implication |
|---|---|---|
| Plugin isolation | None (in-process) | Malicious or buggy plugin can read all vault data |
| Plugin trust | Operator assumes responsibility | Users cannot control which plugins are loaded |
| Plugin versioning | Major version bump on breaking interface changes | Third-party plugins need re-validation on major upgrades |
| Plugin discovery | No registry; manual configuration | No marketplace; ecosystem growth is organic |
| Plugin testing | Compliance test suite | Third-party plugins can self-certify |

## Key Risks

1. **In-process plugin isolation**: a compromised or malicious plugin has full access to all vault data and can bypass authorization. This is arguably the highest-risk architectural decision.
2. **Interface stability**: frequent interface changes break third-party plugins; too-stable interfaces may prevent necessary security improvements.
3. **Plugin trust model gap**: the operator is trusted to vet plugins, but there is no mechanism to verify plugin integrity after installation.
4. **Missing SearchProvider**: without search, many application use cases are limited; with an untrusted SearchProvider, search indexes may leak sensitive data.
5. **BillingProvider design**: if BillingProvider is required but unavailable, does the server fail? This is a single point of failure for hosted deployments.

## Dangerous Assumptions

- Operators will correctly vet third-party plugins before deployment. In practice, many operators will install plugins from unknown sources.
- In-process plugin isolation is sufficient for the MVP. This may be acceptable initially but should be explicitly acknowledged as a known risk.
- Plugin interface contracts will remain stable across minor versions. Without a formal compatibility guarantee, third-party plugins will break.
- All eight plugin types are necessary for MVP. Some (SearchProvider, BackupProvider) may be safely deferred.

## Open Questions for Fable 5

1. **Plugin isolation**: Is in-process plugin execution acceptable for the MVP, given the security implications? What is the minimum viable isolation mechanism?
2. **Required vs. optional plugins**: Which plugins are required for server startup? Can SearchProvider be optional? Can BackupProvider be optional?
3. **Plugin integrity**: Should the server verify plugin signatures before loading?
4. **Interface stability**: What is the recommended policy for plugin interface versioning and compatibility?
5. **Separate process**: At what point should the architecture move to separate-process plugins (e.g., gRPC or WASM)? What triggers that investment?
6. **Plugin registry**: Should the project provide a plugin registry or marketplace? What are the governance implications?
7. **StorageProvider transactions**: Should the StorageProvider interface require transactions, or should the server use checkpoint-based semantics for providers without transactions?
8. **SearchProvider data isolation**: If a SearchProvider indexes vault data, how should search indexes be isolated between tenants and between principals?

## Expected Fable Review Output

- Assessment of whether in-process plugin isolation is acceptable for MVP.
- Recommendation on which plugins are required vs. optional.
- Assessment of plugin interface completeness and correctness.
- Identification of any missing plugin types needed for the security model.
- Recommendation on plugin versioning and compatibility policy.
- Red flags in the proposed Go interface definitions.

## Related Specification Files

- [../spec/architecture/plugin-model.md](../spec/architecture/plugin-model.md)
- [../spec/architecture/overview.md](../spec/architecture/overview.md)
- [../spec/testing/plugin-test-matrix.md](../spec/testing/plugin-test-matrix.md)
- [../spec/security/trust-model.md](../spec/security/trust-model.md)
- [../spec/open-source/third-party-hosting.md](../spec/open-source/third-party-hosting.md)
