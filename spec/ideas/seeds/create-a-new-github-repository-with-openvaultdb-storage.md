---
captured_by: user
status: queued
---
# Create a new GitHub repository with OpenVaultDB storage holding an empty inGitDB (or a small TODO app), as an end-to-end demo of OpenVaultDB vault provisioning.

A dedicated subplot, not part of the DataTug user-owned-storage plans — referenced from them.

Revives a capability that was deferred by decision: `backstage/VAULT-MODEL.md` records "Creating vaults on an OpenVaultDB host from the wallet (provisioning) ... is deferred", and decision 0003 defers vault provisioning. This is the smallest end-to-end artefact that exercises the whole chain: create a repository, bind it as an OVDB storage, and land a valid inGitDB layout in it.

Scope to decide later: empty inGitDB scaffold versus a small TODO app as the first record set; whether the flow starts from the OVDB wallet (`openvaultdb.com/my/vaults`), the `ovdb` CLI, or a DataTug surface; and which GitHub credential performs repo creation (fine-grained PAT with administration write, versus an OVDB GitHub App user access token).

Owner: openvaultdb/openvaultdb. Depends on nothing; consumed by datatug/datatug plans/github.com/datatug/datatug/datatug-user-owned-storage.
## POC flow requirements

- The UI MUST ask which **organization** to create the repository in.
- It MUST show the final repository path (organization + entered name) before creating.
- It MUST validate that the repository does not already exist.
- Once created, the flow MUST install the OpenVaultDB GitHub App on the new repository.

Creating in an organization is functional, not just UX: `POST /orgs/{org}/repos` accepts an installation token with `administration: write`, while `POST /user/repos` never accepts one. Organization listing and the existence check need a user credential.

## Decision: the provider app is independent

The app is https://github.com/apps/openvaultdb (App ID 4786001, client ID `Iv23liJsM9tKD7ZnLwDo`), owned by the **openvaultdb** organization — as REQ:openvaultdb-github-app-registration in `openvaultdb/spec/features/sneat-space-export` already mandates. Independence preserves provider/consumer neutrality (Sneat is otherwise both provider and consumer), the consent-screen brand, and OVDB's ability to operate its own provider identity for self-hosted and third-party consumers.

To verify before relying on it: GitHub documents transferring app ownership, but whether App ID and client ID survive, whether installations persist, and whether the private key must be reissued are unverified. Installations are effectively nil today (`sneat-co/ovdb` install verification is dormant and fail-open), so acting now is cheap. Related coupling: the app's OAuth callback is pinned to `https://sneat.app/github/ovdb-installed` — a consumer's domain inside a provider-owned app.
