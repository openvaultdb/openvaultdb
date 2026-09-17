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

Create a new database or connect an existing inGitDB folder or SQLite file from the CLI, TUI
or web console, choosing from a catalogue of storage engines OVDB really supports, with
sensible names and locations and plain notes about each engine's limits. Engines that need a
database server are listed honestly with how to set them up.

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
| `ingitdb` | inGitDB | Readable files in a folder, with Git history. Recommended to start. | strict, partial, schemaless | create, connect folder |
| `sqlite` | SQLite | One fast local file. You describe your data (a schema) before storing records. | strict | create, connect file |
| `firestore` | Firestore | Google Cloud document database. Set up with a manifest. | strict, partial, schemaless | no: `ovdb init --engine firestore` + docs |
| `mysql` | MySQL | A MySQL server you run. Set up with a manifest. | strict | no: `ovdb init --engine mysql` + docs |
| `postgres` | PostgreSQL | A PostgreSQL server you run. Set up with a manifest. | strict | no: `ovdb init --engine postgres` + docs |

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

Choosing Firestore, MySQL or PostgreSQL in any interface MUST show "OVDB can use this, but
setting it up here isn't available yet" with the `ovdb init --engine <id>` command and a
documentation link, and MUST NOT collect connection details.

### Create a database

#### REQ: create-new-database

Creating MUST take an id (`^[a-zA-Z0-9][a-zA-Z0-9_-]*$`, unique), inGitDB or SQLite, and an
absolute, normalized location. Defaults: inGitDB schemaless at `<data home>/<id>/`; SQLite at
`<data home>/<id>.sqlite`, where data home is `OVDB_DATA_HOME` or `~/ovdb`. The server MUST
write `databases/<id>.yaml`, create the storage and mount it without restart.

#### REQ: create-never-overwrites

Creation MUST fail without changes with `already_exists` for a registered id, or
`location_not_empty` when the inGitDB folder exists and is not empty or the SQLite file
exists; `next` MUST offer another name, another location, or Connect.

#### REQ: sqlite-next-step-is-schema

Creating a SQLite database MUST end with the next step to describe a first collection's
schema (command and documentation link), stated before any write is suggested; the Result
MUST NOT suggest adding a record that would fail.

#### REQ: create-result-next-actions

The Result of creating or connecting MUST offer: **Browse data**, **Explore data**, **Connect
an app or AI assistant** (AI agent skills), **Done**, each with its command.

### Connect an existing database

#### REQ: connect-existing-storage

Connecting MUST register an existing readable inGitDB folder or a valid SQLite file given as
an absolute path, validate it by mounting once, and MUST NOT write into the user's storage
(no inferred-schema catalogue and no git configuration there; depends on the
`openvaultdb-go` changes listed in [configuration parity](../configuration-parity/README.md)).
Failures MUST use `storage_unavailable` with a redacted reason.

### Manage registrations

#### REQ: list-and-remove

With `OVDB_PREVIEW=1`, `ovdb databases` MUST list registered databases (id, engine, location,
needs attention) from state files without a server; without the gate, or with `--url`, it
MUST behave as today. `ovdb databases remove <id>` MUST unregister without deleting data, say
where the data remains, and clear any context that pointed to it, saying so.

#### REQ: legacy-create-compatible

`ovdb databases create` MUST keep today's `POST /v1/databases` behaviour without
`OVDB_PREVIEW`, and with it whenever `--addr`, `--token`, `--owner-token` or
`OVDB_OWNER_TOKEN` is present.

### Commands

| Action | CLI |
|---|---|
| Storage choices | `ovdb engines [--json]` |
| Create | `ovdb databases create <id> [--engine <ingitdb or sqlite>] [--path <absolute>] [--json]` |
| Connect | `ovdb databases connect <id> --engine <ingitdb or sqlite> --path <absolute> [--json]` |
| List | `ovdb databases [--json]` |
| Remove | `ovdb databases remove <id> [--yes]` |
| Manifest for other engines | `ovdb init --engine <firestore, mysql or postgres>` (help lists all five engines) |

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
**Then** both show the "isn't available yet" copy with `ovdb init --engine postgres` and a docs link, and no field for connection details

### AC: create-ingitdb-default (verifies REQ:create-new-database)

**Given** temporary `OVDB_HOME` and `OVDB_DATA_HOME`
**When** the person creates `notes` with defaults in the TUI
**Then** `<data home>/notes/` exists, the manifest declares `ingitdb` schemaless, and `ovdb add /items '{"title":"Hello"}' --db notes` succeeds without a restart

### AC: create-refuses-overwrite (verifies REQ:create-never-overwrites)

**Given** `<data home>/notes/` contains files
**When** the person creates `notes` in the web console
**Then** nothing is written and the problem has `location_not_empty` with next actions for another name, another location and Connect

### AC: sqlite-points-to-schema (verifies REQ:sqlite-next-step-is-schema)

**Given** a fresh setup
**When** `ovdb databases create shop --engine sqlite --json` runs
**Then** `next` starts with describing a collection schema and contains no add-record command

### AC: result-next-actions (verifies REQ:create-result-next-actions)

**Given** a database created in the TUI and one connected in the web console
**When** each Result shows
**Then** both list Browse data, Explore data, Connect an app or AI assistant, Done, with commands

### AC: connect-leaves-folder-untouched (verifies REQ:connect-existing-storage)

**Given** an existing inGitDB Git repository with records and only a global git identity, and a text file named `x.sqlite`
**When** each is connected
**Then** the folder registers with no file added or changed (including `.git/config`), and the text file is rejected with `storage_unavailable`

### AC: remove-keeps-data (verifies REQ:list-and-remove)

**Given** `OVDB_PREVIEW=1`, `notes` registered and set as the project context, and no server running
**When** `ovdb databases` and then `ovdb databases remove notes --yes` run
**Then** the list works without starting a server, removal leaves the data folder intact and names it, and reports the cleared context

### AC: legacy-create-still-works (verifies REQ:legacy-create-compatible)

**Given** `OVDB_PREVIEW=1`, `OVDB_OWNER_TOKEN=T` and `ovdb serve --data-dir ./data` on port 7000
**When** `ovdb databases create crm --addr http://127.0.0.1:7000` runs
**Then** it calls `POST /v1/databases` as today and writes nothing to the registry

## Open Questions

- Should SQLite gain schemaless support in `openvaultdb-go` so it is friendly without a schema?
- When should guided connect for Firestore, MySQL and PostgreSQL return (it needs a design for
  connection details that live in the server's environment)?
- Should the inGitDB "with Git history" copy depend on `git` being installed?

---
*This document follows the https://specscore.md/feature-specification*
