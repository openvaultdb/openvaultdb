---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: AI agent skills

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/ai-agent-skills?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/ai-agent-skills?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/ai-agent-skills?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/ai-agent-skills?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

`ovdb` ships two Agent Skills: an **OpenVaultDB storage skill** that teaches an AI agent
what OVDB is, how to help the person set it up (in the terminal, in the browser, or by
running the commands itself) and how to store and read data; and a **TODO demo skill**
that lets an agent manage the demo lists. Skills are installed only when a person
explicitly agrees, using the same installer engine as `wb skills sync`.

## Problem

AI agents are a primary way people will meet OpenVaultDB, but an agent has no way to know
OVDB exists, whether it is set up, or which commands are safe. Without guidance an agent
either invents commands or pushes one setup path the person may not want. Silently
dropping files into agent configuration directories would be a breach of trust.

## Behavior

### Skills

| Skill id | Installed directory name | Purpose |
|---|---|---|
| `openvaultdb` | `openvaultdb` | Storage: detect, set up, use `use/cd/pwd/list/get/set/add/delete` |
| `todo-demo` | `openvaultdb-todo-demo` | Manage the TODO demo lists by natural language |

Skill sources live in the `ovdb` repository and are embedded in the binary.

#### REQ: storage-skill-content

The storage skill MUST instruct the agent to:

1. Explain OVDB in one sentence: persistent, structured storage for apps and agents that
   the person owns.
2. Detect state with `ovdb status --json`; if `ovdb` is missing, show install options
   (Homebrew cask, `go install`, release download) without running an installer unasked.
3. If no database exists, offer **three equal setup paths** with equal weight and let the
   person choose: (a) guided setup in the terminal (`ovdb`); (b) setup in the browser (the
   agent runs `ovdb server start` and gives `http://ovdb.localhost:6832`); (c) "I can set it
   up for you" using deterministic commands (`ovdb databases create …`, `ovdb use …`); and
   additionally offer **Try the TODO demo** (`ovdb demo install --yes`).
4. Ask before creating a database, choosing its storage or location, and before deleting
   records the person did not name.
5. Use `--json` for reading results and pass `--db` explicitly for writes.
6. Never enable telemetry on its own. If the person wants to decide, show what is and is
   not collected and run `ovdb telemetry enable` or `disable` only with their answer.
7. On errors, relay the `message`, `reason` and `hint` fields rather than guessing.

#### REQ: todo-skill-content

The TODO skill MUST map everyday requests to commands against the demo database, found
through `ovdb demo status --json` (default id `todo`), for example "add bananas and
coffee to my shopping list" → two `ovdb add /lists/to-buy/items '{"title":…,"done":false}'
--db todo` calls; "what's on my watch list?" → `ovdb list /lists/to-watch/items --db todo
--json`; "I watched The Matrix" → `ovdb set <path> --field done=true --db todo`. If the
demo is not installed it MUST offer `ovdb demo install --yes` and ask first.

### Installing

| Action | CLI |
|---|---|
| List skills and where they are installed | `ovdb skills list [--json]` |
| Install | `ovdb skills install <openvaultdb or todo-demo> [--harness <claude, codex, cursor>]… [--dir <path>] [--dry-run] [--yes]` |
| Remove | `ovdb skills uninstall <skill> [--harness …] [--yes]` |

#### REQ: install-with-skillsync

Installation MUST use `github.com/strongo/cli-helpers/skillsync` with each skill as its own
bundle and plugin identity, so installing or removing one skill never changes the other or
any skill owned by another tool. Harness discovery, `--harness`, `--dir`, `--dry-run`,
ownership conflicts and crash-safe writes MUST follow skillsync behaviour. Installing an
already current skill MUST report `already up to date`.

#### REQ: explicit-consent-to-install

No interface MUST write skill files without an explicit human decision for that skill.
The TUI and web console MUST show the skill's purpose, the target agents and the exact
directories before an Install action, with Install not preselected. On the CLI, the
explicit `ovdb skills install <skill>` command is the decision; when stdin is not a
terminal it MUST also require `--yes`, and without it MUST print the plan (as
`--dry-run`) and exit `2`. No other command (including `demo install` and `status`) MUST
install skills as a side effect.

#### REQ: skills-offered-at-the-right-moment

The TUI and web console MUST offer the TODO skill after the demo is installed and the
storage skill under **AI agent skills** on Home. Both MUST show which supported agents
were detected (Claude Code, Codex, Cursor) and allow choosing a subset.

#### REQ: skills-follow-binary-updates

After a successful `ovdb self-update`, installed OVDB skills SHOULD be refreshed from the
new binary's bundle; a refresh failure MUST be a warning, not an update failure.

#### REQ: uninstall-leaves-modified-files

`ovdb skills uninstall` MUST remove only unmodified files owned by that skill and MUST
report, not delete, files the person changed.

### Example copy

Web console and TUI, after the demo:

```
Install the TODO AI skill?

Lets your AI agent read and change your To buy and To watch lists,
for example: "add bananas and coffee to my shopping list".

Install for:
  [x] Claude Code   ~/.claude/skills/openvaultdb-todo-demo
  [ ] Codex         ~/.codex/skills/openvaultdb-todo-demo
  (Cursor not found on this computer)

[ Install skill ]   Not now
```

Storage skill, setup offer the agent shows (excerpt of skill text):

```
OpenVaultDB isn't set up on this computer yet. How would you like to set it up?
1. In the terminal – run `ovdb` and follow the steps.
2. In your browser – I'll start the OVDB server and give you http://ovdb.localhost:6832
3. I can set it up for you – I'll run the commands and show you each one.
Or: try the TODO demo first.
```

## Dependencies

- first-run-onboarding
- todo-demo
- database-context-navigation
- telemetry-consent

## Acceptance Criteria

### AC: storage-skill-offers-three-paths (verifies REQ:storage-skill-content)

**Given** the embedded storage skill text
**When** a skill content test checks it, and an agent evaluation runs in a fresh environment with `ovdb` installed and no databases
**Then** the text contains all seven instructions, and the agent offers the terminal, browser and "set it up for you" paths plus the demo before creating anything

### AC: todo-skill-maps-requests (verifies REQ:todo-skill-content)

**Given** the demo installed and the TODO skill installed for an agent
**When** the person asks "add bananas and coffee to my shopping list"
**Then** the agent runs two `ovdb add /lists/to-buy/items … --db todo` commands and both items appear in the TODO app

### AC: selective-install (verifies REQ:install-with-skillsync)

**Given** both skills installed for Claude Code and an unrelated skill `specscore` in the same directory
**When** `ovdb skills uninstall todo-demo --harness claude --yes` runs
**Then** only `openvaultdb-todo-demo` is removed; `openvaultdb` and `specscore` are untouched; running `ovdb skills install openvaultdb --harness claude --yes` reports `already up to date`

### AC: agent-cannot-install-silently (verifies REQ:explicit-consent-to-install)

**Given** a non-interactive environment
**When** `ovdb skills install todo-demo` runs without `--yes`, and `ovdb demo install --yes` runs
**Then** the first prints the target directories and exits `2` with no files written, and the second installs no skill

### AC: ui-shows-targets-before-install (verifies REQ:explicit-consent-to-install, REQ:skills-offered-at-the-right-moment)

**Given** Claude Code detected and Codex not detected
**When** the person reaches the skill offer after the demo in the TUI and in the web console
**Then** both show the skill purpose, Claude Code with its exact directory, Codex as not found, and nothing is written until Install is chosen

### AC: refresh-after-self-update (verifies REQ:skills-follow-binary-updates)

**Given** an older OVDB skill installed and a successful self-update to a binary with a newer skill
**When** the update completes
**Then** the installed skill matches the new bundle, and a simulated refresh failure produces a warning while the update exits `0`

### AC: modified-files-kept (verifies REQ:uninstall-leaves-modified-files)

**Given** the person edited `SKILL.md` of the installed storage skill
**When** `ovdb skills uninstall openvaultdb --yes` runs
**Then** the modified file remains and the output names it as kept

## Open Questions

- `skillsync` today exposes `sync` over all configured bundles. Per-skill install and
  uninstall may need a small addition to `strongo/cli-helpers` (external dependency,
  same owner). Verify during planning.
- `ovdb self-update` uses `github.com/strongo/selfupdate`; the skills refresh hook exists
  in `cli-helpers/skillsync/selfupdate`. Move `ovdb` to it, or add a hook?
- When should the skills also be published through a marketplace plugin repository
  (the `datatug/ai-plugin` layout)? Recommendation: after the preview gate is removed.
- Which other agents (Gemini CLI, DeepSeek harness) should be supported first?

---
*This document follows the https://specscore.md/feature-specification*
