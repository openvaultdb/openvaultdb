# Sneat Storage Migration Flow

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the user-visible and technical flow for migrating a Sneat Space from one storage provider to another.

## Trigger Scenarios

| Scenario | Example |
|---|---|
| User wants to change provider | Moving from Sneat Cloud to OpenVaultDB Cloud |
| Provider is shutting down | Hosting provider announces end-of-life |
| Provider becomes unavailable | Payment failure; subscription expired |
| User wants self-hosted | Moving from hosted to self-hosted OpenVaultDB |
| Compliance requirement | Data must move to a specific region |

## User-Visible Migration Flow (Draft)

### Step 1: Initiate Migration

```
Space Settings → Storage → Migrate Storage

Current Storage: OpenVaultDB Cloud (api.openvaultdb.com)
                 Vault: my-space-vault
                 Records: 12,450
                 Last backup: 2026-01-01 00:00 UTC

Migrate to: [Select new provider ▼]
```

### Step 2: Select Target Provider

User selects the new provider (same flow as initial provider selection in [space-storage-selection.md](space-storage-selection.md)).

### Step 3: Review Migration Plan

The server generates a migration plan. Sneat presents:

```
Migration Plan

From: OpenVaultDB Cloud (api.openvaultdb.com)
To:   Self-hosted (https://vault.example.com)

Records to migrate: 12,450
Collections: spaces, members, tasks, contacts, notes
Estimated duration: ~3 minutes
Risk level: Low
Reversible: Yes (for 30 days, while source remains accessible)

Before migration:
✓ Backup created automatically
✓ Target vault validated
✓ Schema compatible

What happens:
1. Create backup of current data
2. Copy all records to target vault
3. Verify record counts and checksums
4. Switch Space to target vault
5. Old vault remains accessible for 30 days (read-only rollback)

[Review Details] [Cancel] [Approve Migration]
```

### Step 4: Migration Progress

```
Migrating Space "My Team Space"...

[████████████░░░░░░░░] 62%

Phase: Copying records (contacts)
Processed: 7,719 / 12,450 records
Estimated remaining: ~1 minute 10 seconds

Checkpoint: ✓ (resumable if interrupted)

[Pause] [Cancel]
```

### Step 5: Verification

After copy completes:

```
Migration Verification

Records copied: 12,450 ✓
Schema verified: ✓
Audit log transferred: ✓
Checksum match: ✓

[Complete Migration]
```

### Step 6: Completion

```
Migration Complete

Your Space data is now stored at:
https://vault.example.com

Source vault (api.openvaultdb.com) is read-only for 30 days.
You can roll back during this period.

[Done] [View Space] [Rollback Options]
```

## Technical Migration Flow

### Pre-Migration

1. Generate migration plan via `POST /v1/vaults/{vaultID}/migrations/plan`.
2. Validate target provider is accessible and compatible.
3. Create backup via BackupProvider.
4. Record migration start in audit log.

### Migration Execution

1. Acquire read lock on source vault (no writes during migration).
2. Stream records from source StorageProvider to target StorageProvider.
3. Write checkpoints at configurable intervals (proposed: every 500 records).
4. Transfer schema to target vault (with user approval for schema proposal).
5. Transfer grant definitions to target vault.
6. Verify record count and checksums on both sides.
7. Switch Space endpoint to target vault.
8. Release source vault read lock.
9. Mark source vault as archived (read-only, 30-day retention).

### Failure Handling

| Failure Point | Recovery |
|---|---|
| Pre-migration backup fails | Abort; do not proceed |
| Network failure during copy | Resume from last checkpoint |
| Target validation fails | Abort; source vault unchanged |
| Checksum mismatch | Abort; rollback to source |
| Grant transfer fails | Alert user; migration paused |

### Rollback

Within the rollback period:
1. User initiates rollback from Space Settings.
2. Sneat reverts Space endpoint to source vault.
3. Target vault data is optionally deleted.

After rollback period: source vault archived data is deleted according to retention policy.

## Cross-Provider Schema Compatibility

If the target provider does not support all capabilities required by the Sneat schema:

| Missing Capability | Impact | Resolution |
|---|---|---|
| Full-text search | Search features unavailable | Warn user; proceed without search |
| Transactions | Data consistency risk | Block migration; require capable provider |
| Streaming | Real-time features unavailable | Warn user; proceed with polling |

> **Open question**: Should migrations to capability-limited providers be blocked or warned?

## Sneat-Specific Considerations

- High-volume collections (messages): may take significantly longer. User should be warned.
- Real-time collaboration: must be paused during migration to avoid write conflicts.
- Offline clients: must sync before migration begins, or their pending writes must be queued.

## Open Questions

1. Should Sneat pause real-time collaboration during migration?
2. What is the source vault read lock implementation (advisory or enforced)?
3. Should message history be migrated or only kept on the original provider?
4. How long should the rollback window be (proposed: 30 days)?
5. Who bears the cost of running both providers during the rollback window?
6. How should migration failures be communicated to Space members?

## Risks

- Migration of large Spaces may hit storage provider API rate limits.
- Real-time collaboration during migration may cause data conflicts.
- Users may not understand the rollback window and delete source data prematurely.
- Checksum mismatch may indicate data corruption; unclear recovery path.

## Acceptance Criteria

- Migration completes without data loss for a 10,000-record Space.
- Migration can be resumed after a network interruption.
- Rollback restores the Space to source provider with no data loss.
- User receives clear progress indication throughout.

## Related Specifications

- [space-storage-selection.md](space-storage-selection.md)
- [provider-discovery.md](provider-discovery.md)
- [../schema/migrations.md](../schema/migrations.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
- [../api/endpoints.md](../api/endpoints.md)
