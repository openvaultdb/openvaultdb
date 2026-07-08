# Sneat Integration — Space Storage Selection

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define how Sneat integrates with OpenVaultDB for Space data storage: the user experience for selecting a storage provider when creating a Space, and the ongoing data access model.

## Context

Sneat Spaces are the primary unit of collaboration in the Sneat platform. Currently, Space data is stored in Sneat Cloud. This specification proposes making the storage layer selectable, with OpenVaultDB as the default storage abstraction.

## Vision

When a user creates a new Sneat Space, they choose where the Space data is stored:

```
Where should your Space data be stored?

● OpenVaultDB Cloud (api.openvaultdb.com)  [Recommended]
  Managed by OpenVaultDB. Free tier available.

○ Sneat Cloud (sneat.cloud)
  Current default. Managed by the Sneat team.

○ Existing OpenVaultDB endpoint
  Use a vault you already have.

○ Self-hosted OpenVaultDB
  Run your own instance. [Enter URL]

○ Third-party OpenVaultDB provider
  Use a hosting provider. [Browse providers / Enter URL]
```

> **Assumption**: Users understand the trade-off between convenience (Sneat Cloud) and ownership (OpenVaultDB). This assumption should be validated with UX research.

## Storage Selection UX Flow

### New Space Creation (Draft)

```
1. User taps "Create Space"
2. User enters Space name and basic settings
3. User sees storage selection screen (above)
4. If "OpenVaultDB Cloud" selected:
   a. If user has no OpenVaultDB account: prompt to create one
   b. If user is authenticated: list existing vaults or offer to create a new vault
   c. User selects or creates a vault
   d. Sneat requests grant from OpenVaultDB
   e. OpenVaultDB presents grant approval screen to user
   f. User approves grant
   g. Space is created; data is stored in the selected vault
5. If "Custom endpoint" selected:
   a. User enters OpenVaultDB endpoint URL
   b. Sneat validates the endpoint (see provider-discovery.md)
   c. Continue from step 4d
6. Space creation completes; data model deployed to vault via schema proposal
```

### Storage Selection for Existing Space (Migration)

```
1. User opens Space Settings → Storage
2. Current storage provider displayed
3. User selects "Migrate storage"
4. User selects new provider
5. Migration plan generated (see migration-flow.md)
6. User reviews and approves plan
7. Migration executes
8. User confirms completion
9. Old provider access revoked
```

## Sneat Schema Model

Sneat proposes its data model to the vault via ModelSpec. The vault maps the ModelSpec to the selected storage backend.

Draft Sneat collections:
- `spaces` — Space metadata
- `members` — Space membership and roles
- `tasks` — Task records (if using Sneat Todo)
- `contacts` — Contact records
- `events` — Calendar events
- `notes` — Note records
- `messages` — Chat messages (high-volume; special considerations)

> **Open question**: High-volume collections (messages) may not be appropriate for all storage backends. Should Sneat use a hybrid storage model (OpenVaultDB for structured data, direct cloud storage for high-volume streams)?

## Grant Scope

When Sneat registers as an application in a user's OpenVaultDB vault, it requests the following capabilities:

| Capability | Reason |
|---|---|
| `collections:write` | Deploy Sneat schema collections |
| `records:read` | Read Space data |
| `records:write` | Write Space data |
| `schema:propose` | Propose schema changes (on Sneat updates) |
| `migrations:plan` | Plan migrations when schema changes |

Sneat MUST NOT request:
- `grants:manage` — Sneat cannot manage grants on behalf of the user
- `vault:write` — Sneat cannot modify vault metadata
- `audit:read` — Sneat cannot read audit logs

> **Security principle**: Sneat should request the minimum capabilities required. Users should be able to audit what Sneat can see and do.

## Provider Neutrality

Sneat MUST remain provider-neutral:
- All data access through the OpenVaultDB SDK (not provider-specific APIs).
- Sneat MUST NOT assume Firestore, GitHub, or any specific backend.
- Feature availability may vary by provider capability (e.g., full-text search only if SearchProvider configured).

## Fallback Behavior

If the user's OpenVaultDB endpoint is unavailable:
- Sneat displays a clear error indicating the storage provider is offline.
- Sneat MUST NOT silently fall back to Sneat Cloud storage.
- Cached reads (if implemented) are clearly marked as potentially stale.
- Write operations are queued locally and retried when provider recovers (if offline-first is implemented).

> **Open question**: Should Sneat implement offline-first with local queue? This significantly increases implementation complexity but improves resilience.

## Multi-Space Storage

A user may have different Spaces stored on different providers:
- Space A: OpenVaultDB Cloud
- Space B: Self-hosted OpenVaultDB
- Space C: Sneat Cloud

This is intentional and supported. Each Space independently selects its storage.

## Open Questions

1. Should storage selection be required at Space creation, or optional (defaulting to Sneat Cloud)?
2. How should Sneat handle high-volume collections (messages) that may exceed storage provider limits?
3. Should Sneat implement offline-first with local queue?
4. How should Sneat handle schema changes that affect multiple Spaces on different providers?
5. What happens to a Space if the user's OpenVaultDB subscription expires?
6. Should Sneat support OpenVaultDB as a storage option for existing Spaces?

## Risks

- Storage provider selection adds UX complexity that may reduce adoption.
- High-volume collections may exhaust GitHub API rate limits quickly.
- Cross-provider Spaces increase support complexity.
- Users may lose access to Space data if they lose access to their OpenVaultDB vault.

## Acceptance Criteria

- User can create a Space with each supported storage option.
- Sneat data model is correctly deployed as a schema proposal in the vault.
- Sneat cannot access vault data without an approved grant.
- Storage provider selection is surfaced clearly in Space settings.

## Related Specifications

- [provider-discovery.md](provider-discovery.md)
- [migration-flow.md](migration-flow.md)
- [../cloud/api-openvaultdb-com.md](../cloud/api-openvaultdb-com.md)
- [../security/capability-model.md](../security/capability-model.md)
- [../api/endpoints.md](../api/endpoints.md)
