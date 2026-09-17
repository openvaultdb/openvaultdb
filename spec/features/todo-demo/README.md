---
format: https://specscore.md/feature-specification
status: Amending
---
# Feature: TODO demo

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/todo-demo?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/todo-demo?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/todo-demo?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/todo-demo?op=request-change) |
**Status:** Amending
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
**Supersedes:** —

## Summary

A built-in demo with two lists, **To buy** and **To watch**, stored as readable files on
the person's computer, a small web app to use them, and an optional AI skill so an agent
can change the same lists. It shows in about a minute what OpenVaultDB is for: apps and
agents sharing data the person owns.

Decision: [0010 built-in TODO demo](../../decisions/0010-built-in-todo-demo.md).

## Problem

The existing demos need a clone and three processes (`openvaultdb-todo-demo`) or a cloud
account, a Sneat Space and a tunnel (Listus). A newcomer cannot see OpenVaultDB work
without first understanding servers, manifests and tokens.

## Behavior

### Data

Database id `todo`, engine inGitDB, schema mode schemaless, location
`<data home>/demos/todo/` (data home is `OVDB_DATA_HOME`, default `~/ovdb`).

| Path | Data |
|---|---|
| `/lists/to-buy` | `{"title": "To buy"}` |
| `/lists/to-buy/items/{id}` | `{"title": "Milk", "done": false, "added_at": "<RFC 3339>"}`, also Bananas, Coffee |
| `/lists/to-watch` | `{"title": "To watch"}` |
| `/lists/to-watch/items/{id}` | `{"title": "The Matrix", "done": false, "added_at": "…"}`, also Interstellar |

#### REQ: seed-from-shared-package

The seed records (list and item ids, list and item titles, `done`, and the `added_at` rule:
one second apart, the last at install time) and the list paths MUST come from the Go package
`github.com/ingitdb/ingitdb-go/ingitdb/demos/todo`, which imports only the standard library;
`ovdb` MUST NOT restate them. The titles are English demo data owned by that package, not
user-interface copy: [configuration parity's copy
catalogue](../configuration-parity/README.md#REQ:copy-catalogue) covers UI strings, not seed records, so `copy/en.json` has no `demo.seed.*` keys
and the seed titles are not localised. The inGitDB CLI uses the same package for
`ingitdb demo install`
([ingitdb-cli `cli/demo`](https://github.com/ingitdb/ingitdb-cli/blob/main/spec/features/cli/demo/README.md)),
so both CLIs create the same lists. `ovdb` keeps registering its demo as schemaless and
writing through the data API; the seeded records are unchanged.

#### REQ: ingitdb-cli-demo-folders

A folder created by `ingitdb demo install` is an ordinary inGitDB database to OVDB. It MUST
NOT be treated or adopted as the TODO demo, because the demo is only the database recorded in
`<OVDB_HOME>/demos.json`: connecting it with `ovdb databases connect <id> --engine ingitdb
--path <absolute folder>` registers a normal database whose lists the data commands can read,
without changing its working tree, index or `HEAD`, and a demo install whose location is that
folder is refused as a folder with other files, as for any non-empty folder. People who want
OVDB and the inGitDB CLI on one folder use `ovdb databases connect`; `ingitdb demo install`
points people to `ovdb demo install` and `ovdb demo open`, which create OVDB's own copy.
Revisit adoption only if users ask for it.

#### Known limitations of the demo folder

Not fixed by this feature, tracked separately:

- `ingitdb validate` fails on OVDB's demo folder (and every schemaless OVDB inGitDB database),
  because inferred definitions declare the advisory `id` column non-nullable, written as
  `required: true`:
  [openvaultdb-go#25](https://github.com/openvaultdb/openvaultdb-go/issues/25).
- After `ovdb demo install`, `git status` in the folder is not clean: driver commits use a
  temporary index, never update `.git/index`, and do not include definition files:
  [dalgo2ingitdb#12](https://github.com/ingitdb/dalgo2ingitdb/issues/12).

#### REQ: demo-install-idempotent

`ovdb demo install` MUST register database `todo` at `<data home>/demos/todo/`, record the
install (id and location) in `<OVDB_HOME>/demos.json`, and write the seed data. A database
counts as the TODO demo only because a `demo install` recorded it there, never because it
happens to sit in a folder named `demos/<id>`: a user's own database at such a path (for
example `work/demos/notes`) is left alone and installing the demo still installs it. Install
requests MUST be serialized (the server holds one install at a time), so a request that
arrives while another is seeding waits for it and reports its real outcome, never
`already installed` before the seed data exists. Running it again MUST NOT change existing
data and MUST report `The TODO demo is already installed`. If `todo` is registered with a
different location or engine, install MUST fail without changes and offer `--id <other>`; if
the target location is a folder a person removed with `ovdb databases remove` (data kept),
install MUST reconnect and serve it instead of refusing it as non-empty; any other non-empty
folder still fails without changes. In non-interactive use it MUST require `--yes`;
interactively it MUST show where data will be stored before writing.

#### REQ: demo-command-shape

Demo commands MUST be `ovdb demo install [--yes] [--id <id>]`, `ovdb demo open
[--print-url]` and `ovdb demo status [--json]`, defaulting to the TODO demo, so that an
`--app <name>` option (for example Sneat's `listus`) can be added without breaking them.

### TODO web app

#### REQ: todo-app-same-origin

`ovdb demo open` MUST start the server if needed and open a one-time login link that lands
on `http://ovdb.localhost:<port>/apps/todo/`. The app MUST call the data API on the same
origin using the console session (no separate token, CORS or connect flow), MUST find the
demo database id from `GET /api/local/v1/demo`, and MUST show a clear message with the fix if
the demo is not installed.

#### REQ: todo-app-behaviour

The app MUST show both lists with their items, let the person add an item, mark it done
or not done, and delete it, and MUST reflect changes made by other clients (CLI, agents)
within 3 seconds while visible and immediately when the tab regains focus. It MUST render
item text as text only (never as HTML). It MUST show
a short line "Stored in <data home>/demos/todo on this computer" (the actual path) and a link back to the web
console. It MUST show the session-ended and stopped-server copy from
[local server and web console](../local-server-and-web-console/README.md) when its requests
fail. It MUST meet the web accessibility basics from
[first-run onboarding](../first-run-onboarding/README.md).

### After installing

#### REQ: demo-next-actions

The Result after installing MUST offer, in order: **Open TODO app**, **Install TODO AI
skill**, **Explore data**, **Done**, each with its command. Installing the skill MUST go
through the explicit consent step in [AI agent skills](../ai-agent-skills/README.md);
**Explore data** MUST open the explore menu with the demo database selected and say that
DataTug shows the two lists but not their items yet.

Example copy:

```
The TODO demo is ready

Two lists, To buy and To watch, are stored as files in ~/ovdb/demos/todo.
Your apps and AI agents can use them through the OVDB server.

What next?
> Open TODO app               ovdb demo open
  Install TODO AI skill       ovdb skills install todo-demo
  Explore data                ovdb explore --db todo
  Done
```

### Seeing one database from every client

#### REQ: cross-client-visibility

A change made through any of the TODO app, `ovdb` data commands and the TODO skill MUST
be visible to the others without restart, because all of them go through the one local
server.

## Dependencies

- local-server-and-web-console
- database-context-navigation
- ai-agent-skills
- explore-data-handoff

## Acceptance Criteria

### AC: fresh-install-creates-data (verifies REQ:demo-install-idempotent)

**Given** an empty OVDB home
**When** `ovdb demo install --yes` runs
**Then** `ovdb databases` lists `todo` at `<data home>/demos/todo/`, and `ovdb list /lists/to-buy/items --db todo --json` returns Milk, Bananas and Coffee, all not done

### AC: reinstall-keeps-changes (verifies REQ:demo-install-idempotent)

**Given** the demo installed and an item "Tea" added
**When** `ovdb demo install --yes` runs again
**Then** it reports `The TODO demo is already installed`, exits `0`, and "Tea" is still there

### AC: conflicting-todo-refused (verifies REQ:demo-install-idempotent)

**Given** a user database named `todo` at `~/ovdb/todo/`
**When** `ovdb demo install --yes` runs
**Then** it exits `1` with no changes and suggests `ovdb demo install --id todo-demo`

### AC: user-database-in-demos-folder-not-adopted (verifies REQ:demo-install-idempotent)

**Given** a user database registered at `<data home>/demos/notes/` (not installed by `demo install`)
**When** `ovdb demo status` and `ovdb demo install --yes` run
**Then** status reports the TODO demo as not installed, and install proceeds to install `todo` at `<data home>/demos/todo/` without touching `notes`

### AC: concurrent-install-is-safe (verifies REQ:demo-install-idempotent)

**Given** an empty OVDB home
**When** several `POST /api/local/v1/demo/install` requests race
**Then** exactly one seeds the data and every response, winner or loser, is only sent after the seed completes, so none reports success against empty lists

### AC: reinstall-reconnects-removed-folder (verifies REQ:demo-install-idempotent)

**Given** the demo installed, then removed with `ovdb databases remove todo --yes` (data kept)
**When** `ovdb demo install --yes` runs again
**Then** it reconnects the same folder and serves its existing data, rather than failing with `location_not_empty`

### AC: non-interactive-needs-yes (verifies REQ:demo-install-idempotent, REQ:demo-command-shape)

**Given** a non-interactive environment
**When** `ovdb demo install` runs without `--yes`
**Then** it exits `1` with `confirmation_required` naming `--yes` and writes nothing

### AC: seed-from-shared-package (verifies REQ:seed-from-shared-package)

**Given** the `ovdb` build after the switch to the shared package
**When** the demo is installed with a fixed clock
**Then** the batch of seeded records sent to the data API is byte-identical to the golden batch captured before the switch, the existing demo tests pass unmodified, and `copy/en.json` has no `demo.seed.*` key

### AC: ingitdb-demo-folder-not-adopted (verifies REQ:ingitdb-cli-demo-folders)

**Given** an empty OVDB home and a folder created by `ingitdb demo install`
**When** `ovdb databases connect ingitdb-todo --engine ingitdb --path <absolute folder>` runs
**Then** `ovdb list /lists/to-buy/items --db ingitdb-todo --json` returns Milk, Bananas and Coffee, `git status --porcelain` in the folder is empty and `HEAD` is unchanged, and `ovdb demo status` reports the TODO demo as not installed

### AC: open-starts-server-and-app (verifies REQ:todo-app-same-origin)

**Given** the demo installed and no server running
**When** `ovdb demo open --print-url` runs and a browser loads the printed link
**Then** the server starts, the browser lands on `http://ovdb.localhost:6832/apps/todo/` with a session, and the app shows both lists without asking for anything

### AC: app-edits-items (verifies REQ:todo-app-behaviour)

**Given** the TODO app open
**When** the person adds "Tea" to To buy, ticks Milk, and deletes Coffee using only the keyboard
**Then** `ovdb list /lists/to-buy/items --db todo --json` shows Tea not done, Milk done, and no Coffee

### AC: agent-change-appears-in-app (verifies REQ:todo-app-behaviour, REQ:cross-client-visibility)

**Given** the TODO app visible in a browser
**When** `ovdb add /lists/to-watch/items '{"title":"Arrival","done":false}' --db todo` runs in a terminal
**Then** Arrival appears in To watch within 3 seconds without reloading the page

### AC: item-text-is-not-html (verifies REQ:todo-app-behaviour)

**Given** the TODO app open
**When** `ovdb add /lists/to-buy/items '{"title":"<img src=x onerror=alert(1)>","done":false}' --db todo` runs
**Then** the item shows that literal text and no script runs

### AC: next-actions-after-install (verifies REQ:demo-next-actions)

**Given** the TUI and the web console
**When** the person chooses Try a demo and it completes
**Then** both show "The TODO demo is ready" with Open TODO app, Install TODO AI skill, Explore data, Done in that order, each with its command, and choosing Install TODO AI skill shows the skill consent step before any file is written

## Open Questions

- Should the TODO app also demonstrate sharing a list with another app through the connect
  flow, or leave that to `openvaultdb-todo-demo`? Recommendation: leave it out of MVP.
- Should `ovdb demo reset` restore the seed data?

---
*This document follows the https://specscore.md/feature-specification*
