# Trust Model

## Purpose

Define who and what OpenVaultDB trusts, distrusts, and constrains.

## Key Concepts

- User authority: the user is the source of consent for vault access.
- Vault authority: local vault metadata is the authoritative source for active grants.
- Application principal: an app has identity, registration metadata, and granted capabilities.
- Provider distrust: storage providers may lose, alter, replay, inspect, or withhold bytes.
- Hoster recovery: authentication and access recovery are implementation details of the hoster or provider.
- Future encryption: encryption may be added later, but it is not part of the MVP data-protection model.

## Normative Requirements

- OpenVaultDB MUST assume applications, AI agents, operator-configured plugins/providers, and storage providers can be malicious or compromised.
- User-installable extensions are out of scope for MVP and MUST require a future RFC before they exist.
- OpenVaultDB MUST NOT grant data access based only on process identity, package name, or network origin.
- Every principal MUST have auditable identity metadata.
- The active permission state MUST be derived from vault-controlled grant records, not from caller-held claims alone.
- The MVP MUST NOT claim confidentiality from GitHub, hosters, repository administrators, or provider operators.
- Access recovery behavior MUST be documented by the hoster or provider implementation.
- If encryption is added later, key ownership and recovery options MUST be specified before implementation.

## MVP Behavior

The MVP trusts the user approval flow, vault authority for grants, GitHub/private-repository access controls, and hoster/provider authentication. It does not provide OpenVaultDB-managed encryption or confidentiality from the storage provider.

## Risks

- Local malware can still observe user input or decrypted data.
- Users may approve a malicious application.
- Hoster recovery designs can accidentally grant access to the wrong party.
- Repository backups and Git history can retain sensitive data indefinitely.

## Open Questions

- What local or hosted authentication step is required before high-risk approvals?
- What minimum recovery guarantees must hosters document?
- When should OpenVaultDB-managed encryption become a supported mode?

## Acceptance Criteria

- A reviewer can identify every trusted and untrusted component.
- Provider or repository compromise exposes vault data under the MVP assumptions.
- Revoked capabilities cannot be reactivated by replaying stale caller tokens.

## Related Specifications

- [threat-model.md](threat-model.md)
- [permissions-model.md](permissions-model.md)
- [../storage/provider-trust.md](../storage/provider-trust.md)
- [../mvp/local-first-encrypted-vault.md](../mvp/local-first-encrypted-vault.md)
