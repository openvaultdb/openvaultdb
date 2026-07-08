# Plugin Model

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the plugin architecture for OpenVaultDB: the plugin interfaces, lifecycle, discovery, trust model, and extension points.

## Design Principles

1. **Everything is replaceable.** No provider is hardcoded. Storage, identity, billing, audit, backup, notifications, and search are all plugins.
2. **Plugins are explicit.** The server fails fast if a required plugin is not configured.
3. **Plugin trust is operator-granted.** Users cannot install plugins at runtime; operators configure plugins at deployment time.
4. **Plugin interfaces are public and Apache 2.0.** Third-party plugins are first-class citizens.

## Plugin Interfaces (Draft)

### StorageProvider

Responsible for durable record storage, schema storage, and migration execution.

```go
// Draft — interface subject to review
type StorageProvider interface {
    // Lifecycle
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error
    Close(ctx context.Context) error

    // Records
    GetRecord(ctx context.Context, vaultID, collectionID, recordID string) (*Record, error)
    PutRecord(ctx context.Context, vaultID, collectionID string, record *Record) error
    DeleteRecord(ctx context.Context, vaultID, collectionID, recordID string) error
    QueryRecords(ctx context.Context, vaultID, collectionID string, query *Query) ([]*Record, error)

    // Schema
    GetSchema(ctx context.Context, vaultID string) (*Schema, error)
    PutSchema(ctx context.Context, vaultID string, schema *Schema) error

    // Migration
    BeginMigration(ctx context.Context, plan *MigrationPlan) (*MigrationSession, error)
    WriteCheckpoint(ctx context.Context, session *MigrationSession, checkpoint *Checkpoint) error
    CommitMigration(ctx context.Context, session *MigrationSession) error
    RollbackMigration(ctx context.Context, session *MigrationSession) error

    // Capabilities
    Capabilities() ProviderCapabilities
}

type ProviderCapabilities struct {
    AtomicWrites       bool
    Transactions       bool
    FullTextSearch     bool
    PointInTimeRestore bool
    MaxRecordSizeBytes int64
    MaxQueryResultRows int
}
```

> **Open question**: Should StorageProvider expose transactions, or should the server handle transaction semantics through checkpointing? Transactions would require backend support that not all providers have (e.g., GitHub).

### IdentityProvider

```go
// Draft — interface subject to review
type IdentityProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    // Authentication
    ValidateToken(ctx context.Context, token string) (*Principal, error)
    IssueToken(ctx context.Context, principal *Principal, scope []string, ttl time.Duration) (string, error)
    RevokeToken(ctx context.Context, tokenID string) error

    // User management
    GetUser(ctx context.Context, userID string) (*User, error)
    ListUsers(ctx context.Context, filter UserFilter) ([]*User, error)

    // OIDC federation
    HandleOIDCCallback(ctx context.Context, code, state string) (*Principal, error)
}
```

### BillingProvider

```go
// Draft — interface subject to review
type BillingProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    // Subscription
    GetSubscription(ctx context.Context, accountID string) (*Subscription, error)
    CreateSubscription(ctx context.Context, accountID string, plan Plan) (*Subscription, error)
    CancelSubscription(ctx context.Context, subscriptionID string) error

    // Usage
    RecordUsage(ctx context.Context, accountID string, event UsageEvent) error
    GetUsageSummary(ctx context.Context, accountID string, period Period) (*UsageSummary, error)

    // Webhooks
    HandleWebhook(ctx context.Context, payload []byte, signature string) (*BillingEvent, error)
}
```

> **Note**: `BillingProvider` may return `ErrBillingDisabled` for self-hosted instances where billing is not configured.

### AuditProvider

```go
// Draft — interface subject to review
type AuditProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    // Write
    AppendEvent(ctx context.Context, event *AuditEvent) error
    Flush(ctx context.Context) error

    // Read
    QueryEvents(ctx context.Context, filter AuditFilter) ([]*AuditEvent, error)
    ExportEvents(ctx context.Context, filter AuditFilter, w io.Writer) error
}
```

### BackupProvider

```go
// Draft — interface subject to review
type BackupProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    CreateBackup(ctx context.Context, vaultID string, source StorageProvider) (*BackupManifest, error)
    ListBackups(ctx context.Context, vaultID string) ([]*BackupManifest, error)
    RestoreBackup(ctx context.Context, manifest *BackupManifest, target StorageProvider) error
    DeleteBackup(ctx context.Context, backupID string) error
}
```

### SecretsProvider

```go
// Draft — interface subject to review
type SecretsProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    GetSecret(ctx context.Context, key string) ([]byte, error)
    PutSecret(ctx context.Context, key string, value []byte) error
    DeleteSecret(ctx context.Context, key string) error
    RotateSecret(ctx context.Context, key string) error
}
```

### NotificationProvider

```go
// Draft — interface subject to review
type NotificationProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    SendNotification(ctx context.Context, notification *Notification) error
}
```

### SearchProvider

```go
// Draft — interface subject to review
type SearchProvider interface {
    Initialize(ctx context.Context, config ProviderConfig) error
    HealthCheck(ctx context.Context) error

    Index(ctx context.Context, vaultID, collectionID string, record *Record) error
    Search(ctx context.Context, vaultID string, query *SearchQuery) ([]*SearchResult, error)
    DeleteIndex(ctx context.Context, vaultID, collectionID string) error
}
```

## Plugin Lifecycle

```
Server startup:
1. Load plugin configuration from ovdb.yaml.
2. Instantiate each plugin with its configuration.
3. Call Initialize() on each plugin.
4. If any required plugin fails Initialize(), abort startup.
5. Call HealthCheck() on each plugin.
6. Log plugin status.
7. Begin serving requests.

Server shutdown:
1. Stop accepting new requests.
2. Drain in-flight requests.
3. Call Close() on each plugin in reverse initialization order.
```

## Plugin Trust Model

| Trust Level | Who Can Install | Notes |
|---|---|---|
| Core plugins | Operator (compile-time or config) | Built-in: SQLite, GitHub, Firestore, file audit, etc. |
| Third-party plugins | Operator (config) | Operator assumes responsibility for vetting |
| User-installed plugins | Not supported | Users cannot install plugins |

> **Risk**: An operator-installed malicious plugin has access to all vault data. Plugin isolation (sandbox, separate process) is a future consideration not in scope for MVP.

> **Open question**: Should the server support a plugin signing mechanism so operators can verify plugin provenance?

## Plugin Configuration (Draft)

```yaml
plugins:
  storage:
    provider: github
    config:
      org: myorg
      repo: my-vault
      branch: main
      credentials_secret: github_token

  identity:
    provider: oidc
    config:
      issuer: https://accounts.google.com
      client_id: "..."
      client_secret_key: google_oidc_secret

  billing:
    provider: disabled

  audit:
    provider: local
    config:
      path: ./audit.log
      max_size_mb: 100
```

## Open Questions

1. Should plugins run in-process or in separate processes (for isolation)?
2. Should there be a plugin registry or marketplace?
3. How should plugin versioning and compatibility be enforced?
4. Should plugins have access to all vault data, or should their access be scoped?
5. How should plugin errors be surfaced to users?
6. Should `SearchProvider` be optional? What happens to queries if not configured?

## Risks

- In-process plugins have access to all vault data and can be exploited.
- Plugin configuration errors may silently fall back to insecure defaults.
- Third-party plugins with lax security create liability for the project.
- Plugin interface changes in core break third-party plugins.

## Acceptance Criteria

- All eight plugin interfaces have documented Go interface definitions.
- A plugin that returns an error from `Initialize()` causes the server to abort with a clear error message.
- Plugin health check failures are exposed in the `/health` endpoint.
- Core plugins (SQLite, GitHub, Firestore, local audit) are included in the reference implementation.

## Related Specifications

- [overview.md](overview.md)
- [reference-implementation.md](reference-implementation.md)
- [../storage/storage-backends.md](../storage/storage-backends.md)
- [../billing/billing-provider.md](../billing/billing-provider.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../testing/plugin-test-matrix.md](../testing/plugin-test-matrix.md)
