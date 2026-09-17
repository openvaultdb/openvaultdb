---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Explore data hand-off

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

"Explore data" asks where the person wants to explore — in the terminal with DataTug CLI or in
the browser with DataTug.app — and hands over exactly what that tool needs, stating honestly
what works today. OVDB's own read-only Browse data covers simple viewing; DataTug is for
querying.

## Problem

DataTug has a read-only OpenVaultDB source, but connecting it needs a descriptor file, three
environment variables and a principal flag no newcomer would find. DataTug.app cannot open an
OVDB database at all. Promising a one-click experience that does not exist would break trust.

## Behavior

### What DataTug can do with OVDB today (verified in source, 2026-09-17)

| Capability | State | Evidence |
|---|---|---|
| DataTug CLI query | Read-only DTQL on **root** collections via `datatug query run --db openvaultdb://<descriptor.json>` | `datatug-cli` `pkg/openvaultdb/source.go`, `pkg/dbcopy/url.go`, `apps/datatugapp/commands/cmd_query.go` |
| Descriptor | Exactly `baseUrl`, `databaseId`, `tokenEnv`, `principalId`; token from `$<tokenEnv>` (non-empty), `$<tokenEnv>_BASE_URL` and `$<tokenEnv>_PRINCIPAL_ID` must match | `source.go` `OpenSource`, `client.go` `Target.Validate` |
| Principal | `--as <principalId>` must equal the descriptor | `source.go` |
| Nested collections (demo items) | Not reachable: OVDB DTQL accepts root collections only | `openvaultdb-go` `validateDTQL` |
| DataTug.app opening an OVDB database | **No route exists**; an earlier `pwa/repo/:repo/agent/:agentId` route was not merged as a competing convention | `datatug-apps` `nav-models.ts`, `datatug-app-routes.ts` |

Local-mode OVDB requires authentication, so DataTug needs a real read-only token; spike S4 in
[configuration parity](../configuration-parity/README.md) proves the path end-to-end before
this feature is built.

### Menu

#### REQ: intent-first-menu

**Explore data** MUST ask "Where would you like to explore your data?" with **In the terminal
with DataTug CLI**, **In the browser with DataTug.app** and **Back**, each describing what
works today, for the current database or `--db`, naming it.

#### REQ: demo-copy-is-specific

For the demo database the DataTug CLI option MUST say: "DataTug shows your two lists, not
their items yet. See items in the TODO app, in Browse data, or with
`ovdb list /lists/to-buy/items --db todo`."

### DataTug CLI

#### REQ: prepare-datatug-cli-connection

Choosing DataTug CLI MUST: check whether `datatug` is on `PATH` (otherwise show
`brew tap datatug/tap && brew install datatug` and
`go install github.com/datatug/datatug-cli@latest`); write a descriptor to
`<OVDB home>/explore/datatug/<db>.json` (`baseUrl` `http://127.0.0.1:<port>`, `databaseId`,
`tokenEnv` `OVDB_DATATUG_TOKEN`, `principalId` `local-owner`); and show the environment
variables and exact `datatug query run` command with the absolute descriptor path, plus how
to obtain the read-only token (`ovdb token create --db <db> --scope read-only`). The token
value MUST NOT be written to the descriptor or shown in the web console. Commands are shown
with a copy action; OVDB does not run DataTug.

### DataTug.app

#### REQ: honest-datatug-app-state

Choosing DataTug.app MUST say DataTug.app can't open an OpenVaultDB database directly yet,
MUST NOT offer a control implying otherwise, and MUST offer **Use DataTug CLI instead** and
**Open DataTug.app**.

### Commands

| Action | CLI |
|---|---|
| Show choices | `ovdb explore [--db <db>] [--json]` |
| DataTug CLI | `ovdb explore datatug-cli [--db <db>] [--collection <name>] [--json]` |
| DataTug.app | `ovdb explore datatug-app [--db <db>] [--print-url]` |

### External dependencies

| Owner | Needed for | Status |
|---|---|---|
| `openvaultdb-go` | Nested-collection queries so DataTug can show `/lists/to-buy/items` | Follow-up |
| `openvaultdb/ovdb` | Read-only token creation against the local server (`ovdb token create`, specified in local server) | Proven in spike S4 |
| `datatug-apps` | A supported way to open an OVDB database following DataTug's store-id convention | Not started |
| DataTug.app ↔ loopback | Browser rules for public-site-to-local requests (Chrome's local network access changes); re-verify before designing | Design needed |

## Dependencies

- database-setup-and-providers
- local-server-and-web-console
- todo-demo

## Acceptance Criteria

### AC: menu-asks-intent-first (verifies REQ:intent-first-menu)

**Given** a current database `notes`
**When** the person chooses Explore data in the TUI and web console, and `ovdb explore --json` runs
**Then** all name `notes` and present both tools with current-state descriptions before any file is written

### AC: demo-explore-copy (verifies REQ:demo-copy-is-specific)

**Given** the demo installed
**When** Explore data opens for `todo`
**Then** the DataTug CLI option states that items are not shown yet and names the TODO app, Browse data and the `ovdb list` command

### AC: descriptor-and-command (verifies REQ:prepare-datatug-cli-connection)

**Given** a running server on 6832 and `datatug` on `PATH`
**When** `ovdb explore datatug-cli --db todo --collection lists --json` runs
**Then** the descriptor has exactly the four keys and no token, and the JSON lists the variables, the token command and the `datatug query run` command

### AC: datatug-missing (verifies REQ:prepare-datatug-cli-connection)

**Given** `datatug` not on `PATH`
**When** the person chooses DataTug CLI in the TUI
**Then** the install commands are shown with the prepared command for afterwards

### AC: datatug-app-is-honest (verifies REQ:honest-datatug-app-state)

**Given** the web console
**When** the person chooses DataTug.app
**Then** the page states the limitation, offers Use DataTug CLI instead and Open DataTug.app, and has no control labelled as opening the database there

## Open Questions

- Which DataTug.app convention will DataTug choose for OVDB sources, and who proposes it?
- Deferred: running DataTug from the TUI or CLI ("Run it now").

---
*This document follows the https://specscore.md/feature-specification*
