# Firestore Storage Provider

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Specify the Firestore storage provider in two configurations: user-owned (BYOS) and OpenVaultDB-managed. Document capabilities, limitations, trust assumptions, and security implications for each.

## Provider Configurations

### Configuration A: User-Owned Firestore (BYOS)

The user provides a GCP service account key or Workload Identity Federation token scoped to their own GCP project. OpenVaultDB Cloud acts as a control plane only; data resides in the user's GCP project.

### Configuration B: OpenVaultDB-Managed Firestore

OpenVaultDB Cloud operates the Firestore project on behalf of the user. The user does not have direct GCP access. Data resides in OpenVaultDB's GCP project with logical tenant isolation.

> **Critical trust difference**: In BYOS, OpenVaultDB holds credentials to the user's GCP project. In managed, OpenVaultDB holds the data directly. Both models require explicit trust assumptions. See the trust comparison below.

## Capabilities

| Capability | Supported | Notes |
|---|---|---|
| Record read/write | Yes | Native Firestore documents |
| Schema storage | Yes | Dedicated collection |
| Audit log storage | Yes | Append-only collection |
| Transactions | Yes | Firestore native transactions |
| Atomic writes | Yes | Firestore batch writes |
| Full-text search | No | Requires SearchProvider plugin (e.g., Algolia) |
| Point-in-time restore | Partial | GCP PITR available on some plans |
| Streaming writes | Yes | Firestore real-time updates |
| Binary records | Yes | Firestore byte fields |
| Max document size | 1MB | Firestore limit |
| Max subcollections | Unlimited | Practical limits apply |

## Limitations

| Limitation | Impact | Mitigation |
|---|---|---|
| 1MB document size limit | Large records must be split | Chunking logic required |
| No full-text search | Query limitations | SearchProvider required for text search |
| GCP vendor lock-in | Storage migration required to leave GCP | Migration tooling; data export |
| Firestore pricing | Cost scales with read/write operations | Rate limiting; caching |
| Index limits | Complex queries require composite indexes | Schema-aware index management |
| Security rules complexity | Misconfigured rules may expose data | OpenVaultDB manages rules; user cannot override |

## Data Model (Draft)

Proposed Firestore collection layout:

```
vaults/{vaultID}/
  meta                        # Vault metadata document
  schema/current              # Current schema document
  schema/versions/{version}   # Historical schema versions
  collections/{collectionID}/{recordID}  # Record documents
  audit/{year}/{month}/{eventID}         # Audit event documents
  grants/current              # Grant state document
  migrations/{migrationID}    # Migration state documents
```

> **Open question**: Should each vault be a separate Firestore project (BYOS) or a subcollection within a shared project (managed)? Different isolation models.

## Trust Model Comparison

| Concern | BYOS | Managed |
|---|---|---|
| Who holds GCP credentials? | OpenVaultDB (user's project) | OpenVaultDB (OpenVaultDB's project) |
| Can OpenVaultDB read plaintext data? | Yes (has service account) | Yes (owns the project) |
| User can revoke OpenVaultDB access? | Yes (revoke service account) | No (OpenVaultDB owns the project) |
| GCP data residency | User's GCP region | OpenVaultDB's GCP region |
| GCP compliance | User's GCP compliance posture | OpenVaultDB's GCP compliance posture |
| Data export path | User can access GCP directly | Must use OpenVaultDB export API |

> **Risk**: Both configurations require trusting OpenVaultDB with plaintext data unless client-side encryption is applied. This is a fundamental architectural decision that must be reviewed by Fable 5.

## Encryption

Options for managed Firestore (draft):

| Approach | Pros | Cons |
|---|---|---|
| GCP default encryption (Google-managed keys) | No operational overhead | Google holds keys |
| Customer-managed encryption keys (CMEK) | User controls keys via GCP KMS | User must manage GCP KMS |
| Application-level encryption (OpenVaultDB encrypts before write) | OpenVaultDB holds no plaintext | Key management at OpenVaultDB control plane; complex |
| End-to-end encryption (client encrypts) | True zero-knowledge | Queries impossible; migration complex |

> **Recommendation for review**: Which encryption model is appropriate for managed Firestore? Application-level encryption (Option C) is the strongest privacy claim but most complex to implement.

## Multi-Tenant Isolation (Managed)

In the managed configuration, multiple users share a single GCP project. Isolation mechanisms (draft):

1. **Firestore security rules**: each document path includes `vaultID`; rules enforce per-vault access.
2. **Application-level authorization**: OpenVaultDB server enforces authorization before any Firestore read/write.
3. **GCP IAM**: server uses a single service account; isolation is purely application-layer.

> **Risk**: Application-layer isolation without GCP-level isolation means a bug in authorization logic could expose cross-tenant data. This is a high-severity risk requiring review.

## Performance Characteristics

| Operation | Estimated Latency | Notes |
|---|---|---|
| Single record read | 5–20ms | Firestore in same region |
| Single record write | 10–30ms | Firestore document write |
| Batch write (100 records) | 50–200ms | Firestore batch |
| Transactional write | 20–60ms | Firestore transaction |
| Query (indexed) | 10–50ms | Firestore index query |

## Migration Considerations

| Migration Type | Complexity | Notes |
|---|---|---|
| Record migration (schema change) | Low | Firestore supports partial document updates |
| Storage migration (to another provider) | Medium | Stream all documents; write to target |
| BYOS to managed | Medium | OpenVaultDB re-ingests data; credentials transfer |

## Security Implications

1. **Service account scoping**: BYOS service accounts should be scoped to the minimum required Firestore permissions (`datastore.user` role).
2. **Firestore security rules**: rules should enforce vault-level isolation at the database layer as defense-in-depth.
3. **Credential rotation**: service account keys should be rotated; OpenVaultDB must support rotation without vault downtime.
4. **Audit trail**: GCP audit logs (Cloud Audit Logs) provide an independent audit trail supplementing OpenVaultDB's own audit log.
5. **Data residency**: users in regulated industries may need data to reside in specific GCP regions.

## Open Questions

1. Should application-level encryption be required for managed Firestore?
2. How should multi-tenant isolation be strengthened beyond application-layer enforcement?
3. What GCP compliance certifications does OpenVaultDB Cloud plan to achieve?
4. Should users be able to supply their own CMEK for managed storage?
5. How are BYOS service account credentials stored and rotated?
6. What is the maximum practical vault size for Firestore storage?

## Risks

- Application-level multi-tenant isolation bug could expose cross-tenant data.
- OpenVaultDB holds plaintext data for managed Firestore (unless encrypted) — significant trust assumption.
- GCP pricing changes could make managed Firestore economically unviable.
- Service account credential theft exposes the entire BYOS vault.

## Acceptance Criteria

- BYOS configuration: OpenVaultDB cannot read vault records without a valid service account credential.
- Managed configuration: cross-tenant isolation is tested with deliberate misconfiguration attempts.
- Record write is atomic; partial writes do not corrupt vault state.
- Migration completes correctly (including partial failure and resume).
- Data export produces a complete, self-contained package.

## Related Specifications

- [storage-backends.md](storage-backends.md)
- [github-provider.md](github-provider.md)
- [provider-trust.md](provider-trust.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../cloud/hosted-service-architecture.md](../cloud/hosted-service-architecture.md)
