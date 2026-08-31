---
format: https://specscore.md/decision-specification
status: Approved
---

# Decision: Sneat Co. Identity and Space Principals for OpenVaultDB Cloud

**Status:** Approved
**Date:** 2026-08-31
**Owner:** alex
**Tags:** authentication,authorization,cloud,sneat,spaces
**Source Idea:** —
**Supersedes:** —
**Superseded By:** —

## Context

OpenVaultDB Cloud is operated as a Sneat Co. product and needs to interoperate
with people and collaborative Spaces already represented by the shared Sneat
Co. identity and membership model. A Space can be surfaced by `sneat.work`,
`sneat.app`, or any extension mini-app; the product surface is not the
collaboration boundary.

Creating a second OpenVaultDB account identifier for every authenticated person
would require a permanent identity mapping before OpenVaultDB could resolve
current Space membership, roles, contacts, or invitations. Conversely, treating
an application or extension as if it were the user or Space would erase the
explicit client and capability boundaries required by OpenVaultDB.

## Decision

The hosted OpenVaultDB Cloud service MUST authenticate humans through the shared
Sneat Co. Firebase project `sneat-eur3-1`. The verified Firebase UID is the
canonical Sneat Co. `userID` and MUST be used directly as the hosted
OpenVaultDB user principal; the service MUST NOT create a second translated
OpenVaultDB account ID.

A Sneat Co. Space is a first-class collaborative grant subject identified by
its `spaceID`. Its identity and grants MUST NOT depend on whether it is
presented by `sneat.work`, `sneat.app`, or an extension mini-app.

Products, extension mini-apps, services, and CLIs are registered clients. A
client acts as itself and, where approved, on behalf of an authenticated user
or Space. Merely running inside a product or Space MUST NOT confer OpenVaultDB
access; the client and requested capabilities remain explicit in every grant.

A contact without a linked Sneat Co. `userID` MAY be the target of a pending
invitation, but MUST NOT become an active authenticated grant subject until the
contact is securely claimed and linked to a user.

Long-lived device tokens MUST identify the authenticated `userID`, registered
client, and approved token scopes. They MUST NOT snapshot Space membership or
roles. Resource authorization MUST evaluate the current Space membership and
OpenVaultDB grant when the resource is used, failing closed when membership
cannot be established.

This hosted identity profile does not constrain self-hosted or third-party
OpenVaultDB providers, which MAY use their own identity and group resolvers.

## Rationale

The shared user ID makes OpenVaultDB collaboration compose directly with the
existing Sneat Co. contact and Space membership model. A user removed from a
Space can lose access without rewriting a copied list of per-user grants, and a
contact can retain its team-local identity while an invitation is pending.

Keeping the OpenVaultDB token issuer, registered clients, scopes, grants, and
revocation state separate preserves the capability boundary. Shared human
authentication therefore does not make a Sneat Co. application token an
OpenVaultDB credential or grant applications ambient vault access.

This structure also avoids product-specific authorization. A Space remains the
same collaborative subject as people move between product shells or interact
through extension mini-apps.

## Declined Alternatives

### Separate OpenVaultDB account IDs

Rejected for the hosted service because a one-to-one translation layer adds
joins and lifecycle failure modes to every Space membership decision without
adding a useful security boundary.

### Independent OpenVaultDB Firebase identity pool

Rejected because it duplicates provider configuration and account recovery,
breaks direct user identity across connected Sneat Co. workflows, and requires
account linking before team sharing can work.

### Product-specific teams or grants

Rejected because the collaboration boundary is the Space, not the product or
mini-app presenting it.

### Membership embedded in long-lived tokens

Rejected because team membership and roles can change during a token's
lifetime. A removed member must not retain access until a one-year device token
expires.

## Consequences at Decision Time

- OpenVaultDB Cloud depends on the availability and integrity of the shared
  Sneat Co. identity system for human sign-in.
- A compromise or administrative error in the shared identity project has a
  wider cross-product blast radius.
- OpenVaultDB Cloud must maintain an authoritative, fail-closed Space membership
  resolver or a bounded cache with explicit revocation behavior.
- Device authorization and access-token records store the Sneat Co. `userID`
  directly while remaining bound to an OpenVaultDB client, scopes, expiry, and
  revocation state.
- Contact invitations need an explicit pending-to-linked transition before
  they grant authenticated access.
- Product shells and extension mini-apps can reuse a Space grant without
  redefining the Space or copying its member list.

## Observed Consequences

None observed yet.

## Affected Features

- [Cloud CLI device login](../features/cloud-cli-device-login/README.md)
- [Sneat.app Space Export to GitHub](../features/sneat-space-export/README.md)

---
*This document follows the https://specscore.md/decision-specification*
