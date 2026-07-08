# Open-Source Strategy

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the open-source strategy for OpenVaultDB: the licensing model, the relationship between the open-source reference implementation and the hosted commercial service, and the obligations and freedoms of downstream users.

## Core Principle

> The official OpenVaultDB Cloud service (`api.openvaultdb.com`) is an instance of the same Apache 2.0 open-source reference implementation available for self-hosting and third-party hosting.

This means:
- There is no "open-core" split where enterprise features are proprietary.
- Protocol extensions, plugin interfaces, and the core server are all Apache 2.0.
- Anyone can build a competing hosted service using the same code.

## License

Apache License, Version 2.0.

Rationale:
- Permissive; allows commercial use and hosting without copyleft obligations.
- Widely understood in enterprise and cloud contexts.
- Compatible with most dependencies.
- Does not require patent grants beyond the license grant.

> **Alternative considered**: AGPL. Would require competing hosted services to publish their modifications. Rejected: AGPL creates friction for enterprise adoption and self-hosted deployments that include proprietary integrations.

> **Alternative considered**: BSL (Business Source License). Delayed open-source with commercial terms. Rejected: undermines trust and community investment.

## What Open-Source Covers

| Component | License | Notes |
|---|---|---|
| Core server | Apache 2.0 | Full feature parity with hosted service |
| Plugin interfaces | Apache 2.0 | All plugin contracts public |
| Reference plugins (GitHub, Firestore) | Apache 2.0 | Included in main repo |
| CLI | Apache 2.0 | |
| Go SDK | Apache 2.0 | |
| TypeScript SDK | Apache 2.0 | |
| Documentation | Apache 2.0 | |
| Docker Compose / Kubernetes configs | Apache 2.0 | |

## What Open-Source Does Not Cover

| Component | Owner | Notes |
|---|---|---|
| `api.openvaultdb.com` infrastructure | OpenVaultDB project | Configuration, secrets, SLAs |
| OpenVaultDB brand and trademarks | OpenVaultDB project | Cannot use "OpenVaultDB Cloud" for competing services without permission |
| Managed Firestore operation | OpenVaultDB project | Infrastructure ops |
| Support contracts | OpenVaultDB project | Commercial service |

> **Open question**: Should the project define a compatibility certification mark (similar to "Kubernetes Conformant")? This would let third-party hosting providers signal they pass the compliance test suite.

## Third-Party Hosting Rights

Third-party hosting providers:
- MAY deploy the reference implementation commercially.
- MAY use their own billing, identity, storage, and infrastructure.
- MAY add custom plugins without open-sourcing them (Apache 2.0 does not require this).
- MUST NOT use the "OpenVaultDB Cloud" name without permission.
- SHOULD pass the compatibility test suite to claim OpenVaultDB compatibility.

## Commercial Differentiation Model

| Source of Value | Description |
|---|---|
| Managed operations | 24/7 monitoring, incident response, upgrades |
| Managed backups | Automated backup, point-in-time restore |
| SLAs | Uptime guarantees with financial consequences |
| Support | Expert support for migration, integration, security |
| Migration assistance | Human-assisted storage migrations |
| Enterprise services | Custom integrations, compliance assistance |

## Plugin Ecosystem Strategy

All plugin interfaces are public and Apache 2.0. Third parties may publish plugins for:
- Storage providers (S3, Azure Blob, Postgres, etc.)
- Identity providers (Okta, Auth0, LDAP, etc.)
- Billing systems
- Notification systems
- Audit exporters

> **Risk**: Plugin ecosystem fragmentation. Without a compatibility certification, users cannot tell which plugins are trustworthy. See [../architecture/plugin-model.md](../architecture/plugin-model.md).

## Assumptions

- Apache 2.0 is sufficient to attract enterprise adoption.
- The reference implementation is the canonical server; forks without upstreaming are not supported.
- Compatibility test suite enforceability relies on community norms, not legal enforcement.
- Protocol stability is maintained across minor versions; breaking changes require major version bumps.

## Open Questions

1. Should a compatibility certification mark be created?
2. How should the project handle a well-resourced fork that diverges significantly?
3. Should there be a contributor license agreement (CLA)? Apache projects typically use ICLA/CCLA.
4. How should proprietary plugins be signaled in the plugin registry?
5. What is the governance model? BDFL? Committee? Foundation?

## Risks

- A large cloud provider forks the server and does not contribute back.
- Protocol fragmentation if hosting providers add undocumented extensions.
- Core maintainer burnout without commercial sustainability.
- Open-source label used to attract community contributions while commercial value is extracted.

## Related Specifications

- [self-hosting.md](self-hosting.md)
- [third-party-hosting.md](third-party-hosting.md)
- [../architecture/reference-implementation.md](../architecture/reference-implementation.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../cloud/api-openvaultdb-com.md](../cloud/api-openvaultdb-com.md)
