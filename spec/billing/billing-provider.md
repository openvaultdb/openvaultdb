# Billing Provider

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Define the BillingProvider plugin interface, supported billing systems, and how billing integrates with vault lifecycle, feature gates, and usage tracking.

## Design Principles

1. **Billing is a plugin.** The server has no hardcoded dependency on Stripe or any other payment system.
2. **Self-hosted instances disable billing.** `provider: disabled` is a valid production configuration.
3. **Billing does not block security-critical operations.** Billing failures MUST NOT prevent data export or revocation.
4. **Billing observes, does not authorize.** The Authorization middleware enforces tier limits; BillingProvider records usage and manages subscriptions.

## Plugin Interface

See [../architecture/plugin-model.md](../architecture/plugin-model.md) for the full Go interface definition.

Key responsibilities:
- Return current subscription and tier for an account.
- Record usage events (API calls, storage reads/writes, migration runs).
- Handle billing provider webhooks (subscription renewal, payment failure, cancellation).
- Expose usage summary for the account dashboard.

## Supported Billing Providers (Draft)

| Provider | Status | Use Case |
|---|---|---|
| Disabled | Core | Self-hosted; no billing |
| Stripe | Planned | `api.openvaultdb.com` hosted service |
| Paddle | Possible | EU-preferred; handles VAT |
| Lemon Squeezy | Possible | Simple digital goods billing |
| Chargebee | Possible | Enterprise subscription management |
| Enterprise | Possible | Custom invoicing; no self-service billing |
| Custom | Supported | Plugin interface; any billing system |

## Tier Enforcement

Tier limits are enforced in the Authorization middleware using the subscription returned by BillingProvider:

| Limit Type | Enforcement | Notes |
|---|---|---|
| Vault count | Create vault: check current count vs. tier limit | |
| Record count | Write record: check collection size vs. tier limit | Soft limit: warn at 90%; hard limit at 100% |
| API requests/day | Request middleware: check daily counter | Counter reset at UTC midnight |
| Applications | Register app: check count vs. tier limit | |
| Audit retention | Audit log cleanup job: respect retention period | |

> **Open question**: Should tier limits be enforced synchronously (block the request) or asynchronously (allow and notify)? Synchronous is simpler; async avoids user-facing failures from billing system lag.

## Billing Webhooks

Billing providers send webhooks for:
- Subscription created
- Subscription renewed
- Payment failed
- Subscription cancelled
- Plan upgraded/downgraded

OpenVaultDB must handle:
- **Payment failed**: notify user; grace period before downgrade.
- **Subscription cancelled**: notify user; maintain read/export access; block writes after grace period.
- **Plan downgrade**: enforce new tier limits; notify user of operations blocked.

> **Risk**: Billing webhook delivery is not guaranteed. The server must reconcile subscription state periodically, not rely solely on webhooks.

## Usage Events

The server emits usage events to BillingProvider for:
- API request (per-request)
- Record read (per-record)
- Record write (per-record)
- Storage consumed (periodic)
- Migration run (per-migration)

> **Open question**: Should usage events be recorded per-request (high volume, accurate) or batched (lower volume, eventual accuracy)? Per-request may overwhelm billing API rate limits.

## Free Tier Abuse Prevention

Proposed mitigations for free tier abuse:
- Require verified email before vault creation.
- Require BYOS storage for free tier (user must have a GitHub account).
- Rate limiting per account.
- Anomaly detection on usage patterns (not in scope for MVP).

> **Open question**: Is BYOS-only for the free tier an acceptable anti-abuse measure? It significantly raises the barrier for malicious accounts.

## Billing and Data Privacy

Billing data (subscription, payment method, invoices) is managed by the BillingProvider. OpenVaultDB:
- MUST NOT store payment card data.
- MUST NOT log payment method details in the audit log.
- SHOULD store only the subscription tier and expiry date in the control plane database.

## Stripe Integration (Draft)

For `api.openvaultdb.com`, Stripe is the proposed billing provider:
- Subscription products and prices defined in Stripe.
- Checkout and portal hosted by Stripe (no custom payment UI).
- Webhooks signed with Stripe webhook secret; verified before processing.
- Usage-based billing via Stripe Metered Billing (for managed storage overage).

> **Alternative**: Paddle. Paddle handles EU VAT and acts as Merchant of Record, reducing tax compliance overhead. More appropriate if significant EU user base is anticipated.

## Open Questions

1. Which billing provider for the initial hosted service: Stripe or Paddle?
2. Should tier enforcement be synchronous or asynchronous?
3. How should usage events be batched to avoid overwhelming billing API rate limits?
4. What grace period applies after payment failure before write access is restricted?
5. Should billing data be exposed in the vault audit log?
6. How should enterprise (custom invoicing) accounts be provisioned?

## Risks

- Billing system outages may block legitimate users if tier checks hit the billing API on every request.
- Overage billing surprises may harm user trust.
- Free tier abuse through automated account creation.
- Billing webhook failures causing stale subscription state.

## Acceptance Criteria

- `provider: disabled` configuration starts successfully with no billing API calls.
- Tier limit enforcement works correctly for each limit type.
- Billing failures do not block data export or grant revocation.
- Stripe webhook signature verification is tested for both valid and tampered payloads.
- Subscription cancellation does not result in immediate data loss.

## Related Specifications

- [pricing-model.md](pricing-model.md)
- [../architecture/plugin-model.md](../architecture/plugin-model.md)
- [../cloud/pricing-draft.md](../cloud/pricing-draft.md)
- [../security/trust-model.md](../security/trust-model.md)
