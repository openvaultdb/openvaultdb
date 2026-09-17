---
format: https://specscore.md/feature-specification
status: Approved
---
# Feature: Explore data hand-off

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/explore-data-handoff?op=request-change) |
**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
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
| Nested collections (demo items) | Not reachable: OVDB DTQL accepts root collections only, and `datatug-cli`'s own `--from` also only builds a root-collection reference — a `/`-containing value is sent as one literal name and comes back `200 {"records":[]}`, indistinguishable from a genuinely empty collection | `openvaultdb-go` `validateDTQL`; `datatug-cli` `pkg/dbcopy/url.go` `NewRootCollectionRef`, `apps/datatugapp/commands/cmd_query.go` `buildQuery` (spike S4) |
| DataTug.app opening an OVDB database | **No route exists**; an earlier `pwa/repo/:repo/agent/:agentId` route was not merged as a competing convention | `datatug-apps` `nav-models.ts`, `datatug-app-routes.ts` |

Local-mode OVDB requires authentication, so DataTug needs a real read-only token; spike S4 in
[configuration parity](../configuration-parity/README.md) proves the path end-to-end before
this feature is built.

### Menu

#### REQ: intent-first-menu

**Explore data** MUST ask "Where would you like to explore your data?" with **In the terminal
with DataTug CLI**, **In the browser with DataTug.app** and **Back**, each describing what
works today, for the current database or `--db`, naming it. A `--db` naming a database that is
not registered MUST be refused as `not_found` (exit `1`), never rendered as a menu. For any database other than the
demo, the DataTug CLI and DataTug.app descriptions MUST be real "what works today" copy, never
the option's own label repeated back (an earlier build returned the label key for every
non-demo database, so the menu read "In the terminal with DataTug CLI / In the terminal with
DataTug CLI"). When no database is current and none is named by `--db`, Explore data MUST show
a "Choose a database to explore first" problem (`ovdb databases`) instead of ever reaching the
menu with a blank database name.

#### REQ: demo-copy-is-specific

For the demo database the DataTug CLI option MUST say: "DataTug shows your two lists, not
their items yet. See items in the TODO app, in Browse data, or with
`ovdb list /lists/to-buy/items --db todo`."

### DataTug CLI

#### REQ: prepare-datatug-cli-connection

Choosing DataTug CLI MUST: check whether `datatug` is on `PATH` (otherwise show
`brew tap datatug/tap && brew install datatug` and
`go install github.com/datatug/datatug-cli@latest`); write a descriptor, over **POST** (never a
safe/cacheable method, since it writes a file and only when the person actually chooses DataTug
CLI), to `<OVDB home>/explore/datatug/<db>.json` with exactly the four keys `baseUrl`
(`http://127.0.0.1:<port>`), `databaseId`, `tokenEnv` (`OVDB_DATATUG_TOKEN`) and `principalId`
(`local-owner`), and no token; and show, in this order, how to obtain the read-only token
(`ovdb token create --db <db> --scope read-only`), the environment variables, and the exact
`datatug query run … --no-policies` command with the absolute descriptor path — the order a
person actually performs the steps in, since the environment variables' own token line points
at the token command. The CLI and TUI check `datatug` on **this process's own PATH**, not the
detached server's: the server commonly has a different PATH from whatever shell or agent runs
the CLI (a fresh `go install` shell, brew's prefix missing from whatever launched the server, an
agent harness with a minimal PATH), so presenting the server's own check as "your PATH" could
tell someone to install something they already have, with no fix short of `ovdb server
restart`. The web console has no client process to check and keeps the server's own check,
worded as "the PATH the OVDB server sees" rather than "your PATH". The printed
command MUST always include `--no-policies`: a fresh machine or agent has no
`~/.datatug/policies`, and without the flag `datatug query run` fails immediately with "No
access policies loaded" before it ever reaches OVDB (proven in spike S4). `principalId` and
`--as local-owner` are a `datatug-cli`-side destination-binding convention, checked entirely
inside `datatug-cli` against its own `$OVDB_DATATUG_TOKEN_PRINCIPAL_ID`; OVDB itself does not
validate a principal against the token, and copy MUST NOT imply it does. The token value MUST
NOT be written to the descriptor or shown in the web console. Any `--collection` or database
value interpolated into a printed command MUST be shell-quoted for both `sh` and PowerShell, so
a name containing spaces or shell metacharacters cannot corrupt the printed command; choosing
DataTug CLI for an unregistered database fails the same `not_found` way as the menu itself
(`REQ:intent-first-menu`). The response document carries `"schema": 1` like
every other local API document. Commands are shown truncated for **display only** — a line
too wide for the TUI or a narrow web layout ends with "…" but is never hard-wrapped with an
inserted line break, which would corrupt a pasted command (a shell continuation needs `\`, not a
bare newline, and a break inside a quoted path is worse) — and with a copy action that always
copies the full, untruncated text: the TUI's `c` key (OSC 52 via the terminal, `tea.SetClipboard`)
and a copy button on every command shown in the web console (`OvCommand.vue`), with visible
"Copied" feedback. OVDB does not run DataTug.

#### REQ: safe-collection-default

The DataTug CLI command's `--from`/`--collection` value MUST default to `lists` only for the
demo database. For any other database: with exactly one root collection, that collection MUST
be the default; with more than one, or with none, `--collection` MUST be required, and the error
MUST name the real choices with their exact commands (or state there are none to query yet). A
requested `--collection` containing `/` MUST be refused up front with "DataTug CLI reads root
collections only" (referencing [datatug-cli#256](https://github.com/datatug/datatug-cli/issues/256)),
never silently accepted: `datatug-cli`'s own `--from` builds only a single root-collection
reference, so a path-shaped value is sent as one literal name and comes back `200
{"records":[]}`, indistinguishable from a genuinely empty collection — the exact silent-empty
trap spike S4 documented. Defaulting every database to `"lists"` regardless of its real
collections had the same silent-empty failure mode for any non-demo database.

### DataTug.app

#### REQ: honest-datatug-app-state

Choosing DataTug.app MUST say DataTug.app can't open an OpenVaultDB database directly yet,
MUST NOT offer a control implying otherwise, and MUST offer **Use DataTug CLI instead** and
**Open DataTug.app**. This screen MUST use its own copy keys naming DataTug.app; it MUST NOT
reuse the TODO demo's sign-in-link copy (an earlier build did, so every database's DataTug.app
screen — demo or not — claimed to open "the TODO app with this sign-in link (single use, valid
for 10 minutes)" instead of naming DataTug.app).

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
| `datatug-cli` | Reject a `--from` value containing `/` up front ("root collections only") instead of silently returning `{"records":[]}` | Follow-up (spike S4), filed against `datatug-cli` |
| `datatug-cli` | Distinguish a revoked/expired token (plain server `401`) from a DTQL policy denial (`403` authorization envelope) instead of collapsing both to `Dalgo access denied.` | Follow-up (spike S4), `pkg/openvaultdb/source.go` |
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
**Then** the response carries `"schema": 1`, the descriptor has exactly the four keys and no token, POSTing the endpoint is what wrote it, and the JSON lists the variables, the token command and the `datatug query run … --no-policies` command with the token command ordered before the variables

### AC: datatug-missing (verifies REQ:prepare-datatug-cli-connection)

**Given** `datatug` not on this process's `PATH` but on the detached server's `PATH`
**When** the person chooses DataTug CLI in the TUI
**Then** it reports missing and shows the install commands with the prepared command for afterwards — the CLI/TUI process's own PATH, not the server's

### AC: collection-resolves-safely (verifies REQ:safe-collection-default)

**Given** a non-demo database `notes` with one root collection `/customers`, and separately one with two root collections and no `--collection`
**When** `ovdb explore datatug-cli --db notes --json` runs for each
**Then** the first defaults to `customers` and never `lists`; the second fails `invalid_argument` naming both collections with their exact commands; a third call with `--collection lists/to-buy/items` fails `invalid_argument` before any request reaches `datatug`

### AC: unknown-database-not-found (verifies REQ:prepare-datatug-cli-connection)

**Given** an id no database is registered under
**When** `ovdb explore --db nope --json` runs
**Then** it fails `not_found` naming `nope`, exit `1`, never a menu

### AC: datatug-app-is-honest (verifies REQ:honest-datatug-app-state)

**Given** the web console
**When** the person chooses DataTug.app for any database, demo or not
**Then** the page states the limitation by name ("DataTug.app"), never the TODO demo's sign-in-link copy, offers Use DataTug CLI instead and Open DataTug.app, and has no control labelled as opening the database there

## Open Questions

- Which DataTug.app convention will DataTug choose for OVDB sources, and who proposes it?
- Deferred: running DataTug from the TUI or CLI ("Run it now").

---
*This document follows the https://specscore.md/feature-specification*
