---
format: https://specscore.md/feature-specification
status: Draft
---

# Feature: Sneat.app Space Export to GitHub

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/sneat-space-export?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/sneat-space-export?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/sneat-space-export?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/sneat-space-export?op=request-change) |
**Status:** Draft
**Date:** 2026-08-31
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

OpenVaultDB receives a complete Sneat.app Space snapshot and opens a repository-wide validated pull request in a user-selected private GitHub repository.

## Problem

Sneat Cloud needs to export a complete Space snapshot into a user-owned private
GitHub repository without teaching Sneat.app, its backend, or every extension
how to authenticate to GitHub, construct InGitDB paths, publish a branch, or
resolve concurrent writes. OpenVaultDB is the owner of that provider
boundary, but its current specifications do not define an application-driven
snapshot export, data-free repository onboarding, multi-Space repository
profile, pull-request validation state, or durable receipt that binds an
application revision to a reviewed merge.

The export path must be safe even when users edit the repository independently,
several Spaces share one Git head, GitHub installation identifiers are supplied
by an untrusted browser redirect, and the repository contains unrelated files.
It must process snapshot plaintext transiently without turning the OpenVaultDB
control plane into a second durable copy of the user's records.

## Behavior

### End-to-end journey

1. Sneat.app requests a short-lived connection session from its backend. The
   backend authenticates to OpenVaultDB as the registered `sneat.app`
   application and redirects the user to install the OpenVaultDB GitHub App on
   one selected private repository.
2. OpenVaultDB verifies the returning GitHub identity, installation, selected
   repository, privacy, and one-time state before creating an application
   connection. Cancelling leaves both systems unchanged.
3. Before accepting Space data, OpenVaultDB opens a separate onboarding pull
   request containing root `.ingitdb/`, shared schemas, and the pinned
   validation workflow. The user merges it, then OpenVaultDB observes a passing
   validation run on the repository default branch and marks onboarding ready.
4. The Sneat.app backend submits one complete Space snapshot. Without cloning
   or locally validating the repository, OpenVaultDB uses GitHub APIs to create
   a branch from the exact default-branch head, writes only
   `sneat/spaces/<space-id>/` in one commit, and opens a pull request.
5. The installed workflow validates the full pull-request tree as one InGitDB
   database. OpenVaultDB correlates the check to the exact head SHA and reports
   failed, validating, or ready-to-merge status; it never merges for the user.
6. Once the user merges the passing pull request, OpenVaultDB records a durable
   receipt binding the source revision, pull request, checked head SHA, and
   merge commit. A later logical retry returns the existing result; a new
   snapshot for that Space is outside this one-time-export milestone.

### Application and GitHub authority

#### REQ: openvaultdb-github-app-is-provider-principal

OpenVaultDB MUST use its own GitHub App as the sole provider principal.
Consuming applications MUST NOT receive the App private key, installation
tokens, or GitHub OAuth credentials and MUST NOT be required to register their
own GitHub Apps for this export contract.

#### REQ: openvaultdb-github-app-registration

The provider GitHub App MUST have the user-facing name **OpenVaultDB** and be
owned by the `openvaultdb` organization. Its registration contract MUST use
`https://openvaultdb.com/` as the homepage, the existing fixed setup callback
`https://sneat.app/github/ovdb-installed`, and the corresponding installation
URL `https://github.com/apps/openvaultdb/installations/new` once the App slug is
registered. Installation MUST request user authorization during installation
and offer **Only select repositories**; each connection flow MUST select exactly
one private repository, while one installed repository MAY contain multiple
Spaces. The App MUST request repository permissions of metadata read, contents
write, pull requests write, checks read, and workflows write. The provider MUST
poll GitHub pull-request, check, and repository APIs; no webhook is required
for correctness.

#### REQ: openvaultdb-github-app-deployment

The managed provider deployment MUST receive these configuration values:
`OVDB_GITHUB_APP_ID`, `OVDB_GITHUB_APP_INSTALL_URL`, and
`OVDB_GITHUB_OAUTH_CLIENT_ID`. It MUST receive
`OVDB_GITHUB_APP_PRIVATE_KEY` and `OVDB_GITHUB_OAUTH_CLIENT_SECRET` through
the deployment secret manager. The private key, OAuth client secret, OAuth
codes, and installation tokens MUST never be committed, stored in repository
configuration, persisted in the control-plane database, or written to logs.
Installation tokens are minted ephemerally and kept only in process memory;
the Sneat.app backend and browser receive neither tokens nor the App private
key. A deployment MUST fail closed when a required credential or App identity
is absent, and the deployment environment MUST keep development credentials
separate from production credentials.

#### REQ: authenticated-application-contract

Every connection, export, status, and disconnect operation MUST authenticate a
registered OpenVaultDB application. The Sneat.app browser MUST NOT invoke the
snapshot export API directly; its authenticated backend acts for the user and
supplies the application-scoped Space identity.

#### REQ: installation-callback-verification

The connection session MUST bind application, user, Space, intended operation,
expiry, and a single-use nonce. OpenVaultDB MUST treat callback parameters,
including `installation_id`, as untrusted and verify through GitHub that the
returning user controls the installation and selected repository before
creating a connection.

#### REQ: least-privilege-github-installation

The GitHub App MUST request only repository metadata read, contents read/write,
pull requests read/write, checks/status read, and workflow read/write
permissions required for onboarding and export. Installation MUST be limited to user-selected
repositories. OpenVaultDB MUST NOT request organization-wide repository access
for this feature.

#### REQ: ephemeral-repository-token

OpenVaultDB MUST mint a short-lived installation token down-scoped to the
selected repository and required permissions for each provider operation.
Onboarding MAY use workflow write; export MUST down-scope its token to contents
and pull-request operations and MUST NOT retain workflow write. It
MUST NOT persist installation access tokens; durable control metadata stores
only installation ID, stable repository ID, display owner/name, branch,
connection state, and audit references.

#### REQ: private-repository-only

The feature MUST accept only private repositories. A repository that becomes
public MUST enter `disconnected`, all contained exports MUST fail, and
OpenVaultDB MUST emit an actionable audit/status event.

### Connection and snapshot contract

#### REQ: stable-repository-connection

A connection MUST use the stable GitHub repository ID as identity and retain
owner/name only for display. Repository rename MUST NOT break the connection.
The connection MUST bind one branch and MAY contain multiple Space IDs.

#### REQ: complete-snapshot-request

An export request MUST contain application identity, connection ID, Space ID,
source revision, schema identity, idempotency key, snapshot creation time, and a
complete deterministic representation of the Space records. A partial patch or
browser-derived record list MUST NOT be accepted by this contract.

#### REQ: snapshot-plaintext-is-transient

OpenVaultDB MAY process snapshot plaintext in memory and provider-bound
request streams, but MUST NOT persist record plaintext in its control-plane
database, logs, traces, error payloads, or audit events. Durable record data is
the user's Git repository.

#### REQ: space-id-is-path-safe

OpenVaultDB MUST validate the Space ID against the agreed canonical identifier
grammar and derive the managed path itself. It MUST reject separators, dot
segments, encoded separators, control characters, symlink traversal, and any
input that could escape `sneat/spaces/<space-id>/`.

### Sneat.app export repository profile

#### REQ: root-ingitdb-database

The Git repository MUST be one InGitDB database rooted at `/`. Its database
configuration MUST live at `/.ingitdb/`. The installed workflow MUST validate
the database from the repository root rather than treating each Space as an
independent database.

#### Concrete data-free onboarding file profile

The onboarding pull request MUST establish this exact shared-layout profile
before any Space records are exported:

`.ingitdb/root-collections.yaml`:

```yaml
spaces: sneat/.collections/spaces
```

`sneat/.collections/spaces/definition.yaml` MUST declare the collection's data
directory:

```yaml
data_dir: spaces
record_file:
  name: "{key}/space.yaml"
  records_dir: .
  type: "map[string]any"
  format: yaml
```

For the shared `.collections/` layout, inGitDB resolves `data_dir` relative to
the parent of `.collections/`, not relative to the schema directory. Therefore
the mapping above has base directory `sneat/` and resolves to
`sneat/spaces/`; a future Space export owns its record subtree at
`sneat/spaces/<space-id>/`. The onboarding pull request MUST contain these
configuration and schema files but MUST contain no `sneat/spaces/` records.

The validation workflow MUST grant only repository `contents: read`, invoke
`ingitdb/ingitdb-action` at the immutable commit
`e5bf046ef02d9801d047149928e2adb0cb3d9b4e`, pass the exact
`ingitdb/ingitdb-cli` release `v0.65.14`, and validate `database-root: .` as one
repository-wide database. A representative invocation is:

```yaml
permissions:
  contents: read

steps:
  - uses: ingitdb/ingitdb-action@e5bf046ef02d9801d047149928e2adb0cb3d9b4e
    with:
      cli-version: v0.65.14
      database-root: .
```

#### REQ: managed-space-layout

All Sneat.app Space record data MUST live under
`/sneat/spaces/<space-id>/`. Shared Sneat platform collection schemas MAY live
under `/sneat/.collections/` and MUST be referenced by root InGitDB
configuration. A Space title change MUST NOT rename the immutable Space path.

#### REQ: multiple-spaces-one-repository

One connection MUST support multiple Spaces. A one-time export MUST add only its
target Space subtree, preserve other Space subtrees byte-for-byte, and preserve
unmanaged repository files. A managed-path collision or incompatible existing
InGitDB configuration MUST fail before mutation rather than be overwritten.

#### REQ: profile-is-application-specific

This layout is the Sneat.app export repository profile. It does not supersede
the generic OpenVaultDB generator layout in Decision 0002; generic vaults MAY
retain their own layout while this feature uses the application-owned
`sneat/` namespace and root database contract.

#### REQ: data-free-onboarding-pull-request

Before accepting Space data, OpenVaultDB MUST open a separate onboarding pull
request containing root `.ingitdb/`, compatible shared schemas, and a GitHub
Actions workflow that uses an immutable reviewed revision of
`ingitdb/ingitdb-action` and grants the job only repository contents read. The
pull request MUST contain no Space data. An existing incompatible managed file
MUST cause a conflict instead of being silently replaced.

#### REQ: onboarding-ready-after-default-check

OpenVaultDB MUST NOT accept an export until the onboarding files are merged to
the repository default branch and the workflow has produced a passing
default-branch validation result for the exact current head. A failed,
cancelled, or missing run MUST leave onboarding incomplete.

### GitHub API publication, validation, and concurrency

#### REQ: no-clone-no-local-validation

OpenVaultDB MUST use GitHub APIs for repository reads and writes. It MUST NOT
clone the repository to local disk and MUST NOT invoke InGitDB validation in
the onboarding or export request path. GitHub Actions is the authoritative data
validation boundary for this milestone.

#### REQ: atomic-export-branch-commit

One export attempt MUST create a dedicated branch from the exact target
default-branch head and at most one data commit whose tree contains the complete
target Space subtree. Onboarding files MUST NOT be introduced or modified in
the export commit. No intermediate partial tree may become the branch head.

#### REQ: export-pull-request

After publishing the data commit, OpenVaultDB MUST open a pull request targeting
the repository default branch. It MUST include the Space ID, source revision,
schema identity, managed path, and export correlation ID without including
record contents in the pull-request description. OpenVaultDB MUST NOT merge or
enable auto-merge for the pull request.

#### REQ: repository-wide-pull-request-check

The onboarding-installed workflow MUST validate the complete pull-request tree,
including all Spaces and cross-Space constraints. OpenVaultDB MUST correlate
the workflow/check conclusion to the exact pull-request head SHA. A passing
conclusion means ready for user review; invalid data, cancellation, timeout, or
infrastructure failure MUST remain distinguishable and fail closed.

#### REQ: optimistic-repository-concurrency

An export MUST compare the expected default-branch head before creating its
branch and commit. If the default branch moves before the pull request opens,
OpenVaultDB MAY rebuild the Git tree once from the new head or return a typed
conflict. It MUST NOT silently change a published pull-request head after the
user has begun review.

#### REQ: idempotent-source-revision

The tuple of application, connection, Space ID, source revision, schema
identity, and idempotency key MUST identify one logical export. Repetition MUST
return the existing branch/pull request, merged receipt, or stable in-progress
result and MUST NOT create a duplicate data commit. A failed or closed-unmerged
attempt MAY be retried with a new idempotency key; a merged Space export MUST
reject a later snapshot in this milestone.

#### REQ: pull-request-lifecycle-status

OpenVaultDB MUST consume or query GitHub pull-request, check, and merge state and
report `creating`, `validating`, `checks_failed`, `ready_to_merge`,
`closed_unmerged`, `merged`, or `failed` for the exact attempt. A check from an
older head SHA MUST NOT advance a newer head. Completion requires the checked
change to be merged to the intended default branch.

### Receipt, observability, and recovery

#### REQ: durable-export-receipt

An export receipt MUST contain export ID, application ID, connection ID, Space
ID, source revision, schema identity, repository ID, target branch, export
branch, managed path, prior target SHA, data commit/head SHA, pull-request
number and URL, exact check conclusion, merge commit SHA when present, and start
and completion times. It MUST contain no GitHub credential or record plaintext.

#### REQ: auditable-provider-events

OpenVaultDB MUST emit audit events for connection created/rejected, onboarding
pull request opened/merged/validated/failed, export requested, branch committed,
pull request opened/checked/closed/merged/failed, repository visibility changed,
installation revoked, and connection disconnected. Events MUST carry
correlation IDs and metadata, not exported record contents.

#### REQ: cancelled-connect-is-retryable

A cancelled, rejected, expired, or invalid installation flow MUST not create a
usable connection or mutate the repository. The application MUST receive a
typed retryable or terminal result suitable for its settings UI.

## Acceptance Criteria

### AC: verified-installation-creates-private-connection (verifies REQ:openvaultdb-github-app-is-provider-principal, REQ:authenticated-application-contract, REQ:installation-callback-verification, REQ:least-privilege-github-installation, REQ:ephemeral-repository-token, REQ:private-repository-only, REQ:stable-repository-connection)

**Given** an authenticated Sneat.app backend session and a user who installs the OpenVaultDB GitHub App on exactly one private repository
**When** the callback is completed
**Then** OpenVaultDB independently verifies the GitHub user, installation and repository, stores only durable connection metadata, and gives the Sneat.app backend a one-time connection result without exposing a GitHub credential

### AC: spoofed-installation-id-is-rejected (verifies REQ:installation-callback-verification, REQ:cancelled-connect-is-retryable)

**Given** a valid connection session but an `installation_id` for an installation the returning GitHub user does not control
**When** OpenVaultDB processes the callback
**Then** it rejects the connection, emits an audit event, changes no repository file, and returns a typed failure

### AC: cancelled-install-is-side-effect-free (verifies REQ:cancelled-connect-is-retryable)

**Given** a connection session exists
**When** the user cancels, rejects, or lets it expire
**Then** no usable connection or repository mutation exists and a later fresh session can retry

### AC: onboarding-pr-contains-no-space-data (verifies REQ:root-ingitdb-database, REQ:data-free-onboarding-pull-request, REQ:no-clone-no-local-validation, REQ:auditable-provider-events)

**Given** a verified private repository connection that has not been onboarded
**When** OpenVaultDB performs onboarding
**Then** GitHub receives a setup branch and pull request containing root `.ingitdb/`, shared schemas, and the pinned validation workflow but no `sneat/spaces/<space-id>/` data; OpenVaultDB uses no repository clone or local InGitDB run

### AC: export-waits-for-onboarding-default-check (verifies REQ:onboarding-ready-after-default-check)

**Given** the onboarding pull request is open, closed unmerged, merged but unchecked, or has a failed default-branch check
**When** Sneat.app submits a Space snapshot
**Then** OpenVaultDB refuses export with the exact onboarding state and creates no data branch or pull request

### AC: first-export-opens-reviewed-pr (verifies REQ:complete-snapshot-request, REQ:snapshot-plaintext-is-transient, REQ:space-id-is-path-safe, REQ:managed-space-layout, REQ:no-clone-no-local-validation, REQ:atomic-export-branch-commit, REQ:export-pull-request, REQ:repository-wide-pull-request-check, REQ:durable-export-receipt, REQ:auditable-provider-events)

**Given** an export-ready private repository connection and a complete Space snapshot
**When** OpenVaultDB accepts the one-time export
**Then** it uses GitHub APIs to create one branch and data commit from the exact default-branch head, opens a pull request for `sneat/spaces/<space-id>/`, performs no clone or local validation, and waits for the exact-head repository-wide check and user merge

### AC: passing-checked-pr-completes-only-after-merge (verifies REQ:repository-wide-pull-request-check, REQ:pull-request-lifecycle-status, REQ:durable-export-receipt)

**Given** an export pull request head has a passing repository-wide check
**When** the user reviews and merges that exact change to the default branch
**Then** OpenVaultDB marks the export merged and the receipt binds the source revision, checked head SHA, pull request, and merge commit; before merge it reports only ready to merge

### AC: second-space-preserves-existing-space (verifies REQ:multiple-spaces-one-repository, REQ:repository-wide-pull-request-check)

**Given** an export-ready repository already contains Space A
**When** a complete snapshot for Space B is exported in its own pull request
**Then** only B's new managed subtree changes, A is preserved byte-for-byte, and CI validates the entire pull-request tree before user merge

### AC: incompatible-managed-path-is-not-overwritten (verifies REQ:multiple-spaces-one-repository, REQ:data-free-onboarding-pull-request)

**Given** an existing repository contains incompatible files at a managed InGitDB, schema, workflow, or target Space path
**When** onboarding or export is attempted
**Then** OpenVaultDB reports a conflict and does not overwrite the managed path

### AC: invalid-cross-space-reference-fails-pr (verifies REQ:repository-wide-pull-request-check, REQ:pull-request-lifecycle-status)

**Given** a candidate export for Space B leaves a broken reference to Space A
**When** the onboarding-installed workflow validates the pull-request head
**Then** the check identifies the finding, the default branch remains unchanged, and OpenVaultDB reports checks failed rather than completed

### AC: identical-export-is-idempotent (verifies REQ:idempotent-source-revision, REQ:durable-export-receipt)

**Given** an export tuple already has an active pull request or merged receipt
**When** the same logical request is submitted again
**Then** OpenVaultDB returns the existing attempt/result and does not create another branch, data commit, or pull request

### AC: merged-space-export-is-terminal (verifies REQ:idempotent-source-revision)

**Given** a Space already has a merged export receipt
**When** Sneat.app submits a later source revision for that Space
**Then** OpenVaultDB returns a typed repeated-export-not-supported result and creates no branch, commit, or pull request

### AC: default-head-advance-is-replayed-once-or-conflicts (verifies REQ:optimistic-repository-concurrency, REQ:atomic-export-branch-commit)

**Given** the default-branch head advances between snapshot acceptance and export branch publication
**When** OpenVaultDB detects the changed head
**Then** it rebuilds once from the new head before publishing or returns a typed conflict without overwriting repository data

### AC: target-space-head-advance-conflicts (verifies REQ:optimistic-repository-concurrency)

**Given** the target Space subtree already exists or changes before export branch publication
**When** OpenVaultDB attempts the one-time export
**Then** it returns a conflict and does not overwrite the existing subtree

### AC: pull-request-check-is-correlated-to-exact-sha (verifies REQ:repository-wide-pull-request-check, REQ:pull-request-lifecycle-status)

**Given** an export pull request receives a passing check and its head then changes
**When** GitHub webhooks and checks arrive
**Then** OpenVaultDB applies each verdict only to its exact head SHA and leaves the new head validating until it receives its own conclusion

### AC: workflow-outage-is-not-labelled-invalid-data (verifies REQ:repository-wide-pull-request-check, REQ:pull-request-lifecycle-status)

**Given** the validation workflow is cancelled, times out, or fails before InGitDB produces a data verdict
**When** OpenVaultDB updates connection status
**Then** the pull request remains unready and OpenVaultDB distinguishes validation unavailable from invalid repository data

### AC: public-or-revoked-repository-disconnects (verifies REQ:private-repository-only, REQ:auditable-provider-events)

**Given** a connected repository becomes public or the GitHub App installation is revoked
**When** OpenVaultDB receives the provider event or next verifies access
**Then** the connection becomes disconnected, all contained exports fail, and an actionable audit event is recorded

### AC: malicious-space-id-cannot-escape-prefix (verifies REQ:space-id-is-path-safe)

**Given** an export request contains traversal, encoded separator, control-character, or otherwise invalid Space ID input
**When** OpenVaultDB derives the managed path
**Then** it rejects the request before reading or writing a provider tree and no path outside `sneat/spaces/` is addressable

### AC: generic-vault-layout-remains-independent (verifies REQ:profile-is-application-specific)

**Given** the generic OpenVaultDB generator and the Sneat.app export profile coexist
**When** each generates its documented repository
**Then** generic vaults retain Decision 0002 behavior while Sneat.app exports use root `.ingitdb/` and `sneat/spaces/<space-id>/`

## Dependencies

- `ingitdb/ingitdb-action:repository-validation-action` supplies the pinned,
  checksum-verified GitHub Action used by generated workflows.
- `openvaultdb/openvaultdb-go` supplies the reference server, GitHub API tree,
  branch, pull-request, check-correlation, and export implementation.
- The `ingitdb/ingitdb-go` module `v0.6.0` explicit-record-base support is
  required for `record_file.records_dir: .` in this profile.
- The OpenVaultDB authentication architecture decision permits this
  feature as an optional managed backup/export provider while preserving the
  decentralized core and self-hosted protocol. This feature uses the managed
  service's OpenVaultDB GitHub App as its provider principal.

## Open Questions

- Which managed-provider deployment environment and public API base URL should
  be used for the first production rollout, and how should its
  `sneat.app` application credentials be partitioned from development?
- Should the fixed setup callback remain the shared `sneat.app` landing route,
  or should a later OpenVaultDB-owned callback be introduced while preserving
  the same one-time state and OAuth-code verification contract?
- Should OpenVaultDB attempt to install a GitHub repository ruleset requiring
  the validation check? Recommendation: not in the first release because it
  requires broader administration permissions; document an owner-enabled
  ruleset instead.
- Which durable control-plane database should hold connection metadata and
  receipts? The choice must not change the API contract or permit record
  plaintext persistence.
- Should proactive `installation` and `installation_repositories` webhooks be
  added for faster revocation status, given that polling and lazy API failures
  remain the correctness mechanism?

---
*This document follows the https://specscore.md/feature-specification*
