# Trust Model

## Purpose

Define who and what OpenVaultDB trusts, distrusts, and constrains.

## Key Concepts

- User authority: the user is the source of consent for vault access.
- Vault authority: local vault metadata is the authoritative source for active grants.
- Application principal: an app has identity, registration metadata, and granted capabilities.
- Provider distrust: storage providers may lose, alter, replay, inspect, or withhold bytes.
- Key ownership: encryption keys should be controlled by the user or user-controlled device.
- Passphrase MVP: the first key-ownership mode is expected to be passphrase-based unless review rejects it.

## Normative Requirements

- OpenVaultDB MUST assume applications, AI agents, extensions, and providers can be malicious or compromised.
- OpenVaultDB MUST NOT grant data access based only on process identity, package name, or network origin.
- Every principal MUST have auditable identity metadata.
- The active permission state MUST be derived from vault-controlled grant records, not from caller-held claims alone.
- Providers MUST NOT receive plaintext vault data in the MVP.
- Key recovery options MUST be explicit and MUST document the tradeoff between recoverability and third-party trust.
- The MVP SHOULD start with passphrase-based key ownership.

## MVP Behavior

The MVP trusts the user approval flow, vault authority for grants, and cryptographic operations for confidentiality. It does not trust GitHub, hosted AI systems, app self-attestation, or remote policy caches with plaintext data.

## Risks

- Local malware can still observe user input or decrypted data.
- Users may approve a malicious application.
- Recovery designs can accidentally introduce custodial trust.
- Device backups may copy encrypted vaults and key material together.

## Open Questions

- What local authentication step is required before high-risk approvals?
- What passphrase recovery or reset story is acceptable?
- When should OS keystore or hardware key support follow passphrase mode?
- How should lost-key recovery be explained without implying a guarantee?

## Acceptance Criteria

- A reviewer can identify every trusted and untrusted component.
- Provider compromise does not expose plaintext under the MVP assumptions.
- Revoked capabilities cannot be reactivated by replaying stale caller tokens.

## Related Specifications

- [threat-model.md](threat-model.md)
- [permissions-model.md](permissions-model.md)
- [../storage/provider-trust.md](../storage/provider-trust.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
