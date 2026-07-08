# GitHub Storage Provider

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Specify the GitHub repository storage provider: capabilities, limitations, trust assumptions, data model, migration considerations, and security implications.

This provider is the preferred first backend generator target for OpenVaultDB: a
GitHub repository using InGitDB layout generated from ModelSpec.

## Overview

The GitHub storage provider uses a user-owned GitHub repository as durable storage for vault records, schemas, audit events, and migration checkpoints. OpenVaultDB holds a GitHub OAuth token or GitHub App installation token scoped to the target repository.

## Capabilities

| Capability | Supported | Notes |
|---|---|---|
| Record read/write | Yes | Via GitHub Contents API or Git trees |
| Schema storage | Yes | As ModelSpec AST serialization files in repo |
| Audit log storage | Yes | Append-only files; tamper-evidence via Git history |
| Transactions | No | Best-effort; see limitations |
| Atomic writes | Partial | Single file: atomic via Git blob replace; multi-file: not atomic |
| Full-text search | No | Requires SearchProvider plugin |
| Point-in-time restore | Yes | Via Git history |
| Streaming writes | No | |
| Binary records | Yes | Base64-encoded blobs |
| Max record size | ~1MB | GitHub file size limit |
| Max records | TBD | Rate limits apply |

## Limitations

| Limitation | Impact | Mitigation |
|---|---|---|
| GitHub API rate limits (5000 req/hour authenticated) | Limits throughput | Batching; caching; exponential backoff |
| No multi-file atomic writes | Partial write risk on crash | Write-ahead log + checkpoint |
| Repository visibility | Private repo required for sensitive data | Enforce private repo in configuration |
| GitHub service availability | Vault unavailable during GitHub outages | Caching layer; fallback behavior TBD |
| File path length limits | Limits collection/record ID length | Enforce max ID length |
| Git history as audit log | History rewrite could tamper with audit | Protect branch; enforce branch protection rules |

## Data Model (Draft)

Proposed repository layout:

```
vault/
├── meta.json           # Vault metadata: ID, schema version, created_at
├── schema/
│   ├── current.modelspec.json    # Current ModelSpec AST serialization
│   └── v{N}.modelspec.json       # Historical ModelSpec versions
├── collections/
│   ├── {collection}/
│   │   ├── {record_id}.json   # Individual records
│   │   └── _index.json        # Collection index (optional)
├── audit/
│   └── {year}/{month}/{day}.ndjson  # Append-only audit events
├── grants/
│   └── current.json    # Active grants (encrypted)
└── migrations/
    ├── checkpoints/
    │   └── {migration_id}.json
    └── history.json
```

> **Open question**: Should records be stored as individual files or batched into larger files? Individual files are simpler but hit rate limits faster. Batched files reduce API calls but complicate partial updates.

> **Alternative**: Use Git tree API for bulk writes to reduce API call count. More complex implementation; better throughput.

## Trust Assumptions

| Trust Assumption | Risk |
|---|---|
| GitHub does not read vault file contents | GitHub can read all files in the repository |
| Git history is tamper-evident | GitHub can rewrite history (force push) unless branch protection is enabled |
| OAuth token is scoped to target repository | Compromised token exposes that repository only |
| GitHub App credentials are securely stored | Control plane stores credentials; compromise exposes all GitHub-backed vaults |

> **Critical assumption**: Users trusting GitHub as a storage backend accept that GitHub (or anyone who compromises their GitHub account) can read all vault data. For sensitive data, application-level encryption should be applied before writing to GitHub.

## Encryption

Options (draft):

| Approach | Pros | Cons |
|---|---|---|
| No encryption (plaintext in repo) | Simple; Git history is human-readable | GitHub and anyone with repo access can read data |
| Client-side encryption (vault encrypts before write) | Data opaque to GitHub | Cannot use GitHub search/browse; key management required |
| Hybrid: encrypted records, plaintext schema | Balances usability and privacy | Schema reveals data model |

> **Recommendation for review**: Should the GitHub provider require client-side encryption by default? Or should it be opt-in?

## Migration Considerations

| Migration Type | Complexity | Notes |
|---|---|---|
| Record migration (schema change) | Medium | Requires reading all affected records, transforming, writing back |
| Storage migration (to another provider) | Medium | Read all files; write to target provider |
| Repository migration (change GitHub repo) | Low | Re-configure provider; data already in target |

Migrations must account for:
- GitHub API rate limits during bulk reads/writes.
- Partial write failures requiring checkpoint resume.
- Audit log continuity across migrations.

## Performance Characteristics

| Operation | Estimated Latency | Notes |
|---|---|---|
| Single record read | 100–500ms | GitHub API round trip |
| Single record write | 200–800ms | GitHub API + Git commit |
| Bulk read (100 records) | 10–50s | Rate limit dependent |
| Schema read | 100–300ms | Single API call |

> **Note**: GitHub storage is not suitable for high-frequency read/write applications. It is best for personal vaults with infrequent access patterns.

## Security Implications

1. **Token scope**: OAuth tokens should be scoped to `repo` (specific repository) only. Avoid `read:org` or other broad scopes.
2. **Branch protection**: Enable branch protection on the vault repository to prevent history rewriting.
3. **Private repository**: Vault repository MUST be private.
4. **Token rotation**: Tokens should be rotated periodically; the control plane must support token rotation without vault downtime.
5. **Audit log integrity**: GitHub history provides some tamper-evidence, but can be overridden by repository admins. Not suitable as the sole audit mechanism for high-security requirements.

## Open Questions

1. Should the GitHub provider require client-side encryption?
2. What is the maximum practical vault size for GitHub storage?
3. Should the provider use individual file API calls or Git tree API for bulk operations?
4. How should the provider handle GitHub API rate limit exhaustion?
5. Is GitHub Actions a risk vector? (GitHub Actions may have access to repository contents)
6. Should vault repositories be archived (read-only) during migrations?

## Risks

- GitHub API rate limits may cause migration failures for large vaults.
- Users may accidentally make their vault repository public.
- GitHub Actions or installed GitHub Apps may have unintended access to vault data.
- GitHub history rewriting could compromise audit log integrity.

## Acceptance Criteria

- Provider correctly reads and writes records to GitHub repository.
- Provider handles rate limit errors with exponential backoff and does not corrupt data.
- Branch protection enforcement documented and tested.
- Migration completes correctly (including partial failure and resume).

## Related Specifications

- [storage-backends.md](storage-backends.md)
- [provider-trust.md](provider-trust.md)
- [firestore-provider.md](firestore-provider.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../schema/migrations.md](../schema/migrations.md)
