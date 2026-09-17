---
format: https://specscore.md/decision-specification
status: Draft
---
# Decision: Local OVDB server model and web address

**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Tags:** onboarding,local-server,web-ui,security,networking
**Source Idea:** ovdb-onboarding-and-configuration
**Supersedes:** —
**Superseded By:** —

## Context

`ovdb serve` already binds `127.0.0.1:6832` by default (`DefaultAddr` in `ovdb/main.go`),
runs only in the foreground, has no PID or lock file, and returns the raw bind error when
the port is taken. It needs at least one database or `--data-dir`, otherwise it exits.
Client commands (`status`, `databases`, `token`) default to the same loopback address.
There is no Host-header or Origin checking; CORS is opt-in via `--cors`; authentication
is opt-in via `--auth`.

Onboarding needs a web address a person can remember and an AI agent can print, a way to
run the server without keeping a terminal open, and a clear trust boundary now that a
browser (which also visits arbitrary websites) will talk to it.

The hub's [Docker Compose guide](../deployment/docker-compose.md) documents a container
default of `http://localhost:8080`, which is a different deployment shape.

## Decision

1. **Address.** The local web console and API are served at
   **`http://ovdb.localhost:6832`**. The port spells OVDB on a phone keypad
   (O=6, V=8, D=3, B=2). Output that shows the address MUST also show the fallback
   `http://127.0.0.1:6832` for browsers or resolvers that do not map `*.localhost` to
   loopback.
2. **HTTP, not HTTPS, for the local MVP.** No certificate is generated or installed.
3. **Port configuration.** Precedence: `--port` flag > `OVDB_PORT` environment variable >
   `server.port` in OVDB `config.yaml` > `6832`. Container and self-hosted deployments
   keep their own documented defaults; 6832 is the *local* default.
4. **Loopback only by default.** The server binds `127.0.0.1` and `::1`. Go clients
   connect to `127.0.0.1` and never depend on resolving `ovdb.localhost`. Binding any
   non-loopback address requires `--auth` (existing flag).
5. **Browser trust boundary.**
   - Every request's `Host` MUST be one of `ovdb.localhost`, `localhost`, `127.0.0.1`,
     `[::1]` with the configured port, otherwise the request is rejected with `403` and no data. This
     blocks DNS rebinding.
   - State-changing requests that carry an `Origin` header MUST have an Origin whose host
     is in the same allowlist and whose port matches; requests without `Origin`
     (CLI, agents, curl) are accepted. This blocks cross-site request forgery from other
     websites.
   - The local API (`/api/local/v1/`) never sends wildcard CORS headers. Existing
     `--cors` behaviour for the data API is unchanged.
   - Local authentication stays off by default on loopback; see Rationale for the
     accepted risk.
6. **Background lifecycle.** `ovdb server start` starts a detached background server
   (re-executing the binary with `serve --registry`, using platform-specific detachment
   on Windows, macOS and Linux) and returns once the server answers
   `GET /.well-known/openvaultdb`. `ovdb server stop`, `ovdb server status` and
   `ovdb server open` (alias `ovdb open`) complete the set. `ovdb serve` stays the
   foreground command. Runtime state (`server.json`: pid, port, version, start time) is
   protected with `strongo/cli-helpers/daemonlifecycle` owner-only files and an advisory
   lock.
7. **Port conflicts are deterministic.** On start, if the port is busy the CLI probes
   `GET /.well-known/openvaultdb` on it:
   - an OVDB server recorded in this user's `server.json` → report "already running" and
     succeed;
   - anything else (another program, another user's or version's OVDB) → fail with a
     message naming the port, what is using it if known, and the fix
     (`ovdb server start --port 6833` or `ovdb config set server.port 6833`).
   OVDB never silently picks another port. TUI and web MAY offer a one-step remedy
   "Use port 6833 instead" that persists `server.port` after confirmation.
8. **CLI over HTTP for data.** Data commands (`list`, `get`, `set`, `add`, `delete`) are
   HTTP clients of the local server. If no server is running they start one in the
   background and print one line saying so on stderr; `--no-start` turns that off and
   fails with a hint instead.

## Rationale

- **Memorable, printable address.** `ovdb.localhost` needs no hosts-file edit because
  browsers treat `*.localhost` as loopback (RFC 6761), and it names the product. The
  keypad mnemonic makes the port guessable, and 6832 is already the implemented default.
- **HTTP on loopback.** Browsers treat `http://localhost` and `*.localhost` as potentially
  trustworthy (secure context), so modern web APIs work. HTTPS would require generating a
  local certificate authority and installing it into OS and browser trust stores, which
  is a privileged, platform-specific step, a common support burden and a security risk of
  its own. Traffic never leaves the machine.
- **Host and Origin checks** are the standard defences for loopback servers: DNS
  rebinding makes an attacker's hostname resolve to 127.0.0.1, which the Host allowlist
  rejects; a malicious page can send "simple" cross-origin POSTs, which the Origin check
  rejects. Non-browser clients do not send Origin, so agents are unaffected.
- **No local auth by default.** Any process running as the same OS user can already read
  the database files and OVDB home directly, so a token stored in that home would not
  stop it. Requiring login for `http://ovdb.localhost:6832` would break the first 60
  seconds for the web journey. **Accepted MVP risk:** on a machine shared by several OS
  accounts, another local account can reach a loopback port. This is recorded as an open
  question in the [local server feature](../features/local-server-and-web-console/README.md);
  `--auth` remains available.
- **Deterministic ports.** The web address appears in skill instructions, terminal output
  and bookmarks. Automatic port hopping would make the printed address wrong exactly
  when the user needs it, and would let two OVDB servers run side by side over the same
  registry, breaking the single-writer rule.
- **Auto-start for data commands.** Agents run commands one at a time and do not keep
  shells alive; a mandatory separate `server start` step is the most likely point of
  failure for an agent. One stderr line keeps the side effect visible, and `--no-start`
  gives scripts control.

## Declined Alternatives

### Local HTTPS with a generated certificate

Declined: needs trust-store changes with elevated privileges on some platforms, produces
browser warnings when it goes wrong, and adds no confidentiality for loopback traffic.

### Automatically choose the next free port

Declined: breaks printed and remembered addresses and allows duplicate servers over one
registry. A one-step, persisted remedy keeps the user in control.

### Plain `http://localhost:6832` as the primary address

Works everywhere but says nothing about what it is and collides visually with every other
local dev server. Kept as an allowed Host, not the advertised address.

### Unix domain socket for CLI traffic (as `wb` does)

Avoids port conflicts for the CLI but the browser still needs TCP, so it adds a second
transport without removing the first. Declined for MVP.

### Require a local token for the web console by default

Declined for MVP because it adds a login step to the first web visit while giving little
protection against same-user processes. Revisit for shared multi-user machines.

### Run the server as an OS service (launchd, systemd, Windows service)

Survives reboots but needs installation privileges and per-OS packaging. Declined for
MVP; a background process started on demand is enough.

## Consequences at Decision Time

- `ovdb` gains `server start|stop|status|open`, a runtime `server.json`, Host/Origin
  middleware and platform-specific detachment code with tests on Windows, macOS and Linux.
- Bare `ovdb serve` (no flags) serves the database registry instead of failing.
- Deployment guides keep their `8080` container default; the hub states that `6832` is
  the local default.
- The security specifications gain a normative browser trust boundary for loopback
  servers that did not exist before.
- Accepted risk on shared multi-user machines until local authentication is revisited.

## Observed Consequences

None observed yet.

## Affected Features

- [Local server and web console](../features/local-server-and-web-console/README.md) — implements address, lifecycle, conflicts and trust boundary.
- [First-run onboarding](../features/first-run-onboarding/README.md) — "Start the OVDB server" option and server status.
- [Database context and navigation](../features/database-context-navigation/README.md) — data commands use CLI over HTTP with auto-start.
- [AI agent skills](../features/ai-agent-skills/README.md) — skills print and rely on the address.

---
*This document follows the https://specscore.md/decision-specification*
