# Fable 5 Brief: Commercial Model Review

> **Status: Draft — pending Fable 5 architecture and security review.**

## Current Proposal

OpenVaultDB's commercial model is based on managed hosting, SLAs, and support services — not proprietary server functionality. The server is fully Apache 2.0 open source. Commercial value comes from operating `api.openvaultdb.com` as a reliable, managed service.

Supporting specifications:
- [../spec/cloud/api-openvaultdb-com.md](../spec/cloud/api-openvaultdb-com.md)
- [../spec/cloud/pricing-draft.md](../spec/cloud/pricing-draft.md)
- [../spec/cloud/hosted-service-architecture.md](../spec/cloud/hosted-service-architecture.md)
- [../spec/open-source/strategy.md](../spec/open-source/strategy.md)
- [../spec/billing/billing-provider.md](../spec/billing/billing-provider.md)

## Rationale

- Apache 2.0 maximizes adoption and trust.
- Fully open server differentiates from "open-core" competitors that withhold enterprise features.
- Self-hosting demonstrates confidence in the value of the managed service.
- The commercial moat is operations, reliability, and SLAs — not lock-in.

## Alternatives Considered

| Alternative | Trade-off |
|---|---|
| Open-core (proprietary enterprise features) | Stronger commercial protection; undermines community trust |
| BSL license (delayed open-source) | Some protection; time-limited; creates friction for enterprise |
| AGPL | Requires hosted services to open-source modifications; more friction |
| Dual license (Apache 2.0 + commercial) | Complex licensing; confusion for enterprise legal teams |
| Fully closed source | Strongest commercial protection; incompatible with vision |
| Usage-based pricing only | Simpler; aligns cost with value; harder to forecast revenue |

## Proposed Tiers (Draft)

| Tier | Monthly Price | Key Differentiator |
|---|---|---|
| Free | $0 | BYOS storage; 1 vault; community support |
| Developer | ~$9 | Managed storage; 5 vaults; email support |
| Professional | ~$49 | 25 vaults; priority support; SLA |
| Business | ~$199 | Unlimited vaults; dedicated support; 99.9% SLA |
| Enterprise | Custom | On-premises; custom SLA; custom integrations |

All prices are draft proposals subject to change.

## Trade-offs

| Concern | Implication |
|---|---|
| Free tier BYOS-only | Raises barrier to entry; may reduce conversion to paid tiers |
| Apache 2.0 allows competing hosted services | No protection against large cloud providers deploying OpenVaultDB |
| No proprietary features | No technical lock-in; retention depends entirely on quality and price |
| Managed Firestore pricing pass-through | GCP pricing changes directly affect margin |
| Enterprise tier complexity | Custom pricing requires sales motion; not self-serve |

## Key Risks

1. **The "AWS problem"**: a large cloud provider deploys OpenVaultDB managed service at lower cost, commoditizing the offering. Apache 2.0 provides no protection against this.
2. **Free tier abuse**: automated account creation for BYOS storage (GitHub repos) may be used for purposes other than vault storage.
3. **Managed Firestore economics**: if managed Firestore storage scales faster than expected, the cost structure may become unprofitable before pricing adjustments are possible.
4. **Self-hosting as the preferred path**: if the developer experience for self-hosting is too good, paid tier conversion may be low.
5. **Billing system dependency**: Stripe or Paddle outages affect the commercial service directly.
6. **Pricing anchor ambiguity**: it's unclear whether users will perceive value in vault-count-based pricing vs. record-count-based vs. API-call-based.

## Dangerous Assumptions

- The value of managed hosting (operations, SLAs) is sufficient to sustain the business when the software is freely available.
- Developer tier pricing ($9/month) is sufficient to cover infrastructure costs with margin.
- Enterprise customers will pay for support and on-premises deployment assistance.
- Apache 2.0 community contributions will offset development costs.
- Stripe is the correct billing provider for the initial market (assumed mostly US/EU developer market).

## Open Questions for Fable 5

1. **Commercial sustainability**: Is the "managed hosting + SLA" model sufficient to build a sustainable business against Apache 2.0 competition? What is the minimum viable commercial differentiator?
2. **Free tier strategy**: Should the free tier include managed storage to maximize adoption? Or BYOS-only to reduce cost and prevent abuse? Which maximizes long-term conversion?
3. **Pricing anchor**: What should the primary pricing dimension be? (Vault count, record count, API calls, storage GB, seats, or a composite?)
4. **Enterprise path**: How should enterprise deals be structured? Direct sales? Partner channel? Self-serve with manual approval?
5. **Third-party hosting ecosystem**: Should OpenVaultDB offer a partner program for third-party hosting providers? Would revenue sharing (e.g., on compatibility certification) be appropriate?
6. **BYOS competitive positioning**: If a user provides their own GitHub storage and OpenVaultDB only provides a control plane, what is the perceived value? Is the control plane + security model + migration tooling sufficient?
7. **Pricing evolution**: At what tier limit or MRR should the pricing model be reconsidered?
8. **Open-source funding**: Should the project apply to open-source foundations (Linux Foundation, Apache Foundation) or grants to supplement commercial revenue?

## Expected Fable Review Output

- Assessment of commercial model viability.
- Recommendation on the primary pricing anchor.
- Assessment of risks from Apache 2.0 competition.
- Recommendation on free tier strategy (BYOS-only vs. managed storage included).
- Identification of any commercial model assumptions that conflict with the open-source strategy.
- Recommendation on enterprise tier structure and pricing motion.

## Related Specification Files

- [../spec/cloud/api-openvaultdb-com.md](../spec/cloud/api-openvaultdb-com.md)
- [../spec/cloud/pricing-draft.md](../spec/cloud/pricing-draft.md)
- [../spec/cloud/hosted-service-architecture.md](../spec/cloud/hosted-service-architecture.md)
- [../spec/open-source/strategy.md](../spec/open-source/strategy.md)
- [../spec/billing/billing-provider.md](../spec/billing/billing-provider.md)
- [../spec/billing/pricing-model.md](../spec/billing/pricing-model.md)
