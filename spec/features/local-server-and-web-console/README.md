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

One authenticated local OVDB server per user runs every onboarding service and serves the
registered databases, the web console at `http://ovdb.localhost:6832`, the TODO app and the
local API. It starts in the background on demand, proves its identity to clients, lets
browsers in through one-time login links, and reports conflicts in plain language. Legacy
`ovdb serve` is unchanged.

Decision: [0007 local OVDB server model and web address](../../decisions/0007-local-ovdb-server-and-web-address.md).

## Problem

`ovdb serve` runs only in the foreground, needs manifest flags and surfaces raw bind errors.
An agent cannot start a server and continue; a person loses it when the terminal closes. A
server that writes files and agent skills must not be usable by other accounts, other local
programs or hostile websites.

## Behavior

### Locations

| Kind | Default | Override | Content |
|---|---|---|---|
| Configuration | `os.UserConfigDir()/ovdb` | `OVDB_HOME` | `config.yaml`, `databases/<id>.yaml` (registry manifests), `contexts/`, existing `cloud/` |
| Runtime | `os.UserCacheDir()/ovdb/run` | — | `server.json` (instance id, pid, process start time, port, version), `home.lock`, `secret`, `server.log` |
| Data | `~/ovdb` | `OVDB_DATA_HOME` | New databases and demos |

#### REQ: owner-only-state

Configuration and runtime directories and their files MUST be created owner-only with
`strongo/cli-helpers/daemonlifecycle` (`ProtectOwnerOnly`, validated with
`ValidateOwnerOnly`) on every platform, and written atomically.

### Server modes

#### REQ: local-mode-only-for-new-surfaces

The web console, TODO app, local API, Host allowlist and authentication MUST exist only in
local mode (`ovdb server start`, `ovdb open`, TUI, auto-start). `ovdb serve` with its
existing flags MUST behave exactly as today; without `OVDB_PREVIEW=1`, bare `ovdb serve`
MUST still fail as today, and with it the error MUST suggest `ovdb server start`.

#### REQ: single-server-home-lock

A local-mode server MUST hold `home.lock` exclusively for its lifetime. A second start for
the same home MUST report the running server instead of starting another, even with a
different `--port` (with a one-line warning about the port).

### Lifecycle

| Command | Behaviour |
|---|---|
| `ovdb server start [--port N] [--json]` | Start detached; wait for authenticated readiness; print addresses and a login link |
| `ovdb server stop` | Authenticated shutdown; wait until the port is free |
| `ovdb server restart` | Stop then start with the same settings |
| `ovdb server status [--json]` | Running, address, version, uptime, log path |
| `ovdb open [--print-url]` | Start if needed, create a login link, open the browser (or print it) |
| `ovdb config get server.port`, `ovdb config set server.port <N>` | Read or persist the port |

#### REQ: background-start

`ovdb server start` MUST start a detached process (new session on Unix; detached process
group with no console window and no inherited handles on Windows) with stdio redirected to
`server.log` and working directory OVDB home, MUST wait up to 10 s for authenticated
`whoami`, and MUST print `http://ovdb.localhost:<port>`, `http://127.0.0.1:<port>` and a
login link. On timeout it MUST stop the child and show the last log lines. A calling process
whose stdout is a pipe MUST get control back within 2 s of readiness.

#### REQ: authenticated-stop

`ovdb server stop` MUST call `POST /api/local/v1/server/shutdown` with the instance secret.
If the server does not answer, it MAY terminate the recorded pid only when the pid's process
start time matches `server.json`; otherwise it MUST report that it could not confirm the
process and change nothing.

#### REQ: stale-runtime-state

If `server.json` names a process that is gone or fails `whoami`, `server status` MUST report
"not running" and the next start MUST replace the runtime files without asking.

#### REQ: version-mismatch-notice

When a client's version differs from the running server's, the client MUST print one line
`OVDB server is running version X; restart it to use version Y: ovdb server restart` and
continue; if the local API cannot serve the request it MUST fail with
`server_version_mismatch` and the same `next`.

#### REQ: auto-start

Commands that need the server MUST start it as in `background-start` when it is not running,
printing `Started the OVDB server at http://ovdb.localhost:6832` on stderr; with
`--no-start` they MUST fail with `server_not_running` and `next` `ovdb server start`.

#### REQ: stopped-server-copy

Stop output in CLI and TUI, and the landing page, MUST say how to get back without assuming
a terminal: "Ask your AI assistant to start OVDB again, or run `ovdb open`."

### Registry

#### REQ: registry-serving

The local-mode server MUST mount every manifest in `databases/`. A manifest that fails to
mount MUST NOT stop others and MUST be reported as "needs attention" with a redacted reason in
status. Databases created or connected through the local API MUST become available without
a restart.

### Port

#### REQ: port-precedence

The port MUST resolve as `--port` > `OVDB_PORT` > `server.port` > `6832` when starting.
Clients MUST use the port recorded in `server.json` for a running server.

#### REQ: deterministic-port-conflict

When the port is busy, start MUST probe it with `whoami`: this home's instance → success with
"OVDB server is already running at …"; otherwise fail with `port_in_use` naming the port with
`next` entries `ovdb server start --port <N+1>` and `ovdb config set server.port <N+1>`. A
bind refused by the OS without a listener (for example a Windows reserved port range) MUST
fail with `port_unavailable` ("Port 6832 isn't available on this computer"). OVDB MUST NOT
choose another port on its own; the TUI MUST offer "Use port <N+1> instead", which persists
the port after confirmation.

#### REQ: loopback-bind

Local mode MUST bind `127.0.0.1` and `::1`. If `::1` fails because IPv6 is unavailable the
server MUST continue on IPv4; if it fails because the address is in use it MUST fail as a
conflict. Loopback detection MUST use `net.SplitHostPort` and `netip.Addr.IsLoopback`, with an
empty host treated as all interfaces (not loopback).

### Authentication

#### REQ: instance-secret

At start the server MUST create a random instance id and secret in the runtime directory.
CLI and TUI MUST send the secret as `Authorization: Bearer` on every local API and data API
call, and MUST verify the instance id via `GET /api/local/v1/whoami` before sending data,
reporting "already running" or signalling a process.

#### REQ: login-link

`ovdb server start`, `ovdb open` and the TUI MUST create one-time login links
`http://ovdb.localhost:<port>/login?code=<random>` valid for 10 minutes and a single use.
`GET /login` with a valid code MUST set an `HttpOnly`, `SameSite=Strict`, host-only session
cookie and redirect to the console (or the `next` path within the origin); invalid or used
codes MUST show the landing page. Codes MUST NOT be logged.

#### REQ: landing-page

A request to a console or app page without a valid session MUST return a page titled "Open
the console from OVDB" explaining `ovdb open` and asking an AI assistant for a link, and
MUST expose no data.

#### REQ: all-local-mode-apis-authenticated

In local mode, `/api/local/v1/…` and `/v1/…` MUST reject requests without a valid instance
secret or session cookie with `401 unauthorized`. `POST /api/local/v1/server/shutdown` and
project-scope context writes MUST require the instance secret.

### Browser hardening

#### REQ: host-allowlist

In local mode every request whose `Host` (case-insensitive, no trailing dot) is not
`ovdb.localhost`, `localhost`, `127.0.0.1` or `[::1]` with the server's port MUST get `403`.

#### REQ: cross-origin-protection

In local mode non-safe methods MUST pass Go `http.CrossOriginProtection`; GET handlers MUST
have no side effects; request bodies MUST be `application/json`.

#### REQ: security-headers

Every local-mode response MUST send `X-Content-Type-Options: nosniff` and
`Referrer-Policy: no-referrer`. HTML responses MUST also send
`Content-Security-Policy: default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`
and `X-Frame-Options: DENY`. The web console and apps MUST render record values as text
only (no `v-html`, enforced by lint). Only first-party embedded apps MAY be served under
`/apps/`.

#### REQ: redacted-errors

Every error surfaced by the server to the CLI, TUI, web console, status or `server.log` MUST
pass a redaction layer that removes URL user-info, `key=value` pairs whose key contains
`password`, `secret`, `token` or `key`, and connection-string shapes. Raw driver errors MUST
NOT leave the server unredacted.

### Embedded web console

#### REQ: embedded-assets

The console and TODO app MUST be built from `web/` with pnpm into a directory embedded with
`//go:embed all:dist` (tracked `.gitkeep`). A binary without assets MUST serve "The web
console isn't built into this ovdb binary" naming the Homebrew and release downloads, and
`ovdb demo open` MUST say so instead of opening a blank page. Release builds MUST fail
without assets.

#### REQ: route-layout

Local mode MUST route `/.well-known/openvaultdb` and `/v1/…` (existing APIs, now
authenticated), `/login`, `/api/local/v1/…`, `/apps/todo/…` and `/…` (console) with
client-side route fallback. Middleware order MUST be Host → authentication →
cross-origin protection → headers → routes.

## Dependencies

- first-run-onboarding
- configuration-parity

## Acceptance Criteria

### AC: legacy-serve-unchanged (verifies REQ:local-mode-only-for-new-surfaces)

**Given** `ovdb serve --manifest todo.yaml --addr 127.0.0.1:7000` without `OVDB_PREVIEW`
**When** a client calls `GET /v1/databases` with `Host: tunnel.example` and no credentials, and requests `/`
**Then** the data API answers as today, `/` is not the console, and bare `ovdb serve` fails with today's message

### AC: start-returns-to-piped-caller (verifies REQ:background-start, REQ:instance-secret)

**Given** no server and a caller whose stdout is a pipe, on Linux, macOS and Windows runners
**When** `ovdb server start` runs and the caller exits
**Then** control returns within 2 s of readiness, output has both addresses and a login link, and a later `ovdb server status --json` in a new shell reports running after `whoami` succeeds

### AC: second-start-reuses (verifies REQ:single-server-home-lock, REQ:deterministic-port-conflict)

**Given** a server for this home on 6832
**When** `ovdb server start --port 7000` runs
**Then** it exits `0` with "already running at http://ovdb.localhost:6832" and a port warning, and no second process exists

### AC: impostor-port (verifies REQ:deterministic-port-conflict, REQ:instance-secret, REQ:loopback-bind)

**Given** another program listening only on `[::1]:6832`
**When** `ovdb server start` runs
**Then** it exits `1` with `port_in_use` and does not serve IPv4 only

### AC: reserved-port (verifies REQ:deterministic-port-conflict)

**Given** a bind on 6832 that the OS refuses with no listener
**When** `ovdb server start` runs
**Then** it fails with `port_unavailable` and the "isn't available" copy, not "used by another program"

### AC: stop-never-kills-reused-pid (verifies REQ:authenticated-stop, REQ:stale-runtime-state)

**Given** `server.json` whose pid now belongs to an unrelated process with a different start time
**When** `ovdb server stop` and `ovdb server status` run
**Then** the unrelated process keeps running, stop reports it could not confirm the process, and status reports not running

### AC: version-mismatch-line (verifies REQ:version-mismatch-notice)

**Given** a running server of an older version
**When** `ovdb databases` runs from a newer binary
**Then** it prints the one-line restart notice with `ovdb server restart` and still lists databases

### AC: auto-start-and-no-start (verifies REQ:auto-start)

**Given** no server running
**When** `ovdb databases create notes` runs, then the server is stopped and `ovdb databases create other --no-start` runs
**Then** the first prints the start line on stderr and succeeds; the second exits `1` with `server_not_running`

### AC: stop-copy (verifies REQ:stopped-server-copy)

**Given** a running server
**When** `ovdb server stop` runs, and the TUI stops the server
**Then** both show "Ask your AI assistant to start OVDB again, or run `ovdb open`"

### AC: tolerant-registry (verifies REQ:registry-serving, REQ:redacted-errors)

**Given** `databases/` with a valid `todo.yaml` and a broken manifest whose storage cannot open
**When** the server starts and `ovdb status --json` runs
**Then** `todo` is served, the broken database is "needs attention" with a redacted reason, and a database created via the local API is readable immediately

### AC: login-link-once (verifies REQ:login-link, REQ:landing-page)

**Given** `ovdb open --print-url` printed a link
**When** a browser opens it, then a second browser opens the same link, then a third opens the bare address
**Then** the first reaches the console with a session cookie; the second and third see the landing page with no data

### AC: unauthenticated-rejected (verifies REQ:all-local-mode-apis-authenticated)

**Given** a local-mode server
**When** `GET /v1/databases`, `GET /api/local/v1/status` and `POST /api/local/v1/server/shutdown` are called without credentials, and shutdown is called with only a session cookie
**Then** all return `401`, and the server keeps running

### AC: dns-rebinding-blocked (verifies REQ:host-allowlist)

**Given** a local-mode server
**When** requests arrive with `Host: attacker.example:6832`, `Host: localhost.:6832` and no Host
**Then** each gets `403`

### AC: cross-site-post-blocked (verifies REQ:cross-origin-protection)

**Given** a valid session cookie in the browser
**When** a page on `https://evil.example` submits `POST /api/local/v1/demo/install`
**Then** it is rejected and nothing changes

### AC: framing-refused (verifies REQ:security-headers)

**Given** a page on another origin that embeds `http://ovdb.localhost:6832/` in an iframe
**When** Chromium loads it
**Then** the frame does not render, and responses carry the CSP, `X-Frame-Options`, `nosniff` and `Referrer-Policy` headers

### AC: dsn-never-leaks (verifies REQ:redacted-errors)

**Given** a manifest for PostgreSQL whose connection string `postgres://u:s3cret@nohost/db` is in the server environment
**When** the mount fails and status, `--json`, the local API and `server.log` are inspected
**Then** neither `s3cret` nor the full connection string appears anywhere

### AC: runtime-files-private-and-local (verifies REQ:owner-only-state)

**Given** a fresh setup on each platform
**When** `ovdb server start` runs
**Then** runtime files are under the user cache directory (LocalAppData on Windows), and `ValidateOwnerOnly` passes for config and runtime directories

### AC: not-built-fallback (verifies REQ:embedded-assets)

**Given** a binary built with `go install` without assets
**When** a browser opens a login link and `ovdb demo open` runs
**Then** the page names Homebrew and release downloads, `demo open` reports the missing console, and CLI data commands work

### AC: routes (verifies REQ:route-layout)

**Given** a release binary with a session
**When** the browser requests `/settings`, `/apps/todo/`, `/v1/status` and a hashed asset
**Then** it gets the console `index.html`, the TODO app `index.html`, JSON, and a cacheable asset

## Open Questions

- Should the background server start at login as an opt-in setting (deferred from MVP)?
- Log size limit and rotation.

---
*This document follows the https://specscore.md/feature-specification*
