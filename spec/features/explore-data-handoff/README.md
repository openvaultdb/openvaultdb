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

"Explore data" asks where the person wants to look at their data — in the terminal with
DataTug CLI or in the browser with DataTug.app — and then hands over exactly what that
tool needs, stating honestly what works today. OVDB does not build its own data browser.

## Problem

After creating a database or installing the demo, people want to *see* their data. DataTug
is the ecosystem's data exploration tool and already has an OpenVaultDB source, but
connecting it takes a JSON descriptor, three environment variables and a principal flag
that no newcomer would discover. The browser app has no way to open an OVDB database at
all. Promising a one-click experience that does not exist would break trust.

## Behavior

### What DataTug can do with OVDB today (verified in source, 2026-09-17)

| Capability | State | Evidence |
|---|---|---|
| DataTug CLI query against an OVDB server | Works for read-only DTQL on **root** collections | `datatug-cli` `pkg/openvaultdb/source.go`, `pkg/dbcopy/url.go` (`openvaultdb://<descriptor.json>`), `apps/datatugapp/commands/cmd_query.go` (`datatug query run --db`) |
| Connection descriptor | JSON with exactly `baseUrl`, `databaseId`, `tokenEnv`, `principalId`; token read from `$<tokenEnv>`, which must be non-empty; `$<tokenEnv>_BASE_URL` and `$<tokenEnv>_PRINCIPAL_ID` must match the file | `source.go` `OpenSource`, `client.go` `Target.Validate` |
| Principal | `datatug query run --as <principalId>` must equal the descriptor's `principalId` | `source.go` `ExecuteQueryToRecordsReader` |
| Nested collections (for example `/lists/to-buy/items`) | Not reachable: OVDB's DTQL endpoint accepts only root collections | `openvaultdb-go` `validateDTQL` |
| Record get, transactions | Not supported by the DataTug OVDB source (`dal.ErrNotSupported`) | `source.go` |
| DataTug.app opening an OVDB database | **No route exists.** The app knows local DataTug agents by store id `http-<host>:<port>` (for example `http-localhost:8989`); an earlier `pwa/repo/:repo/agent/:agentId` OVDB route was deliberately not merged as a competing convention | `datatug-apps` `nav-models.ts`, `datatug-app-routes.ts` |
| DataTug.app through a local `datatug serve` agent | Possible only inside a DataTug project whose environment catalog uses driver `openvaultdb` | `datatug-cli` `pkg/api/source_resolver.go` |

The CLI hand-off was verified by reading source, not by running DataTug against a live
OVDB server; the first implementation increment MUST run it end-to-end.

### Menu

#### REQ: intent-first-menu

**Explore data** MUST first ask "Where would you like to explore your data?" with
**In the terminal with DataTug CLI**, **In the browser with DataTug.app**, and **Back**,
each with one line describing what works today. It MUST apply to the current database, or
the one given with `--db`, and MUST say which database it is.

Example copy (TUI; web uses cards):

```
Explore data · todo

Where would you like to explore your data?

> In the terminal with DataTug CLI
    Query your collections from the terminal. Top-level collections only for now.
  In the browser with DataTug.app
    DataTug.app can't open OpenVaultDB databases directly yet. See what you can do today.
  Back
```

### DataTug CLI

#### REQ: prepare-datatug-cli-connection

Choosing DataTug CLI MUST: check whether `datatug` is on `PATH` (and show the install
commands `brew tap datatug/tap && brew install datatug` or
`go install github.com/datatug/datatug-cli@latest` if not); write a descriptor to OVDB home
`explore/datatug/<db>.json` with `baseUrl` `http://127.0.0.1:<port>`, `databaseId` `<db>`,
`tokenEnv` `OVDB_DATATUG_TOKEN`, `principalId` `local-owner`; and show the exact command
with its environment variables in the syntax of the person's shell (POSIX shells, PowerShell or cmd),
using the absolute descriptor path. When the server runs without `--auth`, the token value
MUST be the placeholder `local` and the output MUST say the local server does not check it.
When `--auth` is on, OVDB MUST NOT mint a token silently; it MUST show
`ovdb token create --db <db> --scope read-only` as the step to obtain one.

Example copy:

```
Explore todo with DataTug CLI

DataTug can query top-level collections of this database. Run:

  export OVDB_DATATUG_TOKEN=local
  export OVDB_DATATUG_TOKEN_BASE_URL=http://127.0.0.1:6832
  export OVDB_DATATUG_TOKEN_PRINCIPAL_ID=local-owner
  datatug query run --db openvaultdb:///home/ann/.config/ovdb/explore/datatug/todo.json \
    --from lists --as local-owner --no-policies

Lists inside records (like /lists/to-buy/items) can't be queried by DataTug yet.
To see them now: ovdb list /lists/to-buy/items --db todo

[ Run it now ]   Copy commands   Back
```

#### REQ: run-datatug-now

`ovdb explore datatug-cli --run` and the TUI's **Run it now** MUST run `datatug query run`
with the environment variables set only for that child process, stream its output, and
return its exit code. The web console MUST NOT run commands on the person's behalf; it
shows the commands with a copy button (parity exception).

### DataTug.app

#### REQ: honest-datatug-app-state

Choosing DataTug.app MUST state that DataTug.app cannot open an OpenVaultDB database
directly yet, MUST NOT present a button that implies otherwise, and MUST offer: **Use
DataTug CLI now** (goes to the CLI hand-off) and **Open DataTug.app** (opens
`https://datatug.app` for people who already use DataTug projects). When DataTug adds a
supported way to open an OVDB database, this screen changes to a direct hand-off in a
new specification revision.

### Commands

| Action | CLI |
|---|---|
| Show choices | `ovdb explore [--db <db>] [--json]` (TTY: menu; otherwise prints both options with commands) |
| DataTug CLI | `ovdb explore datatug-cli [--db <db>] [--collection <name>] [--run] [--json]` |
| DataTug.app | `ovdb explore datatug-app [--db <db>] [--print-url]` |

### External dependencies

| Owner | Needed for | Status |
|---|---|---|
| `openvaultdb-go` | DTQL over nested collections, so DataTug can show `/lists/to-buy/items` | Not started |
| `datatug-cli` | Optional: accept an empty token for loopback OVDB without auth | Not started; placeholder token works around it |
| `datatug-apps` | A supported way to open an OVDB database (route or store type) that follows DataTug's existing store-id convention | Not started; must not re-propose the rejected `pwa/repo/:repo/agent/:agentId` shape |
| OVDB server or DataTug agent | If DataTug.app ever calls a loopback server directly from `https://datatug.app`: CORS and Private Network Access headers (`Access-Control-Allow-Private-Network`) | Design needed |

## Dependencies

- database-setup-and-providers
- local-server-and-web-console
- todo-demo

## Acceptance Criteria

### AC: menu-asks-intent-first (verifies REQ:intent-first-menu)

**Given** a current database `todo`
**When** the person chooses Explore data in the TUI and the web console, and runs `ovdb explore` non-interactively
**Then** all three name `todo` and present DataTug CLI and DataTug.app with their current-state descriptions before any file is written

### AC: descriptor-and-command (verifies REQ:prepare-datatug-cli-connection)

**Given** a server without `--auth` on port 6832 and `datatug` on `PATH`
**When** `ovdb explore datatug-cli --db todo --collection lists --json` runs
**Then** `explore/datatug/todo.json` contains exactly the four descriptor keys with the specified values, and the JSON output contains the three environment variables and the `datatug query run` command

### AC: datatug-missing (verifies REQ:prepare-datatug-cli-connection)

**Given** `datatug` not on `PATH`
**When** the person chooses DataTug CLI in the TUI
**Then** the screen shows the Homebrew and `go install` commands and still shows the prepared command for after installation

### AC: auth-mode-needs-token (verifies REQ:prepare-datatug-cli-connection)

**Given** a server started with `--auth`
**When** `ovdb explore datatug-cli --db todo` runs
**Then** no token is created, and the output shows `ovdb token create --db todo --scope read-only` as the step to obtain one

### AC: run-now-end-to-end (verifies REQ:run-datatug-now)

**Given** the TODO demo installed, the server running and `datatug` installed
**When** `ovdb explore datatug-cli --db todo --collection lists --run` runs
**Then** DataTug prints the two lists, the command exits `0`, and the parent shell has none of the `OVDB_DATATUG_TOKEN*` variables afterwards

### AC: datatug-app-is-honest (verifies REQ:honest-datatug-app-state)

**Given** the web console
**When** the person chooses In the browser with DataTug.app
**Then** the page says DataTug.app can't open OpenVaultDB databases directly yet, offers Use DataTug CLI now and Open DataTug.app, and contains no control labelled as opening the database in DataTug.app

## Open Questions

- Should the TODO demo's items also be reachable by DataTug before nested DTQL lands (for
  example a root `items` collection mirror)? Recommendation: no; keep one data layout and
  prioritise nested DTQL in `openvaultdb-go`.
- Which DataTug.app convention will DataTug choose for OVDB sources, and who owns
  proposing it?
- DataTug CLI telemetry is on without an opt-out while OVDB's is opt-in; should the
  hand-off mention this?

---
*This document follows the https://specscore.md/feature-specification*
