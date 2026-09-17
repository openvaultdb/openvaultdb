---
format: https://specscore.md/decision-specification
status: Draft
---
# Decision: Built-in TODO demo is the first-run demo

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,demo,ai-agents
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

Two demos exist around OpenVaultDB, neither suitable as a first-run experience:

- `openvaultdb/openvaultdb-todo-demo` has no `spec/` tree. It runs a separate Go backend
  (port 5180), a Vite frontend (port 5173) and a separately started OVDB server, and
  demonstrates the app connect flow (`/authorize`, consent, `/token`). It needs three
  processes and a clone before anything is visible.
- The Sneat Listus demo (`sneat-co/ovdb`, feature `listus-local-demo`, Implementing)
  runs `ovdb demo serve --app listus`, needs a cloud login, a Sneat Space and a
  Cloudflare tunnel. It is a Sneat product demo.

The founder decided the first-run demo is built into the `ovdb` binary, that
`openvaultdb-todo-demo` is superseded as *the* demo, and that Listus stays a Sneat demo.

## Decision

1. `ovdb` embeds a **TODO demo** with two lists, **To buy** and **To watch**, stored in a
   local schemaless inGitDB database with id `todo` at `<OVDB_DATA_HOME>/demos/todo/`
   (default `~/ovdb/demos/todo/`).
2. The demo includes a small web app served by the local server at
   `http://ovdb.localhost:6832/apps/todo/`, same-origin with the data API and using the
   console's login session, so it needs no separate token, CORS or connect flow. It renders
   item text as text only. Only first-party embedded apps are served under `/apps/`.
3. Data is nested to show OpenVaultDB paths: `/lists/{list-id}` and
   `/lists/{list-id}/items/{item-id}`.
4. Installation is idempotent and never overwrites existing data. An optional TODO AI
   skill lets an agent manage the lists by talking to the same database.
5. `openvaultdb-todo-demo` is **superseded as the first-run demo**. It MAY remain as the
   reference example of a *third-party* app using the connect flow, which local mode
   supports (bearer tokens plus origins listed in `server.cors`); its README should say so
   and link here. No SpecScore artifact exists there to transition.
6. Listus remains a Sneat demo. The `ovdb demo` command namespace MUST keep room for
   `--app listus` (for example `ovdb demo install` defaults to `todo`).

## Rationale

- One binary, one command, no network, no account: the first success happens in seconds
  and works offline on every supported OS.
- Same-origin serving removes the most failure-prone parts of a browser demo (ports,
  CORS, tokens) from the first minute. The connect flow is still demonstrated elsewhere.
- Two familiar lists make the "your agent and your app share your data" moment
  obvious: ask the agent to add bananas, see them appear in the app.
- Nesting items under lists gives `ovdb cd /lists/to-buy/items` a real use and mirrors
  how apps structure data.
- inGitDB keeps the data as readable files with Git history, which reinforces "data you
  own" in a way a binary file does not.

## Declined Alternatives

### Keep `openvaultdb-todo-demo` as the first-run demo

Declined: three processes, a clone and a connect flow before the first result.

### Separate origin (`todo.ovdb.localhost`) with the connect flow

Would demonstrate app authorization, but adds CORS, tokens and consent screens to the
first minute. Declined for first run; the connect flow stays in the third-party example.

### Flat layout (`/items/{id}` with a `list` field)

Easier for tools that query only root collections, but loses the path showcase and does
not mirror nested app data. Declined; the DataTug root-collection limitation is recorded
as an external dependency instead.

### Use Listus as the OVDB demo

Declined: it depends on Sneat accounts, cloud login and a tunnel, and would make OVDB's
first impression a Sneat product.

### SQLite as the demo storage

Declined: SQLite databases in OVDB are strict-schema only today, which would require a
schema before the first item, and the data would not be human-readable files.

## Consequences at Decision Time

- `ovdb` embeds demo seed data, a second web entry (`/apps/todo/`) and a TODO skill.
- `openvaultdb-todo-demo` needs a README note; [roadmap](../mvp/roadmap.md) wording that
  names it as a milestone home is updated.
- `ovdb demo` must coexist with the Sneat `ovdb demo serve --app listus` command shape.
- DataTug CLI shows only the two lists, not their nested items, until nested-collection
  queries exist upstream; the Explore data copy for the demo says so at that moment.

## Observed Consequences

None observed yet.

## Affected Features

- [TODO demo](../features/todo-demo/README.md) — implements this decision.
- [AI agent skills](../features/ai-agent-skills/README.md) — TODO skill.
- [Explore data hand-off](../features/explore-data-handoff/README.md) — demo next action.

---
*This document follows the https://specscore.md/decision-specification*
