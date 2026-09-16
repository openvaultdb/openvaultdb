---
format: https://specscore.md/decision-specification
status: Approved
---
# Decision: OpenVaultDB is an independent and isolated project

**Status:** Approved
**Date:** 2026-09-16
**Owner:** alex
**Tags:** governance,identity,authentication,independence,provider-neutrality
**Source Idea:** —
**Supersedes:** 0004-sneat-co-identity-and-space-principals
**Superseded By:** —

## Context

OpenVaultDB's hosted service and provider integrations were specified with Sneat Co.
as the reference consumer. That was useful for making the early export flow concrete,
but consumer-specific choices hardened into normative requirements:

- [Decision 0004](0004-sneat-co-identity-and-space-principals.md) requires the hosted
  service to authenticate humans through the shared Sneat Co. Firebase project
  `sneat-eur3-1`, to use the verified Firebase UID directly as the OpenVaultDB user
  principal, and forbids creating a translated OpenVaultDB account id.
- The OpenVaultDB GitHub App's OAuth callback is pinned to
  `https://sneat.app/github/ovdb-installed` — a consumer's domain inside a
  provider-owned app.
- The GitHub App was assumed in discussion to be owned by a consumer organization,
  when the specification already requires it to be **owned by the `openvaultdb`
  organization**.

Three separate couplings have therefore appeared in the same shape: a provider-owned
capability bound to one consumer's project, domain or account. Meanwhile two product
requirements point the other way. A person must be able to authorize access to
OpenVaultDB stores using **any OAuth2 provider initially and SSO later**, which is
unsatisfiable while one consumer's provider is the identity root. And OpenVaultDB's own
strategy is open source with self-hosting and third-party hosting, which is not
credible while its identity, credentials and provider apps belong to a consumer.

## Decision

OpenVaultDB is a **fully independent and isolated project**, and this is a governing
principle rather than an implementation preference.

1. OpenVaultDB's identity, credentials, provider applications, data and deployments
   MUST NOT depend on any consumer's accounts, projects or domains.
2. Human identity for OpenVaultDB Cloud is **owned by OpenVaultDB**. Sneat Co. MAY be
   registered as **one of the first federated authentication providers**; it is not the
   root of identity and carries no special standing.
3. External authentication-provider subjects MUST be mapped to OpenVaultDB-issued
   principals by a translation layer. The prohibition in decision 0004 on a translated
   account id is withdrawn: under multiple providers, that mapping is the design, not a
   smell.
4. Provider-owned GitHub Apps and equivalent integrations MUST be owned by the
   OpenVaultDB organization and MUST NOT hard-code a consumer's domain as an OAuth
   callback, consent target or setup URL.
5. Consumers integrate as registered OpenVaultDB clients. A consumer's collaborative
   unit — for Sneat Co., a Space — MAY be a grant subject, but it is one such subject
   among others rather than the canonical one.

This supersedes [decision 0004](0004-sneat-co-identity-and-space-principals.md).

## Rationale

Independence is a precondition for the product's stated capability, not a stylistic
preference. Multi-provider authentication requires that OpenVaultDB issue its own
principals; while a consumer's UID is canonical, adding a second provider only produces
more subjects that must be translated back into that consumer's namespace, so the
requirement cannot be met at all rather than merely being awkward to meet.

It is also a trust requirement. A vault product is asked to protect data its operator
cannot read, and its users must be able to reason about who controls access. If a
consumer controls the identity provider, then that consumer's project ownership, auth
provider configuration, security rules and incident surface are OpenVaultDB's, and a
third-party adopter or self-hoster would be trusting a party they did not choose.

Finally, the coupling is cheap to remove now and expensive later. There are effectively
no existing hosted identities or app installations to migrate, whereas each installation
and each established principal raises the cost of the same change. Removing it while the
surface is small is the only moment this is a low-risk edit.

## Declined Alternatives

### Keep Sneat Co. as the identity root and add further providers alongside it

The least disruptive reading of decision 0004. It loses because additional providers
would still be translated into Sneat-issued principals, so OpenVaultDB's identity
remains scoped to one consumer and the multi-provider requirement stays unsatisfiable.

### Issue OpenVaultDB identities inside the consumer's Firebase project

Appears to satisfy "OpenVaultDB owns its principals" while sharing the consumer's
project. It loses because it inherits the same blast radius and the same dependency on
that project's administration, so the isolation is nominal, and provider configuration
still requires the consumer's cooperation.

### Defer independence until a second consumer actually exists

Pragmatic, and it loses on cost asymmetry: the change is inexpensive now and grows with
every installation and principal, and deferring it blocks the multi-provider requirement
in the meantime rather than merely postponing an internal refactor.

## Consequences at Decision Time

- Provider/consumer neutrality: any consumer, self-hoster or third party can adopt
  OpenVaultDB without inheriting another consumer's trust assumptions.
- Multi-provider authentication becomes possible, with SSO as a later extension.
- OpenVaultDB must operate its own identity project and, in time, decide whether that is
  a hosted identity service or its own OIDC issuer.
- A principal translation layer becomes a maintained component, and with it the question
  of how principals are merged, linked and revoked across providers.
- Collaborative group identity must live in OpenVaultDB. A consumer's collaborative
  unit (Sneat Co. Spaces) becomes one federated group, which is real modelling work and
  interacts with sharing scopes in consuming products.
- [Decision 0004](0004-sneat-co-identity-and-space-principals.md) must be treated as
  superseded, and anything that assumed it — the auth architecture decisions in
  `openvaultdb-com`, and the `sneat-space-export` callback — must be revised.
- Cost: one more identity deployment to operate, monitor and secure.

## Observed Consequences

None observed yet.

## Affected Features

- [Sneat.app Space Export to GitHub](../features/sneat-space-export/README.md) — its
  GitHub App registration requirement already asserts `openvaultdb` ownership, but its
  fixed OAuth callback points at a consumer domain and must be corrected.
- [Cloud CLI device login](../features/cloud-cli-device-login/README.md) — the machine
  OAuth surface is already provider-independent and should remain so; its account model
  must not be re-rooted in a consumer's identity.
- `openvaultdb-com/spec/decisions/0001-auth-architecture.md` and
  `openvaultdb-com/spec/decisions/0003-host-vault-namespace-model.md` — both must be
  re-read against this principle for the same class of coupling.

---
*This document follows the https://specscore.md/decision-specification*
