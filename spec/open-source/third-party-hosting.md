# Third-Party Hosting

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define what it means to be a third-party OpenVaultDB hosting provider, what is permitted and recommended, and how the ecosystem should differentiate.

## Definition

A third-party hosting provider is an organization that deploys the OpenVaultDB reference implementation and offers it as a service under their own brand, domain, billing, and support model.

Examples:

```
https://ovdb.hosting-provider.com
https://vault.company.internal
https://data.regional-cloud.example
```

## Permitted Under Apache 2.0

Third-party providers:

- MAY deploy the reference implementation commercially.
- MAY use their own domain, brand, and pricing.
- MAY configure their own storage, identity, and billing plugins.
- MAY add proprietary plugins (Apache 2.0 does not require publishing modifications to plugins).
- MAY offer features not present in the hosted OpenVaultDB Cloud service (via plugins).
- MAY fork the server code; however, maintaining a fork has ongoing cost.
- MUST NOT use the "OpenVaultDB Cloud" name without permission.
- MUST NOT misrepresent compliance with the OpenVaultDB protocol if they have diverged from it.

## Recommended Compatibility

Third-party providers who claim OpenVaultDB compatibility SHOULD:

1. Pass the official compatibility test suite (when published).
2. Implement the full API surface required for SDK compatibility.
3. Support standard authentication methods (OIDC, API keys).
4. Support the data export API so users can migrate away.
5. Implement the standard plugin interfaces without undocumented extensions to core protocol messages.

> **Open question**: Should there be a formal certification program? This requires maintaining the test suite and certification infrastructure.

## Plugin Configuration Freedom

Third-party providers can plug in:

| Plugin Type | Example Provider-Specific Choices |
|---|---|
| StorageProvider | S3, Azure Blob, local NFS, proprietary database |
| IdentityProvider | Corporate SSO, LDAP, custom OIDC |
| BillingProvider | Their own billing system |
| BackupProvider | Provider-specific backup infrastructure |
| AuditProvider | Provider-specific audit export |
| NotificationProvider | Provider-specific notification system |

This is by design: third-party providers should be able to use their existing infrastructure without modifying core server code.

## User Migration Rights

Users hosted at a third-party provider MUST be able to:

1. Export their complete vault data at any time.
2. Import that data into another OpenVaultDB-compatible instance (including `api.openvaultdb.com`).
3. Revoke the provider's access credentials from within the vault.

> **Risk**: A third-party provider that implements a non-standard storage format or withholds the export API effectively locks in users. The open-source strategy does not prevent this unless the compatibility test suite is enforced.

## Third-Party Provider Discovery (Draft)

Proposed: a community-maintained registry of third-party OpenVaultDB providers, with compatibility certification status. This is analogous to CNCF Certified Kubernetes providers.

> **Alternative**: No registry; relying on market discovery. Simpler; less overhead; may fragment the ecosystem.

## Assumptions

- Third-party providers are responsible for their own compliance, data protection, and security.
- Users choose a provider based on geography, price, and trust.
- OpenVaultDB project does not endorse specific third-party providers.
- SDK compatibility is the primary technical constraint; providers that diverge break client applications.

## Open Questions

1. Should a compatibility test suite be a hard requirement before using the "OpenVaultDB compatible" label?
2. How should the project handle a provider that implements a known-broken security model?
3. Should providers be required to publish their plugin list?
4. What is the minimum API surface for a compliant OpenVaultDB provider?

## Risks

- Protocol fragmentation: providers add undocumented extensions; SDKs break.
- Security: a provider with a weak security model damages the OpenVaultDB reputation.
- User confusion: too many providers with varying features make the ecosystem confusing.
- Captive portals: providers that make migration difficult undermine user data ownership.

## Acceptance Criteria

- A third-party provider can deploy the reference implementation using only public documentation.
- Applications using the Go or TypeScript SDK work against any compatible provider without code changes.
- Users can export their data from any provider and import it into `api.openvaultdb.com`.

## Related Specifications

- [strategy.md](strategy.md)
- [self-hosting.md](self-hosting.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../api/endpoints.md](../api/endpoints.md)
- [../sneat-integration/provider-discovery.md](../sneat-integration/provider-discovery.md)
