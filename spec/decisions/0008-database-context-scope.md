---
format: https://specscore.md/decision-specification
status: Draft
---
# Decision: Database context scope for `ovdb use`, `ovdb cd` and `ovdb pwd`

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,cli,context,ai-agents
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

Every `ovdb` client command today names its target explicitly (`--url`, `--addr`,
`--db`). Once a person or an agent works with one database for a while, repeating
`--db todo` and long record paths on every command is noisy and error-prone. The founder
asked for `ovdb use <database>` plus `ovdb cd` and `ovdb pwd` with relative and absolute
paths, with a safe scope for the remembered choice.

OpenVaultDB record keys are already path-shaped: segments alternate collection and id,
for example `orders/123/order_details/456` (`core.ParseKeyPath` in `openvaultdb-go`),
with ids escaped by `dal.EscapeID`. Nothing in `ovdb` stores a current database today.

The hard part is scope. Several AI agents may work at the same time in different
projects on one machine, and a person may have several terminals open. A remembered
context that leaks between them silently writes to the wrong database.

## Decision

1. **Context** is the pair `{database, path}`; a reserved `server` field allows a remote
   OVDB server later and is always local in MVP.
2. **Resolution precedence** for every command that needs a database:
   1. explicit `--db` flag;
   2. `OVDB_DATABASE` (and `OVDB_PATH`) environment variables;
   3. the **project context** for the current project;
   4. the **global default** (`ovdb use --global <database>`);
   5. the only registered database, if exactly one exists;
   6. otherwise an error listing registered databases and the `ovdb use` command.
   Commands that print a result state which rung supplied the database when it did not
   come from `--db` (for example `(project context)`).
3. **Project context scope.** The project root is the nearest Git working-tree root
   above the current directory, otherwise the current directory itself. Project contexts
   are stored in OVDB home as `contexts/<sha256(normalized root)>.yaml` containing the
   root path, database and path. Normalization: absolute path, `filepath.Clean`, symlinks
   resolved, and case-folded on Windows and macOS. No file is written into the user's
   project. Two sessions in the same project share one context, like Git's current
   branch.
4. **Output always names the scope:** `Now using todo for this project (/home/ann/shop)`
   or `Now using todo as your default for all projects`.
5. **`ovdb use <database>` resets the path to `/`**, because paths belong to one
   database. `ovdb use` without arguments prints the current context and its source.
   `ovdb use --clear` removes the project context; `ovdb use --global --clear` removes
   the global default.
6. **Paths.** Absolute paths start with `/`; others are relative to the context path.
   `.` and `..` are supported; `..` above `/` stays at `/`. `ovdb cd` with no argument
   or with `/` returns to the database root. Odd depth is a collection
   (`/lists/to-buy/items`), even depth is a record (`/lists/to-buy`). Record ids are
   escaped per `dal.EscapeID`; a `/` inside an id is written `%2F`.
7. **`cd` checks syntax and database existence only.** Collections in schemaless
   databases exist only once they hold records, so `cd` does not require the path to
   exist; when it is empty it says `Nothing here yet`.
8. **Web console and TUI** show and change the database context (the TUI for the
   project it was started in, the web console for the global default); path navigation
   is a CLI and agent capability in MVP (documented parity exception).

## Rationale

- **Per-project scope matches how people and agents work.** An agent's session lives in
  one repository; keying by project root means two agents in two projects never
  interfere, while commands run from sub-directories of one project agree.
- **Storing in OVDB home, not in the repository,** avoids polluting repositories, avoids
  `.gitignore` changes and avoids committing machine-specific paths.
- **Explicit output of scope** makes the remembered state visible every time it is set,
  which is the main defence against writing to the wrong database.
- **The precedence ladder** lets scripts be fully explicit (`--db`), lets CI and agent
  harnesses pin a database through environment variables, and keeps the convenient
  defaults last.
- **Resetting the path on `use`** avoids pointing into a collection that does not exist
  in the new database.
- **Not validating path existence in `cd`** matches OpenVaultDB's schemaless model and
  avoids a round trip that would give a misleading "not found" for a collection the
  user is about to create.

## Declined Alternatives

### One machine-global current database

Simplest, but two agents or two terminals in different projects overwrite each other's
choice and write to the wrong database. Declined as unsafe. It survives as the explicit
`--global` default, one rung below project context.

### A dot-directory in the working directory (`.ovdb/context.yaml`)

Visible and portable, but writes into user repositories, needs `.gitignore` handling,
and risks committing local paths. Declined.

### Per-shell environment variables only (`eval "$(ovdb use todo)"`)

Precise scope, but agent tool calls usually run each command in a fresh shell, so the
choice is lost between commands. Kept as rung 2 for people who want it.

### Terminal-session identifier (TTY name, parent PID)

Not portable across platforms, unstable under multiplexers, and unavailable to agents
without a TTY. Declined.

### Validate that the path exists on `cd`

Declined because empty collections do not exist in schemaless storage, which would make
the first `cd` into a new list fail.

## Consequences at Decision Time

- OVDB home gains `contexts/`; stale entries for deleted projects are harmless and may
  be pruned by a later cleanup command.
- Every data command and the skills use one resolver; agents are told to pass `--db`
  explicitly in skills where correctness matters more than brevity.
- Git root detection must not require the `git` binary (read `.git` markers directly) so
  context works on machines without Git.
- Parity exception: path navigation exists only in the CLI and agent surface in MVP.

## Observed Consequences

None observed yet.

## Affected Features

- [Database context and navigation](../features/database-context-navigation/README.md) — implements use, cd, pwd and data verbs.
- [Configuration parity](../features/configuration-parity/README.md) — records the path-navigation exception.
- [AI agent skills](../features/ai-agent-skills/README.md) — skills rely on the precedence ladder.

---
*This document follows the https://specscore.md/decision-specification*
