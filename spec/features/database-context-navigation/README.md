---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Database context and navigation

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

`ovdb use` remembers which database a project works with, `ovdb cd` and `ovdb pwd` move
around inside it with filesystem-like paths, and five small data commands (`list`, `get`,
`set`, `add`, `delete`) read and write records over the existing HTTP API. Together they
let a person or an AI agent work with stored data in a few short commands.

Decision: [0008 database context scope](../../decisions/0008-database-context-scope.md).
Transport: [0007](../../decisions/0007-local-ovdb-server-and-web-address.md) (data
commands are HTTP clients of the local server and start it when needed).

## Problem

There is no CLI to read or write a record: the only way is raw HTTP. There is no
remembered database, so every call would repeat `--db`. OpenVaultDB keys are already
hierarchical (`collection/id/collection/id`), but nothing lets a person see or use that
structure. Agents need a compact, predictable vocabulary; this is not a redesign of the
data API, access control or schema management.

## Behavior

### Context commands

| Command | Effect |
|---|---|
| `ovdb use <db>` | Set the project context to `<db>` at `/` |
| `ovdb use --global <db>` | Set the default for all projects |
| `ovdb use` | Show the current database, path and where it came from |
| `ovdb use --clear` / `ovdb use --global --clear` | Remove the project context / global default |
| `ovdb cd [path]` | Change the path within the current database |
| `ovdb pwd [--json]` | Print database and path |

#### REQ: use-sets-scoped-context

`ovdb use <db>` MUST fail with a list of registered databases if `<db>` is not registered.
On success it MUST store the context for the project root defined in decision 0008, reset
the path to `/`, and print the scope, for example
`Now using todo for this project (/home/ann/shop)`. `--global` MUST store the global
default instead and print `Now using todo as your default for all projects`.

#### REQ: context-precedence

Every command that needs a database MUST resolve it with the decision 0008 ladder:
`--db` > `OVDB_DATABASE`/`OVDB_PATH` > project context > global default > the only
registered database > error. `ovdb use` and `ovdb pwd` MUST name the rung that supplied
the value.

#### REQ: path-resolution

Paths MUST resolve as follows: a leading `/` is absolute; anything else is relative to the
context path; `.` is the current location; `..` goes up one segment and never above `/`;
empty segments are ignored. Segment 1, 3, 5… are collections, segment 2, 4, 6… are record
ids. Segments MUST be escaped with `dal.EscapeID` rules when sent to the server, and a `/`
inside an id MUST be written `%2F`. Output MUST always show absolute paths.

#### REQ: cd-validates-syntax-not-existence

`ovdb cd` with no argument or `/` MUST go to the root. `cd` MUST fail only for an invalid
path or unregistered database. It MUST NOT fail when the collection or record has no data
yet; it MUST then print `Nothing here yet`. `cd` MUST reuse the context scope (project or
global) that currently supplies the database.

Examples, starting at `todo:/lists/to-buy`:

| Command | Result | Kind |
|---|---|---|
| `ovdb cd items` | `/lists/to-buy/items` | collection |
| `ovdb cd ..` | `/lists` | collection |
| `ovdb cd ../to-watch` | `/lists/to-watch` | record |
| `ovdb cd /lists/to-watch/items` | `/lists/to-watch/items` | collection |
| `ovdb cd ../../../..` | `/` | root |
| `ovdb cd` | `/` | root |
| `ovdb use notes` then `ovdb pwd` | `notes:/` | root |

### Data commands

| Command | Path kind | Server call (existing API) |
|---|---|---|
| `ovdb list [path]` (alias `ls`) | root | `GET /v1/databases/{db}` (collections) |
| `ovdb list [path]` | collection | `POST /v1/databases/{db}/query` with `collection` and `parent` |
| `ovdb get <path>` | record | `GET /v1/databases/{db}/records/{key}` |
| `ovdb set <path> <json or ->` | record | `PUT …/records/{key}` (create or replace) |
| `ovdb set <path> --field k=v…` | record | `PATCH …/records/{key}` with `updates` |
| `ovdb add <path> <json or ->` | collection | `POST …/records/{collection}/{new-id}` (insert only) |
| `ovdb delete <path>` (alias `rm`) | record | `DELETE …/records/{key}` |

All data commands accept `--db`, `--json` and `--no-start`. `list` accepts `--limit`
(default 50).

#### REQ: data-commands-use-http

Data commands MUST call the local OVDB server's existing data API and MUST NOT open
storage in-process. If no server is running they MUST start one as specified in decision
0007, print `Started the OVDB server at http://ovdb.localhost:6832` on stderr, and
continue; with `--no-start` they MUST fail with the hint `ovdb server start`.

#### REQ: list-behaviour

`ovdb list` at the root MUST list collections reported by the server. At a collection
path it MUST list records with their id and up to three top-level scalar fields in a
compact table, and with `--json` an array of `{"path","id","data"}`. At a record path it
MUST show the record and state `Listing collections inside a record isn't supported yet`
with an example of listing a known sub-collection. An empty collection MUST print
`Nothing here yet`.

#### REQ: get-set-add-delete

`get` MUST print a record's data (pretty JSON; `--json` gives `{"path","id","data"}`).
`set` with a JSON object MUST create or replace the record; `set --field k=v` MUST
update only named fields, parsing `v` as a JSON literal when valid (`true`, `3`,
`"x"`, `null`) and as a string otherwise. `add` MUST generate a short, URL-safe unique id
(or use `--id`), insert without overwriting, and print the new absolute path. `delete`
MUST delete one record without prompting and print its path; it MUST refuse collection
paths. JSON input MAY be `-` to read stdin.

#### REQ: path-kind-mismatch-guidance

Using a collection path where a record is required, or the reverse, MUST produce the
problem pattern with the correct command, for example
`/lists/to-buy/items is a collection. To see its records: ovdb list /lists/to-buy/items`.

#### REQ: server-errors-mapped

Server errors (not found, validation failures including strict-mode "no schema declared",
access denied, unsupported operation) MUST be rendered with the problem pattern and a
next step, and `--json` MUST include the server's error code.

### Interfaces other than the CLI

#### REQ: select-database-in-tui-and-web

The TUI MUST show the current database and let the person choose another, stored as the
project context for the directory where the TUI was started. The web console MUST show
the global default and let the person change it. Path navigation and data commands are a
CLI and agent capability in MVP (parity exception recorded in
[configuration parity](../configuration-parity/README.md)).

## Dependencies

- local-server-and-web-console
- database-setup-and-providers
- configuration-parity

## Acceptance Criteria

### AC: use-is-project-scoped (verifies REQ:use-sets-scoped-context, REQ:context-precedence)

**Given** databases `todo` and `notes`, project A at `/p/a` and project B at `/p/b` (both Git repositories)
**When** `ovdb use todo` runs in `/p/a/src`, `ovdb use notes` runs in `/p/b`, and `ovdb pwd` runs in `/p/a`
**Then** the first prints `Now using todo for this project (/p/a)`, and `pwd` in `/p/a` prints `todo:/` with source `project`, unaffected by project B

### AC: precedence-ladder (verifies REQ:context-precedence)

**Given** project context `todo`, global default `notes`, and `OVDB_DATABASE=notes`
**When** `ovdb pwd`, `ovdb pwd --db todo`, and (after unsetting the variable and clearing the project context) `ovdb pwd` run
**Then** they report `notes` from environment, `todo` from flag, and `notes` from global default

### AC: no-context-error-lists-databases (verifies REQ:context-precedence)

**Given** two registered databases and no context, flag or variable
**When** `ovdb list` runs
**Then** it exits `1` listing both databases and the hint `ovdb use <database>`

### AC: use-resets-path (verifies REQ:use-sets-scoped-context, REQ:path-resolution)

**Given** context `todo:/lists/to-buy/items`
**When** `ovdb use notes` and `ovdb pwd` run
**Then** `pwd` prints `notes:/`

### AC: cd-examples (verifies REQ:path-resolution, REQ:cd-validates-syntax-not-existence)

**Given** context `todo:/lists/to-buy`
**When** each command in the examples table runs from that starting point
**Then** each resulting path matches the table, and `ovdb cd /lists/new-list/items` succeeds printing `Nothing here yet`

### AC: escaped-ids-round-trip (verifies REQ:path-resolution)

**Given** a schemaless database
**When** `ovdb set /files/a%2Fb.txt '{"n":1}'` and then `ovdb list /files --json` run
**Then** the record id is `a/b.txt` on the server and the listed path is `/files/a%2Fb.txt`

### AC: data-commands-auto-start (verifies REQ:data-commands-use-http)

**Given** the `todo` demo installed and no server running
**When** `ovdb list /lists --db todo` runs, and later (server stopped) `ovdb list /lists --db todo --no-start` runs
**Then** the first prints the start line on stderr and the two lists on stdout; the second exits `1` with the hint `ovdb server start`

### AC: list-kinds (verifies REQ:list-behaviour)

**Given** the TODO demo data
**When** `ovdb list /`, `ovdb list /lists`, `ovdb list /lists/to-buy`, `ovdb list /lists/to-buy/items --json` and `ovdb list /empty` run with `--db todo`
**Then** they show the `lists` collection, the two lists, the To buy record with the sub-collection note, a JSON array of three items with `path`, `id`, `data`, and `Nothing here yet`

### AC: add-set-get-delete (verifies REQ:get-set-add-delete)

**Given** the TODO demo
**When** `ovdb add /lists/to-buy/items '{"title":"Tea","done":false}' --db todo` prints a path P, then `ovdb set P --field done=true --db todo`, `ovdb get P --json --db todo`, `ovdb delete P --db todo` run
**Then** `get` shows `done` as boolean `true`, `title` unchanged, and after `delete` a `get` exits `1` with a not-found problem

### AC: kind-mismatch-hint (verifies REQ:path-kind-mismatch-guidance)

**Given** the TODO demo
**When** `ovdb get /lists/to-buy/items --db todo` and `ovdb delete /lists --db todo` run
**Then** both exit `1`; the first suggests `ovdb list /lists/to-buy/items`, the second explains only single records can be deleted

### AC: strict-mode-error-is-explained (verifies REQ:server-errors-mapped)

**Given** a SQLite database `shop` with no declared schemas
**When** `ovdb add /orders '{"total":1}' --db shop --json` runs
**Then** it exits `1` with an error object whose `code` is the server's validation code and whose hint explains that this collection needs a schema

### AC: tui-and-web-select-database (verifies REQ:select-database-in-tui-and-web)

**Given** databases `todo` and `notes`
**When** the person selects `notes` in the TUI started in `/p/a`, and selects `todo` in the web console
**Then** `ovdb pwd` in `/p/a` reports `notes` from project context, and in a directory without project context reports `todo` from global default

## Open Questions

- Should `ovdb list` at a record path list sub-collections once the server exposes them?
  This needs an `openvaultdb-go` endpoint.
- Should `ovdb delete` support a collection with `--recursive --yes`?
- Should `--field` support nested field paths (`address.city=Paris`) in MVP?

---
*This document follows the https://specscore.md/feature-specification*
