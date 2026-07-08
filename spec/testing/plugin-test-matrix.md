# Plugin Test Matrix

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the test matrix for validating plugin interface implementations. This matrix ensures that any StorageProvider, IdentityProvider, or other plugin correctly implements the required contract.

## How to Use This Matrix

For each plugin type, the table lists test scenarios that MUST pass for a plugin to be considered compliant. Tests are organized by:
- **Functional**: correct behavior under normal conditions
- **Error**: correct behavior when input is invalid or operation fails
- **Security**: correct behavior under adversarial conditions
- **Performance**: behavior under load

## StorageProvider Test Matrix

### Functional

| # | Test | Expected Behavior |
|---|---|---|
| SP-F-01 | Write and read back a single record | Record content identical |
| SP-F-02 | Write 100 records; list all | All 100 records returned |
| SP-F-03 | Update a record; read back | Updated content returned |
| SP-F-04 | Delete a record; read | 404 / not found |
| SP-F-05 | Query with equality filter | Only matching records returned |
| SP-F-06 | Query with ordering | Records in correct order |
| SP-F-07 | Paginate through 1000 records | All records returned without duplicates |
| SP-F-08 | Write schema; read back | Schema content identical |
| SP-F-09 | Begin migration; write checkpoint | Checkpoint readable |
| SP-F-10 | Begin migration; commit | Migration marked complete |
| SP-F-11 | Begin migration; rollback | Vault state unchanged from before migration |
| SP-F-12 | Initialize with valid config | No error |
| SP-F-13 | HealthCheck on healthy backend | Returns healthy |
| SP-F-14 | ProviderCapabilities returns valid struct | Capabilities match backend |

### Error

| # | Test | Expected Behavior |
|---|---|---|
| SP-E-01 | Read non-existent record | Returns not-found error (not panic) |
| SP-E-02 | Write with invalid record ID | Returns validation error |
| SP-E-03 | Initialize with missing config | Returns configuration error |
| SP-E-04 | Initialize with invalid credentials | Returns auth error |
| SP-E-05 | HealthCheck on unavailable backend | Returns error |
| SP-E-06 | Query with invalid filter | Returns validation error |
| SP-E-07 | CommitMigration without BeginMigration | Returns error |
| SP-E-08 | Write record exceeding max size | Returns size error |

### Security

| # | Test | Expected Behavior |
|---|---|---|
| SP-S-01 | Read vault A records using vault B credentials | Returns auth/permission error |
| SP-S-02 | Write to read-only collection | Returns permission error |
| SP-S-03 | Record ID with path traversal (`../secret`) | Returns validation error |
| SP-S-04 | Record content with embedded null bytes | Handled correctly (not truncated) |
| SP-S-05 | Migration rollback after partial write | No partial data visible |
| SP-S-06 | Concurrent writes to same record | No data corruption (last-write-wins or error) |

### Performance

| # | Test | Expected Behavior |
|---|---|---|
| SP-P-01 | Single record read latency | P99 within provider SLA (documented) |
| SP-P-02 | 100 concurrent reads | No errors; latency within 5x single-read |
| SP-P-03 | Bulk write 1000 records | Completes within documented time bound |

## IdentityProvider Test Matrix

### Functional

| # | Test | Expected Behavior |
|---|---|---|
| IP-F-01 | Issue token for valid principal | Valid JWT returned |
| IP-F-02 | ValidateToken with valid token | Principal returned |
| IP-F-03 | ValidateToken with expired token | Returns expired error |
| IP-F-04 | RevokeToken; ValidateToken | Returns revoked error |
| IP-F-05 | GetUser with valid userID | User record returned |
| IP-F-06 | OIDC callback with valid code | Principal returned |
| IP-F-07 | Initialize with valid OIDC config | No error |

### Error

| # | Test | Expected Behavior |
|---|---|---|
| IP-E-01 | ValidateToken with invalid signature | Returns signature error |
| IP-E-02 | ValidateToken with unknown issuer | Returns issuer error |
| IP-E-03 | ValidateToken with malformed JWT | Returns parse error |
| IP-E-04 | OIDC callback with invalid state | Returns CSRF error |
| IP-E-05 | GetUser with unknown userID | Returns not-found error |

### Security

| # | Test | Expected Behavior |
|---|---|---|
| IP-S-01 | Token with modified claims (tampered) | Returns signature error |
| IP-S-02 | Token with future `iat` | Returns validation error |
| IP-S-03 | OIDC callback with replayed code | Returns error (code used) |
| IP-S-04 | Emergency revocation; existing tokens | All tokens for principal rejected |

## BillingProvider Test Matrix

| # | Test | Expected Behavior |
|---|---|---|
| BP-F-01 | GetSubscription for active account | Subscription with correct tier returned |
| BP-F-02 | RecordUsage; GetUsageSummary | Usage reflected in summary |
| BP-F-03 | HandleWebhook with valid signature | Event processed |
| BP-E-01 | HandleWebhook with invalid signature | Returns error; event not processed |
| BP-E-02 | GetSubscription for unknown account | Returns not-found error |
| BP-S-01 | Disabled provider: GetSubscription | Returns default free tier |

## AuditProvider Test Matrix

| # | Test | Expected Behavior |
|---|---|---|
| AP-F-01 | AppendEvent; QueryEvents | Event returned in query |
| AP-F-02 | Append 1000 events; QueryEvents with pagination | All events returned |
| AP-F-03 | QueryEvents with time range filter | Only events in range returned |
| AP-F-04 | ExportEvents produces valid NDJSON | All events in output |
| AP-E-01 | AppendEvent with missing required fields | Returns validation error |
| AP-S-01 | AppendEvent; attempt to modify event | Modification returns error or is rejected |

## BackupProvider Test Matrix

| # | Test | Expected Behavior |
|---|---|---|
| BK-F-01 | CreateBackup; ListBackups | Backup appears in list |
| BK-F-02 | CreateBackup; RestoreBackup | Restored data matches original |
| BK-F-03 | DeleteBackup; RestoreBackup | Returns not-found error |
| BK-E-01 | RestoreBackup to occupied vault | Returns error or prompts |
| BK-S-01 | Backup contains all records | No records missing from backup |

## SecretsProvider Test Matrix

| # | Test | Expected Behavior |
|---|---|---|
| SEC-F-01 | PutSecret; GetSecret | Value matches |
| SEC-F-02 | DeleteSecret; GetSecret | Returns not-found error |
| SEC-F-03 | RotateSecret | New value retrievable; old value rejected |
| SEC-S-01 | GetSecret for non-existent key | Returns not-found (not empty string) |

## Compliance Test Runner (Draft)

The reference implementation includes a CLI command for running the compliance test suite against any plugin:

```bash
ovdb test plugin compliance \
  --plugin storage \
  --provider github \
  --config ./test-config.yaml
```

> **This is the technical foundation for third-party compatibility claims.** See [../open-source/third-party-hosting.md](../open-source/third-party-hosting.md).

## Open Questions

1. How should performance baselines be defined for third-party storage providers with variable latency (e.g., GitHub)?
2. Should the compliance test runner be a separate binary or part of the `ovdb` CLI?
3. How should flaky tests (due to network variability) be handled?
4. Should there be a test mode where the server generates synthetic audit events for testing?

## Related Specifications

- [security-test-matrix.md](security-test-matrix.md)
- [migration-test-matrix.md](migration-test-matrix.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../open-source/third-party-hosting.md](../open-source/third-party-hosting.md)
