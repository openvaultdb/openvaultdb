---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Database setup and storage choices

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

Create a new database or connect existing storage from the CLI, TUI or web console, by
choosing where to store data from a catalogue that lists only storage engines OVDB really
supports, with sensible names and locations and an honest note about each engine's
limits.

## Problem

`ovdb init` writes a manifest in the current directory and its help lists only
`sqlite | ingitdb`, although the binary also supports Firestore, MySQL and PostgreSQL.
`ovdb databases create` only works against a server started with `--data-dir` and always
creates inGitDB. A person has to learn the manifest format, choose a schema mode and
start a server with the right flags before the first record. Nothing warns that SQLite,
MySQL and PostgreSQL mounts accept writes only to collections with a declared schema.

## Behavior

### Storage catalogue

The catalogue is data in the shared services, derived from engines compiled into the
binary (`openvaultdb-go/pkg/mount`). Listing order is: pinned **inGitDB**, pinned
**SQLite**, then the rest alphabetically by display name. This is a *display* order and
does not change the backend build order in [storage](../../storage/README.md).

| Id | Display name | One-line description (copy) | Needs | Schema modes (verified) | New | Existing |
|---|---|---|---|---|---|---|
| `ingitdb` | inGitDB | Readable files in a folder, with Git history. Recommended. | folder | strict, partial, schemaless | yes | folder |
| `sqlite` | SQLite | One fast local file. Collections need a schema before you add records. | file | strict | yes | file |
| `firestore` | Firestore | Google Cloud document database you already use. | project id, optional database id; Google credentials in the environment | strict, partial, schemaless | — | project |
| `mysql` | MySQL | A MySQL server you already run. Collections need a schema. | name of an environment variable holding the connection string | strict | — | server |
| `postgres` | PostgreSQL | A PostgreSQL server you already run. Collections need a schema. | name of an environment variable holding the connection string | strict | — | server |

inGitDB stored directly in a GitHub repository (`storage.ingitdb.github`) supports only
strict and partial modes and needs a token. It is shown under inGitDB as "Store in a
GitHub repository (advanced)" with a link to the manifest documentation, not as a guided
flow in MVP.

#### REQ: catalogue-lists-only-supported-engines

The catalogue MUST contain exactly the engines the running binary can mount, with id,
display name, description, needs, supported schema modes, and whether it supports
creating new storage. A test MUST fail if an engine accepted by the manifest parser is
missing from the catalogue or the catalogue lists one the parser rejects. Unsupported
engines (for example SQL Server) MUST NOT appear.

#### REQ: catalogue-order-and-filter

All interfaces MUST list inGitDB first and SQLite second, then the remaining engines
sorted alphabetically by display name, and MUST offer a case-insensitive filter over id,
display name and description. Filtering MUST keep the pinned engines pinned when they
match.

#### REQ: engine-limits-are-stated

Wherever an engine is offered or a database using it is created or connected, a
strict-only engine MUST carry the note "Collections need a schema before you add
records", and the Result screen MUST explain where schemas are declared.

### Create a database

#### REQ: create-new-database

Creating a database MUST take: an id (pattern `^[a-zA-Z0-9][a-zA-Z0-9_-]*$`, unique in
the registry), an engine that supports new storage, and a location. Defaults: inGitDB
schemaless at `~/ovdb/<id>/`; SQLite strict at `~/ovdb/<id>.sqlite`. The service MUST
write `databases/<id>.yaml`, create the storage (inGitDB folder initialised as the
existing runtime creation does; SQLite file), and mount it on the running server if any.

#### REQ: create-never-overwrites

Creation MUST fail without changing anything when the id is already registered, when the
target inGitDB folder exists and is not empty, or when the target SQLite file exists. The
hint MUST offer a different id, `--path`, or "Connect an existing database".

#### REQ: remote-engines-route-to-connect

Choosing Firestore, MySQL or PostgreSQL in the Create flow MUST explain "OVDB uses a
database server you already run" and continue in the Connect flow with that engine
selected; the CLI `databases create --engine postgres` MUST fail with the hint
`ovdb databases connect <id> --engine postgres --dsn-env <NAME>`.

### Connect an existing database

#### REQ: connect-existing-storage

Connecting MUST register existing storage without moving or modifying data: an inGitDB
folder that exists and is readable; a file that is a valid SQLite database; a Firestore
project id; or for MySQL/PostgreSQL the *name* of an environment variable that holds the
connection string. The service MUST validate by mounting it once and MUST report the
mount error with the problem pattern if it fails. Connection strings MUST NOT be written
to OVDB files, logs or telemetry.

#### REQ: env-var-visible-to-server

For engines that read environment variables, the Result MUST state that the variable must
be set in the environment of the OVDB server process, and `ovdb status` MUST flag a
database whose variable is missing in the server's environment.

### Manage registrations

#### REQ: list-and-remove

`ovdb databases` MUST list registered databases (id, engine, location, mount state)
without needing a running server; `--url` MUST keep today's behaviour of calling
`GET /v1/databases`. `ovdb databases remove <id>` MUST unregister a database and
MUST NOT delete its data; it MUST say where the data remains. Removing a database that is
the current context MUST clear that context and say so.

### Commands

| Action | CLI |
|---|---|
| List storage choices | `ovdb engines [--filter <text>] [--json]` |
| Create | `ovdb databases create <id> [--engine <ingitdb or sqlite>] [--path <p>] [--json]` |
| Create on a server started with `--data-dir` (existing) | `ovdb databases create <id> --addr <url> [--token …]` (unchanged when `--addr`, `--token` or `--owner-token` is given explicitly) |
| Connect a folder or file | `ovdb databases connect <id> --engine <ingitdb or sqlite> --path <p> [--schema-mode <m>]` |
| Connect Firestore | `ovdb databases connect <id> --engine firestore --project <id> [--firestore-database <id>]` |
| Connect MySQL or PostgreSQL | `ovdb databases connect <id> --engine <mysql or postgres> --dsn-env <NAME>` |
| List | `ovdb databases [--json]` |
| Remove | `ovdb databases remove <id> [--yes]` |

`ovdb init` remains as the low-level manifest writer; its help MUST list all five
engines.

#### REQ: legacy-remote-create-compatible

`ovdb databases create` MUST keep today's HTTP behaviour (`POST /v1/databases` against
`--addr`) whenever `--addr`, `--token` or `--owner-token` is given explicitly. Without
them it MUST use the local registry flow. This changes the default of a command whose
`--addr` previously defaulted to the local server, so release notes MUST call it out.

### Example copy

Where to store your data (TUI; web shows the same as selectable cards with a search box):

```
Create a database

Where should OVDB keep your data?
Filter: _

> inGitDB      Readable files in a folder, with Git history. Recommended.
  SQLite       One fast local file. Collections need a schema before you add records.
  ─────────────
  Firestore    Google Cloud document database you already use.
  MySQL        A MySQL server you already run. Collections need a schema.
  PostgreSQL   A PostgreSQL server you already run. Collections need a schema.
```

Name and location:

```
Create a database · inGitDB

Name        notes
Location    ~/ovdb/notes/

Names can use letters, numbers, - and _.

[ Create database ]   Back
```

Result:

```
Created database notes

Stored in ~/ovdb/notes/ as readable files with Git history.

What next?
  Use it in this project      ovdb use notes
  Add your first record       ovdb add /items '{"title":"Hello"}' --db notes
  Explore data                ovdb explore
  Open the web console        ovdb open
```

## Dependencies

- local-server-and-web-console
- first-run-onboarding
- database-context-navigation

## Acceptance Criteria

### AC: catalogue-matches-binary (verifies REQ:catalogue-lists-only-supported-engines)

**Given** the engine list accepted by the manifest parser in the linked `openvaultdb-go` version
**When** the catalogue test runs
**Then** it passes only if the catalogue contains exactly `firestore`, `ingitdb`, `mysql`, `postgres`, `sqlite` with the schema modes each mount returns

### AC: pinned-then-alphabetical (verifies REQ:catalogue-order-and-filter)

**Given** the CLI, TUI and web console
**When** the catalogue is shown unfiltered, then filtered by `sql`, then by `google`
**Then** the order is inGitDB, SQLite, Firestore, MySQL, PostgreSQL; `sql` shows SQLite, MySQL, PostgreSQL with SQLite first; `google` shows Firestore

### AC: create-ingitdb-default (verifies REQ:create-new-database)

**Given** an empty OVDB home and a running server
**When** the person creates `notes` with defaults in the TUI
**Then** `~/ovdb/notes/` exists, `databases/notes.yaml` declares engine `ingitdb` and mode `schemaless`, and `ovdb add /items '{"title":"Hello"}' --db notes` succeeds without restarting the server

### AC: create-sqlite-states-schema-need (verifies REQ:create-new-database, REQ:engine-limits-are-stated)

**Given** an empty OVDB home
**When** `ovdb databases create shop --engine sqlite` runs and then `ovdb add /orders '{"total":1}' --db shop`
**Then** the create result mentions that collections need a schema and where to declare it, and the add fails with the problem pattern explaining strict mode instead of a raw validation error

### AC: create-refuses-overwrite (verifies REQ:create-never-overwrites)

**Given** `~/ovdb/notes/` contains files
**When** the person creates `notes` in the web console
**Then** nothing is written, and the problem offers another name, a different location and "Connect an existing database"

### AC: postgres-create-routes-to-connect (verifies REQ:remote-engines-route-to-connect)

**Given** the Create flow
**When** the person picks PostgreSQL in the TUI, and runs `ovdb databases create crm --engine postgres`
**Then** the TUI continues in Connect with PostgreSQL selected, and the CLI exits `1` with the `databases connect` hint

### AC: connect-validates-and-keeps-data (verifies REQ:connect-existing-storage)

**Given** an existing inGitDB folder with records, a text file named `x.sqlite`, and a PostgreSQL connection string in `CRM_DSN`
**When** each is connected
**Then** the folder registers with no file modified, the text file is rejected as not a SQLite database, and the PostgreSQL manifest contains `dsn_env: CRM_DSN` but not the connection string, which also appears in no log

### AC: missing-env-var-flagged (verifies REQ:env-var-visible-to-server)

**Given** a connected PostgreSQL database with `dsn_env: CRM_DSN` and a background server started without `CRM_DSN`
**When** `ovdb status` runs
**Then** it lists the database as not mounted with "CRM_DSN is not set for the OVDB server" and the restart hint

### AC: legacy-create-still-works (verifies REQ:legacy-remote-create-compatible)

**Given** a server started with `ovdb serve --data-dir ./data --owner-token T` on port 7000
**When** `ovdb databases create crm --addr http://127.0.0.1:7000 --owner-token T` runs
**Then** it calls `POST /v1/databases` as today, creates `./data/crm/`, and writes nothing to the OVDB home registry

### AC: remove-keeps-data (verifies REQ:list-and-remove)

**Given** `notes` registered and set as the project context, and no server running
**When** `ovdb databases` and then `ovdb databases remove notes --yes` run
**Then** the list shows notes without contacting a server, removal leaves `~/ovdb/notes/` intact, says where it is, and reports that the project context was cleared

## Open Questions

- Should OVDB offer to declare a first collection schema for SQLite during creation, or
  should SQLite gain schemaless support in `openvaultdb-go` (JSON column) so it is
  friendly without schemas? Recommendation: keep inGitDB as the recommended default and
  file the SQLite schemaless work in `openvaultdb-go`.
- Should a guided "Store in a GitHub repository" flow reuse `ovdb cloud login` or a
  personal token?
- Should `databases remove --delete-data` exist, given the risk?

---
*This document follows the https://specscore.md/feature-specification*
