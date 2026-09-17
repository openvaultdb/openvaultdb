---
format: https://specscore.md/feature-specification
status: Approved
---
# Feature: Database context and navigation

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-context-navigation?op=request-change) |
**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
**Supersedes:** —

## Summary

`ovdb use` remembers which database a project works with, `ovdb cd` and `ovdb pwd` move
inside it with file-like paths, and five small data commands (`list`, `get`, `set`, `add`,
`delete`) read and write records through the local server. The TUI and web console offer a
read-only **Browse data** view so people can see their own data without a terminal.

Decision: [0008 database context scope](../../decisions/0008-database-context-scope.md).
Transport and auto-start: [0007](../../decisions/0007-local-ovdb-server-and-web-address.md).

## Problem

There is no way to read or write a record except raw HTTP, no remembered database, and no
way to see one's own data in any UI. Agents need a compact, predictable vocabulary. This is
not a redesign of the data API, access control or schemas.

## Behavior

### Context commands

| Command | Effect |
|---|---|
| `ovdb use <db>` | Set the project context to `<db>` at `/` |
| `ovdb use --global <db>` | Set the default for all projects |
| `ovdb use` | Show the current database, path, scope and supplying directory |
| `ovdb use --clear`, `ovdb use --global --clear` | Remove the project context or global default |
| `ovdb cd [path]` | Change the path within the current database |
| `ovdb pwd [--json]` | Print database, path and scope |

#### REQ: use-sets-scoped-context

`ovdb use <db>` MUST fail with `not_found` listing registered databases when `<db>` is not
registered. On success the CLI MUST send the project root (nearest Git working-tree root,
each linked worktree its own root, else the current directory) to the server with the
instance secret; the server MUST store the context, reset the path to `/` and return copy
naming the scope, for example `Now using todo for this project (/home/ann/shop)`.

The server MUST refuse to store a project context whose root is the user's home directory or
a filesystem root, since every folder below would share the choice; it MUST fail with
`invalid_argument` naming the conflict, with `next` steps to run `ovdb use` inside a project
folder or use `ovdb use --global <database>` instead. Project-context lookup keys the stored
context by the hash of the canonicalized directory; on Windows and macOS this hash folds case
first (`~/Shop` and `~/shop`, like `C:\Work` and `c:\work`, are one directory), since both
platforms' default file systems ignore case.

#### REQ: context-lookup

Resolution MUST follow `--db` > `OVDB_DATABASE`/`OVDB_PATH` > project context > global default
> the only registered database > `not_found` with the list and `ovdb use <database>`. Project
context lookup MUST walk up from the current directory to the nearest directory with a stored
context, not above the Git root when inside a repository. `ovdb use` and `ovdb pwd` MUST name
the rung and the supplying directory. `OVDB_PATH` without a database MUST be ignored with a
warning.

A stored project context naming a database that is no longer registered MUST NOT fail lookup
outright: it MUST be skipped with a notice on stderr naming the directory and the missing
database, and resolution MUST continue to the next rung (a shallower project context, the
global default, or the only registered database). `OVDB_PATH` set without `--db` or
`OVDB_DATABASE` MUST still be syntactically valid; an unparsable one MUST fail with
`invalid_argument` rather than silently resolving to `/`.

#### REQ: path-resolution

A leading `/` is absolute; other paths are relative to the context path; `.` stays; `..` goes
up one segment, never above `/`; empty segments are ignored. Odd segments are collections,
even segments record ids. Ids MUST be written and displayed escaped as `record.EscapeID`
(`dal-go/record`) does (`/` → `%2F`, `.` → `%2E`, `$` → `%24`, `#` → `%23`, `[` → `%5B`,
`]` → `%5D`); a `%` that does not start one of these escapes MUST fail with `invalid_argument`
(literal `%` is not a valid id character). Output always shows absolute paths.

Once a segment is unescaped, none of its `/`-separated parts (an id MAY legitimately contain an
escaped `/`, written `%2F`) may be empty, `.` or `..`, and the segment MUST NOT contain a
control character (U+0000–U+001F, U+007F); either fails with `invalid_argument`. Names and ids
that reach human output are shown with any remaining non-printable rune as `\uXXXX`.

#### REQ: cd-validates-syntax-not-existence

`ovdb cd` with no argument or `/` goes to the root. It MUST fail only for invalid paths or an
unregistered database, print `Nothing here yet` for empty locations, and update the scope that
currently supplies the database. When the database came from `--db` or
`OVDB_DATABASE`/`OVDB_PATH`, `cd` MUST fail with `invalid_argument` instead of moving within
it (`next`: set `OVDB_PATH=<target>`, or use the target path directly in the next command),
since there is no context to update. When the current scope is the only-registered-database
rung (no stored context, flag or variable), `cd` MUST save a project context for the project
root the same way `use` does and say so (`Saved as the project context for {dir}.`), so a
later command in that project keeps resolving the same database without `--db`.

Examples from `todo:/lists/to-buy`:

| Command | Result | Kind |
|---|---|---|
| `ovdb cd items` | `/lists/to-buy/items` | collection |
| `ovdb cd ..` | `/lists` | collection |
| `ovdb cd ../to-watch` | `/lists/to-watch` | record |
| `ovdb cd ../../../..` | `/` | root |
| `ovdb use notes` then `ovdb pwd` | `notes:/` | root |

### Data commands

| Command | Path kind | Server call |
|---|---|---|
| `ovdb list [path]` (alias `ls`) | root | `GET /v1/databases/{db}` (collections) |
| `ovdb list [path]` | collection | `POST /v1/databases/{db}/query` with `collection` and `parent` |
| `ovdb get <path>` | record | `GET /v1/databases/{db}/records/{key}` |
| `ovdb set <path> <json or ->` | record | `PUT …/records/{key}` |
| `ovdb set <path> --field k=v…` | record | `PATCH …/records/{key}` |
| `ovdb add <path> <json or ->` | collection | `POST …/records/{collection}/{new-id}` |
| `ovdb delete <path>` (alias `rm`) | record | `DELETE …/records/{key}` |

All accept `--db`, `--json` and `--no-start`; `list` accepts `--limit` (default 50).

`--json` output of reads is the existing `/v1` response body, with one field added to each
record: an absolute escaped `path`, usable as `<path>` in a later command, next to the
server's untouched `key`; writes, whose `/v1` response has no body, print the affected key:

| Command | `--json` success body | Source |
|---|---|---|
| `list` at root | `{"id","engine","schemaMode","collections"}` | `GET /v1/databases/{db}` |
| `list` at a collection | `{"records":[{"key","data","path"}]}` | `POST …/query`, `path` added by the CLI |
| `get` | `{"key","data","path"}` | `GET …/records/{key}`, `path` added by the CLI |
| `set`, `add`, `delete` | `{"key":"/lists/to-buy/items/k3f9x2"}` — the affected record's absolute escaped path, usable as `<path>` in the next command | built by the CLI (`PUT`/`PATCH`, `POST` and `DELETE` return no body) |
| any failure | `{"error":{"code","message"}}` with the `/v1` code | `/v1` error body |

Adding `path` this way answers the earlier open question about `get --json` symmetry without
breaking "the `/v1` body unchanged": `key` and `data` stay exactly as the server returned them;
`path` is additive.

A query's `key` for a record in a nested collection is the server's full key from the database
root (`openvaultdb-go` ≥ v0.6.2, for example `lists/to-buy/items/x`); the CLI prefers this full
key when computing `path` and still composes one from an older server's shorter key (missing
its parent) plus the collection asked for. A `/v1` `400 invalid_key` (an id whose decoded form
would escape its collection, such as `%2E%2E%2F%2E%2E%2Fsecrets`) maps to human-output
`invalid_argument` with the id-escaping guidance and a `next` to list the collection.

Human output (without `--json`) maps `/v1` errors into the envelope using the table in
[configuration parity](../configuration-parity/README.md).

#### REQ: data-commands-use-server

Data commands MUST call the local server's data API with the instance secret and auto-start
as in [local server](../local-server-and-web-console/README.md); they MUST NOT open storage
in-process.

#### REQ: database-named-in-output

Every data and context command's human output MUST name the database it acted on (for example
`todo: added /lists/to-buy/items/k3f9x2`), including when it came from the "only registered
database" rung.

#### REQ: list-behaviour

At the root `list` MUST list collections; at a collection it MUST list records (id and data,
`--json` as in the table above); at a record it MUST show the record and say
`Listing collections inside a record isn't supported yet`; empty locations print
`Nothing here yet`.

#### REQ: get-set-add-delete

`get` prints a record. `set` with JSON creates or replaces it; `set --field k=v` updates named
fields, parsing `v` as a JSON literal when valid and as a string otherwise. `add` generates a
short URL-safe id (or `--id`) and inserts without overwriting. `delete` removes one record
without prompting and refuses collection paths. `set`, `add` and `delete` MUST print the
affected record's absolute escaped path on stdout: in human output as part of the result line
(for example `todo: added /lists/to-buy/items/k3f9x2`), and with `--json` as exactly one object
`{"key":"<absolute path>"}`, so agents can use the key `add` generated without parsing text or
reading stderr.

A record missing at `get` or `set --field` MUST exit `1` in both human and `--json` modes
(there is no special-cased "nothing here yet" success for a missing record, unlike an empty
collection). `delete` of a missing record MUST fail with `not_found` unless `--if-exists` is
given, in which case it MUST succeed and say there was nothing to delete.

#### REQ: path-kind-mismatch-guidance

A collection path where a record is required, or the reverse, MUST fail with
`invalid_argument` and a `next` command, for example
`/lists/to-buy/items is a collection. To see its records: ovdb list /lists/to-buy/items`.

#### REQ: server-errors-mapped

Server errors MUST be rendered in human output through the `/v1`-to-envelope mapping with a
`next` step; with `--json` the `/v1` error body is printed unchanged.

### Browse data in TUI and web

#### REQ: browse-data-read-only

The TUI and web console MUST offer **Browse data** for any registered database: collections →
records (paged, 50 at a time) → one record as formatted JSON, using the data API. It MUST be
read-only, render values as text, show the equivalent `ovdb list`/`ovdb get` command, and for
nested collections accept a typed collection name under a record. Editing stays with the CLI,
agents and apps (parity exception E5).

#### REQ: select-database-in-tui-and-web

The TUI MUST let the person choose the current database for the project it was started in.
The web console MUST show the global default and let the person change only that; the local
API MUST refuse project-scope writes authenticated only by a session cookie.

## Dependencies

- local-server-and-web-console
- database-setup-and-providers
- configuration-parity

## Acceptance Criteria

### AC: use-is-project-scoped (verifies REQ:use-sets-scoped-context, REQ:context-lookup)

**Given** databases `todo` and `notes`, Git projects `/p/a` and `/p/b`
**When** `ovdb use todo` runs in `/p/a/src`, `ovdb use notes` runs in `/p/b`, and `ovdb pwd` runs in `/p/a`
**Then** the first prints `Now using todo for this project (/p/a)` and `pwd` in `/p/a` reports `todo:/` from project context `/p/a`

### AC: walk-up-outside-git (verifies REQ:context-lookup)

**Given** a non-Git folder `/w/proj` where `ovdb use todo` ran, and a global default `notes`
**When** `ovdb pwd` runs in `/w/proj/src/deep`
**Then** it reports `todo` from project context `/w/proj`

### AC: worktree-is-own-project (verifies REQ:use-sets-scoped-context)

**Given** repository `/r/main` with context `todo` and a linked worktree `/r/wt`
**When** `ovdb pwd` runs in `/r/wt`
**Then** it does not use `/r/main`'s context

### AC: precedence-ladder (verifies REQ:context-lookup)

**Given** project context `todo`, global default `notes`, and `OVDB_DATABASE=notes`
**When** `ovdb pwd`, and `ovdb pwd --db todo` run
**Then** they report `notes` from environment and `todo` from flag

### AC: no-context-error (verifies REQ:context-lookup)

**Given** two registered databases and no context, flag or variable
**When** `ovdb list` runs
**Then** it exits `1` with `not_found`, listing both databases and `ovdb use <database>`

### AC: cd-examples (verifies REQ:path-resolution, REQ:cd-validates-syntax-not-existence)

**Given** context `todo:/lists/to-buy`
**When** each command in the examples table runs from that starting point
**Then** results match the table, and `ovdb cd /lists/new-list/items` prints `Nothing here yet`

### AC: escaped-ids-round-trip (verifies REQ:path-resolution)

**Given** a schemaless database
**When** `ovdb set /files/a%2Fb%2Etxt '{"n":1}'` and `ovdb list /files --json` run
**Then** the server id is `a/b.txt`, the human listing shows `/files/a%2Fb%2Etxt`, and `ovdb get /files/50%off` exits `1` with `invalid_argument`

### AC: data-commands-auto-start (verifies REQ:data-commands-use-server)

**Given** the demo installed and no server
**When** `ovdb list /lists --db todo` runs
**Then** the start notice goes to stderr and the two lists to stdout

### AC: list-kinds (verifies REQ:list-behaviour)

**Given** the demo data
**When** `ovdb list /`, `/lists`, `/lists/to-buy`, `/lists/to-buy/items --json` and `/empty` run with `--db todo`
**Then** they show `lists`, the two lists, the record with the sub-collection note, `{"records":[…]}` with three items, and `Nothing here yet`

### AC: only-database-is-named (verifies REQ:database-named-in-output)

**Given** only the demo database registered and no context
**When** `ovdb delete /lists/to-buy/items/<id>` runs
**Then** the output names `todo` and the absolute path

### AC: add-set-get-delete (verifies REQ:get-set-add-delete)

**Given** the demo
**When** `ovdb add /lists/to-buy/items '{"title":"Tea","done":false}' --db todo` prints P, then `set P --field done=true`, `get P --json`, `delete P` run with `--db todo`
**Then** `add` prints P on stdout, `add --json` prints exactly `{"key":"<P>"}` on stdout, `set --json` and `delete --json` print `{"key":"<P>"}`, `get` prints `{"key":…,"data":{…,"done":true},"path":P}`, and a later `get P` exits `1` in both human and `--json` mode; its human output uses `not_found` and with `--json` prints the `/v1` error body

### AC: delete-missing-needs-if-exists (verifies REQ:get-set-add-delete)

**Given** the demo and a record `P` already deleted
**When** `ovdb delete P --db todo` runs, and separately `ovdb delete P --db todo --if-exists` runs
**Then** the first exits `1` with `not_found`, and the second exits `0` saying there was nothing to delete

### AC: use-refuses-home-and-root (verifies REQ:use-sets-scoped-context)

**Given** the current directory is the user's home directory
**When** `ovdb use todo` runs
**Then** it exits `1` with `invalid_argument` naming the conflict, and `next` offers running inside a project folder or `ovdb use --global todo`

### AC: cd-saves-only-database-context (verifies REQ:cd-validates-syntax-not-existence)

**Given** only the demo database `todo` registered, no context, flag or variable, in project `/p/shop`
**When** `ovdb cd /lists` runs in `/p/shop`, then `ovdb pwd` runs again in `/p/shop`
**Then** the first prints `Saved as the project context for /p/shop.` and `/lists`, and the second reports `todo` from project context `/p/shop` without `--db`

### AC: cd-refuses-flag-and-env-scope (verifies REQ:cd-validates-syntax-not-existence)

**Given** `OVDB_DATABASE=todo` set
**When** `ovdb cd /lists` runs
**Then** it exits `1` with `invalid_argument` and `next` suggests `OVDB_PATH=/lists`

### AC: invalid-key-mapped (verifies REQ:server-errors-mapped)

**Given** a record whose escaped id decodes to a relative path component, such as `%2E%2E%2F%2E%2E%2Fsecrets`
**When** `ovdb get` is called with that id, without and with `--json`
**Then** the human output exits `1` with `invalid_argument` and the id-escaping guidance, and `--json` prints the `/v1` `invalid_key` error body unchanged

### AC: kind-mismatch-hint (verifies REQ:path-kind-mismatch-guidance)

**Given** the demo
**When** `ovdb get /lists/to-buy/items --db todo` runs
**Then** it exits `1` with `invalid_argument` and `next` `ovdb list /lists/to-buy/items`

### AC: strict-mode-error (verifies REQ:server-errors-mapped)

**Given** a SQLite database `shop` without schemas
**When** `ovdb add /orders '{"total":1}' --db shop --json` runs
**Then** it exits `1` printing the `/v1` `schema_validation` error body, and without `--json` it shows `schema_required` with a `next` step to describe the collection's schema

### AC: browse-own-data (verifies REQ:browse-data-read-only)

**Given** database `notes` with a record `/items/x` created by the CLI
**When** the person opens Browse data in the TUI and in the web console
**Then** both show `items`, then `x`, then its JSON with `ovdb get /items/x --db notes`, and offer no edit action; a title containing `<script>` is displayed as text

### AC: tui-and-web-select-database (verifies REQ:select-database-in-tui-and-web)

**Given** databases `todo` and `notes`
**When** `notes` is chosen in the TUI started in `/p/a`, `todo` is chosen in the web console, and a session-cookie request tries a project-scope write
**Then** `ovdb pwd` in `/p/a` reports `notes` (project), elsewhere `todo` (global), and the cookie request is refused

## Open Questions

- Should `list` at a record show sub-collections once the server exposes them (needs an
  `openvaultdb-go` endpoint)?
- Should `--field` support nested field paths?

---
*This document follows the https://specscore.md/feature-specification*
