---
format: https://specscore.md/plan-specification
status: Approved
---
# Plan: OVDB onboarding and configuration

**Status:** Approved
**Source:** idea:ovdb-onboarding-and-configuration
**Date:** 2026-09-17
**Owner:** alex
**Supersedes:** —

## Summary

This plan implements the onboarding, configuration and AI storage experience specified by the
idea, decisions 0006–0010 and nine features. The code goes into `openvaultdb/ovdb`, with
provider-first changes in `openvaultdb-go`, `strongo/cli-helpers` and (non-blocking) the
`dal-go` drivers. Increment 0 runs spikes S1–S8, each just before the increment that needs it.
A legacy safety net and the `openvaultdb-go` bump come next. Then increments 1a–9 each ship one
vertical slice behind `OVDB_PREVIEW=1`. Increment 10 is the founder's 24-item final
verification.

## Approach

**Slicing.** Every increment carries capability-matrix rows from
[configuration parity](../features/configuration-parity/README.md) end to end: server service →
`/api/local/v1` endpoint → CLI (`--json` = API body) → TUI screen → Vue route → tests →
parity-registry row. A capability stays hidden (preview gate, and registry `Implemented=false`)
until all three interfaces have it or an exception is cited. Increment 1 is split into 1a (CLI),
1b (browser) and 1c (TUI); parity for its rows is reached at the end of 1c. Home, Result `next`
lists and status `next` show only implemented options, always in the founder's order: Try a
demo, Create a database, Connect an existing database, Start the OVDB server. Interim Home
screens are therefore subsets, by design.

**Spikes.** A spike runs before the first increment that depends on it (spec
`REQ:increment-zero-spikes`). There are no artificial chains between spikes.

| Spike | Gates | Depends on |
|---|---|---|
| S2 detach | 1a | — |
| S3 embed, S6 copy, S7 auth | 1b (S6 also 1c) | S7: legacy safety net |
| S1 Mount/Unmount | 2 | — |
| S4 DataTug | 7 | S7 |
| S5 skillsync | 8 | — |
| S8 Safari/Edge (founder, manual) | gate removal | 1b |

**Code facts this plan builds on** (verified on `origin/main` and in review, 2026-09-17).

| Fact | Where | Consequence |
|---|---|---|
| `ovdb` is one flat `package main` (Cobra + fang) on `openvaultdb-go` v0.2.0; its only test is `token_test.go` | `ovdb/` | New code goes in `internal/…`. Legacy files stay put and gain only a preview branch. Characterization tests come first |
| v0.2.0 → v0.5.1 compiles cleanly but touches 38 files: layered ACL, policystore, principal resolver. `OwnerToken` is now "admin; database policies still apply" | `openvaultdb-go` diff | Behaviour risk for legacy `serve`/`token`, and for cookie → owner forwarding on ACL manifests |
| `server.New(version, dbs)` takes a fixed map; there is no exported Mount/Unmount; `core.Database.Close()` is a no-op, yet the SQLite mount holds a file handle | `pkg/server/server.go`, `pkg/core/core.go` | S1 upstream change, including a real Close |
| `mount.Dir` fails on the first error; the inGitDB mount runs `ensureGitIdentity` and writes `<folder>/.ovdb/inferred-schema.json` | `pkg/mount/` | S1 upstream change |
| `/authorize` and `/token` are public paths; `POST /authorize` mints a code with no owner check | `pkg/auth/middleware.go`, `pkg/server/connect.go` | Local mode returns 404 `not_supported` for both until increment 6 adds the session check |
| `POST …/query` accepts `parent`; DTQL accepts root collections only; record writes return no body | `pkg/core/query.go`, `pkg/server/records.go` | `ovdb list` of demo items works; the CLI builds `{"key"}` |
| `daemonlifecycle` has lock + `ProtectOwnerOnly`/`ValidateOwnerOnly` (exact 0700 on Unix), but no detach and no process start time | `cli-helpers` v0.12.0 | S2 upstream change; OVDB never chmods directories it did not create |
| `skillsync.Sync` reconciles every bundle of one identity; `cobracmd.DefaultHarnesses` resolves harness dirs | `cli-helpers/skillsync` | S5 |
| wb: `Setsid` / `DETACHED_PROCESS\|CREATE_NEW_PROCESS_GROUP` detach; embeds `hub/web/dist` with `.gitkeep`; its GoReleaser hook is `sh -c '…pnpm build'`, and it releases on the same `strongo/cicd` runner with no setup-node step | `sneat-dev/wb` | Lift the detach code (S2); copy the embed pattern and hook (S3 shrinks) |
| TUI: one `Model` with `currentScreen`, tested through `Update(tea.WindowSizeMsg…)`; same Charm v2 stack as fang | `ingitdb-cli/cmd/ingitdb/tui` | Same pattern, no PTY |
| specscore telemetry: `CollectOSEnvSignals`, EU endpoint, key via `-ldflags -X` | `specscore-cli/internal/telemetry` | Copy the opt-out logic; no PostHog SDK |
| `strongo/cicd` `release.yml@v1.18.0` cannot forward a `POSTHOG_KEY` secret | `strongo/cicd` | Telemetry stays "unavailable in this build" until that is added (deferred) |
| `datatug query run --db openvaultdb://<descriptor> --from <root> --as <principal> [--no-policies] --format json`; `<TokenEnv>_BASE_URL` and `_PRINCIPAL_ID` must match the descriptor | `datatug-cli` | S4 command |

**New `ovdb` layout.**
- `copy/en.json`, plus `copy/copy.go` (package `uicopy`).
- `internal/preview`.
- `internal/paths`: home, runtime and data directories; injectable for tests; owner-only only on
  directories OVDB creates. `cloud.go` keeps `os.UserConfigDir()`.
- `internal/envelope`, `internal/redact`.
- `internal/runtime`: `server.json`, secret, lock, detach, whoami, stop.
- `internal/setup`: the services.
- `internal/localserver`: middleware chain, login, sessions (sliding-expiry writes at most once
  a minute per session), landing, local API; wraps the `openvaultdb-go` handler.
- `internal/client`: typed client with auto-start.
- `internal/cli`, `internal/tui`, `internal/parity`, `internal/telemetry`.
- `skills/{openvaultdb,todo-demo}`.
- `web/`: pnpm pinned in `packageManager`; Vue 3 + TS + Vite + Tailwind; a multi-page build
  with the console at `/` and the TODO app at `/apps/todo/`; `web/routes.json` shared with the Go
  parity test; `web/embed.go`.
- `go.mod` gets `ignore ./web/node_modules`.

**Conventions for every increment.**
- *Isolation:* build first, then set
  `OVDB_PREVIEW=1 OVDB_PORT=7832 OVDB_HOME=$(mktemp -d) OVDB_DATA_HOME=$(mktemp -d) OVDB_RUNTIME_DIR=$(mktemp -d)`.
  Go tests inject directories through `internal/paths`, so `t.Parallel()` is safe. Every runtime
  test registers `t.Cleanup(stop+wait)`, which Windows temp-dir cleanup needs.
- *Commands:*
  - Go: `GOMAXPROCS=2 GOFLAGS=-p=2 go test ./...`, adding `-race` only on the touched lifecycle
    package.
  - Web: `pnpm -C web install --frozen-lockfile && pnpm -C web build && pnpm -C web test -- --maxWorkers=1`.
  - Journeys: `pnpm -C web exec playwright test --workers=1`.
  - Use `bun x`, never `bunx`.
- *Regression gate:* from increment 2 on, every increment re-runs all previously passing
  journey scripts (the partial A–D scripts are extended, never replaced) in CI.
- *CI:* the Playwright journeys are a required PR check with `retries: 1` and uploaded traces.
  `screens.spec.ts` is not in the gating job.
- *TUI:* model tests render each new screen at 80×24, 120×40, 60×20 and 50×15. For manual checks,
  run `tmux new -d -s t -x 80 -y 24 ovdb; tmux send-keys -t t …; tmux capture-pane -pt t`, then
  repeat at `-x 120 -y 40`.
- *Rendered web review:* `web/e2e/screens.spec.ts` captures every new route at 1280×800,
  1920×1080 and 360×740, in light and dark. The implementer and the reviewer look at the images.
- *VM lanes:* at most 3 lanes, ≤1 frontend build, ≤2 Go test lanes.
- *Gate:*
  - New commands, including `skills`, are `Hidden: !preview.On()`. They stay callable, but are
    not offered.
  - Changed defaults of `status`, `databases`, `databases create`, `serve` and `token` branch on
    `preview.On()`.
  - Bare `ovdb` shows today's help without the gate (golden test).
  - The console and local API exist only in local mode.
  - Skill text never mentions `OVDB_PREVIEW`. Journey C sets it in the harness environment.
- *Landing:*
  - One `wb` task per increment, including cross-repo edits such as the `openvaultdb-todo-demo`
    README. Titles use `feat(preview): …`. Land with `wb worktree land` (merge commits). Each
    merge auto-releases to Homebrew with the new surface hidden.
  - Upstream changes are merged and tagged first, then `go get module@vX.Y.Z`. Local work may use
    an untracked `go.work`, never a committed `replace`.
- *Done per increment:*
  - Every non-exception cell is tested (registry test green).
  - Journey scripts are green.
  - Screenshots and TUI captures are reviewed.
  - A fresh adversarial reviewer has signed off.
  - The work is landed and the worktree cleaned.

## Tasks

### Task 1: S1 — runtime Mount/Unmount with real Close, tolerant scan, side-effect-free mount

**Id:** spike-s1-openvaultdb-go
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:tolerant-registry, database-setup-and-providers#ac:connect-leaves-folder-untouched
**Depends-On:** —
**Status:** planning

- **Work:** an `openvaultdb-go` PR adding:
  - `(*server.Server).Mount(*core.Database) error` and `Unmount(id) error` on `s.mu`. Unmount
    waits for in-flight requests on that database, then calls a real `Close`, reached through
    `core.Database` down to the engine mount (the SQLite handle included).
  - `mount.DirReport(dir)`, which returns the databases that mounted and a per-manifest error
    map.
  - `mount.FileWithOptions(path, mount.Options{CatalogueDir, SkipGitIdentity})`.
- **Pass:**
  - `go test -race ./pkg/server/ -run Mount` passes with 50 concurrent readers during an unmount.
  - One broken manifest next to one valid manifest gives one mount and one error.
  - Connecting a Git repo leaves `git status --porcelain` empty and `.git/config` identical.
  - On `windows-latest`, `os.Rename` of a SQLite file succeeds after `Unmount`.
- **Fallback:**
  - If a safe unmount is not possible: ovdb rebuilds the handler on registry change, swaps it
    through `atomic.Pointer`, and closes the old databases after a drain.
  - If a side-effect-free inGitDB mount is not possible: change the spec first, so that connect
    discloses the `.ovdb/` catalogue before it runs.
- **Release:** `openvaultdb-go` v0.6.0, consumed in increment 2.
- **Model:** opus. **Frontend:** no.

### Task 2: S2 — detached start that returns to a piped caller, readiness, stop

**Id:** spike-s2-detach
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:start-returns-to-piped-caller, local-server-and-web-console#ac:stop-never-kills-reused-pid
**Depends-On:** —
**Status:** planning

- **Work:** a `cli-helpers` PR adding to `daemonlifecycle`:
  - `ConfigureDetached`, lifted from wb: `Setsid`; on Windows `DETACHED_PROCESS |
    CREATE_NEW_PROCESS_GROUP | CREATE_BREAKAWAY_FROM_JOB`, with no inherited handles.
  - `StartDetached`, which retries without breakaway when access is denied.
  - `ProcessStartTime(pid)`.

  The PR also adds a test-only probe binary with `whoami`, a secret file and shutdown.
- **Pass:** on ubuntu, macOS and Windows runners:
  - `probe start | reader` gives the reader EOF within 2 s of readiness, and the child's
    handles do not include the pipe.
  - A fresh process finds the probe answering `whoami`.
  - Authenticated shutdown frees the port.
  - A pid with a different start time is never signalled.
- **Fallback:** if breakaway is refused, keep the retry and rely on the `server_start_failed`
  guidance. If detach is unusable on an OS, add a hidden foreground `ovdb server run` there and
  change the spec first.
- **Release:** `cli-helpers` v0.13.0. **Model:** opus. **Frontend:** no.

### Task 3: S3 — embedded web build in the release pipeline

**Id:** spike-s3-embedded-web
**Verifies:** configuration-parity#ac:spikes-recorded
**Depends-On:** —
**Status:** planning

- **Work (half a day, reusing wb's evidence):**
  - `web/` with one page and `web/embed.go` copied from wb's `hub/web/embed.go`: `all:dist`,
    tracked `.gitkeep`, a not-built page naming Homebrew and release downloads.
  - `.goreleaser.yaml` hooks copied in wb's form: `sh -c 'command -v pnpm >/dev/null || npm i -g
    pnpm@<packageManager pin>; pnpm -C web install --frozen-lockfile && pnpm -C web build'`, then
    `sh -c 'test -f web/dist/index.html'`, after `go mod tidy -diff`. No corepack.
  - A CI job running `goreleaser build --snapshot --clean --single-target`.
- **Pass:** `go install .` from a clean clone compiles and serves the not-built page. The
  snapshot build embeds the page, and fails when `dist` is missing.
- **Fallback:** a provider-first `strongo/cicd` input `setup_pnpm`.
- **Model:** sonnet. **Frontend:** yes.

### Task 4: S4 — DataTug CLI against local mode with a read-only token

**Id:** spike-s4-datatug
**Verifies:** configuration-parity#ac:spikes-recorded, explore-data-handoff#ac:descriptor-and-command
**Depends-On:** 7
**Status:** planning

- **Work:** on the S7 prototype, with an inGitDB database seeded like the demo:
  - Mint a read-only grant in `<OVDB_HOME>/auth.json`.
  - Write the four-key descriptor.
  - Run `datatug query run --db openvaultdb://$D --from lists --as local-owner --format json`
    with `OVDB_DATATUG_TOKEN`, `…_BASE_URL` and `…_PRINCIPAL_ID` set. Record whether
    `--no-policies` is needed.
- **Pass:** it returns two rows; a write with that token is refused; the descriptor holds no
  token.
- **Fallback:** Explore data ships the honest "can't connect yet" copy plus Browse data (spec
  change first), and the fix is filed in `datatug-cli`.
- **Model:** sonnet. **Frontend:** no.

### Task 5: S5 — `skillsync` per-skill install

**Id:** spike-s5-skillsync
**Verifies:** configuration-parity#ac:spikes-recorded, ai-agent-skills#ac:install-one-skill-only
**Depends-On:** —
**Status:** planning

- **Work:** `Sync` with only the `todo-demo` bundle into a directory that already holds
  `openvaultdb` and an unrelated `specscore` skill. Try it with a shared identity, then with one
  `PluginIdentity` per skill.
- **Pass:** some configuration installs one skill with no `removed` changes, and reports
  `unchanged` on the second run. In that case no upstream change is needed.
- **Fallback:** a `cli-helpers` `Options.OnlyBundles`, released before increment 8.
- **Model:** sonnet. **Frontend:** no.

### Task 6: S6 — `copy/en.json` shared by Go and Vite

**Id:** spike-s6-copy
**Verifies:** configuration-parity#ac:spikes-recorded, configuration-parity#ac:copy-key-missing-fails
**Depends-On:** —
**Status:** planning

- **Work:** `uicopy.T(key, params)` and a Go AST test over `uicopy.T("…")` literals. On the web
  side, a Vite import of `../../copy/en.json` (`server.fs.allow`), a `t()` helper, and a Vitest
  scan of `t('…')`.
- **Pass:** both suites fail when a key is missing, and the build inlines the catalogue.
- **Fallback:** a prebuild step copies the file to `web/src/generated/` (git-ignored).
- **Model:** sonnet. **Frontend:** yes.

### Task 7: S7 — local-mode credentials, login exchange, sessions, hardening

**Id:** spike-s7-auth-hardening
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:unauthenticated-rejected, local-server-and-web-console#ac:dns-rebinding-blocked, local-server-and-web-console#ac:cross-site-cookie-post-blocked, local-server-and-web-console#ac:login-link-both-hosts
**Depends-On:** 9
**Status:** planning

- **Work:** prototype the middleware chain in the specified order:
  1. Security headers.
  2. Host allowlist (a trailing dot is rejected).
  3. Authentication: instance secret, session cookie, or scoped token.
  4. `http.CrossOriginProtection` for cookie requests and `POST /login`.
  5. CORS, for bearer requests only.
  6. Routes.

  Cookie requests to `/v1/…` are forwarded with an internal owner bearer (the handler is built
  with `WithAuth{OwnerToken: secret, Store}`). An explicit `Authorization` header wins.
  `/authorize` and `/token` return 404 `not_supported`. Login codes live in memory; sessions are
  stored hashed.
- **Pass:**
  - Go HTTP tests for the four ACs.
  - A bearer `PUT` from an allowed origin passes with CORS headers.
  - `GET /login` does not consume the code.
  - The cookie flags are right.
  - A manifest with `acl.enabled`: an owner-forwarded cookie request behaves exactly like the
    instance-secret owner. The spike note records whether database policies bind the owner; if
    they do, the spec says so before 1b.
  - Chromium: a cross-site form POST is rejected, and a cross-origin link click stays signed in.
- **Fallback:** a small `Sec-Fetch-Site`/`Origin` check with the same tests.
- **Model:** opus. **Frontend:** Playwright only.

### Task 8: S8 — founder check of `ovdb.localhost` in Safari and Edge

**Id:** spike-s8-localhost-browsers
**Verifies:** configuration-parity#ac:spikes-recorded
**Depends-On:** 11
**Status:** planning

- **Work:** a 2-minute founder check on one Mac (Safari) and one Windows PC (Edge), using a
  preview build from 1b. There is no CI job.
- **Pass:** the login link gives a signed-in console on `ovdb.localhost` and on `127.0.0.1`,
  which is still signed in after a reload and after `ovdb server restart`. Record whether a proxy
  or PAC file intercepts `ovdb.localhost`.
- **Fallback:** `ovdb open` opens `fallback_url` by default on that platform (spec change).
  Increment 10 reports this item as founder-owned.
- **Model:** — (founder). **Frontend:** no.

### Task 9: Legacy safety net and openvaultdb-go bump

**Id:** legacy-safety-net
**Verifies:** local-server-and-web-console#ac:legacy-serve-unchanged, database-setup-and-providers#ac:legacy-create-still-works, first-run-onboarding#ac:status-unchanged-without-gate
**Depends-On:** —
**Status:** planning

- **Goal:** a release built on the new `openvaultdb-go` that behaves exactly like today's `ovdb`.
- **Work:**
  1. On v0.2.0, add black-box tests in `ovdb` (`legacy_test.go`, built binary, loopback):
     - `serve --manifest` CRUD on inGitDB and SQLite fixtures.
     - `serve --auth` with `token create|list|revoke`: read allowed, write denied, revoke works.
     - `databases create --url/--addr`, `status --url`, the bare `serve` error, Host handling.
  2. In a separate `fix(deps):` commit, bump to `openvaultdb-go` v0.5.1 and keep the tests green.
     The release note covers owner-token semantics for manifests with access policies. Legacy
     manifests without policies must behave identically.
- **Tests:** `GOMAXPROCS=2 GOFLAGS=-p=2 go test -run Legacy ./...`, run before and after the bump.
- **Manual:** `ovdb serve --manifest todo.yaml` plus `curl` CRUD, on the released Homebrew build
  after merge.
- **Model:** sonnet (tests); opus reviews the ACL note. **Frontend:** no.

### Task 10: Increment 1a — A server you can start and stop from the CLI

**Id:** inc-1a-server-cli
**Verifies:** local-server-and-web-console#ac:start-returns-to-piped-caller, local-server-and-web-console#ac:stop-never-kills-reused-pid, local-server-and-web-console#ac:impostor-port, local-server-and-web-console#ac:reserved-port, local-server-and-web-console#ac:runtime-files-private-and-local, local-server-and-web-console#ac:existing-dirs-not-chmodded, local-server-and-web-console#ac:dns-rebinding-blocked, configuration-parity#ac:error-envelope-shape, configuration-parity#ac:usage-error-exits-one, configuration-parity#ac:endpoints-authenticated
**Depends-On:** 2, 9
**Status:** planning

- **Result:**
  - Commands: `ovdb server start|stop|restart|status [--json]`, `ovdb status [--json]` (preview),
    `ovdb open --print-url` (prints both links), `ovdb config get|set server.port`.
  - Browsing to the address shows a Go-rendered landing page.
  - `/authorize` and `/token` return 404 `not_supported`.
- **Rows:** CLI cells of 2, 3, 4, 5, 6, 7 (hidden until 1b and 1c).
- **Code:**
  - `internal/{preview,paths,envelope,redact,runtime,client,cli,parity}`, `copy/` (seeded), and
    `internal/localserver` with the instance secret, headers, Host allowlist, `whoami`, `status`,
    `shutdown`, `login-links`, `config`, and the `openvaultdb-go` handler over an empty map.
  - `cli-helpers` v0.13.0.
  - A preview branch in `status.go`.
  - A hidden test-only variable `OVDB_TEST_START_FAULT` makes the child exit before readiness,
    for `server_start_failed`.
- **CI:** a `go-os-matrix` job (ubuntu, macOS, windows) running
  `go test ./internal/runtime/... ./internal/paths/...`.
- **Tests:**
  - Runtime: piped start with EOF, stale `server.json`, reused pid, `[::1]` impostor, injected
    reserved-port error, fault injection → `server_start_failed` with sandbox `next`, existing
    0755 directories.
  - HTTP: credential table for the local API; `/authorize` and `/token` 404; headers on 401/403.
  - Envelope goldens.
  - CLI: `--json` byte-equal to the API; unknown flag → `invalid_argument`, exit 1.
- **Manual:** isolation; `ovdb server start | cat` (returns, no code printed); `ovdb server status
  --json`; `ovdb server stop` (a server already running on the default port makes the next check
  fail with `server_config_mismatch` instead of a real port conflict); `python3 -m http.server
  7833` then `OVDB_PORT=7833 ovdb server start` → both fixes;
  `curl -i -H 'Host: attacker.example:7832' http://127.0.0.1:7832/` → 403 with headers;
  `ovdb server stop` → stopped copy; `ovdb --help` without the gate is unchanged.
- **Cross-platform:** LocalAppData runtime, Windows reserved ranges, `::1` missing in containers.
- **Model:** opus. **Frontend:** no.

### Task 11: Increment 1b — Sign in from the browser; console Home and server status

**Id:** inc-1b-web-console
**Verifies:** local-server-and-web-console#ac:login-link-both-hosts, local-server-and-web-console#ac:unauthenticated-rejected, local-server-and-web-console#ac:framing-refused, configuration-parity#ac:copy-key-missing-fails, configuration-parity#ac:ci-runs-matrix
**Depends-On:** 10, 3, 6, 7
**Status:** planning

- **Result:** `ovdb open` launches the browser (print-only fallback). `GET /login` renders an
  auto-POST page; `POST /login` sets the session. The console shows Home with the status line and
  the options implemented so far, the **OVDB server** panel, Settings (port for next start), and
  session-ended and stopped copy.
- **Rows:** web cells of 2, 4, 7 (E1 for 3 and 6, E2 for 5).
- **Code:** S7 middleware hardened into `internal/localserver` (sessions hashed, writes
  throttled); `web/` from S3 and S6 (console shell, Home, Server, Settings); `web/routes.json`; a
  `web` CI job (build, Vitest, Playwright Chromium, `retries: 1`).
- **Tests:** HTTP login on both hosts and code reuse; Vitest for Home, Server and Settings;
  Playwright `smoke.spec.ts` (landing, link, Home, iframe refused) and `screens.spec.ts`.
- **Manual:** `ovdb open --print-url`; open both links at 1280×800 and 1920×1080 in light and
  dark; reuse a code (landing); change the port in Settings, then `ovdb config get server.port`.
- **Cross-platform:** browser launch through `xdg-open`, `open` and `rundll32`.
- **Model:** opus for login/sessions; sonnet for Vue. **Frontend:** yes.

### Task 12: Increment 1c — TUI Home, server and settings

**Id:** inc-1c-tui-home
**Verifies:** first-run-onboarding#ac:tty-launches-tui, first-run-onboarding#ac:tui-sizes, first-run-onboarding#ac:problem-shows-why-and-fix, local-server-and-web-console#ac:stop-copy, configuration-parity#ac:missing-cell-fails, configuration-parity#ac:gate-hides-incomplete
**Depends-On:** 10, 6
**Status:** planning

- **Result:** `OVDB_PREVIEW=1 ovdb` in a terminal opens Home (status line, Start the OVDB server,
  Settings). The OVDB server screen covers start, stop, restart and Open in browser. Settings
  covers the port, with "Use port N+1 instead" on conflict. Piped `ovdb` prints status and the
  implemented `next` entries.
- **Rows:** TUI cells of 1–7. This completes parity for rows 2–7, and the registry test is
  enforced from here on.
- **Code:** `internal/tui` (root model and screens Home, Server, Settings, Result, Problem), a
  root `RunE` gated by preview and TTY checks, and the parity registry with the route, screen,
  command and endpoint existence test.
- **Tests:** TUI model tests at four sizes; a golden test for help without the gate; the registry
  test (drop a web route → failure naming row and interface); `ovdb --help` hides the new
  commands without the gate.
- **Manual:** tmux at 80×24 and 120×40: Home → OVDB server → start → Open in browser → stop
  (stopped copy); occupy the port → Problem screen → Use port 7833.
- **Model:** sonnet. **Frontend:** no. Runs in parallel with 1b (one Go lane and one frontend
  lane).

### Task 13: Increment 2 — Create, list and remove databases

**Id:** inc-2-create-databases
**Verifies:** database-setup-and-providers#ac:catalogue-matches-binary, database-setup-and-providers#ac:pinned-then-alphabetical, database-setup-and-providers#ac:postgres-is-manifest-only, database-setup-and-providers#ac:create-refuses-overwrite, database-setup-and-providers#ac:sqlite-points-to-schema, database-setup-and-providers#ac:remove-keeps-data, local-server-and-web-console#ac:tolerant-registry, local-server-and-web-console#ac:auto-start-and-no-start, local-server-and-web-console#ac:home-or-port-mismatch, local-server-and-web-console#ac:version-mismatch-line, local-server-and-web-console#ac:dsn-never-leaks, first-run-onboarding#ac:result-lists-next-actions, configuration-parity#ac:cli-json-matches-api
**Depends-On:** 1, 11, 12
**Status:** planning

- **Result:**
  - Commands: `ovdb engines`, `ovdb databases` (preview, from state files + `mounts.json`),
    `ovdb databases create`, `ovdb databases remove`.
  - TUI and web: **Create a database** (filterable picker, name, location, Result) and
    **Databases**. Manifest-only engines show the manifest steps.
  - Auto-start and `--no-start` for every command that needs the server.
- **Rows:** 8, 9, 11, 12; Home gains Create.
- **Code:** `openvaultdb-go` v0.6.0; `internal/setup/{engines,registry,create,remove}`
  (catalogue derived from the manifest parser); `DirReport` at startup; `mounts.json`;
  redaction everywhere, including `server.log`; home/port mismatch and version notice in
  `internal/client`; preview branches in `databases.go` and `databases_create.go`.
- **Tests:** service tests (id regex, `already_exists`, `location_not_empty`, SQLite
  schema-first `next`); redaction table plus an unreachable-DSN PostgreSQL manifest checked in
  status, JSON, API, `mounts.json` and log; CLI JSON = API; TUI filter; Vitest picker; Playwright
  `create.spec.ts`; the journey regression gate starts.
- **Manual:** isolation; `ovdb databases create notes` (start line on stderr), then again →
  `already_exists`; TUI Create → filter `sql` → SQLite Result; PostgreSQL shows manifest steps;
  web Create `web1` at 1280×800 and 360 px; stop the server → `ovdb databases` shows unknown;
  `remove notes --yes` keeps the data.
- **Cross-platform:** Windows paths; SQLite released on unmount.
- **Model:** opus for registry, mount and redaction; sonnet for presentations. **Frontend:** yes.

### Task 14: Increment 3 — Project context, data commands, Browse data

**Id:** inc-3-context-and-data
**Verifies:** database-context-navigation#ac:use-is-project-scoped, database-context-navigation#ac:walk-up-outside-git, database-context-navigation#ac:worktree-is-own-project, database-context-navigation#ac:precedence-ladder, database-context-navigation#ac:no-context-error, database-context-navigation#ac:cd-examples, database-context-navigation#ac:escaped-ids-round-trip, database-context-navigation#ac:data-commands-auto-start, database-context-navigation#ac:list-kinds, database-context-navigation#ac:only-database-is-named, database-context-navigation#ac:add-set-get-delete, database-context-navigation#ac:kind-mismatch-hint, database-context-navigation#ac:strict-mode-error, database-context-navigation#ac:browse-own-data, database-context-navigation#ac:tui-and-web-select-database, database-setup-and-providers#ac:create-ingitdb-default, local-server-and-web-console#ac:sandboxed-start-fails-clearly, first-run-onboarding#ac:returning-user-summary
**Depends-On:** 13
**Status:** planning

- **Result:**
  - Commands: `ovdb use`, `cd`, `pwd`, `list|ls`, `get`, `set`, `add`, `delete|rm`. Writes print
    the path, or `{"key"}` with `--json`.
  - TUI: Browse data and Use in this project. Web: Browse data and Use as default (E3).
  - The returning-user Home summary line appears.
- **Rows:** 13, 14, 15, 16 (E4), 17 (E5).
- **Code:** `internal/setup/context` (Git root or cwd, hashed keys, walk-up, ladder); `GET/PUT
  /api/local/v1/context`; `internal/cli/path` (`record.EscapeID`, `%` check); data commands
  over `/v1`; `databases remove` clears contexts; web `/browse/:db/*`; TUI `browse`; ESLint
  `vue/no-v-html`. Test fixture: a database with the demo's paths.
- **Tests:** `cd` and escaping tables; context tests on the OS matrix (symlinks, drive letters,
  worktrees); CLI stdout/stderr split, `{"key"}`, unchanged `/v1` error bodies; SQLite
  `schema_required`; fault-injected auto-start from `ovdb list`; TUI Browse paging; Vitest text
  rendering; Playwright `browse.spec.ts`; partial Journey A (no telemetry) and Journey C (no
  skill).
- **Manual:** `git init /tmp/p && mkdir /tmp/p/src && cd /tmp/p/src && ovdb use notes`; `ovdb add
  /items '{"title":"Hello"}'`; `ovdb add /items '{}' --json`; `ovdb list /items`; `ovdb cd /items
  && ovdb pwd`; `ovdb get /items` (hint); TUI 80×24 Browse; web Browse at 1920×1080, Use as
  default; Home summary in all three.
- **Model:** sonnet; opus reviews context scope. **Frontend:** yes.

### Task 15: Increment 4 — Built-in TODO demo and TODO app

**Id:** inc-4-todo-demo
**Verifies:** todo-demo#ac:fresh-install-creates-data, todo-demo#ac:reinstall-keeps-changes, todo-demo#ac:conflicting-todo-refused, todo-demo#ac:non-interactive-needs-yes, todo-demo#ac:open-starts-server-and-app, todo-demo#ac:app-edits-items, todo-demo#ac:agent-change-appears-in-app, todo-demo#ac:item-text-is-not-html, local-server-and-web-console#ac:session-ended-shown, local-server-and-web-console#ac:session-survives-restart, local-server-and-web-console#ac:not-built-fallback, local-server-and-web-console#ac:routes, first-run-onboarding#ac:web-keyboard-and-contrast
**Depends-On:** 14
**Status:** planning

- **Result:** `ovdb demo install|open|status`. TUI and web **Try a demo** with a Result offering
  Open TODO app and Done; skill and explore entries arrive in increments 7 and 8.
  `/apps/todo/` shows both lists with add, tick and delete, 3 s polling and refresh on focus,
  plus "Stored in …".
- **Rows:** 18, 19; Home gains Try a demo.
- **Code:** `internal/setup/demo`; `GET /api/local/v1/demo`, `POST …/demo/install`; login `next`
  → `/apps/todo/`; `web/apps/todo/` (second Vite entry sharing the client and copy components);
  `openvaultdb-todo-demo` README ("connect-flow example; superseded as first-run demo") in the
  same wb task.
- **Tests:** service idempotence and conflict; CLI `--yes`; TUI; Vitest (text rendering, poll,
  401 and network copy); Playwright `todo.spec.ts`:
  - keyboard-only edits;
  - `ovdb add` appears within 3 s;
  - `<img onerror>` stays text;
  - session removed and server stopped copy;
  - session survives restart;
  - cross-site cookie POST to `demo/install` rejected (cookie half only);
  - axe check at 360 and 1280 px.

  Also: the not-built binary test for `demo open`.
- **Manual:** piped `ovdb demo install` → `confirmation_required`; TUI Try a demo → Open TODO
  app; tick Milk in the browser; `ovdb add /lists/to-watch/items '{"title":"Arrival","done":false}'
  --db todo` appears; `ovdb server stop` → stopped copy; screenshots at 1280×800, 1920×1080 and
  360 px.
- **Model:** sonnet. **Frontend:** yes.

### Task 16: Increment 5 — Connect an existing folder, SQLite file or manifest

**Id:** inc-5-connect-existing
**Verifies:** database-setup-and-providers#ac:connect-leaves-folder-untouched, database-setup-and-providers#ac:connect-postgres-manifest, database-setup-and-providers#ac:result-next-actions, local-server-and-web-console#ac:dsn-never-leaks, first-run-onboarding#ac:home-shows-options
**Depends-On:** 13
**Status:** planning

- **Result:** `ovdb databases connect <id> --engine --path` and `--manifest <abs>`. TUI and web
  **Connect an existing database** completes the four Home options. `ovdb init --help` lists all
  five engines.
- **Rows:** 10, 10a.
- **Code:** `POST /api/local/v1/databases/connect` using `FileWithOptions{CatalogueDir:
  <OVDB_HOME>/catalogues/<id>, SkipGitIdentity: true}`; manifest copied with absolute paths;
  `storage_unavailable` naming a missing `dsn_env`; `init.go` help. Upstream, non-blocking:
  `dalgo2postgres` and `dalgo2mysql` stop putting the DSN in errors.
- **Tests:** Git repo fixture untouched; `x.sqlite` text file rejected; manifest with and
  without `CRM_DSN` plus redaction; TUI and Vitest forms; Playwright `connect.spec.ts`.
- **Manual:** connect a cloned inGitDB repo → `git status` clean; `ovdb init --engine postgres
  --id crm2` + connect without the variable → names `CRM_DSN` and shows no secret; web Connect at
  1280×800; Home shows all four options in order.
- **Model:** opus. **Frontend:** yes.

### Task 17: Increment 6 — Tokens, CORS origins and the connect flow

**Id:** inc-6-tokens-and-apps
**Verifies:** local-server-and-web-console#ac:token-against-local-server, local-server-and-web-console#ac:connect-flow-needs-session, local-server-and-web-console#ac:cross-site-cookie-post-blocked
**Depends-On:** 13
**Status:** planning

- **Result:** with the gate, `ovdb token create|list|revoke` go to the local server and
  `<OVDB_HOME>/auth.json`. `ovdb config set server.cors`. `/authorize` and `/token` are enabled,
  and approval requires a console session.
- **Rows:** 25 (E7).
- **Code:** preview branch in `token.go` (explicit `--addr`/`--owner-token` keep today's path);
  `server.cors` → `ParseCORSOrigins`; `/authorize` session wrapper, which replaces the 404.
- **Tests:** HTTP tests for the three ACs (bearer + CORS half included); CLI tests for both token
  paths; Playwright `connect-flow.spec.ts`.
- **Manual:** `ovdb token create --db notes --scope read-only --json` → `curl` read works, write
  is denied, local API returns 403; run `openvaultdb-todo-demo` with `ovdb config set server.cors
  http://localhost:5173` and approve in a signed-in browser.
- **Model:** opus. **Frontend:** no Vue build.

### Task 18: Increment 7 — Explore data hand-off to DataTug

**Id:** inc-7-explore-data
**Verifies:** explore-data-handoff#ac:menu-asks-intent-first, explore-data-handoff#ac:demo-explore-copy, explore-data-handoff#ac:descriptor-and-command, explore-data-handoff#ac:datatug-missing, explore-data-handoff#ac:datatug-app-is-honest
**Depends-On:** 4, 15, 17
**Status:** planning

- **Result:** `ovdb explore`, `explore datatug-cli`, `explore datatug-app`. TUI and web
  **Explore data** (intent first, copy actions, demo copy). Results and Home gain Explore data.
- **Rows:** 22.
- **Code:** `internal/setup/explore`: `LookPath("datatug")` in the client; descriptor under
  `<OVDB home>/explore/datatug/`; commands plus environment-variable lines for the shell family
  of the OVDB process's `runtime.GOOS` (sh, or PowerShell on Windows), with no other detection;
  S4 findings baked in. `GET /api/local/v1/explore/datatug?db=`.
- **Tests:** four-key descriptor with no token; datatug missing; CLI `--json`; TUI and Vitest
  menus; Playwright `explore.spec.ts`, which asserts the DataTug.app honesty copy and that no
  "open database" control exists (`toHaveCount(0)`); an opt-in real `datatug` test.
- **Manual:** demo installed; `ovdb explore --db todo`; run the printed token and
  `datatug query run` commands; web DataTug.app page at 1280×800.
- **Model:** sonnet. **Frontend:** yes.

### Task 19: Increment 8 — Storage skill and TODO AI skill

**Id:** inc-8-agent-skills
**Verifies:** ai-agent-skills#ac:skill-less-agent-learns-options, ai-agent-skills#ac:storage-skill-text, ai-agent-skills#ac:todo-skill-maps-requests, ai-agent-skills#ac:install-one-skill-only, ai-agent-skills#ac:web-cannot-target-arbitrary-dir, ai-agent-skills#ac:agent-cannot-install-silently, ai-agent-skills#ac:ui-shows-targets-before-install, local-server-and-web-console#ac:client-resolves-skill-dirs, todo-demo#ac:next-actions-after-install, first-run-onboarding#ac:agent-gets-next-not-prompt, first-run-onboarding#ac:status-covers-whole-setup, configuration-parity#ac:journey-c-passes, configuration-parity#ac:journey-d-passes
**Depends-On:** 5, 15, 18
**Status:** planning

- **Result:** `ovdb skills list` and `ovdb skills install <openvaultdb|todo-demo>`, hidden under
  the gate. TUI and web **AI agent skills** plus the consent step after the demo and after
  create/connect. `ovdb status --json` lists all five bootstrap `next` entries.
- **Rows:** 20, 21 (E6).
- **Code:**
  - `skills/openvaultdb/SKILL.md`: nine instructions, including `--json` writes and `{"key"}`;
    no mention of the gate.
  - `skills/todo-demo/SKILL.md`.
  - `internal/setup/skills` with S5's configuration.
  - The client resolves directories through `cobracmd.DefaultHarnesses`; the server accepts only
    known layouts, or a CLI `--dir` under home.
- **Tests:** skill text; one-skill install next to an unrelated skill; API refuses a `dir` field;
  `--dir /etc/x` refused; non-TTY without `--yes`; `demo install --yes` installs no skill; TUI and
  Vitest consent screens; Journey C (`OVDB_PREVIEW=1`, stdin closed, `CLAUDECODE=1`); Journey D in
  Playwright.
- **Manual:** isolation with `HOME=$(mktemp -d)` and `~/.claude`; TUI Try a demo → Install TODO
  AI skill → exact directory shown; a live Claude Code session: "add bananas and coffee to my
  shopping list" with the app open at 1280×800; a skill-less agent relays `ovdb status --json`.
- **Model:** opus for install targets and skill text; sonnet for UI. **Frontend:** yes.

### Task 20: Increment 9 — Opt-in telemetry with parity

**Id:** inc-9-telemetry
**Verifies:** telemetry-consent#ac:nothing-sent-by-default, telemetry-consent#ac:enable-then-disable, telemetry-consent#ac:client-env-wins, telemetry-consent#ac:unavailable-build, telemetry-consent#ac:non-tty-enable-needs-confirmation, telemetry-consent#ac:prompt-once-equal-choices, telemetry-consent#ac:buffer-flushed-or-dropped, telemetry-consent#ac:allowlist-enforced, telemetry-consent#ac:channel-derived, telemetry-consent#ac:events-delivered-within-bound, first-run-onboarding#ac:telemetry-question-is-late-and-once, configuration-parity#ac:journey-a-passes, configuration-parity#ac:journey-b-passes
**Depends-On:** 19
**Status:** planning

- **Result:** `ovdb telemetry status|enable [--confirmed-by-user]|disable`. TUI and web Settings →
  Usage statistics. One prompt after the first success. A build without a key says "unavailable
  in this build".
- **Rows:** 23, 24 (E6).
- **Code:**
  - `internal/telemetry`: closed structs, opt-out copied from specscore, channel detection, and
    a synchronous `net/http` batch POST to the EU endpoint with a 2 s bound.
  - The key comes from `-ldflags` via `{{ if isEnvSet "POSTHOG_KEY" }}`.
  - Buffers: TUI in memory; the web page posts its buffer only after Turn on.
  - `GET/PUT /api/local/v1/telemetry` and `POST …/telemetry/events`.
  - Instrumentation in increments 1–8.
- **Tests:** allowlist with hostile inputs; `httptest` recorder for nothing-by-default, flush,
  drop, client `DO_NOT_TRACK` and the 2 s bound; non-TTY enable; TUI and Vitest prompt-once; full
  Journeys A and B.
- **Manual:** dev build with the key and endpoint set by `-ldflags`, pointed at a 10-line recorder
  that answers 200 and prints bodies. TUI first success → No thanks → nothing sent; web Turn on
  → buffered events arrive; `DO_NOT_TRACK=1 ovdb telemetry status` names the reason; disable
  removes the install id.
- **Model:** sonnet for UI and wiring; opus for allowlist and sender. **Frontend:** yes.

### Task 21: Increment 10 — Final verification, adversarial review, fixes, re-run

**Id:** inc-10-final-verification
**Verifies:** configuration-parity#ac:tests-per-capability, configuration-parity#ac:journey-a-passes, configuration-parity#ac:journey-b-passes, configuration-parity#ac:journey-c-passes, configuration-parity#ac:journey-d-passes
**Depends-On:** 8, 16, 17, 18, 19, 20
**Status:** planning

Run on a snapshot release build and on the Homebrew build from the last merge, on Linux (VM),
macOS and Windows. Evidence goes to `~/.wb/reports/ovdb-onboarding-final/`. The founder's
checklist, verbatim, with how each item is verified:

| # | Founder item (verbatim) | Verification |
|---|---|---|
| 1 | Run the relevant automated test suites. | `go test ./...` (ovdb and touched providers), CI OS matrix, Vitest, Playwright journeys |
| 2 | Build the Go binaries. | `goreleaser build --snapshot --clean` (sequential); `go install .` from a clean clone |
| 3 | Build and verify the embedded Vue application. | Release binary serves `/`, `/apps/todo/` and hashed assets; `go install` binary shows the not-built page |
| 4 | Verify no Node runtime is required after build. | Journeys re-run with `node`, `pnpm` and `bun` removed from `PATH` |
| 5 | Exercise representative onboarding from a clean/unconfigured state. | Fresh `HOME`, `OVDB_HOME`, `OVDB_DATA_HOME`, runtime dir: TUI Home; piped `ovdb` → five `next` entries |
| 6 | Verify CLI/TUI/Web configuration parity. | Registry test; `tests-per-capability` report; manual walk of rows 1–25 in all interfaces |
| 7 | Verify `http://ovdb.localhost:6832`. | Chrome and Firefox on the default port; S8 founder result for Safari and Edge; fallback link |
| 8 | Verify configurable/fallback behaviour around port conflicts. | Foreign listener, `[::1]` impostor, own server, reserved range, `config set server.port`, TUI "Use port" |
| 9 | Verify inGitDB onboarding. | Create, connect an existing repo untouched, add/list/get, readable files |
| 10 | Verify SQLite onboarding. | Create → schema-first Result; `schema_required`; connect an existing file |
| 11 | Verify provider discovery/filtering. | `ovdb engines` order, filter `sql`, manifest-only honesty, manifest connect |
| 12 | Verify `ovdb use`. | Project scope, walk-up, worktree, global default from web, precedence ladder, returning-user summary |
| 13 | Verify hierarchical context and relative/absolute paths required by the implemented scope. | All `cd` examples, escaping, `Nothing here yet`, `{"key"}` reuse |
| 14 | Verify TODO demo installation/start. | Idempotent install, conflict refusal, `demo open` auto-start, next actions in TUI and web |
| 15 | Verify **To buy** and **To watch** through the Web app. | Keyboard edits, CLI change within 3 s, text-only rendering, session and stopped copy |
| 16 | Verify TODO AI skill installation/integration to the extent supported by the environment. | Consent step, one-skill install, live agent adds bananas and coffee |
| 17 | Verify **Explore data** correctly leads to DataTug CLI/DataTug.app choices. | Menu, demo copy, descriptor, real `datatug query run`, DataTug.app honesty |
| 18 | Verify PostHog is disabled before consent. | Recorder receives nothing before Turn on; no install id |
| 19 | Verify telemetry status and enable/disable behaviour across CLI/TUI/Web. | Same state, reason and lists in all three; channel values |
| 20 | Verify no sensitive database information is accidentally included in telemetry. | Allowlist test plus inspection of captured payloads |
| 21 | Review usability/readability of actual CLI, TUI and Web outputs. | Fresh reviewer reads outputs, TUI captures (80×24, 120×40) and screenshots (1280×800, 1920×1080, 360) against the copy principles |
| 22 | Run a final adversarial review against the approved specifications and implementation plan. | Independent opus reviewer (security, parity, cross-platform), plus a second model if available |
| 23 | Fix valid findings rather than merely listing them. | Accepted findings fixed in their own commits; spec updated when behaviour changes |
| 24 | Re-run affected tests after fixes. | Items 1–21 re-run; founder report with evidence, S8 as founder-owned, and a gate-removal proposal |

- **Model:** opus (reviewers); sonnet (evidence). **Frontend:** Playwright only.

## Deferred and Simplified

**Deferred (not in MVP).**

| Item | Spec reference |
|---|---|
| Removing `OVDB_PREVIEW` (separate founder-approved change) | first-run-onboarding `REQ:preview-gate` |
| Login item or OS service; no-terminal cold start | decision 0007; local-server Open Questions |
| Web console stop/restart; record editing in TUI and web | parity E2, E5 |
| `ovdb skills uninstall`, skill refresh after self-update, marketplace publication | ai-agent-skills Open Questions |
| DataTug run-now, DataTug.app OVDB route, nested DTQL for demo items | explore-data-handoff |
| Guided connect for Firestore, MySQL and PostgreSQL; remote servers as contexts | database-setup Open Questions; decision 0008 |
| Per-storage-folder lock; local HTTPS; log rotation | local-server; decision 0007 |
| `ovdb demo reset`; list sharing in the TODO app | todo-demo Open Questions |
| PostHog key in releases (`POSTHOG_KEY` + `strongo/cicd` forwarding) | founder answer; telemetry `unavailable` |
| Crash reports as a separate opt-in channel | telemetry-consent Open Questions |
| inGitDB "with Git history" copy depending on `git` being installed | database-setup Open Questions |
| Languages beyond English; SQLite schemaless | first-run and idea Open Questions |
| wb consuming the detach code from `cli-helpers` | S2 follow-up |

**Deliberate simplifications.**
1. Menus and `next` lists show only implemented options, in the founder's order.
2. Local-mode auth wraps the unchanged `openvaultdb-go` handler: cookie requests are forwarded as
   the owner, and `/authorize` is gated in `ovdb`.
3. Login codes live in memory; session sliding-expiry writes are throttled to at most one per
   minute per session.
4. Test isolation uses the hidden `OVDB_RUNTIME_DIR` and injectable paths.
5. S5 may make the `skillsync` upstream change unnecessary.
6. Journey A is automated as a TUI model script plus CLI assertions, with no PTY.
7. `web/routes.json` feeds both the Vue router and the Go parity test (no YAML matrix).
8. The `dal-go` DSN fix is non-blocking behind the redaction layer and its test.
9. One Vite multi-page build serves the console and the TODO app.
10. The connect-flow consent page keeps `openvaultdb-go`'s HTML, gated by a session.
11. `{"key"}` uses the CLI's absolute path, which differs from the `/v1` `get` body `key` (no
    leading slash).
12. Explore commands use the shell family of the OVDB process's OS, with no further detection.

## Plan Review History

**Round 1 (2026-09-17).** Reviewers: Claude Opus (feasibility and risk; checked code and upgraded
a scratch `ovdb`) and Claude Sonnet (parity, tests and scope; traced every REQ and AC). Both
said ready with fixes. Verdicts reconciled by the architect.

| Finding | Verdict | Change |
|---|---|---|
| `/authorize`, `/token` unguarded in local mode from increment 1 to 6 (O) | Accepted | 404 `not_supported` until increment 6, with a test |
| Increment 1 too large; horizontal foundation (O, S) | Accepted | Split into 1a CLI, 1b browser, 1c TUI; parity at the end of 1c |
| Spikes over-serialized; spec said "all first" (O) | Accepted | Spikes run before their dependent increment; spec wording changed |
| v0.2.0 → v0.5.1 changes legacy behaviour untested (O) | Accepted | Legacy safety net first; bump alone as `fix(deps):`; ACL owner note |
| GoReleaser hook not shell-wrapped; corepack risk (O) | Accepted | `sh -c` hook from wb; pnpm pinned, no corepack; S3 shrunk |
| Unmount cannot close SQLite; Windows locks (O) | Accepted | Real Close in S1; Windows rename check |
| S2 measured the wrong thing; no sandbox fixture; ACs using later commands (O) | Accepted | Pipe-EOF criterion; hidden fault-injection variable; ACs moved |
| Test isolation through `HOME` is slow and fragile (O) | Accepted | Hidden `OVDB_RUNTIME_DIR` (spec) and injectable paths |
| Owner-only chmod of existing directories (O) | Accepted | Never chmod existing directories; warn; refuse the secret in a shared runtime dir (spec) |
| S8 CI job over-engineered (O) | Accepted | Founder manual check, reported in increment 10 |
| Session write churn, no-Host test, skills gate, CORS half, flaky gate, recorder (O minors) | Accepted | Throttled writes; test dropped (AC reworded); skills hidden; CORS half in 6; `retries: 1`; 200 recorder |
| Returning-user Home unresolved (S) | Accepted | Same Home plus summary line (spec `REQ:returning-user-home`) |
| Home order undocumented (S) | Accepted | Founder order and web rationale recorded in the spec and here |
| 24-item checklist not verbatim (S) | Accepted | Verbatim table in increment 10 |
| No journey regression gate between increments (S) | Accepted | Every increment from 2 re-runs prior journey scripts |
| DataTug.app honesty not asserted; OS-specific commands unscoped; two open questions dropped (S) | Accepted (OS commands modified) | Playwright assertion; `runtime.GOOS` shell family only; both questions deferred |

**Implementation amendments (2026-09-17, increment 1a).** Findings from building increment 1a,
folded back into the spec and this plan:

| Finding | Change |
|---|---|
| Task 10's manual port-conflict check ran against an already-running server and got `server_config_mismatch` instead of `port_in_use` | Manual steps stop the server first (this task, above) |
| `config set` had no path to persist the TUI's "Use port N+1 instead" remedy when the server itself cannot start | Decision 0006 gets a narrow direct-write exception to the single-transport rule |
| `/api/local/v1/status` did not cover capability 4 (server status) on its own | `configuration-parity` endpoint table gains `GET /api/local/v1/server` |
| `/authorize` and `/token` in local mode, before increment 6, needed their error shape pinned down | `local-server-and-web-console` clarifies they return `404` in the existing `/v1` shape, not the new envelope |
| `server.json`'s process field is an opaque process-identity token, not a raw process start time (unreliable to compare across platforms) | `local-server-and-web-console` Locations table, `REQ:authenticated-stop` and its AC renamed accordingly |
| The status document is built up field group by field group across increments | `first-run-onboarding` `REQ:status-command` notes increment 1a ships only version, locations, server and `next` |
| S5 confirmed `skillsync` needs one `Sync` call per skill with its own `PluginIdentity`, no upstream change | `ai-agent-skills` `REQ:install-with-skillsync` clarified (no behaviour change) |

**Implementation amendments (2026-09-17, increments 1b/1c).** Findings from building the browser
sign-in flow and the TUI Home screen, folded back into the specs and this plan:

| Finding | Change |
|---|---|
| S7's ACL manifest check confirmed database access-control policies bind the owner under `openvaultdb-go` v0.5.1+, not only scoped tokens | `local-server-and-web-console` `REQ:credentials` and `database-setup-and-providers` `REQ:connect-with-manifest` state it |
| The credential table's "owner" grant for console sessions on the general `/api/local/v1/…` row would let a browser session write `server.cors` and manage tokens, which parity exception E7 reserves for the CLI | `local-server-and-web-console` gains `REQ:console-session-write-restrictions` (403 `forbidden` with a CLI `next`) |
| Browsers do not isolate cookies by port, so the planned 30-day sliding session cookie would leak across any local server sharing a fallback host (`127.0.0.1`, `localhost`, `[::1]`) | `REQ:sessions` splits by host: 30-day sliding on `ovdb.localhost`, 8-hour absolute non-renewing on fallback hosts; decision 0007 gets an Observed Consequence |
| There was no way to end a session from the browser | `POST /logout` + "Sign out" added (`REQ:logout`, routed, and in the endpoint table) |
| TUI and web each risked computing Home's status line and option order themselves | `GET /api/local/v1/home` added to the endpoint table, returning ordered options (`label_key`, `web_label_key`, `description_key`, `badge`) and `next` |
| The `server` document lacked the `next` list `status` already carries, and `config`'s `PUT` gave no signal whether a write changed anything | `server` document now carries `next`; `PUT /api/local/v1/config` response carries `changed` |
| The CSP allowed form submission to non-`self` origins, and authenticated responses had no cache directive | CSP gains `form-action 'self'`; `Cache-Control: no-store` added to `/api/local/v1/…` and authenticated HTML |
| Home's "Start the OVDB server" description was static text that stayed accurate only while stopped | Its description is now state-dependent (stopped vs running), driven by `description_key` |

**Implementation amendments (2026-09-17, increment 2).** Findings from building create, list,
remove and the database registry, folded back into the specs and this plan:

| Finding | Change |
|---|---|
| Returning users had no way back to their database list from Home; it only appeared under Browse data | `first-run-onboarding` `REQ:returning-user-home` adds a **Databases** option to the secondary group once at least one database is registered |
| A manifest edited by hand, or a manifest-only engine dropped straight into `databases/`, had no way to take effect short of a full server restart | `database-setup-and-providers` gains `REQ:reload-database` (`ovdb databases reload <id>\|--all`); `configuration-parity` gains matrix row 12a and its endpoints |
| Mounting every manifest before the listener started meant one slow or hanging database delayed every request, including `whoami` | `local-server-and-web-console` `REQ:registry-serving` now starts the listener first and mounts in the background, one per-database deadline each |
| A database whose storage had been deleted out from under OVDB (folder or SQLite file gone) was indistinguishable from a broken manifest, and a careless fix could recreate it silently | `REQ:registry-serving` states missing storage as its own "needs attention" case that is never recreated |
| Nothing stopped a new database's location from landing inside `OVDB_HOME`, the runtime directory, or another database's own storage | `database-setup-and-providers` gains `REQ:create-refuses-unsafe-locations` (`invalid_argument`, naming the conflict) |
| SQLite's schema-first next step left a person with an empty manifest and no working example to edit | Creating SQLite now declares a placeholder `example` collection; the next step is edit the manifest, then `ovdb databases reload <id>` |
| Firestore/MySQL/PostgreSQL's spec already pointed at "Connect with a manifest file", a command that does not exist until increment 5 | `REQ:manifest-only-engines-are-honest` now says "put the manifest in `<OVDB_HOME>/databases` and run `ovdb databases reload <name>`" until guided connect ships |
| Id uniqueness (`already_exists`) was untested against case variants, and two ids differing only by case would otherwise collide on case-insensitive filesystems | `REQ:create-new-database`/`REQ:create-never-overwrites` state the comparison is case-insensitive |

**Implementation amendments (2026-09-17, increment 3).** Findings from building project
context, the data commands and Browse data, and from the upstream hardening that landed
alongside them (`openvaultdb-go` v0.6.2, `dalgo2ingitdb` v0.6.1), folded back into the specs
and this plan:

| Finding | Change |
|---|---|
| `list`/`get --json` had no way to hand a record's own address back to an agent without it parsing text | `database-context-navigation` JSON table adds a CLI-computed absolute `path` field to each record, alongside the untouched `key`/`data`; resolves the plan's open question |
| Nothing stopped a project context from being written at `$HOME` or a filesystem root, where every folder below would share it | `database-context-navigation` `REQ:use-sets-scoped-context` refuses it (`invalid_argument`); decision 0008 gains an Observed Consequence |
| `cd` on the "only registered database" rung had no way to persist that choice for later commands | `REQ:cd-validates-syntax-not-existence` has `cd` save a project context the first time, saying `Saved as the project context for {dir}.` |
| `cd` could not sensibly move within a database supplied by `--db` or `OVDB_DATABASE`/`OVDB_PATH` (no directory to update) | `REQ:cd-validates-syntax-not-existence` states `cd` fails there, suggesting `OVDB_PATH` |
| Project-context path hashing folded case on Windows only; macOS's default file systems also ignore case | `REQ:use-sets-scoped-context` states the hash folds case on both |
| A stored project context whose database was later deregistered failed lookup outright instead of falling through | `REQ:context-lookup` skips it with a stderr notice and continues to the next rung |
| Decoded ids could contain relative-path components (`%2E%2E%2F%2E%2E%2Fsecrets`) that were syntactically escaped but unsafe, and a bad `OVDB_PATH` silently resolved to `/` | `REQ:path-resolution` and `REQ:context-lookup` reject empty/`.`/`..` parts and control characters, and an unparsable `OVDB_PATH`, with `invalid_argument` |
| A missing record printed a friendly "nothing here yet" for human `get`/`list` but `not_found`/exit 1 for `--json`, and `delete` of a missing record always "succeeded" | `REQ:get-set-add-delete` states a missing record exits `1` in both modes; `delete` needs `--if-exists` to treat a missing record as success |
| `openvaultdb-go`'s own key-segment check (upstream `harden-record-keys`) found the same escaped-`..` gap at the server, now `400 invalid_key`, and query results on nested collections return full keys (`lists/to-buy/items/x`) instead of a parent-less key | `database-context-navigation` maps `invalid_key` to `invalid_argument`; `configuration-parity`'s error table gains the code; the CLI/TUI/web prefer the server's full key and still compose one from an older server |
| inGitDB's own path containment (`dalgo2ingitdb`) is lexical (`filepath.Rel`/`filepath.IsLocal`), not symlink-resolving, inside a database's storage folder | Recorded as a known limitation under decision 0008's Observed Consequences, not a blocker |

**Implementation amendments (2026-09-17, increment 4).** Findings from building and reviewing
the TODO demo (`ovdb` PR #16), folded back into the specs and this plan:

| Finding | Change |
|---|---|
| A database counted as "the TODO demo" whenever it sat in a folder named `demos/<id>`, so a user's own database at such a path was mistaken for the demo, and `demo install` reported success against it without writing anything | `todo-demo` `REQ:demo-install-idempotent` states the demo is only the database a `demo install` recorded in `<OVDB_HOME>/demos.json` |
| A concurrent `demo install` returned `already_installed` before the winner had seeded, so a loser could read empty lists right after a `200` | `REQ:demo-install-idempotent` requires install requests to be serialized |
| Reinstalling into a folder left behind by `ovdb databases remove todo` (data kept) was refused as non-empty, with no way forward short of a second copy | `REQ:demo-install-idempotent` has it reconnect and serve that folder instead |
| Journey D's example ("add bananas and coffee to my shopping list") already matches the shared seed, so it added nothing new and the AC passed vacuously | `configuration-parity` `REQ:journey-d-todo-demo` and `AC:journey-d-passes` use items not in the seed (Tea, Arrival), matching the shipped test; decision 0010 gains an Observed Consequence |
| The companion `openvaultdb-todo-demo` README (superseding note, decision 0010 point 5) advertised `demo install`/`demo open` and the connect flow before any released `ovdb` shipped them | Recorded in decision 0010's Observed Consequences: the README must name the shipping release and hold back the connect-flow sentence until increment 6, and has not landed yet |

**Implementation amendments (2026-09-17, increment 5).** Findings from building and reviewing
connect for an existing inGitDB folder, SQLite file or manifest (`ovdb` PR #18), folded back
into the specs and this plan:

| Finding | Change |
|---|---|
| Guided connect had shipped, but `REQ:manifest-only-engines-are-honest` and its AC still described the pre-increment-5 "put the manifest in `<OVDB_HOME>/databases` and reload" fallback as the next step | Both now say the next step is **Connect with a manifest file** (`ovdb databases connect --manifest`) unconditionally |
| Any readable folder connected as inGitDB, including a code project's own Git repository with no `.ingitdb/`; a first write then committed into the person's branch | `database-setup-and-providers` `REQ:connect-existing-storage` refuses a folder engine `ingitdb` with no `.ingitdb/` (including an empty folder) as `invalid_argument`, pointing at Create or the real `.ingitdb` folder |
| A connected SQLite file's manifest declared a table only when the table had an `id` column, but the whole file (including undeclared tables and columns) stayed readable, and `ID` in upper case was not detected | `REQ:connect-existing-storage` states this: no qualifying table is `schema_required`; the case-sensitivity gap and whole-file readability are recorded as known limitations the Result must disclose |
| Connecting an inGitDB folder adds `.git/dalgo2ingitdb/transaction.lock`, which the spec's "no file added or changed" AC did not allow for, and the original test fixture pre-mounted the repo so the gap was invisible | `AC:connect-leaves-folder-untouched` now allows that one file; `REQ:connect-existing-storage` records it as a known `dalgo2ingitdb` limitation |
| A YAML merge key under `storage`/`acl_store` could make the location the checks read and the location the mount used disagree | `REQ:connect-with-manifest` requires both to be derived from the decoded, typed manifest and to be re-checked equal before registering |
| A manifest with `acl.enabled: true` and no `acl_store` pointed at policy files relative to the manifest's own folder, which the copy under `databases/` does not have | `REQ:connect-with-manifest` refuses it as `unsupported`, suggesting an `acl_store` folder instead |
| Concurrent connects of the same storage under different ids could all succeed before the second overlap check ran | `REQ:connect-existing-storage` requires the overlap check to run again under the registry lock immediately before registering |
| A write to a Git-backed database with no git identity returned a bare local API `500`; the human-facing `git_identity_missing` code and its `503` status had no place in the shared error table | `configuration-parity`'s `storage_unavailable` row gains `git_identity_missing` |

**Implementation amendments (2026-09-17, increment 6).** Findings from building and reviewing
tokens, CORS origins and the local-mode connect flow (`ovdb` PR #17), folded back into the
specs and this plan:

| Finding | Change |
|---|---|
| The spec said `server.cors` origins get CORS on `/v1/…` and `/token`, but did not say a `/token` request carrying the session cookie is a CSRF-protected write, not a CORS one, so the credentials table's "allowed" for a console session there read as unconditional | `local-server-and-web-console` `REQ:cross-origin-protection` and `REQ:route-layout` state CORS on `/token` is for credential-less code exchanges only |
| `/token` returns a bearer secret but had no `Cache-Control: no-store`, unlike every other secret-bearing local response | `REQ:security-headers` adds it |
| `/authorize` used `openvaultdb-go`'s library consent page, whose inline stylesheet the CSP blocks; `redirect_uri` accepted any `https`/`http` URL including one with userinfo or a fragment, shown and followed as given | `REQ:connect-flow-in-local-mode` states OVDB renders its own consent page and validates `redirect_uri` (https, or http to loopback, no userinfo, no fragment) before consent renders and before any redirect |
| The consent page listed raw capability ids with no explanation, and a database-scoped connect request could carry the server-level `databases:create` capability, which can never do anything on a database-scoped grant | `REQ:connect-flow-in-local-mode` requires plain-language capability labels and refuses `databases:create` on a `db`-scoped request before consent, matching `token create --db … --scope create-db` |
| `<OVDB_HOME>/auth.json`'s owner-only protection relied only on the home directory's ACL inheritance on Windows (an open question since increment 1b) | `REQ:owner-only-state` requires an explicit reprotect at start and after every write; the Open Question is resolved |
| Connect-flow tokens' one-hour expiry (`openvaultdb-go`'s `auth.TokenTTL`) was implied by the library but not stated for OVDB's own connect flow | `REQ:connect-flow-in-local-mode` states it |
| `ovdb token create\|list\|revoke`'s local-server path was documented for "no explicit `--addr` or `--owner-token`" without saying an `OVDB_OWNER_TOKEN` variable alone does not select the legacy path, unlike the matching database-create rule | `REQ:tokens-against-local-server` states it, cross-referencing `database-setup-and-providers` |

**Implementation amendments (2026-09-17, spike S4).** DataTug CLI against a local-mode server
with a read-only token passed on all three pass criteria (`scratchpad/spike-s4.md`); findings
folded back into `explore-data-handoff`:

| Finding | Change |
|---|---|
| A fresh machine or agent has no `~/.datatug/policies`, so the plain `datatug query run` command the spec described would fail immediately with "No access policies loaded" before reaching OVDB | `REQ:prepare-datatug-cli-connection` requires the printed command to always include `--no-policies` |
| The descriptor's `principalId`/`--as` match is a `datatug-cli`-side destination-binding convention checked entirely inside `datatug-cli`; OVDB accepts the token regardless of `--as` | `REQ:prepare-datatug-cli-connection` states OVDB does not validate a principal, so copy must not imply it does |
| `datatug-cli`'s own `--from` also builds only a root-collection reference; a `/`-containing value silently returns `{"records":[]}` instead of an error, indistinguishable from a genuinely empty collection | The "What DataTug can do" table and External dependencies gain this as a `datatug-cli` follow-up (not an OVDB defect) |
| A revoked or expired token and a genuine DTQL policy denial both surface from `datatug-cli` as the same bare `Dalgo access denied.`, with no way to tell them apart | Recorded as a `datatug-cli` follow-up in External dependencies |

**Implementation amendments (2026-09-17, increment 7).** Findings from building and reviewing
Explore data hand-off to DataTug (`ovdb` PR #20, review-inc-7.md, verdict LAND-AFTER-FIXES, all
eleven findings fixed before landing), folded back into `explore-data-handoff` and
`configuration-parity`:

| Finding | Change |
|---|---|
| `ovdb explore datatug-app` reused the TODO demo's sign-in-link copy, so every database's DataTug.app screen — demo or not — claimed to open "the TODO app with this sign-in link" instead of naming DataTug.app (F1) | `REQ:honest-datatug-app-state` requires its own copy keys, never the demo's |
| `datatug` was checked on the detached server's `PATH`, not the CLI/TUI process's own, so a PATH difference between the shell that started the server and the shell running the command told people to install something they already had, with no fix short of a server restart (F2) | `REQ:prepare-datatug-cli-connection` requires the CLI/TUI to check their own process's PATH and override the server's answer; the web (no client process) keeps the server's check, worded "the PATH the OVDB server sees" |
| Every non-demo database's DataTug CLI/DataTug.app menu description rendered as the option's own label repeated back, because the description key returned was the label key, not a help key; the AC's own example (`notes`) failed as written (F3) | `REQ:intent-first-menu` requires real "what works today" copy for non-demo databases |
| The TUI hard-wrapped printed commands with a bare inserted newline (no shell continuation), corrupting a pasted command — including breaking a quoted descriptor path mid-string — and a single long unwrapped line blew up the whole screen's apparent width; neither TUI nor web offered a copy action (F4) | `REQ:prepare-datatug-cli-connection` requires display-only truncation (never hard-wrap) plus a copy action: TUI `c` (OSC 52) and a web copy button |
| Every database defaulted to `--from lists`, which silently returns `{"records":[]}` for any non-demo database's real root collection — datatug-cli's own `--from` builds only a root-collection reference, so a mismatched or nested name comes back empty, never an error (F5, matching spike S4) | New `REQ:safe-collection-default`: demo defaults to `lists`; one root collection defaults to it; several or none requires `--collection` naming the real choices; a `/`-containing value is refused up front (datatug-cli#256) |
| The demo Result's Explore data action had no TUI key; with no current database, Explore data reached the menu with a blank database name and then a bare "no database registered" Problem; the menu's third choice ("Back") was Esc/a page link only, not a real option in either surface (F6) | `REQ:intent-first-menu` requires a "Choose a database to explore first" problem instead of ever reaching the menu blank |
| A `--collection` or database value was interpolated into printed sh/PowerShell commands unquoted, so a name containing shell metacharacters could corrupt the printed (never executed) command (F7) | `REQ:prepare-datatug-cli-connection` requires shell-quoting for both shells |
| `ovdb explore --db nope --json` exited `0` with a full menu for a database that was never registered, unlike `datatug-cli --db nope`'s own `not_found` (F8) | `REQ:intent-first-menu` requires `not_found`, exit `1` |
| `GET /api/local/v1/explore/datatug` wrote the descriptor file on a safe/cacheable HTTP method, reachable by a plain cross-site top-level navigation carrying the session cookie (F9) | The endpoint is `POST`; `configuration-parity`'s endpoint table updated |
| The DataTug CLI JSON document had no `schema` field, unlike the Menu and DataTug.app documents (F10) | `REQ:prepare-datatug-cli-connection` requires `"schema": 1` |
| The env-var block's own token line pointed at a command printed below it (F11) | `REQ:prepare-datatug-cli-connection` reorders: token command, then env vars, then query command |

**Implementation amendments (2026-09-17, increment 8).** Findings from building and reviewing
AI agent skills (`ovdb` PR #21, review-inc-8.md, verdict LAND-AFTER-FIXES, all eleven findings
fixed before landing; merged with increment 7 — 18 conflicts resolved), folded back into
`ai-agent-skills` and `first-run-onboarding`:

| Finding | Change |
|---|---|
| `encoding/json` matches field names case-insensitively, so a session body spelled `"Targets"` slipped past an exact-key `"targets"` refusal and installed into an arbitrary existing directory outside the person's home (F1, founder hard constraint) | `REQ:install-targets-restricted` requires strict decoding (`DisallowUnknownFields`) into only `skill`/`harnesses`/`dry_run` for a session, and each resolved target to equal the directory the server itself computes for that harness |
| The storage skill's text told agents to run `ovdb telemetry …`, a command increment 9 had not shipped yet, so a build with the skill installed but without telemetry gave agents a nonsense error to relay (F2) | Recorded here, not as a spec change: the shipped skill text temporarily read "never turn on usage statistics", restored to the real commands once increment 9 landed (`ai-agent-skills#REQ:storage-skill-content` item 8 already specified the restored form) |
| `ovdb status` resolved skills from the server's own environment (the shell that first started it), while `ovdb skills list` always used the caller's, so an agent whose `HOME`/`CLAUDE_CONFIG_DIR`/`CODEX_HOME` differed from that shell was told a skill was installed when it was not, or the reverse (F3) | `first-run-onboarding` `REQ:status-command` and `AC:status-covers-whole-setup` state `--json` equals the API status body except the client-resolved skills group |
| An installed skill an older `ovdb` shipped, or one the person edited since install, had no distinct state; installing over an edited copy failed as a generic `storage_unavailable` (F2 update-available, F7 changed-since-install) | New `ai-agent-skills` `REQ:skill-states`: `not_installed`/`installed`/`update_available`/`changed`/not-OVDB's-folder, `already_exists` on a changed target, `--replace-changed` (consent again) to override |
| Local Playwright runs without CI's explicit env lost `OVDB_E2E_BIN`, and the e2e temp HOME did not neutralise agent-harness env vars (`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, `DSH_HOME`, `JUNIE_HOME`, `GEMINI_CLI_HOME`), risking a developer's real agent config being written to (F4, F5) | Test-harness fixes only, no spec change |
| A dry run's next step named the real install command instead of implying nothing would happen; skill-install `next` entries other than `status` lacked "(ask the person first)"; TUI Settings showed the configured port, not the port the server actually uses; a home reached through a symlink got a misleading "outside your home" message (F8, F9, F10, F11) | Copy/UI fixes matching existing spec wording, no spec change |

**Implementation amendments (2026-09-17, early final verification, `ovdb` PR #23).** Two
defects found running the 24-item verification checklist before increment 9, folded back:

| Finding | Change |
|---|---|
| Defect A: non-interactive bare `ovdb` printed the whole `ovdb status` output (starting with "Start the OVDB server") instead of the five-entry bootstrap list `first-run-onboarding#REQ:bare-ovdb-non-interactive` already specified | No spec change (the spec was already correct); `first-run-onboarding#REQ:bare-ovdb-non-interactive` gains one sentence distinguishing it from `ovdb status`'s fuller, filtered list |
| Defect B: `ovdb databases create --engine ingitdb` never created `.ingitdb/` (`dalgo2ingitdb` writes it lazily, on the first record write), so a database created and removed from OVDB (data kept) before any write looked identical to a plain Git repository and failed to connect again | `database-setup-and-providers` `REQ:create-new-database` requires create to provision `.ingitdb/` itself |

**Implementation amendments (2026-09-17, increment 9 phase A, `ovdb` PR #22, branch
`ovdb-inc-9-telemetry`, open — not yet landed).** Findings from the adversarial privacy review
(review-inc-9a.md, verdict FIXES-NEEDED; F1–F9 all fixed on the branch before this fold except
the release-wiring gap F8, which is not an `ovdb` code change), written here as requirements
ahead of landing since the source PR is still open:

| Finding | Change |
|---|---|
| A TUI session's pre-consent buffer was sent at exit whenever telemetry had become `enabled` on disk through another process (for example an agent relaying consent in another terminal) while the session was open, not only by that session's own Turn on (F1) | `telemetry-consent` `REQ:pre-consent-buffer` requires release only by that same session's own Turn on |
| Disabling GeoIP enrichment does not stop the sending process's real IP address reaching PostHog; copy called the statistics "anonymous" and said addresses are "never collected" without qualifying this (F2) | New `telemetry-consent` `REQ:ip-handling-and-release-precondition`; decision 0009 gains an Observed Consequence; copy no longer says "anonymous" unqualified |
| An agent harness attaching a pseudo-terminal to `ovdb telemetry enable` passed the terminal-prompt path, even though channel detection already recognised it as `agent` (F3) | `telemetry-consent` `REQ:enable-requires-a-person` requires the non-terminal `--confirmed-by-user` path whenever the sending process's channel is `agent`, terminal or not |
| An instance-secret caller could set the recorded deciding `channel` to any value including `web`, so the stored channel is not independent evidence for bearer callers (F4) | Recorded in decision 0009 as a known limitation of self-reported channel, not fixed (cryptographically unenforceable, as the decision already states) |
| CI detection matched only the literal `true` for several variables, missing `TF_BUILD=True`, `JENKINS_URL`, etc. (F5) | Implementation-only fix (broader truthy/presence matching), no spec change |
| Human `next` output for `telemetry status` suggested `ovdb telemetry enable --confirmed-by-user` — the relay flag — instead of the prompting form (F6) | Implementation-only fix (the flag stays in `--json`/non-TTY `next` only), no spec change |
| `ovdb telemetry disable` failed outright (not merely fail-closed) when `config.yaml` was unparseable, instead of always working (F7) | `telemetry-consent` `REQ:enable-requires-a-person` requires `disable` to rewrite only the `telemetry` section or refuse naming the file to fix |
| `.github/workflows/release.yml` does not forward a `POSTHOG_KEY` secret to the goreleaser build env, so a release build ships key-less until a shared `strongo/cicd` change forwards release secrets (same gap as `specscore-cli`'s `POSTHOG_WRITE_KEY`) (F8) | Recorded as a release precondition in decision 0009 and `telemetry-consent#REQ:ip-handling-and-release-precondition`, not an `ovdb`-repo code change |
| The allowlist test enumerated event constructors by hand, so a new constructor for an existing event name would not automatically be exercised (F9) | Implementation-only test-quality fix, no spec change |

## Open Questions

- Risks to watch: agent sandboxes that kill detached children; Node image changes in the
  release runner; TUI copy width at 80×24 with long commands.

Resolved: "Should `ovdb get --json` also normalize `key` to the absolute path for symmetry
with `{"key"}`, at the cost of breaking "`/v1` body unchanged"?" — increment 3 added a
CLI-computed `path` field alongside the untouched `key`/`data` instead, keeping the `/v1` body
promise while giving `set`/`add`/`delete`-style symmetry (implementation amendments below).

---
*This document follows the https://specscore.md/plan-specification*
