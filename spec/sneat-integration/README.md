# Sneat Integration

> **Status: Draft — pending Fable 5 architecture and security review.**

Specifications for OpenVaultDB integration with the Sneat platform.

## Contents

- [space-storage-selection.md](space-storage-selection.md) — UX and flow for selecting storage when creating a Space
- [provider-discovery.md](provider-discovery.md) — discovering, validating, and connecting to OpenVaultDB providers
- [migration-flow.md](migration-flow.md) — migrating a Sneat Space between storage providers

## Key Principle

Sneat is provider-neutral. All data access goes through the OpenVaultDB SDK. Sneat MUST NOT access storage backends directly.

## Related Specifications

- [../cloud/api-openvaultdb-com.md](../cloud/api-openvaultdb-com.md)
- [../api/endpoints.md](../api/endpoints.md)
- [../security/capability-model.md](../security/capability-model.md)
## Open Questions

- See individual specification files in this section for open questions.
