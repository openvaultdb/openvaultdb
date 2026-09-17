---
format: https://specscore.md/feature-specification
status: Approved
---
# Feature: Database setup and storage choices

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/database-setup-and-providers?op=request-change) |
**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** ovdb-onboarding-and-configuration
**Supersedes:** —

## Summary

Create a new database, connect an existing inGitDB folder or SQLite file, or connect any
engine with a manifest file, from the CLI, TUI or web console, choosing from a catalogue of
storage engines OVDB really supports, with sensible names and locations and plain notes about
each engine's limits.

## Problem

`ovdb init` writes a manifest in the current directory and its help lists only
`sqlite | ingitdb`, although the binary supports Firestore, MySQL and PostgreSQL too.
`ovdb databases create` needs a server started with `--data-dir`. A person must learn the
manifest format and server flags before the first record, and nothing warns that SQLite,
MySQL and PostgreSQL accept writes only to collections with a declared schema.

## Behavior

### Storage catalogue

The catalogue is data in the shared Go package, derived from engines the binary can mount
(`openvaultdb-go/pkg/mount`), and sorted server-side: pinned **inGitDB**, pinned **SQLite**,
then the rest alphabetically. This display order does not change the backend build order in
[storage](../../storage/README.md).

| Id | Name | Description (copy) | Schema modes (verified) | Guided |
|---|---|---|---|---|
| `ingitdb` | inGitDB | Readable files in a folder, with Git history. Recommended to start. | strict, partial, schemaless | create, connect folder or manifest |
| `sqlite` | SQLite | One fast local file. You describe your data (a schema) before storing records. | strict | create, connect file or manifest |
| `firestore` | Firestore | Google Cloud document database. Set up with a manifest. | strict, partial, schemaless | manifest: `ovdb init --engine firestore`, then `ovdb databases connect --manifest` |
| `mysql` | MySQL | A MySQL server you run. Set up with a manifest. | strict | manifest: `ovdb init --engine mysql`, then `ovdb databases connect --manifest` |
| `postgres` | PostgreSQL | A PostgreSQL server you run. Set up with a manifest. | strict | manifest: `ovdb init --engine postgres`, then `ovdb databases connect --manifest` |

inGitDB stored directly in a GitHub repository is mentioned under inGitDB as "advanced, set up
with a manifest".

#### REQ: catalogue-lists-only-supported-engines

The catalogue MUST contain exactly the engines the binary can mount, with id, name,
description, schema modes and guided support. A test MUST fail if the manifest parser
accepts an engine missing from the catalogue or rejects one it lists.

#### REQ: catalogue-order-and-filter

`GET /api/local/v1/engines` and `ovdb engines` MUST return inGitDB, SQLite, then the rest by
name. Interfaces MAY filter the returned list locally by case-insensitive substring over id,
name and description, keeping returned order.

#### REQ: manifest-only-engines-are-honest

Choosing Firestore, MySQL or PostgreSQL in any interface MUST show "Set this up with a manifest
file" with the steps `ovdb init --engine <id>` (then edit the file), plus a documentation link,
and MUST NOT collect connection details. The next step is **Connect with a manifest file**
(`ovdb databases connect --manifest`).

### Create a database

#### REQ: create-new-database

Creating MUST take an id (`^[a-zA-Z0-9][a-zA-Z0-9_-]*$`, unique ignoring case), inGitDB or
SQLite, and an absolute, normalized location. Defaults: inGitDB schemaless at
`<data home>/<id>/`; SQLite at `<data home>/<id>.sqlite`, where data home is `OVDB_DATA_HOME`
or `~/ovdb`. The server MUST write `databases/<id>.yaml`, create the storage and mount it
without restart. The client MUST resolve the data home and send the absolute default location.
Creating an inGitDB database MUST create its `.ingitdb/` directory at create time (empty is
fine; `dalgo2ingitdb` otherwise only writes it lazily on the first record write), so a database
that is removed from OVDB before any write (`REQ:list-and-remove` keeps the data) still
satisfies `REQ:connect-existing-storage`'s "has a `.ingitdb/` directory" check and can be
connected again.

#### REQ: create-never-overwrites

Creation MUST fail without changes with `already_exists` (id comparison case-insensitive) for
a registered id, or `location_not_empty` when the inGitDB folder exists and is not empty or
the SQLite file exists; `next` MUST offer another name, another location, or Connect.

#### REQ: create-refuses-unsafe-locations

Creating MUST fail without changes with `invalid_argument` and a `reason` naming the conflict
when the location is inside `OVDB_HOME`, the runtime directory, or inside or around another
registered database's storage (nested inside it, or itself containing it); `next` MUST offer
another location.

#### REQ: sqlite-next-step-is-schema

Creating a SQLite database MUST declare a placeholder `example` collection in the manifest so
the database mounts cleanly, and end with the next step to edit the manifest to describe the
real schema and run `ovdb databases reload <id>` (command and documentation link), stated
before any write is suggested; the Result MUST NOT suggest adding a record that would fail.

#### REQ: create-result-next-actions

The Result of creating or connecting MUST offer: **Browse data**, **Explore data**, **Connect
an app or AI assistant** (AI agent skills), **Done**, each with its command.

### Connect an existing database

#### REQ: connect-existing-storage

Connecting MUST register an existing readable inGitDB folder or a valid SQLite file given as
an absolute path, validate it by mounting once, and MUST NOT write into the user's storage
(no inferred-schema catalogue and no git configuration there; depends on the
`openvaultdb-go` changes listed in [configuration parity](../configuration-parity/README.md)).
Failures MUST use `storage_unavailable` with a redacted reason, except that a folder with
engine inGitDB that has no `.ingitdb/` directory (for example a code project's own Git
repository, or an empty folder) MUST be refused with `invalid_argument`, pointing at Create or
at choosing the folder that contains `.ingitdb/`, so a first write can never land inside someone's
own project or an unrelated empty folder. Connecting a SQLite file MUST describe, in the
generated manifest, only the tables that have an `id` column; when none qualify the result is
`schema_required` with next steps to edit the manifest or read the docs (matching Create's
SQLite next step). The `id` column is matched ignoring case (`ID` qualifies), as SQLite
column names are. Known limitation, not fixed by this feature
([openvaultdb-go#27](https://github.com/openvaultdb/openvaultdb-go/issues/27)): because
`openvaultdb-go` strict mode does not filter storage at the file level, a connected SQLite file's undeclared tables and columns remain readable to owner
credentials even though the manifest does not describe them — the Result MUST say so. Known
limitation, also not fixed by this feature: connecting an inGitDB folder adds
`.git/dalgo2ingitdb/transaction.lock` (a `dalgo2ingitdb` library artifact created by the mount
itself, before any read or write through OVDB); the working tree, the Git index, `HEAD` and
`.git/config` stay unchanged. Overlap with a location `REQ:create-refuses-unsafe-locations`
would refuse MUST be re-checked once more, still under the registry lock, immediately before a
connect registers; two connects racing the same storage under different ids MUST NOT both
succeed.

#### REQ: connect-with-manifest

**Connect with a manifest file** (CLI `ovdb databases connect --manifest <absolute path>`, TUI
and web with a path field) MUST validate the manifest with the manifest parser, copy it into
`databases/<id>.yaml` (id from the manifest, relative storage paths made absolute against the
manifest's folder), mount it once and keep it only if the mount succeeds. When a variable named
by the manifest (for example `dsn_env`) is missing in the server's environment, it MUST fail
with `storage_unavailable`, a `reason` naming the variable (never a value) and `next`
"Set <NAME> and run `ovdb server restart` from that shell". A manifest with `acl.enabled: true`
and no `acl_store` MUST be refused with `unsupported`, because its policy files are read
relative to the manifest's own folder, which the copy under `databases/` does not have; `next`
MUST suggest keeping policies in an `acl_store` folder instead. Location checks (for example
`create-refuses-unsafe-locations`) MUST read `storage.path`/`acl_store.path` from the decoded,
typed manifest (YAML anchors and merge keys already resolved), not from the raw YAML text, and
the canonical copy written to `databases/<id>.yaml` MUST re-derive its absolute paths the same
way; if the location the checks saw and the location the copy mounts from ever disagree, connect
MUST refuse with `invalid_argument` rather than mount. Under `openvaultdb-go` v0.5.1+, a
manifest's access-control policies (`acl.enabled`) bind the owner too: the instance secret and
a forwarded console-session cookie are subject to those policies exactly like any other
principal, not only scoped tokens (see [local server and web console](../local-server-and-web-console/README.md#REQ:credentials)).

### Manage registrations

#### REQ: list-and-remove

With `OVDB_PREVIEW=1`, `ovdb databases` MUST list registered databases (id, engine, location,
mount state) from state files without a server, taking mount state from the server's
`mounts.json` when it runs and reporting "unknown (server not running)" otherwise; without the
gate, or with an explicit `--url`, it MUST behave as today. `ovdb databases remove <id>` MUST unregister without deleting data, say
where the data remains, and clear any context that pointed to it, saying so.

#### REQ: legacy-create-compatible

`ovdb databases create` MUST keep today's `POST /v1/databases` behaviour without
`OVDB_PREVIEW`; with it, only when `--addr` is given explicitly (an `OVDB_OWNER_TOKEN`
variable alone does not select the legacy path).

#### REQ: reload-database

`ovdb databases reload <id>` MUST unmount and remount that one registered database from its
current manifest on disk, so edits made directly to a manifest (schema changes, a
manifest-only engine dropped into `databases/`) take effect without a server restart;
`ovdb databases reload --all` MUST do the same for every registered database. Both MUST
report per-database success or "needs attention" with a redacted reason, the same as startup
mounting, and MUST NOT change a database's registration or delete its storage. TUI and web
Databases screens MUST offer a **Reload** action per database and for all.

### Commands

| Action | CLI |
|---|---|
| Storage choices | `ovdb engines [--json]` |
| Create | `ovdb databases create <id> [--engine <ingitdb or sqlite>] [--path <absolute>] [--json]` |
| Connect a folder or file | `ovdb databases connect <id> --engine <ingitdb or sqlite> --path <absolute> [--json]` |
| Connect with a manifest file | `ovdb databases connect --manifest <absolute path> [--json]` |
| List | `ovdb databases [--json]` |
| Remove | `ovdb databases remove <id> [--yes]` |
| Reload | `ovdb databases reload <id>\|--all [--json]` |
| Write a manifest | `ovdb init --engine <engine>` (help lists all five engines) |

### Example copy

```
Create a database

Where should OVDB keep your data?
Filter: _

> inGitDB      Readable files in a folder, with Git history. Recommended to start.
  SQLite       One fast local file. You describe your data (a schema) before storing records.
  ─────────────
  Firestore    Google Cloud document database. Set up with a manifest.
  MySQL        A MySQL server you run. Set up with a manifest.
  PostgreSQL   A PostgreSQL server you run. Set up with a manifest.
```

```
Created database notes

Stored in ~/ovdb/notes/ as readable files with Git history.

What next?
  Browse data                          ovdb list / --db notes
  Explore data                         ovdb explore --db notes
  Connect an app or AI assistant       ovdb skills install openvaultdb
  Done
```

## Dependencies

- local-server-and-web-console
- first-run-onboarding
- database-context-navigation
- configuration-parity

## Acceptance Criteria

### AC: catalogue-matches-binary (verifies REQ:catalogue-lists-only-supported-engines)

**Given** the manifest parser in the linked `openvaultdb-go`
**When** the catalogue test runs
**Then** it passes only if the catalogue has exactly `firestore`, `ingitdb`, `mysql`, `postgres`, `sqlite` with the schema modes each mount returns

### AC: pinned-then-alphabetical (verifies REQ:catalogue-order-and-filter)

**Given** `ovdb engines --json` and the TUI and web pickers
**When** shown unfiltered and filtered by `sql`
**Then** the order is inGitDB, SQLite, Firestore, MySQL, PostgreSQL, and `sql` shows SQLite, MySQL, PostgreSQL in that order

### AC: postgres-is-manifest-only (verifies REQ:manifest-only-engines-are-honest)

**Given** the Create flow in TUI and web
**When** the person picks PostgreSQL
**Then** both show "Set this up with a manifest file" with `ovdb init --engine postgres`, a docs link, no field for connection details, and the next step **Connect with a manifest file** (`ovdb databases connect --manifest`)

### AC: create-ingitdb-default (verifies REQ:create-new-database)

**Given** temporary `OVDB_HOME` and `OVDB_DATA_HOME`
**When** the person creates `notes` with defaults in the TUI
**Then** `<data home>/notes/` exists, the manifest declares `ingitdb` schemaless, and `ovdb add /items '{"title":"Hello"}' --db notes` succeeds without a restart

### AC: create-then-reconnect-without-writes (verifies REQ:create-new-database, REQ:connect-existing-storage)

**Given** a freshly created inGitDB database with no record ever written to it
**When** `ovdb databases remove <id> --yes` runs, then `ovdb databases connect <id> --engine ingitdb --path <same location>` runs
**Then** the folder already has `.ingitdb/` from create, and connect succeeds instead of refusing it as a plain Git repository

### AC: create-refuses-overwrite (verifies REQ:create-never-overwrites)

**Given** `<data home>/notes/` contains files, and separately a database `Notes` already registered
**When** the person creates `notes` in the web console, and `ovdb databases create notes` runs
**Then** the first writes nothing and the problem has `location_not_empty` with next actions for another name, another location and Connect; the second fails with `already_exists` because `notes` and `Notes` collide ignoring case

### AC: create-refuses-unsafe-location (verifies REQ:create-refuses-unsafe-locations)

**Given** a registered database `notes` at `<data home>/notes/`
**When** the person creates a database at `<OVDB_HOME>/x`, and separately at `<data home>/notes/sub`
**Then** both fail without changes with `invalid_argument`, the reason names the OVDB home or the other database's storage, and `next` offers another location

### AC: sqlite-points-to-schema (verifies REQ:sqlite-next-step-is-schema)

**Given** a fresh setup
**When** `ovdb databases create shop --engine sqlite --json` runs
**Then** the manifest declares a placeholder `example` collection, `next` starts with editing the manifest and running `ovdb databases reload shop`, and contains no add-record command

### AC: result-next-actions (verifies REQ:create-result-next-actions)

**Given** a database created in the TUI and one connected in the web console
**When** each Result shows
**Then** both list Browse data, Explore data, Connect an app or AI assistant, Done, with commands

### AC: connect-leaves-folder-untouched (verifies REQ:connect-existing-storage)

**Given** an existing inGitDB Git repository with records and only a global git identity, and a text file named `x.sqlite`
**When** each is connected
**Then** the folder registers with the working tree, index, `HEAD` and `.git/config` unchanged (only `.git/dalgo2ingitdb/transaction.lock` may appear), and the text file is rejected with `storage_unavailable`

### AC: connect-refuses-non-ingitdb-folder (verifies REQ:connect-existing-storage)

**Given** a Git repository with source files and no `.ingitdb/` folder, and separately an empty folder
**When** each is connected with `--engine ingitdb`
**Then** both fail with `invalid_argument` pointing at Create or the `.ingitdb` folder, and neither folder gains any file

### AC: connect-sqlite-describes-id-tables-only (verifies REQ:connect-existing-storage)

**Given** a SQLite file with a table `users(id, email)` and a table `noid(k, v)` with no `id` column, and separately a file with only tables lacking an `id` column
**When** each is connected
**Then** the first's manifest declares `users` and the Result states the whole file remains readable to owner credentials; the second fails with `schema_required` and next steps to edit the manifest or read the docs

### AC: connect-postgres-manifest (verifies REQ:connect-with-manifest, REQ:manifest-only-engines-are-honest)

**Given** `crm.yaml` written by `ovdb init --engine postgres` with `dsn_env: CRM_DSN`, and a server started without `CRM_DSN`
**When** `ovdb databases connect --manifest /abs/crm.yaml --json` runs, then the server is restarted from a shell with `CRM_DSN` set and the command runs again
**Then** the first fails with `storage_unavailable` naming `CRM_DSN` and no registry entry; the second registers `crm` and `GET /v1/databases/crm` works

### AC: remove-keeps-data (verifies REQ:list-and-remove)

**Given** `OVDB_PREVIEW=1`, `notes` registered and set as the project context, and no server running
**When** `ovdb databases` and then `ovdb databases remove notes --yes` run
**Then** the list works without starting a server, removal leaves the data folder intact and names it, and reports the cleared context

### AC: legacy-create-still-works (verifies REQ:legacy-create-compatible)

**Given** `OVDB_PREVIEW=1`, `OVDB_OWNER_TOKEN=T` and `ovdb serve --data-dir ./data` on port 7000
**When** `ovdb databases create crm --addr http://127.0.0.1:7000` runs, and `ovdb databases create notes` runs
**Then** the first calls `POST /v1/databases` as today and writes nothing to the registry; the second uses the local server

### AC: reload-remounts-database (verifies REQ:reload-database)

**Given** registered databases `crm` (a manifest edited by hand after creation) and `notes`, with `crm`'s edit making its schema invalid
**When** `ovdb databases reload crm --json` runs, and then `ovdb databases reload --all --json` runs
**Then** the first remounts `crm` and reports it "needs attention" with a redacted reason without touching `notes`'s registration or data, and the second reports both databases' states without a server restart

## Open Questions

- Should SQLite gain schemaless support in `openvaultdb-go` so it is friendly without a schema?
- When should guided connect (without a manifest) for Firestore, MySQL and PostgreSQL be
  designed, given connection details live in the server's environment?
- Should the inGitDB "with Git history" copy depend on `git` being installed?

---
*This document follows the https://specscore.md/feature-specification*
