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

`ovdb serve` binds `127.0.0.1:6832` by default (`DefaultAddr`), runs in the foreground,
has no PID or lock file, returns raw bind errors and requires `--manifest`, `--dir` or
`--data-dir`. Authentication (`--auth`) and CORS (`--cors`) are opt-in. Its loopback check
(`isNonLoopback`) treats an empty host (`:6832`, all interfaces) as loopback. Sneat's
Listus demo runs `ovdb serve` behind a Cloudflare tunnel.

Onboarding needs a memorable address, a server that outlives the terminal, and a trust
boundary now that a browser — which also visits hostile websites — talks to a server that
can create databases and write agent skill files. Review found the local API would
otherwise be a file-write primitive reachable by other OS accounts, containers, SSH
forwards and any cross-site trick.

## Decision

1. **Two server modes.** *Local mode* is the new per-user server started by
   `ovdb server start`, `ovdb open`, the TUI or auto-start; it serves the registry, the web
   console, the TODO app, the local API and the data API. *Legacy* `ovdb serve` with its
   flags keeps today's behaviour exactly (no console, no local API, no Host allowlist), so
   existing scripts and the Listus tunnel are unaffected.
2. **Address.** `http://ovdb.localhost:6832` (O=6 V=8 D=3 B=2). Output always also shows
   `http://127.0.0.1:6832`. Port precedence: `--port` > `OVDB_PORT` > `config.yaml
   server.port` > `6832`. Clients discover a running server's port from its runtime file.
3. **HTTP, not HTTPS**, on loopback only: bind `127.0.0.1` and `::1`. If `::1` fails
   because IPv6 is unavailable, continue on IPv4; if it fails because the port is in use,
   treat it as a conflict. Loopback detection uses `net.SplitHostPort` + `netip`; an empty
   host means all interfaces and is not loopback (fixing `isNonLoopback`).
4. **Local mode always authenticates**, for the local API and the data API:
   - At start the server creates an **instance secret** in the owner-only runtime
     directory. CLI and TUI send it as a bearer token; an authenticated
     `GET /api/local/v1/whoami` returning the instance id proves the server is ours.
   - Browsers use a **one-time login link** `http://ovdb.localhost:6832/login?code=…`
     (single use, 10-minute lifetime) printed by `ovdb server start` and `ovdb open`,
     opened by the TUI and handed out by agents. It is exchanged for an `HttpOnly`,
     `SameSite=Strict`, host-only session cookie.
   - The bare address without a session shows a friendly page: "Open the console from
     OVDB" with `ovdb open` and "ask your AI assistant for a link".
5. **Browser hardening (local mode).** Host allowlist (`ovdb.localhost`, `localhost`,
   `127.0.0.1`, `[::1]` with the port); Go `http.CrossOriginProtection` for non-safe
   methods; every response sends `X-Content-Type-Options: nosniff` and
   `Referrer-Policy: no-referrer`; HTML adds `Content-Security-Policy: default-src 'self';
   object-src 'none'; base-uri 'none'; frame-ancestors 'none'` and `X-Frame-Options: DENY`;
   record data is rendered as text only.
6. **Runtime and data locations.** Configuration in `os.UserConfigDir()/ovdb`
   (`OVDB_HOME`); runtime files (runtime record, lock, secret, log) in
   `os.UserCacheDir()/ovdb/run` (LocalAppData on Windows, not Roaming); data in `~/ovdb`
   (`OVDB_DATA_HOME`).
7. **Lifecycle.** `ovdb server start|stop|restart|status` and `ovdb open`. Start detaches
   (setsid / Windows detached process group, stdio to the log, working directory OVDB
   home) and waits for authenticated readiness. Stop is an authenticated shutdown call;
   killing by pid is a fallback only when pid *and* recorded process start time match.
8. **Deterministic ports.** A busy port is probed with `whoami`: our instance → "already
   running"; anything else → fail naming the port and the fix (`--port 6833` or
   `ovdb config set server.port 6833`). A Windows reserved-range bind failure is reported
   as "port unavailable", not "used by another program". No automatic port hopping; the TUI
   may offer a one-step "Use port 6833 instead".
9. **Auto-start.** Configuration and data commands start the server when needed, printing
   one line on stderr; `--no-start` refuses with a hint.

## Rationale

- `ovdb.localhost` needs no hosts edit in major browsers and names the product; 6832 is
  already the implemented default. Loopback HTTP is a secure context; local HTTPS needs a
  trust-store install for no confidentiality gain.
- **Authentication in local mode** is required because the local API writes files and agent
  skills: loopback is reachable by other OS accounts, containers with host networking,
  WSL and SSH forwards, and by clickjacking or XSS. A secret in an owner-only file is
  readable exactly by the processes that could read the data anyway.
- The login link (the Jupyter precedent) keeps the browser path one click from any
  terminal or agent output, and the cookie never leaves the host.
- Keeping legacy `ovdb serve` unchanged avoids breaking deployments, tunnels and scripts.
- Instance-secret proof defeats port squatting and stale-pid mistakes; recorded start time
  prevents killing a reused pid.
- Non-roaming runtime files avoid syncing pids and secrets across Windows domain profiles.
- Deterministic ports keep printed addresses and skill instructions true.

## Declined Alternatives

### Trust loopback without authentication (first draft)

Declined after review: other OS users, containers, WSL, SSH forwards and cross-site tricks
can reach loopback, and the local API can plant skill files that agents then execute.

### Verify the calling OS user

Peer credentials exist only for Unix sockets, not TCP from browsers, and are not portable.
Declined.

### Local HTTPS with a generated certificate

Trust-store changes, browser warnings when it fails, no benefit on loopback. Declined.

### Automatically choose the next free port

Breaks printed addresses and allows duplicate servers. Declined.

### Apply the new model to `ovdb serve`

Would break container deployments, reverse proxies and the Listus tunnel. Declined; local
mode is a separate entry point.

### Run the server as an OS service or login item

Needs installation privileges and per-OS packaging. Deferred beyond MVP.

## Consequences at Decision Time

- A browser visit needs a login link; the friendly landing page and `ovdb open` carry that
  usability cost, which is accepted.
- `ovdb` gains detachment code (lifted from `wb` into `strongo/cli-helpers`), runtime
  files, auth middleware and hardening headers, tested on Linux, macOS and Windows.
- Deployment guides keep `8080`; `6832` is the local default.
- Safari and Edge `*.localhost` resolution is verified manually; the IP fallback is always
  printed.

## Observed Consequences

None observed yet.

## Affected Features

- [Local server and web console](../features/local-server-and-web-console/README.md) — implements modes, auth, hardening, lifecycle and conflicts.
- [First-run onboarding](../features/first-run-onboarding/README.md) — server option, landing page and journeys.
- [Database context and navigation](../features/database-context-navigation/README.md) — data commands use the server with auto-start.
- [AI agent skills](../features/ai-agent-skills/README.md) — agents hand out login links.

---
*This document follows the https://specscore.md/decision-specification*
