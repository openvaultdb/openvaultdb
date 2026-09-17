---
format: https://specscore.md/decision-specification
status: Approved
---
# Decision: Database context scope for `ovdb use`, `ovdb cd` and `ovdb pwd`

**Status:** Approved
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,cli,context,ai-agents
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

Every `ovdb` client command names its target explicitly today. Repeating `--db` and long
record paths is noisy for people. The founder asked for `ovdb use <database>`, `ovdb cd`
and `ovdb pwd` with relative and absolute paths, and a safe, documented scope.

Record keys are path-shaped, alternating collection and id (`core.ParseKeyPath` in
`openvaultdb-go`). Several agents may work at once in different projects, or in the same
project, and a person may have several terminals open.

## Decision

1. **Context** is `{database, path}`; a reserved `server` field is always local in MVP.
2. **Precedence:** `--db` flag > `OVDB_DATABASE` (and `OVDB_PATH`) > project context (found
   by walk-up) > global default (`ovdb use --global`) > the only registered database >
   error listing databases.
3. **Writing a project context.** `ovdb use` stores the context for the *project root*:
   the nearest Git working-tree root above the current directory (each linked worktree is
   its own root), otherwise the current directory. Contexts live in OVDB home keyed by the
   hash of the canonical absolute path; nothing is written into the project.
4. **Finding a project context.** Commands walk up from the current directory to the
   nearest directory that has a stored context, not crossing above the Git root when inside
   a repository. Output names the directory that supplied it.
5. **Only CLI and TUI set project contexts** (they know the working directory). The web
   console can set only the global default.
6. **Output always names the scope:** `Now using todo for this project (/home/ann/shop)`.
7. **`ovdb use <database>` resets the path to `/`.**
8. **Paths.** Leading `/` is absolute; otherwise relative to the context path; `.` and `..`
   supported, never above `/`. Odd depth is a collection, even depth a record. Segments are
   escaped with `record.EscapeID` for the server (which escapes `/ . $ # [ ]`); display and
   input use the same escaped form.
9. **`cd` checks syntax and database existence only**, printing `Nothing here yet` for an
   empty location, because schemaless collections exist only once they hold records.
10. **Context is a convenience, not a coordination mechanism.** Skills and scripts use
    absolute paths and `--db` for writes, or `OVDB_DATABASE`/`OVDB_PATH` per process.

## Rationale

- Per-project scope matches how people and agents work, and walk-up lookup makes
  sub-directories (with or without Git) agree with the directory where `use` was run.
- Storing contexts in OVDB home avoids polluting repositories and committing local paths.
- Naming the scope and the supplying directory every time is the main defence against
  writing to the wrong database.
- The shared mutable path is safe only for interactive convenience; making skills use
  absolute paths removes the cross-session hazard where it matters.
- Letting only terminal clients set project contexts keeps the browser from writing
  contexts for directories it cannot see.

## Declined Alternatives

### One machine-global current database

Agents in different projects overwrite each other's choice. Kept only as the explicit
`--global` rung.

### Exact-directory lookup without walk-up (first draft)

Declined after review: outside Git, `ovdb use` in `~/proj` did not apply in `~/proj/src`,
which silently fell through to the global default.

### A dot-directory in the project (`.ovdb/context.yaml`)

Writes into user repositories and risks committing local paths. Declined.

### Per-shell environment variables only

Agent tool calls usually run in fresh shells, losing the choice. Kept as rung 2.

### Per-invocation path only (no persisted `cd`)

Safest for concurrency but removes the navigation the founder asked for. Declined;
skills use absolute paths instead.

### Validate that the path exists on `cd`

Empty schemaless collections do not exist, so the first `cd` into a new list would fail.
Declined.

## Consequences at Decision Time

- OVDB home gains `contexts/`; stale entries are harmless.
- Every data command and skill uses one resolver in the shared Go package.
- Git root detection reads `.git` markers directly and does not need the `git` binary.
- Parity exception: project contexts cannot be set from the web console.

## Observed Consequences

None observed yet.

## Affected Features

- [Database context and navigation](../features/database-context-navigation/README.md) — implements use, cd, pwd, data verbs and browse.
- [Configuration parity](../features/configuration-parity/README.md) — records the web context exception.
- [AI agent skills](../features/ai-agent-skills/README.md) — skills use absolute paths and `--db`.

---
*This document follows the https://specscore.md/decision-specification*
