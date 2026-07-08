# Fable 5 Brief: Sneat Integration Review

> **Status: Draft — pending Fable 5 architecture and security review.**

## Current Proposal

Sneat will use OpenVaultDB as the default storage abstraction for Sneat Spaces. When creating a Space, users choose a storage provider. Sneat acts as a registered application in the user's OpenVaultDB vault, with explicitly granted capabilities.

Full Sneat integration specifications are in [../spec/sneat-integration/](../spec/sneat-integration/).

## Rationale

- Demonstrates OpenVaultDB's real-world applicability with a production application.
- Gives users data ownership and storage portability for their Sneat data.
- Creates a reference integration for other application developers.
- Aligns with OpenVaultDB's vision: "applications connect to an OpenVaultDB endpoint without caring where data is stored."

## Alternatives Considered

| Alternative | Trade-off |
|---|---|
| Keep Sneat on Sneat Cloud only | Simpler; faster; no OpenVaultDB dependency for Sneat users |
| Sneat stores data in OpenVaultDB directly (no BYOS) | Simpler UX; no portability |
| Sneat as first-party OpenVaultDB app (special permissions) | Creates a privileged integration that undermines the permission model |
| OpenVaultDB as optional export target only | Less useful; doesn't validate real-time integration |

## Trade-offs

| Concern | Implication |
|---|---|
| Storage selection UX adds complexity | May reduce Sneat adoption if users find provider selection confusing |
| High-volume collections (messages) | GitHub storage may not be practical for chat history |
| Cross-provider Spaces | Multiple providers per user increases support complexity |
| Schema proposal overhead | Every Sneat update requires schema proposal → user approval → migration |
| Real-time collaboration | Pausing collaboration during migration is a poor UX |

## Key Risks

1. **Schema proposal approval friction**: every time Sneat updates its data model, users must approve a schema change. This creates significant UX friction and may lead users to approve changes without understanding them.
2. **High-volume collection mismatch**: chat messages at scale are incompatible with GitHub's API rate limits (5000 req/hour). This could make GitHub an impractical choice for active Sneat spaces.
3. **Provider failure UX**: if a user's OpenVaultDB endpoint goes offline, their Sneat space becomes inaccessible. This is worse than Sneat's current behavior.
4. **Grant scope creep**: as Sneat adds features, it may request increasingly broad capabilities. Users may approve without understanding the impact.
5. **Migration complexity for multi-device users**: offline clients with pending writes complicate storage migration timing.
6. **First-class vs. third-party**: if Sneat is treated as a first-class OpenVaultDB integration, it may receive special privileges that aren't available to other apps — undermining the open permission model.

## Dangerous Assumptions

- Users understand the trade-off between convenience (Sneat Cloud) and ownership (OpenVaultDB). UX research has not validated this.
- Schema changes in Sneat updates are infrequent enough not to cause significant approval fatigue.
- Users are willing to manage an OpenVaultDB account in addition to their Sneat account.
- OpenVaultDB storage is fast enough for Sneat's real-time collaboration UX requirements.
- GitHub storage is viable for typical Sneat usage patterns. (Likely false for high-volume use.)

## Open Questions for Fable 5

1. **Schema update approval model**: How should Sneat handle schema changes without requiring users to approve every minor update? Can schema changes be batched? Can they be pre-approved for trusted applications?
2. **High-volume collections**: Should Sneat use a hybrid model (OpenVaultDB for structured data, direct cloud storage for messages)? What are the protocol implications?
3. **Offline-first feasibility**: Is offline-first with write queuing necessary for a good UX, or is a "degraded mode" indicator sufficient?
4. **Migration during collaboration**: What is the correct protocol for pausing/resuming real-time collaboration during a storage migration?
5. **Provider discovery trust**: How should Sneat validate that a user-provided OpenVaultDB URL is not a phishing endpoint? What trust signals should be presented to the user?
6. **Grant review frequency**: Should Sneat display a periodic reminder of what capabilities it holds, even when no change has been requested?
7. **Multi-device sync during migration**: How should Sneat handle pending writes from offline devices when a storage migration is in progress?
8. **Provider neutrality boundary**: How strictly should Sneat avoid provider-specific APIs? Can Sneat use Firestore's real-time updates when the backend is Firestore, or must it always go through OpenVaultDB's abstraction?

## Expected Fable Review Output

- Assessment of whether the Sneat integration is a good real-world validation of the OpenVaultDB model.
- Recommendation on schema change approval UX.
- Assessment of feasibility for high-volume collections on different storage backends.
- Identification of any dangerous privilege patterns in the proposed grant scope.
- Recommendation on offline-first vs. degraded-mode approach.
- Red flags in the provider discovery trust model.

## Related Specification Files

- [../spec/sneat-integration/space-storage-selection.md](../spec/sneat-integration/space-storage-selection.md)
- [../spec/sneat-integration/provider-discovery.md](../spec/sneat-integration/provider-discovery.md)
- [../spec/sneat-integration/migration-flow.md](../spec/sneat-integration/migration-flow.md)
- [../spec/security/capability-model.md](../spec/security/capability-model.md)
- [../spec/storage/github-provider.md](../spec/storage/github-provider.md)
- [../spec/schema/user-visible-migration-flow.md](../spec/schema/user-visible-migration-flow.md)
