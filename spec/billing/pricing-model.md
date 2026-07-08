# Pricing Model

> **Status: Draft — pending Fable 5 architecture and security review.**
>
> **This document expands on the cloud pricing draft with implementation considerations.**

## Purpose

Define the pricing model implementation: how tiers translate to enforcement logic, how usage is metered, and how pricing integrates with the BillingProvider plugin.

## Tier Model

Tiers are defined as structured configuration consumed by both the BillingProvider and the Authorization middleware.

### Tier Definition (Draft)

```go
// Draft — subject to review
type Tier struct {
    ID              string
    Name            string
    MaxVaults       int
    MaxRecordsPerVault int
    MaxApplications int
    MaxAPIRequestsPerDay int
    AuditRetentionDays int
    MigrationsPerMonth int  // -1 = unlimited
    StorageBackends []string // allowed backend types
    SupportLevel    SupportLevel
    UptimeSLA       float64 // 0 = no SLA
}
```

### Proposed Tier Definitions

| Field | Free | Developer | Professional | Business |
|---|---|---|---|---|
| MaxVaults | 1 | 5 | 25 | -1 (unlimited) |
| MaxRecordsPerVault | 10,000 | 100,000 | 1,000,000 | -1 |
| MaxApplications | 3 | 20 | -1 | -1 |
| MaxAPIRequestsPerDay | 1,000 | 10,000 | 100,000 | 1,000,000 |
| AuditRetentionDays | 30 | 90 | 365 | 1095 |
| MigrationsPerMonth | 5 | -1 | -1 | -1 |
| StorageBackends | byos | byos, managed | all | all |
| SupportLevel | community | email | priority | dedicated |
| UptimeSLA | 0 | 0 | 0.995 | 0.999 |

> **Note**: All limits are draft proposals. Real limits should be derived from cost modeling.

## Overage Handling

Proposed overage behavior by limit type:

| Limit | At Limit | Overage Behavior |
|---|---|---|
| Vault count | Block new vault creation | Notification sent; upgrade prompt |
| Records | Soft warning at 90%; block writes at 100% | Notification; upgrade prompt |
| API requests/day | Throttle to 1 req/s at 100% | 429 response with retry-after |
| Applications | Block new registration | Notification; upgrade prompt |
| Migrations | Block new plan creation | Notification; upgrade prompt |

> **Alternative**: Allow overage with automatic billing (like AWS). More user-friendly; more complex to implement; risk of unexpected charges.

## Managed Storage Pricing

For managed Firestore storage, proposed add-on pricing:

```
Base managed storage: $0.10/GB/month (draft)
Additional reads: $0.06 per 100,000 reads (draft)
Additional writes: $0.18 per 100,000 writes (draft)
```

These are pass-through estimates from GCP Firestore pricing with a margin. Actual pricing TBD.

## Usage Metering

The server meters the following usage dimensions:

| Dimension | Metering Method | Billing Impact |
|---|---|---|
| API requests | Counter per account, reset daily | Daily limit enforcement |
| Storage (managed) | Periodic size query | Monthly billing add-on |
| Records | Count per collection | Tier limit enforcement |
| Vault count | Count per account | Tier limit enforcement |
| Migrations | Count per month | Tier limit enforcement (Free tier) |

## Trial and Grace Periods

Proposed trial and grace periods:

| Event | Grace Period |
|---|---|
| New account | 14-day trial of Professional features |
| Payment failure | 7 days read/write access; then read-only |
| Subscription cancellation | 30 days to export data; then read-only |
| Account deletion | 30 days to recover; then permanent delete |

> **Open question**: Should the grace period be configurable per deployment for self-hosted instances?

## Self-Hosted Pricing

Self-hosted deployments: free (Apache 2.0). The BillingProvider is configured as `disabled`. No tier limits unless the operator configures them.

> **Open question**: Should the reference implementation support operator-defined tier limits for self-hosted multi-tenant deployments (e.g., a hosting provider with their own billing)?

## Open Questions

1. Should overage be blocked or allowed with automatic billing?
2. What is the correct pricing anchor? (Records, API calls, storage GB, or a combination?)
3. Should there be a usage-based (pay-as-you-go) option?
4. How should trials interact with billing system timing (trial periods vary by OIDC provider join date)?
5. Should self-hosted operators be able to configure tier limits without implementing a full BillingProvider?

## Risks

- Hard limits on records may surprise users during migrations (record count temporarily spikes).
- Daily API request reset at UTC midnight may cause confusion for users in other time zones.
- Managed storage pricing pass-through from GCP creates pricing instability.

## Related Specifications

- [billing-provider.md](billing-provider.md)
- [../cloud/pricing-draft.md](../cloud/pricing-draft.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
