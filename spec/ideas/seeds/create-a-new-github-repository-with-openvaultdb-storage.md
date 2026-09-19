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

Use https://github.com/apps/openvaultdb (App ID 4786001, client ID
`Iv23liJsM9tKD7ZnLwDo`), owned by **openvaultdb**, as
REQ:openvaultdb-github-app-registration already mandates. This keeps the provider identity
neutral and preserves the OpenVaultDB consent-screen brand.

Before relying on it, verify ownership-transfer identity, installation continuity, private-key
rotation, and replace the callback pinned to `https://sneat.app/github/ovdb-installed`.
