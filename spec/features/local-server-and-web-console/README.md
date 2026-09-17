---
format: https://specscore.md/feature-specification
status: Draft
---
# Feature: Local server and web console

> [SpecScore.**Studio**](https://specscore.studio): | [Explore](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/local-server-and-web-console?op=explore) | [Edit](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/local-server-and-web-console?op=edit) | [Ask question](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/local-server-and-web-console?op=ask) | [Request change](https://specscore.studio/app/github.com/openvaultdb/openvaultdb/spec/features/local-server-and-web-console?op=request-change) |
**Status:** Draft
**Date:** 2026-09-17
**Owner:** alex
**Source Ideas:** —
**Supersedes:** —

## Summary

One local OVDB server per user serves every registered database, the embedded web console
at `http://ovdb.localhost:6832` and the local API that the web console, TUI and CLI share.
It starts in the background with one command, reports conflicts in plain language, and
accepts browser traffic only from its own pages.

Decision: [0007 local OVDB server model and web address](../../decisions/0007-local-ovdb-server-and-web-address.md).

## Problem

`ovdb serve` runs only in the foreground, needs manifest flags, fails when there is no
database, and surfaces raw bind errors. A person who closes the terminal loses the
server; an agent cannot start one and continue. Nothing protects a loopback server from
malicious websites once a browser UI talks to it.

## Behavior

### Local state

OVDB home is `os.UserConfigDir()/ovdb` (for example `~/.config/ovdb` on Linux,
`~/Library/Application Support/ovdb` on macOS, `%AppData%\ovdb` on Windows), overridable
with `OVDB_HOME`. The existing `cloud/` credential folder already lives there.

| Path | Content | Written by |
|---|---|---|
| `config.yaml` | `server.port`, telemetry consent and install id, global default context | services |
| `databases/<id>.yaml` | database registry; ordinary OVDB manifests | services |
| `contexts/<hash>.yaml` | per-project context ([decision 0008](../../decisions/0008-database-context-scope.md)) | services |
| `server.json` | runtime: pid, port, version, local API version, start time | server |
| `logs/server.log` | background server log, size-bounded | server |
| `explore/datatug/<id>.json` | DataTug connection descriptors | services |

#### REQ: owner-only-state

OVDB home, `config.yaml`, `server.json` and `contexts/` MUST be created owner-only using
`strongo/cli-helpers/daemonlifecycle` protection on every platform, and writes MUST be
atomic (temporary file and rename).

### Server lifecycle

| Command | Behaviour |
|---|---|
| `ovdb server start [--port N]` | Start in the background; wait until ready; print address |
| `ovdb server stop` | Graceful stop; wait until the port is free |
| `ovdb server status [--json]` | Running or not, address, pid, version, uptime, log path |
| `ovdb server open [--print-url]` / `ovdb open` | Start if needed, then open the web console in the default browser |
| `ovdb serve [flags]` | Foreground server (existing); bare `ovdb serve` serves the registry |
| `ovdb config get server.port`, `ovdb config set server.port <N>` | Read or persist the port |

#### REQ: background-start

`ovdb server start` MUST start a detached server process that survives the terminal
closing on Windows, macOS and Linux, MUST wait until `GET /.well-known/openvaultdb`
answers (timeout 10 s) and MUST print both `http://ovdb.localhost:<port>` and
`http://127.0.0.1:<port>`. On timeout it MUST stop the child and report the last log
lines and the log path.

#### REQ: single-server-per-home

At most one OVDB server MUST run per OVDB home, enforced by an advisory lock held by the
server. A second start for the same home MUST report the running server instead of
starting another, even when a different port is requested.

#### REQ: stale-runtime-state

If `server.json` names a process that is not running or not answering as OVDB, `server
status` MUST report "not running" and the next `server start` MUST replace the stale
state without asking.

#### REQ: registry-serving

Bare `ovdb serve` and the background server MUST mount every manifest in
`databases/` (reusing the existing `mount.Dir`). Existing `--dir`, `--manifest`,
`--data-dir`, `--auth`, `--cors` flags MUST keep working unchanged. A database created or
connected through the local API MUST become available without restarting the server. A
manifest that fails to mount MUST NOT stop other databases from being served; the failure
MUST appear in `ovdb status` with its reason.

#### REQ: version-skew

When the running server's version or local API version differs from the CLI's,
`ovdb status` and `ovdb server status` MUST say so with the hint
`ovdb server stop && ovdb server start`. A CLI that cannot speak the server's local API
version MUST refuse configuration changes with that hint rather than writing files
in-process.

#### REQ: stop-from-web

The web console MAY stop the server only after a confirmation that explains the web
console will close, and MUST then show "OVDB server stopped. Start it again from a
terminal: `ovdb server start`".

### Port

#### REQ: port-precedence

The port MUST resolve as `--port` > `OVDB_PORT` > `config.yaml server.port` > `6832`.
`ovdb status` MUST show the port and where it came from.

#### REQ: deterministic-port-conflict

When the chosen port is busy, `server start` MUST probe it. If it is this home's running
OVDB server, the command MUST succeed with "OVDB server is already running at …". Otherwise
it MUST fail with the problem pattern naming the port and offering `--port` and
`ovdb config set server.port`. OVDB MUST NOT pick another port on its own. The TUI and
web console MUST offer "Use port <N+1> instead", which persists `server.port` after
confirmation and starts on that port.

### Browser trust boundary

#### REQ: loopback-bind

Without `--auth`, the server MUST bind only loopback addresses (`127.0.0.1` and, where
available, `::1`) and MUST refuse a non-loopback `--addr` with a problem explaining
`--auth`.

#### REQ: host-allowlist

Every request whose `Host` is not `ovdb.localhost`, `localhost`, `127.0.0.1` or `[::1]`
with the server's port MUST be rejected with `403` before routing, including static
assets, the local API and the data API. When `--auth` is used with a non-loopback bind,
the allowlist MUST include the configured external host.

#### REQ: origin-check

Any `POST`, `PUT`, `PATCH` or `DELETE` request carrying an `Origin` header whose scheme,
host (from the allowlist) and port do not match the server MUST be rejected with `403`,
except data API (`/v1/…`) requests from an origin the operator listed with `--cors`.
Requests without `Origin` MUST be accepted. The local API MUST NOT emit
`Access-Control-Allow-Origin: *`.

#### REQ: no-secrets-in-browser-responses

The local API MUST NOT return tokens, DSN values or environment variable values to the
browser; it MAY return environment variable *names*.

### Embedded web console

#### REQ: embedded-assets

The web console and the TODO app MUST be built from `web/` (Vue 3, TypeScript, Vite,
Tailwind, pnpm) into a directory embedded with `//go:embed all:dist`. A binary built
without assets (`go install`) MUST serve a plain page "The web console is not built into
this ovdb binary" with build instructions, while the data API, local API and CLI keep
working. Release builds MUST fail if the assets are missing.

#### REQ: route-layout

The server MUST route: `/.well-known/openvaultdb` and `/v1/…` (existing APIs, unchanged),
`/api/local/v1/…` (local API), `/apps/todo/…` (TODO app), and `/…` (web console), with
client-side routes falling back to the matching `index.html`. Static assets MUST be
served with explicit content types and `Cache-Control` that lets hashed assets be cached
and `index.html` revalidated.

#### REQ: local-api-contract

The local API MUST expose the shared services as JSON endpoints under `/api/local/v1/`
(status, server, providers, databases, context, demo, skills, explore, telemetry,
config) returning typed results and the shared error shape. It MUST be documented in the
`ovdb` repository and versioned; breaking changes MUST increment the version reported in
`server.json` and `/api/local/v1/status`.

### Cross-platform

#### REQ: cross-platform-lifecycle

Start, stop, status, open and conflict handling MUST be covered by automated tests on
Linux, macOS and Windows in CI, and browser opening MUST degrade to printing the address
when no browser can be launched (headless, SSH, agent).

## Dependencies

- first-run-onboarding
- configuration-parity

## Acceptance Criteria

### AC: start-survives-terminal (verifies REQ:background-start, REQ:cross-platform-lifecycle)

**Given** no server running on Linux, macOS and Windows CI runners
**When** `ovdb server start` runs in a shell that then exits
**Then** the command prints both addresses after readiness, and a later `ovdb server status --json` in a new shell reports running with the same pid

### AC: second-start-reuses (verifies REQ:single-server-per-home, REQ:deterministic-port-conflict)

**Given** a server for this OVDB home running on 6832
**When** `ovdb server start` and `ovdb server start --port 7000` run
**Then** both exit `0` with "OVDB server is already running at http://ovdb.localhost:6832" and no second process exists

### AC: foreign-port-conflict (verifies REQ:deterministic-port-conflict)

**Given** a non-OVDB program listening on 127.0.0.1:6832
**When** `ovdb server start` runs, and the person chooses "Use port 6833 instead" in the TUI
**Then** the CLI exits `1` naming port 6832 and both fixes, and the TUI persists `server.port: 6833` and starts the server at `http://ovdb.localhost:6833`

### AC: stale-state-recovers (verifies REQ:stale-runtime-state)

**Given** `server.json` names a pid that no longer exists
**When** `ovdb server status` and then `ovdb server start` run
**Then** status reports not running and start succeeds without prompting

### AC: bare-serve-mounts-registry (verifies REQ:registry-serving)

**Given** `databases/` holds a valid `todo.yaml` and a `broken.yaml` pointing at a missing SQLite directory it cannot create
**When** `ovdb serve` runs with no flags
**Then** `todo` is served, `ovdb status` lists `broken` with its mount error, and `ovdb serve --manifest x.yaml` still works as before

### AC: live-registry-update (verifies REQ:registry-serving, REQ:local-api-contract)

**Given** a running server
**When** a database is created through `POST /api/local/v1/databases`
**Then** `GET /v1/databases/<id>` succeeds immediately without restart

### AC: version-skew-hint (verifies REQ:version-skew)

**Given** a running server whose local API version is lower than the CLI's
**When** `ovdb databases create x` runs
**Then** it exits `1` with a message that the server is older and the hint `ovdb server stop && ovdb server start`, and no file under OVDB home changes

### AC: dns-rebinding-blocked (verifies REQ:host-allowlist)

**Given** a running server
**When** a request arrives with `Host: attacker.example:6832`
**Then** it receives `403` for `/`, `/api/local/v1/status` and `/v1/databases`

### AC: cross-site-post-blocked (verifies REQ:origin-check)

**Given** a running server
**When** a `POST /api/local/v1/demo/install` arrives with `Origin: https://evil.example`, and another with `Origin: http://ovdb.localhost:6832`, and another with no Origin
**Then** the first gets `403` and changes nothing; the second and third succeed

### AC: non-loopback-needs-auth (verifies REQ:loopback-bind)

**Given** no `--auth`
**When** `ovdb serve --addr 0.0.0.0:6832` runs
**Then** it exits `1` explaining that non-loopback addresses require `--auth`

### AC: browser-sees-no-secrets (verifies REQ:no-secrets-in-browser-responses)

**Given** a connected PostgreSQL database configured with `dsn_env: OVDB_POSTGRES_DSN` set in the server environment
**When** the web console loads database details
**Then** the response contains the variable name and no DSN value

### AC: not-built-fallback (verifies REQ:embedded-assets)

**Given** a binary built with `go install` without web assets
**When** a browser opens `http://ovdb.localhost:6832/`
**Then** it shows the not-built page, while `ovdb demo install --yes` and `GET /v1/status` work

### AC: spa-fallback-and-routes (verifies REQ:route-layout)

**Given** a release binary
**When** the browser requests `/settings`, `/apps/todo/`, `/apps/todo/lists/to-buy`, `/v1/status` and a hashed asset
**Then** the first returns the console `index.html`, the next two the TODO app `index.html`, `/v1/status` the existing JSON, and the asset has a long-lived cache header

### AC: state-is-owner-only (verifies REQ:owner-only-state)

**Given** a fresh OVDB home on each platform
**When** `ovdb server start` and `ovdb use --global todo` run
**Then** `daemonlifecycle` validation of OVDB home, `config.yaml` and `server.json` passes

### AC: stop-from-web-confirms (verifies REQ:stop-from-web)

**Given** the web console open
**When** the person chooses Stop and confirms
**Then** the server exits and the page shows the restart command; choosing Cancel leaves it running

## Open Questions

- Shared multi-user machines: another OS account can reach a loopback port while local
  authentication is off. Options: (a) accept and document for MVP (current decision);
  (b) owner token file for CLI plus a one-time link from `ovdb open` that sets an
  `HttpOnly`, `SameSite=Strict` cookie, with the bare address showing "Open this page
  with `ovdb open`"; (c) detect multi-user hosts and switch to (b). Recommendation: (a)
  now, (b) before a stable release. Needs security review.
- Should the background server start at login (launchd, systemd user unit, Windows
  startup) as an opt-in setting?
- Log retention size and whether `ovdb server logs` is worth a command.

---
*This document follows the https://specscore.md/feature-specification*
