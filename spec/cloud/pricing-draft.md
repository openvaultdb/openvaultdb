# Pricing Model — Draft

> **Status: Draft — pending Fable 5 architecture and security review.**
>
> **This pricing model is a draft proposal only. No prices, tiers, or limits are final.**

## Purpose

Propose a pricing structure for the OpenVaultDB Cloud hosted service. Pricing should be commercially realistic, provider-neutral where possible, and aligned with the open-source strategy.

## Guiding Principles

1. The free tier must be genuinely useful for evaluation and personal projects.
2. Storage costs differ significantly between backends; pricing should reflect this.
3. Self-hosting should always be free; pricing must not penalize open-source users.
4. Enterprise pricing should not be published as fixed prices; handled via sales.

## Proposed Tiers (Draft)

### Free

| Feature | Limit |
|---|---|
| Vaults | 1 |
| Storage backend | BYOS only (GitHub or user-owned Firestore) |
| Records per vault | 10,000 |
| Applications | 3 |
| API requests/day | 1,000 |
| Audit log retention | 30 days |
| Migrations | 5 per month |
| Support | Community only |
| SLA | None |

> **Open question**: Is "BYOS only" for the free tier acceptable? It raises the barrier significantly (user needs a GitHub account with a repo).

### Developer

Proposed price: **$9/month** (draft — subject to change)

| Feature | Limit |
|---|---|
| Vaults | 5 |
| Storage backends | BYOS + Managed Firestore |
| Records per vault | 100,000 |
| Applications | 20 |
| API requests/day | 10,000 |
| Audit log retention | 90 days |
| Migrations | Unlimited |
| Support | Email |
| SLA | None |

### Professional

Proposed price: **$49/month** (draft — subject to change)

| Feature | Limit |
|---|---|
| Vaults | 25 |
| Storage backends | All supported |
| Records per vault | 1,000,000 |
| Applications | Unlimited |
| API requests/day | 100,000 |
| Audit log retention | 1 year |
| Migrations | Unlimited |
| Storage migration | Included |
| Backup | Daily automated (managed storage) |
| Support | Priority email |
| SLA | 99.5% uptime (proposed) |

### Business

Proposed price: **$199/month** (draft — subject to change)

| Feature | Limit |
|---|---|
| Vaults | Unlimited |
| Storage backends | All supported + custom |
| Records per vault | Unlimited |
| Applications | Unlimited |
| API requests/day | 1,000,000 |
| Audit log retention | 3 years |
| Migrations | Unlimited |
| Backup | Continuous (managed storage) |
| Support | Dedicated support channel |
| SLA | 99.9% uptime (proposed) |
| Custom IdentityProvider | Included |
| Custom BillingProvider | Included |

### Enterprise

Custom pricing. Includes:
- On-premises deployment support
- Custom SLAs
- Custom storage integrations
- Audit compliance assistance
- Dedicated account manager

> **Note**: Enterprise tier does not imply proprietary server functionality. Enterprise customers receive the same reference implementation with priority support and custom plugin integration assistance.

## Storage-Differentiated Pricing (Draft)

Storage backend selection affects operational cost significantly:

| Storage Backend | Cost Driver | Pricing Impact |
|---|---|---|
| GitHub BYOS | GitHub API rate limits; user pays GitHub | Minimal — control plane only |
| Firestore BYOS | User pays GCP; OpenVaultDB is control plane only | Minimal — control plane only |
| Managed Firestore | OpenVaultDB pays GCP; pass-through + margin | Usage-based add-on (proposed) |

Proposed managed Firestore add-on: **$0.10 per GB/month** (draft — subject to change)

> **Alternative**: Bundle managed storage into tier limits rather than charging separately. Simpler UX; less revenue visibility.

## Billing Provider Abstraction

Billing is handled through the BillingProvider plugin. The hosted service uses Stripe (proposed). Self-hosted instances may use:
- Stripe
- Paddle
- Lemon Squeezy
- Disabled (self-hosted, no billing)
- Custom

See [../billing/billing-provider.md](../billing/billing-provider.md).

## Open Questions

1. Should the free tier require BYOS storage, or should managed storage be included?
2. How should overage be handled — hard limit, soft limit with notification, or automatic upgrade prompt?
3. What is the correct pricing anchor: vaults, records, API calls, or storage GB?
4. Should there be a usage-based option for unpredictable workloads?
5. How does pricing interact with self-hosted white-label deployments by third parties?
6. What are the actual GCP Firestore costs at anticipated scale?

## Risks

- Free tier BYOS requirement may reduce adoption by non-technical users.
- Record limits may penalize legitimate use cases with many small records.
- Managed Firestore pricing creates revenue concentration risk if GCP pricing changes.
- Publishing specific prices early creates downward price pressure.

## Related Specifications

- [../billing/billing-provider.md](../billing/billing-provider.md)
- [../billing/pricing-model.md](../billing/pricing-model.md)
- [api-openvaultdb-com.md](api-openvaultdb-com.md)
- [../open-source/strategy.md](../open-source/strategy.md)
