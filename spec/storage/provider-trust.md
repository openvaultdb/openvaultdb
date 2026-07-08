# Provider Trust

## Purpose

Define assumptions for storage providers and synchronization services.

## Key Concepts

- Provider: service or backend that stores or transports vault bytes.
- Compromised provider: provider that reads, modifies, replays, deletes, withholds, or reorders data.
- Trust tier: documented provider assumptions and required mitigations.
- Replay: serving older valid-looking vault state.

## Normative Requirements

- Providers MUST be assumed capable of compromise unless explicitly trusted by a non-MVP deployment.
- Provider compromise exposes vault data in the MVP model because OpenVaultDB does not encrypt vault data.
- Provider replay or rollback SHOULD be detectable or user-visible.
- Provider-specific credentials MUST be revocable.
- Cloud sync MUST have a reviewed conflict, replay, deletion, and audit model before implementation.

## MVP Behavior

The MVP does not use remote providers. Provider trust is documented for future review only.

## Risks

- Users may confuse private repository access controls with confidentiality from the provider.
- Provider deletion can cause data loss even without confidentiality loss.
- Sync conflict resolution can become an implicit migration.

## Open Questions

- What rollback-detection mechanism is required before cloud sync?
- Should provider credentials be separate from vault capabilities?
- How should provider outages appear in audit logs?

## Acceptance Criteria

- Future provider support includes a trust tier and explicit residual risks.
- Cloud sync cannot be added by implementation alone without a specification update.
- Provider credential leak response is documented.

## Related Specifications

- [storage-backends.md](storage-backends.md)
- [local-first.md](local-first.md)
- [../security/trust-model.md](../security/trust-model.md)
- [../security/threat-model.md](../security/threat-model.md)
