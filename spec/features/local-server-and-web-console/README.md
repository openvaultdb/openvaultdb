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
registered databases, the web console at `http://ovdb.localhost:6832`, the TODO app, the
local API and the connect flow. It starts in the background on demand, proves its identity to
clients, lets browsers in through one-time login links, and reports conflicts in plain
language. Legacy `ovdb serve` is unchanged.

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
| Configuration | `os.UserConfigDir()/ovdb` | `OVDB_HOME` | `config.yaml` (`server.port`, `server.cors`, telemetry, global context), `databases/<id>.yaml`, `contexts/`, `auth.json` (scoped tokens, hashed), existing `cloud/` |
| Runtime | `os.UserCacheDir()/ovdb/run` | — | `server.json` (instance id, OVDB home, pid, process start time, port, version), `home.lock`, `secret`, `sessions.json` (hashed), `mounts.json` (per-database mount state), `server.log` |
| Data | `~/ovdb` | `OVDB_DATA_HOME` | New databases, `demos/todo/` |

#### REQ: owner-only-state

Configuration and runtime directories and their files MUST be created owner-only with
`strongo/cli-helpers/daemonlifecycle` (`ProtectOwnerOnly`, validated with
`ValidateOwnerOnly`) on every platform, and written atomically.

### Server modes

#### REQ: local-mode-only-for-new-surfaces

The web console, TODO app, local API, login, Host allowlist and local-mode authentication
MUST exist only in local mode (`ovdb server start`, `ovdb open`, TUI, auto-start). `ovdb serve`
with its existing flags MUST behave exactly as today; without `OVDB_PREVIEW=1`, bare
`ovdb serve` MUST still fail as today, and with it the error MUST suggest
`ovdb server start`.

#### REQ: single-server-home-lock

A local-mode server MUST hold `home.lock` exclusively for its lifetime; it is the only writer
of that home's registry and of databases it mounts. A second start for the same home MUST
report the running server. Writes to the same storage by other tools (another `OVDB_HOME`,
legacy `ovdb serve`, editors) are out of scope; a per-storage lock is deferred.

### Lifecycle

| Command | Behaviour |
|---|---|
| `ovdb server start [--port N] [--json]` | Start detached; wait for authenticated readiness; print the plain address and "Sign in with `ovdb open`" |
| `ovdb server stop` | Authenticated shutdown; wait until the port is free |
| `ovdb server restart [--port N]` | Stop then start |
| `ovdb server status [--json]` | Running, address, version, uptime, log path |
| `ovdb open [--print-url] [--host 127.0.0.1] [--json]` | Start if needed, create a login link, open the browser; always print both links |
| `ovdb config get <key>`, `ovdb config set <key> <value>` | Keys `server.port`, `server.cors` (comma-separated origins) |

#### REQ: background-start

`ovdb server start` MUST start a detached process — a new session on Unix; on Windows
`DETACHED_PROCESS | CREATE_NEW_PROCESS_GROUP | CREATE_BREAKAWAY_FROM_JOB`, retrying without
breakaway when the job forbids it — with no inherited handles, stdio redirected to
`server.log` and working directory OVDB home. It MUST wait up to 10 s for authenticated
`whoami`, then print `http://ovdb.localhost:<port>`, `http://127.0.0.1:<port>` and "Sign in
with `ovdb open`", and return control to a piped caller within 2 s of readiness. It MUST NOT
print login links.

#### REQ: start-failure-in-restricted-environments

If the child exits, or `whoami` does not succeed within the timeout, start MUST stop the
child and fail with `server_start_failed`, a `reason` with the last log line (redacted), and
`next` including "If you are an AI agent in a sandbox, ask the person to run `ovdb open` or
`ovdb server start` outside the sandbox".

#### REQ: client-values-and-mismatch

Clients MUST resolve environment-dependent inputs themselves and send them with each request:
skill target directories, the absolute data home for default locations, and telemetry
opt-outs. A client whose `OVDB_HOME` differs from the running server's recorded home, or
whose explicit `--port`/`OVDB_PORT` differs from the running server's port, MUST fail with
`server_config_mismatch` and `next` entries to unset the variable or run
`ovdb server restart` from that shell. CLI and TUI MUST connect to `127.0.0.1:<port>` and
never resolve `ovdb.localhost`.

#### REQ: authenticated-stop

`ovdb server stop` MUST call `POST /api/local/v1/server/shutdown` with the instance secret.
If the server does not answer, it MAY terminate the recorded pid only when the pid's process
start time matches `server.json`; otherwise it MUST report that it could not confirm the
process and change nothing.

#### REQ: stale-runtime-state

If `server.json` names a process that is gone or fails `whoami`, `server status` MUST report
"not running" and the next start MUST replace the runtime files (keeping `sessions.json`)
without asking.

#### REQ: version-mismatch-notice

When a client's version differs from the running server's, the client MUST print one line
`OVDB server is running version X; restart it to use version Y: ovdb server restart` and
continue; if the local API cannot serve the request it MUST fail with
`server_version_mismatch` and the same `next`.

#### REQ: auto-start

Commands that need the server MUST start it as in `background-start` when it is not running,
printing `Started the OVDB server at http://ovdb.localhost:6832` on stderr (never a login
link); with `--no-start` they MUST fail with `server_not_running` and `next`
`ovdb server start`.

#### REQ: stopped-server-copy

Stop output in CLI and TUI, and the landing page, MUST say: "Ask your AI assistant to start
OVDB again, or run `ovdb open`."

### Registry

#### REQ: registry-serving

The server MUST mount every manifest in `databases/`. A manifest that fails to mount MUST NOT
stop others; its state MUST be "needs attention" with a redacted reason in `mounts.json` and
status. Pure reads without a running server MUST report mount state as
"unknown (server not running)". Databases created or connected through the local API MUST
become available without a restart.

### Port

#### REQ: port-precedence

The port MUST resolve as `--port` > `OVDB_PORT` > `server.port` > `6832` when starting.
Clients without an explicit port MUST use the port recorded in `server.json`.

#### REQ: deterministic-port-conflict

When the port is busy, start MUST probe it with `whoami`: this home's instance → success with
"OVDB server is already running at …"; otherwise fail with `port_in_use` naming the port with
`next` entries `ovdb server start --port <N+1>` and `ovdb config set server.port <N+1>`. A
bind refused by the OS without a listener (for example a Windows reserved range) MUST fail
with `port_unavailable` ("Port 6832 isn't available on this computer"). OVDB MUST NOT choose
another port on its own; the TUI MUST offer "Use port <N+1> instead", which persists the port
after confirmation.

#### REQ: loopback-bind

Local mode MUST bind `127.0.0.1` and `::1`. If `::1` fails because IPv6 is unavailable the
server MUST continue on IPv4; if the address is in use it MUST fail as a conflict. Loopback
detection MUST use `net.SplitHostPort` and `netip.Addr.IsLoopback`, with an empty host treated
as all interfaces (not loopback).

### Authentication

| Route | Instance secret | Console session cookie | Scoped bearer token | No credential |
|---|---|---|---|---|
| `GET /login`, `POST /login` | — | — | — | allowed |
| `/.well-known/openvaultdb`, `POST /token` | allowed | allowed | allowed | allowed |
| `GET/POST /authorize` (connect consent) | — | owner approves | — | landing page with sign-in hint |
| Console and `/apps/…` pages | — | allowed | landing page | landing page |
| `/api/local/v1/…` (general) | owner | owner | `403 forbidden` | `401 unauthorized` |
| `POST /api/local/v1/server/shutdown`, `POST /api/local/v1/login-links`, project-scope `PUT /api/local/v1/context` | owner | `403 forbidden` | `403 forbidden` | `401 unauthorized` |
| `/v1/…` data API and `/v1/tokens` | owner | owner | per capabilities (tokens: `403`) | `401 unauthorized` |

#### REQ: credentials

Local mode MUST accept exactly the three credentials and routes in the table. The instance
secret is created at start in the runtime directory and sent by CLI and TUI as
`Authorization: Bearer`; clients MUST verify the instance id via `GET /api/local/v1/whoami`
before sending data, reporting "already running" or signalling a process. Scoped tokens live
in `<OVDB_HOME>/auth.json`.

#### REQ: tokens-against-local-server

With `OVDB_PREVIEW=1` and no explicit `--addr` or `--owner-token`, `ovdb token create|list|revoke`
MUST call the running local server (auto-starting it) with the instance secret. With those
flags they MUST behave as today.

#### REQ: connect-flow-in-local-mode

The existing connect flow (`/authorize`, `/token`) MUST be served in local mode. Approving on
`/authorize` MUST require a console session; without one the page MUST show the landing copy
with a sign-in hint and approve nothing. Its form posts are exempt from the JSON-body rule
but not from cross-origin protection.

#### REQ: login-links

`POST /api/local/v1/login-links` with body `{"next"?: "<same-origin path>"}` MUST return
`{"schema":1,"url","fallback_url","expires_at"}` where `url` uses `ovdb.localhost` and
`fallback_url` uses `127.0.0.1` with the same code. Codes MUST be random, single-use, valid
for 10 minutes on every allowed host, and never logged. `ovdb open` and `ovdb open
--print-url` MUST print both links; `--host 127.0.0.1` opens the fallback link. When no
browser can be launched, `ovdb open` MUST print the links and exit `0`.

#### REQ: login-exchange-on-post

`GET /login?code=` MUST have no side effects and render a minimal page that submits the code
by `POST /login` automatically (with a `noscript` Continue button). Only the POST MUST
consume the code, set the session cookie and redirect to `next` or the console. Invalid or
used codes MUST show the landing page.

#### REQ: sessions

The session cookie MUST be `HttpOnly`, `SameSite=Lax`, host-only and named
`ovdb_session_<port>`. Sessions MUST be stored hashed in `sessions.json` with a 30-day sliding
expiry and survive server restarts.

#### REQ: session-ended-copy

When a console or TODO app request gets `401`, the page MUST show "Your session ended — use
`ovdb open` or ask your AI assistant for a new link"; when the server is unreachable it MUST
show the stopped-server copy.

#### REQ: landing-page

A console or app page without a valid session MUST return a page titled "Open the console from
OVDB" explaining `ovdb open` and asking an AI assistant for a link, adding "If ovdb.localhost
didn't open, use the 127.0.0.1 link" on the fallback host, and MUST expose no data.

### Browser hardening

#### REQ: host-allowlist

In local mode every request whose `Host` (case-insensitive, no trailing dot) is not
`ovdb.localhost`, `localhost`, `127.0.0.1` or `[::1]` with the server's port MUST get `403`.

#### REQ: cross-origin-protection

In local mode, non-safe requests authenticated by the session cookie (and `POST /login`) MUST
pass Go `http.CrossOriginProtection`. Bearer-authenticated requests are not CSRF-able and MUST
be exempt. Browser apps on other origins MUST use bearer tokens and origins listed in
`server.cors`, which get CORS headers on `/v1/…` and `/token` only. GET handlers MUST have no
side effects; local API request bodies MUST be `application/json`.

#### REQ: security-headers

Every local-mode response, including `401`, `403` and the landing page, MUST send
`X-Content-Type-Options: nosniff` and `Referrer-Policy: no-referrer`. HTML responses MUST also
send `Content-Security-Policy: default-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'`
and `X-Frame-Options: DENY`. Console and apps MUST render record values as text only (no
`v-html`, enforced by lint). Only first-party embedded apps MAY be served under `/apps/`.

#### REQ: redacted-errors

Every error surfaced by the server to the CLI, TUI, web console, status, `mounts.json` or
`server.log` MUST pass a redaction layer removing URL user-info, `key=value` pairs whose key
contains `password`, `secret`, `token` or `key`, and connection-string shapes. Raw driver
errors MUST NOT leave the server unredacted. Missing environment variables MAY be named, never
their values.

### Embedded web console

#### REQ: embedded-assets

The console and TODO app MUST be built from `web/` with pnpm into a directory embedded with
`//go:embed all:dist` (tracked `.gitkeep`). A binary without assets MUST serve "The web console
isn't built into this ovdb binary" naming Homebrew and release downloads, and `ovdb demo open`
MUST say so instead of opening a blank page. Release builds MUST fail without assets.

#### REQ: route-layout

Local mode MUST route `/.well-known/openvaultdb`, `/v1/…`, `/authorize`, `/token`, `/login`,
`/api/local/v1/…`, `/apps/todo/…` and `/…` (console) with client-side route fallback.
Middleware order MUST be security headers → Host allowlist → authentication →
cross-origin protection (cookie requests) → CORS (`server.cors`, bearer requests) → routes.

## Dependencies

- first-run-onboarding
- configuration-parity

## Acceptance Criteria

### AC: legacy-serve-unchanged (verifies REQ:local-mode-only-for-new-surfaces)

**Given** `ovdb serve --manifest todo.yaml --addr 127.0.0.1:7000` without `OVDB_PREVIEW`
**When** a client calls `GET /v1/databases` with `Host: tunnel.example` and no credentials, and requests `/`
**Then** the data API answers as today, `/` is not the console, and bare `ovdb serve` fails with today's message

### AC: start-returns-to-piped-caller (verifies REQ:background-start, REQ:credentials)

**Given** no server and a caller whose stdout is a pipe, on Linux, macOS and Windows runners
**When** `ovdb server start` runs and the caller exits
**Then** control returns within 2 s of readiness, output has both addresses and "Sign in with `ovdb open`" but no login code, and a later `ovdb server status --json` in a new shell reports running after `whoami`

### AC: sandboxed-start-fails-clearly (verifies REQ:start-failure-in-restricted-environments)

**Given** an environment where the child process is killed when the calling command ends
**When** `ovdb list / --db todo` auto-starts the server
**Then** it exits `1` with `server_start_failed` and a `next` entry asking the person to run `ovdb open` or `ovdb server start` outside the sandbox

### AC: client-resolves-skill-dirs (verifies REQ:client-values-and-mismatch)

**Given** a server started from a shell with `CODEX_HOME=/x`
**When** `ovdb skills install openvaultdb --harness codex --yes` runs from a shell with `CODEX_HOME=/y`
**Then** the skill is written under `/y`

### AC: home-or-port-mismatch (verifies REQ:client-values-and-mismatch, REQ:single-server-home-lock)

**Given** a server for the default home running on 6832
**When** `OVDB_HOME=/tmp/other ovdb databases create x` runs, and `ovdb server start --port 7000` runs
**Then** both exit `1` with `server_config_mismatch` and `next` entries including `ovdb server restart`, and no second server starts

### AC: impostor-port (verifies REQ:deterministic-port-conflict, REQ:credentials, REQ:loopback-bind)

**Given** another program listening only on `[::1]:6832`
**When** `ovdb server start` runs
**Then** it exits `1` with `port_in_use` and does not serve IPv4 only

### AC: reserved-port (verifies REQ:deterministic-port-conflict)

**Given** a bind on 6832 that the OS refuses with no listener
**When** `ovdb server start` runs
**Then** it fails with `port_unavailable` and the "isn't available" copy

### AC: stop-never-kills-reused-pid (verifies REQ:authenticated-stop, REQ:stale-runtime-state)

**Given** `server.json` whose pid now belongs to an unrelated process with a different start time
**When** `ovdb server stop` and `ovdb server status` run
**Then** the unrelated process keeps running, stop reports it could not confirm the process, and status reports not running

### AC: version-mismatch-line (verifies REQ:version-mismatch-notice)

**Given** a running server of an older version
**When** `ovdb databases` runs from a newer binary
**Then** it prints the restart notice with `ovdb server restart` and still lists databases

### AC: auto-start-and-no-start (verifies REQ:auto-start)

**Given** no server running
**When** `ovdb databases create notes` runs, then the server is stopped and `ovdb databases create other --no-start` runs
**Then** the first prints the start line (no login link) on stderr and succeeds; the second exits `1` with `server_not_running`

### AC: stop-copy (verifies REQ:stopped-server-copy)

**Given** a running server
**When** `ovdb server stop` runs, and the TUI stops the server
**Then** both show "Ask your AI assistant to start OVDB again, or run `ovdb open`"

### AC: tolerant-registry (verifies REQ:registry-serving, REQ:redacted-errors)

**Given** `databases/` with a valid `todo.yaml` and a broken manifest
**When** the server starts, `ovdb status --json` runs, then the server stops and `ovdb databases --json` runs
**Then** `todo` is served and the broken database is "needs attention" with a redacted reason; after stopping, both report "unknown (server not running)"

### AC: token-against-local-server (verifies REQ:tokens-against-local-server, REQ:credentials)

**Given** `OVDB_PREVIEW=1`, a local-mode server and database `todo`
**When** `ovdb token create --db todo --scope read-only --json` runs and the token calls `GET /v1/databases/todo`, `PUT /v1/databases/todo/records/lists/x` and `GET /api/local/v1/status`
**Then** the read succeeds, the write is denied by capability, the local API returns `403 forbidden`, and `auth.json` is under OVDB home

### AC: connect-flow-needs-session (verifies REQ:connect-flow-in-local-mode)

**Given** a local-mode server and a valid connect request to `/authorize`
**When** a browser without a session opens it, then a signed-in browser approves it and the app exchanges the code at `/token`
**Then** the first shows the landing copy and approves nothing; the second yields a scoped token that works on `/v1/…`

### AC: login-link-both-hosts (verifies REQ:login-links, REQ:login-exchange-on-post)

**Given** `ovdb open --print-url --json`
**When** a link previewer fetches `GET` on the fallback link, then a browser opens the fallback link, then another browser opens the primary link with the same code
**Then** the output contains `url` and `fallback_url`; the previewer does not consume the code; the browser gets a session on `127.0.0.1`; the reused code shows the landing page

### AC: session-survives-restart (verifies REQ:sessions)

**Given** a browser signed in on `ovdb.localhost:6832`
**When** `ovdb server restart` runs and the person clicks a link to `http://ovdb.localhost:6832/apps/todo/` from another site
**Then** the cookie `ovdb_session_6832` is `HttpOnly` and `SameSite=Lax`, and the TODO app opens signed in

### AC: session-ended-shown (verifies REQ:session-ended-copy)

**Given** the TODO app open and its session removed from `sessions.json`
**When** the next poll gets `401`, and later the server is stopped
**Then** the page shows the session-ended copy, then the stopped-server copy

### AC: unauthenticated-rejected (verifies REQ:credentials, REQ:landing-page)

**Given** a local-mode server
**When** `GET /v1/databases` and `GET /api/local/v1/status` are called without credentials, `POST /api/local/v1/server/shutdown` is called with only a session cookie, and `/` is opened without a session
**Then** the first two return `401`, shutdown returns `403` and the server keeps running, and `/` shows the landing page with no data

### AC: dns-rebinding-blocked (verifies REQ:host-allowlist)

**Given** a local-mode server
**When** requests arrive with `Host: attacker.example:6832`, `Host: localhost.:6832` and no Host
**Then** each gets `403` with the security headers

### AC: cross-site-cookie-post-blocked (verifies REQ:cross-origin-protection)

**Given** a valid session cookie in the browser and `server.cors` listing `http://localhost:5173`
**When** a page on `https://evil.example` submits `POST /api/local/v1/demo/install`, and a page on `http://localhost:5173` sends `PUT /v1/databases/todo/records/lists/x` with a bearer token
**Then** the first is rejected and nothing changes; the second succeeds with CORS headers

### AC: framing-refused (verifies REQ:security-headers)

**Given** a page on another origin that embeds `http://ovdb.localhost:6832/` in an iframe
**When** Chromium loads it
**Then** the frame does not render, and the landing, `401` and `403` responses all carry the CSP, `X-Frame-Options`, `nosniff` and `Referrer-Policy` headers

### AC: dsn-never-leaks (verifies REQ:redacted-errors)

**Given** a PostgreSQL manifest whose connection string `postgres://u:s3cret@nohost/db` is in the server environment
**When** the mount fails and status, `--json`, the local API, `mounts.json` and `server.log` are inspected
**Then** neither `s3cret` nor the connection string appears anywhere

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
