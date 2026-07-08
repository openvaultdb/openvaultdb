# api.openvaultdb.com — Hosted Service Specification

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the user-facing scope, lifecycle, and UX of the official OpenVaultDB Cloud service at `https://api.openvaultdb.com`.

## Key Concepts

- **Hosted vault**: a vault managed on behalf of a user by the OpenVaultDB Cloud service.
- **Bring-your-own storage (BYOS)**: user supplies storage credentials (e.g., GitHub repo, user-owned Firestore) and OpenVaultDB Cloud acts as a control plane only.
- **Managed storage**: OpenVaultDB Cloud operates the storage on behalf of the user; the user retains export rights.
- **Control plane vs. data plane**: OpenVaultDB Cloud always owns the control plane; the data plane may be BYOS or managed.

## Service Scope (Draft)

The hosted service at `api.openvaultdb.com` provides:

1. Account lifecycle (create, verify, suspend, delete)
2. Vault lifecycle (create, configure, archive, delete)
3. Storage backend selection and credential management
4. Application registration and credential issuance
5. Permission grant and revocation UI
6. Schema change approval workflow
7. Migration planning, approval, and progress tracking
8. Audit log access and export
9. Data export and portability
10. Provider migration workflow
11. Billing and subscription management (via pluggable BillingProvider)
12. Identity federation (OIDC, Google, GitHub, Apple, Microsoft, Passkeys)

## MVP Storage Backends

The following storage backends are proposed for the initial hosted service:

| Backend | Type | Trust Model | Notes |
|---|---|---|---|
| GitHub repository (user-owned) | BYOS | User-controlled OAuth token | Data in user's repo; OpenVaultDB holds no plaintext |
| Firestore (user-owned) | BYOS | User-supplied service account credentials | User controls GCP project |
| Managed Firestore (OpenVaultDB-operated) | Managed | OpenVaultDB holds data | Export always available; encryption approach TBD |

> **Open question**: For managed Firestore, does OpenVaultDB hold encryption keys? This fundamentally changes the trust model. See [security/trust-model.md](../security/trust-model.md).

## User Lifecycle

### Account Creation

```
1. User visits api.openvaultdb.com
2. User authenticates (OIDC provider or passkey)
3. Account created; primary identity verified
4. User selects subscription tier
5. User creates first vault
```

> **Assumption**: email verification is required before vault creation. This may conflict with passkey-only flows.

### Vault Creation

```
1. User selects storage backend
2. For BYOS: user grants OAuth scopes or provides service account credentials
3. Vault encryption key provisioned (key model TBD — see open questions)
4. Vault metadata stored in OpenVaultDB control plane
5. Vault ready for application registration
```

### Application Registration

```
1. Developer registers application (name, redirect URIs, requested capabilities)
2. OpenVaultDB issues application credentials (client ID + secret or public key)
3. User reviews requested capabilities
4. User approves or rejects grant
5. Application receives scoped access token
```

### Schema Change Approval

```
1. Application submits schema change proposal (via ModelSpec or diff)
2. OpenVaultDB control plane presents diff to user
3. User reviews: affected collections, record count, risk level, reversibility
4. User approves or rejects
5. If approved, migration plan generated
6. User approves migration plan separately (or delegates approval to trusted agent)
```

> **Risk**: users approving schema changes without understanding implications. See [schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md).

### Data Export

```
1. User initiates export
2. Export package generated: records, schema, audit log, grants (credentials redacted)
3. Package signed with vault key
4. User downloads directly (for BYOS storage, user already has access)
```

### Provider Migration

```
1. User selects target storage backend
2. Migration plan generated: source, target, estimated record count, duration, risks
3. User reviews and approves plan
4. Backup created from source
5. Migration executed with progress tracking
6. Verification: record count, schema hash, audit log continuity
7. Old backend decommissioned after user confirmation
```

## Assumptions

- OpenVaultDB Cloud does not hold plaintext record data for BYOS storage backends.
- OpenVaultDB Cloud does hold plaintext data for managed Firestore unless client-side encryption is applied (see open questions).
- Authentication tokens are short-lived; refresh tokens are stored encrypted in the control plane.
- All user-approval actions are logged to the append-only audit log.
- Service-to-service communication uses mTLS or signed JWTs.

## Alternatives Considered

| Alternative | Trade-off |
|---|---|
| Single managed storage only | Simpler initial offering; forces trust in OpenVaultDB for all data |
| BYOS only | No managed tier; loses revenue from non-technical users |
| Self-hosting only at launch | Avoids cloud complexity; delays commercial viability |

## Risks

- Credential storage for BYOS backends: OpenVaultDB holds user's GitHub OAuth tokens or GCP service account keys. Compromise of the control plane compromises all BYOS vaults.
- Managed Firestore encryption: if OpenVaultDB holds keys, the trust model weakens significantly.
- Storage provider outages: user may lose access to vault data if BYOS backend is unavailable.
- Account recovery: if user loses all authentication factors, vault data may be inaccessible.

## Open Questions

1. For managed Firestore: does OpenVaultDB hold encryption keys? Who can access plaintext?
2. How are BYOS credentials (GitHub tokens, GCP service accounts) stored and rotated?
3. What is the key recovery model for managed vaults?
4. What SLA commitments are realistic for MVP?
5. Should users be able to use OpenVaultDB Cloud as a control plane only (no storage)?
6. How does account deletion cascade to BYOS data?

## Acceptance Criteria

- User can complete the full lifecycle (create account → create vault → register app → approve grant → export data) without engineering assistance.
- BYOS storage: OpenVaultDB control plane holds no plaintext record data.
- All user-approval actions appear in the audit log within 5 seconds.
- Data export produces a self-contained package importable by another OpenVaultDB instance.
- Provider migration completes without data loss or audit log gaps.

## Related Specifications

- [hosted-service-architecture.md](hosted-service-architecture.md)
- [pricing-draft.md](pricing-draft.md)
- [../open-source/strategy.md](../open-source/strategy.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../security/threat-model.md](../security/threat-model.md)
- [../storage/github-provider.md](../storage/github-provider.md)
- [../storage/firestore-provider.md](../storage/firestore-provider.md)
- [../billing/billing-provider.md](../billing/billing-provider.md)
- [../api/endpoints.md](../api/endpoints.md)
