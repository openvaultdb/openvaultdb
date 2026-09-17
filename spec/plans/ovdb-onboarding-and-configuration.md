---
format: https://specscore.md/plan-specification
status: Draft
---
# Plan: OVDB onboarding and configuration

**Status:** Draft
**Source:** idea:ovdb-onboarding-and-configuration
**Date:** 2026-09-17
**Owner:** alex
**Supersedes:** —

## Summary

Implements the onboarding, configuration and AI storage experience specified by the idea,
decisions 0006–0010 and nine features, in `openvaultdb/ovdb` plus provider-first changes in
`openvaultdb-go`, `strongo/cli-helpers` and (non-blocking) `dal-go` drivers. Increment 0 runs
spikes S1–S8; increments 1–9 each ship one vertically complete slice (service + local API +
CLI + TUI + web console, or a cited exception) behind `OVDB_PREVIEW=1`; increment 10 is the
founder's 24-item final verification.

## Approach

**Slicing.** Every increment adds matrix rows from
[configuration parity](../features/configuration-parity/README.md) end to end: server service →
`/api/local/v1` endpoint → CLI command (`--json` = API body) → TUI screen → Vue route → tests →
parity-registry row. Home menus and `next` lists are filtered by the registry's
`Implemented` flag, so no interface ever offers an option that does not work yet. The first
runnable result is increment 1 (start the server, see Home in the terminal and the browser).

**Code facts this plan builds on (verified on `origin/main`, 2026-09-17).**

| Fact | Where | Consequence |
|---|---|---|
| `ovdb` is one flat `package main` (Cobra + fang), depends on `openvaultdb-go` v0.2.0 | `ovdb/main.go`, `go.mod` | New code goes to `internal/…`; legacy command files stay at the root and gain only a preview branch |
| `server.New(version, dbs)` takes a fixed map; runtime add exists only inside `POST /v1/databases` (`s.mu`, `createMu`); no exported Mount/Unmount | `openvaultdb-go/pkg/server/server.go`, `databases_create.go` | S1 upstream change |
| `mount.Dir` returns on first error; inGitDB mount calls `ensureGitIdentity` and writes `<folder>/.ovdb/inferred-schema.json` | `pkg/mount/mount.go`, `git_identity.go` | S1 upstream change |
| `auth.Config{OwnerToken, Store}` + `auth.OpenStore(path)`; `/authorize`, `/token` are public paths; `POST /authorize` approves with no owner check | `pkg/auth/middleware.go`, `pkg/server/connect.go` | Instance secret = `OwnerToken`; `auth.json` path is just an argument; ovdb wraps `/authorize` with the session check |
| `POST …/query` accepts `parent` (nested listing works); DTQL accepts root collections only | `pkg/core/query.go` | `ovdb list` of demo items works; DataTug items stay a follow-up |
| `PUT/POST/PATCH/DELETE …/records/{key}` return no body (204/201) | `pkg/server/records.go` | CLI builds `{"key"}` for writes |
| `daemonlifecycle` has `TryLock/Lock/Unlock`, `ProtectOwnerOnly`, `ValidateOwnerOnly`; no detach or process start time | `strongo/cli-helpers` v0.12.0 | S2 upstream change |
| `skillsync.Sync(ctx, Config{CLI, Bundles}, Options{Dir, DryRun})` reconciles all bundles of one identity (can report `removed`); `cobracmd.DefaultHarnesses` resolves harness dirs | `cli-helpers/skillsync` | S5 decides per-bundle install |
| wb detaches with `Setsid` (unix) and `DETACHED_PROCESS|CREATE_NEW_PROCESS_GROUP` (windows, no breakaway); embeds `hub/web/dist` with `.gitkeep`, not-built page, goreleaser `before` hook `corepack enable pnpm && pnpm build` + `test -f` | `sneat-dev/wb/internal/process/detach_*`, `hub/web/embed.go`, `.goreleaser.yml` | Lift into cli-helpers (S2) and copy the embed pattern (S3) |
| TUI pattern: one `Model` with `currentScreen`, constructed with width/height, tested by calling `Update(tea.WindowSizeMsg…)` directly | `ingitdb-cli/cmd/ingitdb/tui/model.go`, `model_test.go` | Same pattern, no PTY |
| specscore telemetry: `CollectOSEnvSignals` (spec-zero, `DO_NOT_TRACK`, CI), EU endpoint constant, key via `-ldflags -X` | `specscore-cli/internal/telemetry/optout.go`, `usage.go` | Copy the opt-out logic (internal package, not importable); no PostHog SDK per spec |
| `ovdb` releases through `strongo/cicd` `release.yml@v1.18.0` (ubuntu, GoReleaser `release --clean`), no Node setup step and no way to forward a `POSTHOG_KEY` secret | `ovdb/.github/workflows/release.yml`, `strongo/cicd` | S3 checks runner Node/corepack; telemetry key wiring deferred |
| DataTug: `datatug query run --db openvaultdb://<descriptor> --from <root collection> --as <principal> [--no-policies] --format json` | `datatug-cli/apps/datatugapp/commands/cmd_query.go` | S4 command |

**`ovdb` package layout (new).** `copy/en.json` + `copy/copy.go` (package `uicopy`, embeds the
file; Vite imports `../copy/en.json`); `internal/preview` (gate); `internal/paths` (OVDB home,
runtime, data home, owner-only atomic writes via `daemonlifecycle`); `internal/envelope`
(codes, HTTP status, `/v1` mapping, `next`); `internal/redact`; `internal/runtime`
(`server.json`, secret, `home.lock`, detached start, whoami probe, stop);
`internal/setup` (services: status, registry, engines, create/connect/remove, context, demo,
skills, explore, telemetry state, config); `internal/localserver` (middleware chain, login,
sessions, landing, `/api/local/v1`, wraps `openvaultdb-go` `server.Handler()`, serves
`web/dist`); `internal/client` (typed local API client + auto-start, used by CLI and TUI);
`internal/cli` (new Cobra commands, registered from `addRootCommands`); `internal/tui`;
`internal/parity` (registry + tests); `internal/telemetry`; `skills/{openvaultdb,todo-demo}`
(embedded); `web/` (pnpm, Vue 3 + TS + Vite + Tailwind; multi-page build: console at `/`, TODO
app at `/apps/todo/`; `web/routes.json` shared by the Vue router and the Go parity test;
`web/embed.go` with `//go:embed all:dist`).

**Conventions for every increment.**

- *Isolation for tests and manual runs* (the runtime directory has no override in the spec,
  so isolate through the OS cache variable):
  ```sh
  export OVDB_PREVIEW=1 OVDB_PORT=7832
  export OVDB_HOME=$(mktemp -d) OVDB_DATA_HOME=$(mktemp -d) XDG_CACHE_HOME=$(mktemp -d)  # macOS: HOME=$(mktemp -d); Windows: LOCALAPPDATA
  GOMAXPROCS=2 GOFLAGS=-p=2 go build -o "$PWD/.try/ovdb" . && export PATH="$PWD/.try:$PATH"
  ```
- *Go tests:* `GOMAXPROCS=2 GOFLAGS=-p=2 go test ./...` (lifecycle: add `-race` on the touched
  package only). *Web:* `pnpm -C web install --frozen-lockfile && pnpm -C web build &&
  pnpm -C web test -- --maxWorkers=1`; journeys `pnpm -C web exec playwright test --workers=1`
  (global setup builds nothing; it starts `.try/ovdb` with the isolation variables).
  Use `bun x` never `bunx`.
- *TUI model tests* render every screen the increment adds at 80×24, 120×40, 60×20 and 50×15
  (`internal/tui/sizes_test.go` table). *Manual TUI:*
  `tmux new -d -s t -x 80 -y 24 ovdb && tmux send-keys -t t <keys> && tmux capture-pane -pt t`
  (repeat with `-x 120 -y 40`).
- *Rendered web review:* `web/e2e/screens.spec.ts` saves screenshots of every route the
  increment adds at 1280×800, 1920×1080 and 360×740, light and dark, to
  `web/test-results/screens/`; the implementer and the reviewer look at them (not only at the
  DOM assertions).
- *VM lanes:* at most 3 concurrent lanes, ≤1 frontend build lane, ≤2 Go test lanes.
- *Gate:* new commands `Hidden: !preview.On()` (callable when hidden); changed defaults of
  `status`, `databases`, `databases create`, `serve`, `token` branch on `preview.On()` at the top
  of `RunE` and keep today's code path otherwise; bare `ovdb` keeps today's help without the
  gate (golden test). The web console and local API exist only in local mode (`ovdb server
  start`/auto-start), so released binaries change nothing for non-preview users.
- *Landing:* one `wb` task per increment; `feat(preview): …` PR titles; land with
  `wb worktree land` (merge commits). Each merge auto-releases to Homebrew with the surface
  hidden. Upstream changes land and are tagged first, then `go get module@vX.Y.Z` in `ovdb`;
  local development may use an untracked `go.work`, never a committed `replace`.
- *Definition of done per increment:* all non-exception cells of its matrix rows implemented
  and tested (registry test green), its journeys' partial scripts green, rendered screens and
  TUI captures reviewed, an adversarial reviewer (fresh agent, reads code and screenshots)
  signed off, landed, worktree cleaned.

**Spec housekeeping.** Before increment 1, set the nine features and the idea to Approved and
their `Source Ideas`; record spike results in configuration parity (AC `spikes-recorded`); move
features to Implementing as their first increment lands.

## Tasks

### Task 1: S1 — openvaultdb-go upgrade, runtime Mount/Unmount, tolerant scan, side-effect-free mount

**Id:** spike-s1-openvaultdb-go
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:tolerant-registry, database-setup-and-providers#ac:connect-leaves-folder-untouched
**Depends-On:** —
**Status:** planning

- **Work:** (a) `ovdb` on `openvaultdb-go` v0.5.1: `go get …@v0.5.1`, fix compile/test breaks in
  `serve.go`, `token.go`, `databases_create.go`, `cloud.go`. (b) `openvaultdb-go` PR:
  `(*server.Server).Mount(*core.Database) error` and `Unmount(id) error` reusing `s.mu`
  (unmount closes the database after in-flight requests on it finish, e.g. a per-database
  `sync.WaitGroup`); `mount.DirReport(dir) (map[string]*core.Database, map[string]error)`;
  `mount.FileWithOptions(path, mount.Options{CatalogueDir string, SkipGitIdentity bool})`.
- **Pass:** (a) `go test ./...` green in `ovdb` on v0.5.1, legacy `serve` AC
  `legacy-serve-unchanged` script green; (b) `go test -race ./pkg/server/ -run Mount` with 50
  concurrent readers during unmount passes; a broken manifest next to a valid one yields one
  mount + one error; connecting a Git repo with records leaves `git status --porcelain` empty
  and `.git/config` byte-identical.
- **Fallback:** (a) upgrade breaks → pin the newest compatible tag and file the gap; (b) safe
  unmount not achievable → ovdb rebuilds `server.New(...).Handler()` on each registry change and
  swaps it through `atomic.Pointer[http.Handler]`, closing old databases after a 30 s drain;
  side-effect-free inGitDB mount not achievable → change the spec first (connect discloses the
  `.ovdb/` catalogue before confirming).
- **Release:** `openvaultdb-go` minor tag (v0.6.0), then `ovdb` consumes it in increment 2.
- **Model:** opus. **Frontend:** no. **Lane:** Go.

### Task 2: S2 — detached start, authenticated readiness and stop on Linux, macOS, Windows

**Id:** spike-s2-detach
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:start-returns-to-piped-caller, local-server-and-web-console#ac:stop-never-kills-reused-pid
**Depends-On:** —
**Status:** planning

- **Work:** `strongo/cli-helpers` PR adding to `daemonlifecycle`: `ConfigureDetached(*exec.Cmd)`
  (lifted from wb `internal/process/detach_*`: `Setsid`; Windows `DETACHED_PROCESS |
  CREATE_NEW_PROCESS_GROUP | CREATE_BREAKAWAY_FROM_JOB`, `HideWindow`, no inherited handles) with a
  `StartDetached` helper that retries without breakaway on `ERROR_ACCESS_DENIED`, and
  `ProcessStartTime(pid) (time.Time, error)` (`/proc/<pid>/stat`, `sysctl kern.proc.pid`,
  `GetProcessTimes`). A throwaway `cmd/detachprobe` test binary serves `whoami` behind a secret
  file.
- **Pass:** a Go test on `ubuntu-latest`, `macos-latest`, `windows-latest` (Actions steps on Windows
  normally run inside a job object, which exercises breakaway; confirm in the log) starts the probe from a piped
  parent, the parent exits within 2 s of readiness, a fresh step finds it answering `whoami`, an
  authenticated shutdown frees the port, and a pid whose start time differs is never signalled.
- **Fallback:** breakaway refused → keep the no-breakaway retry and rely on
  `server_start_failed` guidance (already specified); detach unusable on an OS → add a hidden
  foreground `ovdb server run` for that OS and change the spec before increment 1.
- **Release:** `cli-helpers` minor tag (v0.13.0). wb may later consume it (not in this plan).
- **Model:** opus. **Frontend:** no. **Lane:** Go (CI runners do the cross-OS work).

### Task 3: S3 — embedded Vue build through the release pipeline with the `.gitkeep` fallback

**Id:** spike-s3-embedded-web
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:not-built-fallback
**Depends-On:** 6
**Status:** planning

- **Work:** `ovdb` branch with `web/` (Vue 3, TS, Vite, Tailwind, pnpm pinned in
  `packageManager`), one page, `web/embed.go` copied from wb's pattern (`//go:embed all:dist`,
  tracked `dist/.gitkeep` restored by `public/.gitkeep`, `Built()`, not-built page naming
  Homebrew and release downloads); `.goreleaser.yaml` `before.hooks`: `corepack enable pnpm &&
  pnpm -C web install --frozen-lockfile && pnpm -C web build`, then `test -f web/dist/index.html`;
  a CI job `goreleaser build --snapshot --clean --single-target` on `ubuntu-latest`.
- **Pass:** `go install .` from a clean clone compiles and serves the not-built page; the CI
  snapshot build fails when `web/dist/index.html` is missing and otherwise serves the page from a
  binary run with `node` absent from `PATH`.
- **Fallback:** the `strongo/cicd` release runner lacks Node/corepack → provider-first
  `strongo/cicd` input `setup_pnpm: true` (adds `actions/setup-node` + corepack) before `ovdb`
  adopts the hook.
- **Model:** sonnet. **Frontend:** yes (single frontend lane with S6, S8).

### Task 4: S4 — DataTug CLI against a local-mode server with a read-only token

**Id:** spike-s4-datatug
**Verifies:** configuration-parity#ac:spikes-recorded, explore-data-handoff#ac:descriptor-and-command
**Depends-On:** 1, 7
**Status:** planning

- **Work:** on the S7 prototype server with an inGitDB database seeded like the demo, mint a
  read-only grant in `<OVDB_HOME>/auth.json` (prototype of `ovdb token create --db todo --scope
  read-only`), write the four-key descriptor, run
  `OVDB_DATATUG_TOKEN=… OVDB_DATATUG_TOKEN_BASE_URL=http://127.0.0.1:7832 OVDB_DATATUG_TOKEN_PRINCIPAL_ID=local-owner datatug query run --db openvaultdb://$D --from lists --as local-owner --format json`
  (add `--no-policies` only if required, and record it).
- **Pass:** two list rows returned; a write with the same token is refused; no token value in
  the descriptor.
- **Fallback:** principal or token mismatch not fixable in `ovdb` → Explore data ships the honest
  "DataTug CLI can't connect to a local OVDB server yet" copy plus Browse data, and
  `explore-data-handoff` is changed first; the DataTug fix is filed in `datatug-cli`.
- **Model:** sonnet. **Frontend:** no. **Lane:** Go.

### Task 5: S5 — `skillsync` per-skill install

**Id:** spike-s5-skillsync
**Verifies:** configuration-parity#ac:spikes-recorded, ai-agent-skills#ac:install-one-skill-only
**Depends-On:** —
**Status:** planning

- **Work:** test in `ovdb` scratch: call `skillsync.Sync` with `Config.Bundles` holding only
  `todo-demo` into a directory that already has `openvaultdb` (same `CLI` identity) and an
  unrelated `specscore` skill; repeat with one `PluginIdentity` per skill.
- **Pass:** some configuration installs one skill without `removed` changes for the other
  skills and reports `unchanged` on the second run — then no upstream change is needed.
- **Fallback:** removal cannot be avoided → `cli-helpers` PR `Options.OnlyBundles []string`
  (reconcile only the named bundles), released provider-first before increment 8.
- **Model:** sonnet. **Frontend:** no. **Lane:** Go.

### Task 6: S6 — `copy/en.json` shared by Go and Vite

**Id:** spike-s6-copy
**Verifies:** configuration-parity#ac:spikes-recorded, configuration-parity#ac:copy-key-missing-fails
**Depends-On:** —
**Status:** planning

- **Work:** `copy/en.json` with `{name}` placeholders, `copy/copy.go` (`uicopy.T(key, params)`),
  a Go AST test that collects every `uicopy.T("…")` literal under `internal/` and fails on a
  missing key, a Vite import `import en from '../../copy/en.json'` (`server.fs.allow`), a
  `t(key, params)` helper and a Vitest test that scans `src/**/*.vue|ts` for `t('…')`.
- **Pass:** both suites fail naming a deliberately missing key; `pnpm -C web build` inlines the
  catalogue.
- **Fallback:** Vite cannot import outside `web/` in the release build → `pnpm build` prestep
  copies the file to `web/src/generated/en.json` (git-ignored).
- **Model:** sonnet. **Frontend:** yes.

### Task 7: S7 — local-mode credentials, login exchange, sessions and browser hardening

**Id:** spike-s7-auth-hardening
**Verifies:** configuration-parity#ac:spikes-recorded, local-server-and-web-console#ac:unauthenticated-rejected, local-server-and-web-console#ac:dns-rebinding-blocked, local-server-and-web-console#ac:cross-site-cookie-post-blocked, local-server-and-web-console#ac:login-link-both-hosts
**Depends-On:** 1
**Status:** planning

- **Work:** prototype `internal/localserver` middleware chain in the specified order: security
  headers → Host allowlist → authentication (instance secret | session cookie | scoped token
  via `auth.Store`) → `http.CrossOriginProtection` for cookie-authenticated non-safe requests and
  `POST /login` → CORS (`server.cors`, bearer only) → routes. Cookie requests to `/v1/…` are
  forwarded to the `openvaultdb-go` handler with an internal `Authorization: Bearer <instance
  secret>` (the handler is built with `WithAuth(&auth.Config{OwnerToken: secret, Store})`); an
  incoming `Authorization` header wins over a cookie. Login codes in memory; sessions hashed in
  `sessions.json`.
- **Pass:** Go HTTP tests for the four ACs above plus: bearer `PUT /v1/…` from an allowed
  `Origin` passes with CORS headers; `GET /login?code=` does not consume; POST on
  `127.0.0.1` sets `ovdb_session_<port>` (`HttpOnly`, `SameSite=Lax`, host-only); a
  Chromium Playwright check that a cross-site form POST is rejected and a link click from
  another origin keeps the session.
- **Fallback:** `http.CrossOriginProtection` cannot exempt bearer requests or `POST /login`
  cleanly → a 40-line `Sec-Fetch-Site`/`Origin` check with the same tests.
- **Model:** opus. **Frontend:** Playwright only (counts as the frontend lane while it runs).

### Task 8: S8 — `ovdb.localhost` in Safari (macOS) and Edge (Windows)

**Id:** spike-s8-localhost-browsers
**Verifies:** configuration-parity#ac:spikes-recorded
**Depends-On:** 3
**Status:** planning

- **Work:** a `workflow_dispatch` job in the S3 branch: on `macos-latest` start the S3 binary
  on `127.0.0.1:6832`, enable `safaridriver` and load `http://ovdb.localhost:6832/`; on
  `windows-latest` do the same with Playwright `channel: 'msedge'`; also bind `::1` to confirm
  both families. The founder repeats it by hand on one Mac and one Windows PC if CI is
  inconclusive.
- **Pass:** both browsers render the page from `ovdb.localhost`.
- **Fallback:** a browser does not resolve `*.localhost` → `ovdb open` opens `fallback_url` on
  that platform by default and prints the `127.0.0.1` link first; spec change to
  `REQ:login-links` before increment 1.
- **Model:** sonnet. **Frontend:** no build (uses S3 output).

### Task 9: Increment 1 — Background server, sign-in and Home status in all three interfaces

**Id:** inc-1-server-and-home
**Verifies:** configuration-parity#ac:missing-cell-fails, configuration-parity#ac:error-envelope-shape, configuration-parity#ac:usage-error-exits-one, configuration-parity#ac:endpoints-authenticated, configuration-parity#ac:copy-key-missing-fails, configuration-parity#ac:ci-runs-matrix, configuration-parity#ac:gate-hides-incomplete, first-run-onboarding#ac:tty-launches-tui, first-run-onboarding#ac:status-unchanged-without-gate, first-run-onboarding#ac:problem-shows-why-and-fix, first-run-onboarding#ac:tui-sizes, local-server-and-web-console#ac:legacy-serve-unchanged, local-server-and-web-console#ac:start-returns-to-piped-caller, local-server-and-web-console#ac:sandboxed-start-fails-clearly, local-server-and-web-console#ac:home-or-port-mismatch, local-server-and-web-console#ac:impostor-port, local-server-and-web-console#ac:reserved-port, local-server-and-web-console#ac:stop-never-kills-reused-pid, local-server-and-web-console#ac:version-mismatch-line, local-server-and-web-console#ac:stop-copy, local-server-and-web-console#ac:login-link-both-hosts, local-server-and-web-console#ac:session-survives-restart, local-server-and-web-console#ac:unauthenticated-rejected, local-server-and-web-console#ac:dns-rebinding-blocked, local-server-and-web-console#ac:framing-refused, local-server-and-web-console#ac:runtime-files-private-and-local, local-server-and-web-console#ac:not-built-fallback
**Depends-On:** 1, 2, 3, 6, 7, 8
**Status:** planning

- **Goal:** the walking skeleton — one authenticated local server that people and agents can
  start, see and stop from every interface.
- **User-visible result:** `OVDB_PREVIEW=1 ovdb` opens the TUI Home (status line, "What would
  you like to do?" with **Start the OVDB server**, secondary **Settings**); `ovdb server
  start|stop|restart|status`, `ovdb open [--print-url] [--host 127.0.0.1]`, `ovdb config
  get|set server.port`, `ovdb status [--json]`; piped `ovdb` prints status + `next` (entries
  implemented so far); browser: landing page without a session, login link → console Home with
  status line, **OVDB server** panel and Settings (port for next start).
- **Matrix rows:** 1 (partial Home), 2, 3 (web E1), 4, 5 (web E2), 6 (web E1), 7.
- **Code:** `ovdb` — new `internal/{preview,paths,envelope,redact,runtime,setup (status, config),
  localserver,client,cli,tui,parity}`, `copy/`, `web/` (console shell, Home, Server, Settings,
  landing and session-ended states); upgrade to `cli-helpers` v0.13.0 (`daemonlifecycle`
  detach, `ProcessStartTime`, lock, owner-only) and `openvaultdb-go` ≥ v0.5.1; legacy
  `status.go` gains the preview branch (`--url` keeps today's path); root `RunE` launches TUI or
  non-interactive status only with the gate. Reuse: S7 middleware, S3 embed, S6 catalogue,
  ingitdb-cli TUI model structure, `serve.go` shutdown pattern. `isNonLoopback` stays for legacy
  serve; local mode uses `netip` checks.
- **CI:** add `go-os-matrix` job (ubuntu, macos, windows) running
  `go test ./internal/runtime/... ./internal/paths/...`; add `web` job (pnpm build, Vitest,
  Playwright Chromium) to the `Go CI` workflow so `require_workflow_success` also gates releases.
- **Tests:** runtime tests (detached start from a pipe, stale `server.json`, reused pid,
  impostor on `[::1]`, reserved port via an injectable `listen` error, home/port mismatch,
  version notice); localserver HTTP tests (credential×route table, headers on 401/403/landing,
  Host allowlist, login on both hosts, sessions survive restart); envelope golden tests (every
  code ↔ HTTP status); CLI tests for text, `--json` byte-equality with `GET
  /api/local/v1/status`, exit codes, unknown flag → `invalid_argument`; gate tests (help lists no
  new command, bare `ovdb` golden help without the variable, legacy `status --url`); TUI model
  tests for Home/Server/Settings/Problem at four sizes; Vitest for Home, Server, Settings, landing;
  parity registry test; Playwright `smoke.spec.ts` (landing, login link, Home) and
  `screens.spec.ts`.
- **Manual journey:** isolation block; `ovdb status`; `ovdb server start | cat` (returns, no
  code printed); `ovdb` in tmux 80×24 and 120×40 → Home, OVDB server, Settings; occupy the port
  (`python3 -m http.server 7832`) → `ovdb server start` shows "Couldn't start the OVDB server"
  with both fixes, TUI offers "Use port 7833 instead"; `ovdb open --print-url` → open both links
  in a desktop browser at 1280×800 and 1920×1080, reuse a code (landing), dark mode;
  `curl -H 'Host: attacker.example:7832' -i http://127.0.0.1:7832/` → 403 with headers;
  `ovdb server stop` shows the stopped-server copy; without `OVDB_PREVIEW`, `ovdb --help` and
  `ovdb` are unchanged.
- **Cross-platform:** runtime dir under `os.UserCacheDir()` (LocalAppData); Windows reserved
  ranges (`port_unavailable`); `::1` unavailable in containers; browser launch via
  `xdg-open`/`open`/`rundll32` with print-only fallback; line endings in `server.log`.
- **Gate/compat:** all new commands hidden; `ovdb status` without the gate or with `--url`
  unchanged; `serve` untouched; `init`, `databases`, `token` untouched until their increments.
- **Model / lanes:** 1A Go core (paths, runtime, envelope, localserver, client, CLI) — opus;
  1B TUI — sonnet, starts when the local API and copy keys are frozen; 1C web — sonnet,
  frontend lane, same start condition. 1B and 1C run in parallel (one Go + one frontend lane).

### Task 10: Increment 2 — Create, list and remove databases from a truthful storage catalogue

**Id:** inc-2-create-databases
**Verifies:** database-setup-and-providers#ac:catalogue-matches-binary, database-setup-and-providers#ac:pinned-then-alphabetical, database-setup-and-providers#ac:postgres-is-manifest-only, database-setup-and-providers#ac:create-refuses-overwrite, database-setup-and-providers#ac:sqlite-points-to-schema, database-setup-and-providers#ac:remove-keeps-data, database-setup-and-providers#ac:legacy-create-still-works, local-server-and-web-console#ac:tolerant-registry, local-server-and-web-console#ac:auto-start-and-no-start, local-server-and-web-console#ac:dsn-never-leaks, first-run-onboarding#ac:result-lists-next-actions, configuration-parity#ac:cli-json-matches-api
**Depends-On:** 9
**Status:** planning

- **Goal:** a person or agent creates their own inGitDB or SQLite database from any interface
  and sees it listed with its mount state.
- **User-visible result:** `ovdb engines [--json]`; `ovdb databases [--json]` (preview, from
  state files + `mounts.json`); `ovdb databases create <id> [--engine] [--path]`; `ovdb
  databases remove <id> [--yes]`; TUI and web **Create a database** (filterable picker, name,
  location, Result with next actions) and **Databases** (list, remove); manifest-only engines
  show "Set this up with a manifest file" with `ovdb init --engine <id>`.
- **Matrix rows:** 8, 9, 11, 12; row 1 gains Create.
- **Code:** `openvaultdb-go` v0.6.0 from S1 (`Server.Mount/Unmount`, `DirReport`);
  `internal/setup/{engines,registry,create,remove}` (catalogue test enumerates engines accepted
  by `openvaultdb-go/pkg/manifest`); server startup mounts `databases/` with `DirReport` and
  writes `mounts.json`; `internal/redact` applied to every surfaced error and `server.log`;
  auto-start + `--no-start` in `internal/client`; legacy `databases.go` and
  `databases_create.go` gain preview branches (`--url`/`--addr` keep today's path). Web routes
  `/create`, `/databases`; TUI screens `create`, `databases`, `result`, `problem`.
- **Tests:** service tests (id regex, absolute normalized paths, `already_exists`,
  `location_not_empty`, SQLite `next` starts with schema, remove keeps data); redaction table tests (URL user-info, `password=`, DSN
  shapes) + a PostgreSQL manifest with an unreachable DSN whose secret never appears in status,
  `--json`, API, `mounts.json`, `server.log`; CLI `--json` equals API; TUI filter `sql` order;
  Vitest picker/filter; Playwright `create.spec.ts` (create `notes`, refuse overwrite) and
  screenshots.
- **Manual journey:** isolation block; `ovdb databases create notes` (stderr start line), again
  → `already_exists`; TUI Create → filter `sql` → SQLite → Result says describe a schema first;
  TUI pick PostgreSQL → manifest steps, no fields; browser Create `web1` at 1280×800 and 360 px,
  Databases shows both; `ovdb server stop && ovdb databases` → "unknown (server not running)";
  `ovdb databases remove notes --yes` → data folder named and intact.
- **Cross-platform:** default paths with `filepath`, Windows drive letters and case, SQLite file
  locking on Windows during remove (unmount before reporting).
- **Gate/compat:** legacy `databases`/`databases create` unchanged without the gate or with
  explicit `--url`/`--addr`.
- **Model:** opus for registry/mount/redaction; sonnet for CLI, TUI, web. **Frontend:** yes.

### Task 11: Increment 3 — Project context, data commands and read-only Browse data

**Id:** inc-3-context-and-data
**Verifies:** database-context-navigation#ac:use-is-project-scoped, database-context-navigation#ac:walk-up-outside-git, database-context-navigation#ac:worktree-is-own-project, database-context-navigation#ac:precedence-ladder, database-context-navigation#ac:no-context-error, database-context-navigation#ac:cd-examples, database-context-navigation#ac:escaped-ids-round-trip, database-context-navigation#ac:data-commands-auto-start, database-context-navigation#ac:list-kinds, database-context-navigation#ac:only-database-is-named, database-context-navigation#ac:add-set-get-delete, database-context-navigation#ac:kind-mismatch-hint, database-context-navigation#ac:strict-mode-error, database-context-navigation#ac:browse-own-data, database-context-navigation#ac:tui-and-web-select-database, database-setup-and-providers#ac:create-ingitdb-default
**Depends-On:** 10
**Status:** planning

- **Goal:** the first "my own data" moment: store and read records without `--db`, and see them
  in the TUI and browser.
- **User-visible result:** `ovdb use [<db>] [--global] [--clear]`, `ovdb cd`, `ovdb pwd
  [--json]`, `ovdb list|ls`, `get`, `set` (JSON or `--field`), `add`, `delete|rm`; writes print
  the affected path, `--json` writes print `{"key":"/…"}`; TUI **Browse data** and **Use in this
  project**; web **Browse data** and **Use as default** (E3); Home status line shows the current
  database and scope.
- **Matrix rows:** 13 (web E3), 14, 15, 16 (TUI/web E4), 17 (TUI/web E5).
- **Code:** `internal/setup/context` (project root via `git rev-parse --show-toplevel` fallback to
  a `.git` walk, contexts keyed by hash of the canonical path, walk-up lookup, precedence ladder);
  `GET/PUT /api/local/v1/context` (project scope only with the instance secret);
  `internal/cli/path` (resolution, `record.EscapeID` from `dal-go/record`, `%` validation);
  data commands call existing `/v1` routes through `internal/client`; id generator (short
  URL-safe); `/v1`→envelope mapping from increment 1; `databases remove` now clears contexts.
  Web routes `/browse/:db/*`; TUI screen `browse`. Values rendered as text (ESLint
  `vue/no-v-html` error).
- **Tests:** table tests for every `cd` example and escaping case; context tests on the OS
  matrix (symlinked temp dirs on macOS, drive letters on Windows, linked worktrees); CLI tests
  for stdout/stderr split, `{"key"}` bodies, `/v1` error bodies unchanged with `--json`,
  `schema_required` mapping on a SQLite fixture; TUI Browse model tests (paging 50, typed nested
  collection); Vitest Browse (`<script>` shown as text); Playwright `browse.spec.ts`;
  Journey A script without the telemetry step; Journey C script without skill assertions.
- **Manual journey:** isolation block; `git init /tmp/p && cd /tmp/p/src` (mkdir first);
  `ovdb use notes` → names `/tmp/p`; `ovdb add /items '{"title":"Hello"}'` (prints the path),
  `ovdb add /items '{"title":"x"}' --json`; `ovdb list /items`; `ovdb cd /items && ovdb pwd`;
  `ovdb get /items --db notes` → kind-mismatch hint; TUI 80×24 Browse notes → items → record;
  browser Browse at 1920×1080, Use as default, then `cd /tmp && ovdb pwd` → global.
- **Cross-platform:** path separators vs record paths (always `/`), Git missing on PATH, case-
  insensitive filesystems when hashing project roots (canonicalize with `filepath.EvalSymlinks`).
- **Gate/compat:** all new commands hidden; no existing command changes.
- **Model:** sonnet (well specified); opus review of context scope. **Frontend:** yes.

### Task 12: Increment 4 — Built-in TODO demo and TODO app

**Id:** inc-4-todo-demo
**Verifies:** todo-demo#ac:fresh-install-creates-data, todo-demo#ac:reinstall-keeps-changes, todo-demo#ac:conflicting-todo-refused, todo-demo#ac:non-interactive-needs-yes, todo-demo#ac:open-starts-server-and-app, todo-demo#ac:app-edits-items, todo-demo#ac:agent-change-appears-in-app, todo-demo#ac:item-text-is-not-html, local-server-and-web-console#ac:session-ended-shown, local-server-and-web-console#ac:cross-site-cookie-post-blocked, local-server-and-web-console#ac:routes
**Depends-On:** 11
**Status:** planning

- **Goal:** the one-minute "apps and agents share my data" moment.
- **User-visible result:** `ovdb demo install [--yes] [--id]`, `ovdb demo open [--print-url]`,
  `ovdb demo status [--json]`; TUI and web **Try a demo** (shows location, installs, Result with
  **Open TODO app** and **Done** — skill and explore entries appear in increments 7 and 8);
  `http://ovdb.localhost:<port>/apps/todo/` with both lists, add, tick, delete, 3 s polling and
  refresh on focus, "Stored in …" line, link back to the console.
- **Matrix rows:** 18, 19; row 1 gains Try a demo.
- **Code:** `internal/setup/demo` (seed via the mounted database, idempotence check, conflict
  detection); `GET /api/local/v1/demo`, `POST /api/local/v1/demo/install`; login link `next`
  param lands on `/apps/todo/`; `web/apps/todo/` as a second Vite entry reusing the console's
  API client, session-ended and stopped-server components. `openvaultdb-todo-demo` README:
  "superseded as the first-run demo; kept as the connect-flow example" (decision 0010).
- **Tests:** service tests (fresh, reinstall with extra item, conflicting `todo`, `--yes`
  required, `--id`); CLI tests; TUI model tests; Vitest for list rendering (text only), poll and
  focus refresh, 401 and network-error copy; Playwright `todo.spec.ts` (keyboard-only edit, an
  `ovdb add` appears within 3 s, `<img onerror>` stays text, session removed → copy, server
  stopped → copy) and screenshots at 1280×800, 1920×1080, 360 px.
- **Manual journey:** isolation block; `ovdb demo install` piped → `confirmation_required`;
  TUI Try a demo → Result → Open TODO app; in the browser tick Milk; in a terminal
  `ovdb add /lists/to-watch/items '{"title":"Arrival","done":false}' --db todo` and watch it
  appear; `ovdb list /lists/to-buy/items --db todo`; `ovdb server stop` → app shows stopped copy.
- **Cross-platform:** `<data home>/demos/todo` path display with `~` only on Unix; browser open
  with a `next` path on Windows (`rundll32` quoting).
- **Gate/compat:** hidden; `ovdb demo` keeps room for `--app` (Sneat `listus` untouched).
- **Model:** sonnet. **Frontend:** yes.

### Task 13: Increment 5 — Connect an existing folder, SQLite file or manifest

**Id:** inc-5-connect-existing
**Verifies:** database-setup-and-providers#ac:connect-leaves-folder-untouched, database-setup-and-providers#ac:connect-postgres-manifest, database-setup-and-providers#ac:postgres-is-manifest-only, database-setup-and-providers#ac:result-next-actions, local-server-and-web-console#ac:dsn-never-leaks
**Depends-On:** 10
**Status:** planning

- **Goal:** people with data already in inGitDB, SQLite or a server database use it through OVDB
  without OVDB touching their storage.
- **User-visible result:** `ovdb databases connect <id> --engine --path`, `ovdb databases
  connect --manifest <abs>`; TUI and web **Connect an existing database** (folder/file path or
  manifest path, Result with next actions); `ovdb init --help` lists all five engines.
- **Matrix rows:** 10, 10a; row 1 gains Connect.
- **Code:** `POST /api/local/v1/databases/connect` using `mount.FileWithOptions` with
  `CatalogueDir: <OVDB_HOME>/catalogues/<id>` and `SkipGitIdentity: true`; manifest copy with
  paths made absolute; missing `dsn_env` → `storage_unavailable` naming the variable;
  `init.go` flag help. Upstream, non-blocking: `dal-go/dalgo2postgres` and `dalgo2mysql` stop
  formatting the DSN into errors (released, then bumped through `openvaultdb-go`).
- **Tests:** connect a Git repo fixture and assert zero file changes (`git status --porcelain`,
  `.git/config` hash); text file named `x.sqlite` rejected; manifest connect with and without
  `CRM_DSN` (PostgreSQL absent → mount failure path, redaction assertions); TUI/Vitest forms;
  Playwright `connect.spec.ts`.
- **Manual journey:** isolation block; clone any inGitDB repo, `ovdb databases connect crm
  --engine ingitdb --path $PWD/crm` → `git -C crm status` clean; `ovdb init --engine postgres
  --id crm2` then connect the manifest without the variable → names `CRM_DSN`, no secret shown;
  web Connect at 1280×800.
- **Cross-platform:** absolute-path validation on Windows (`C:\…`, UNC), SQLite validation
  without holding the file open.
- **Gate/compat:** `init` only gains help text (allowed ungated by `REQ:preview-gate`).
- **Model:** opus (storage side effects, secrets). **Frontend:** yes.

### Task 14: Increment 6 — Tokens, CORS origins and the connect flow on the local server

**Id:** inc-6-tokens-and-apps
**Verifies:** local-server-and-web-console#ac:token-against-local-server, local-server-and-web-console#ac:connect-flow-needs-session, local-server-and-web-console#ac:cross-site-cookie-post-blocked
**Depends-On:** 9, 10
**Status:** planning

- **Goal:** tools (DataTug) and third-party browser apps get scoped access to the local server.
- **User-visible result:** with the gate, `ovdb token create|list|revoke` work against the local
  server (auto-start) and store grants in `<OVDB_HOME>/auth.json`; `ovdb config set server.cors
  <origins>`; `/authorize` requires a console session.
- **Matrix rows:** 25 (TUI/web E7; consent page only in the browser).
- **Code:** `token.go` preview branch (explicit `--addr`/`--owner-token` keep today's path);
  `server.cors` in `internal/setup/config` feeding `server.ParseCORSOrigins`; `/authorize` wrapper
  in `internal/localserver` (no session → landing copy with sign-in hint; approval POST passes
  cross-origin protection).
- **Tests:** HTTP tests for the three ACs; CLI tests for both token paths; Playwright
  `connect-flow.spec.ts` (no session → landing; signed in → approve → `/token` → `/v1` works).
- **Manual journey:** isolation block; `ovdb token create --db notes --scope read-only --json`,
  `curl` read OK / write denied / `GET /api/local/v1/status` 403; run `openvaultdb-todo-demo`
  against the local server with `ovdb config set server.cors http://localhost:5173` and approve
  in a signed-in browser.
- **Cross-platform:** none beyond increment 1.
- **Gate/compat:** legacy token flags unchanged; `openvaultdb-todo-demo` keeps working with
  legacy `ovdb serve --auth`.
- **Model:** opus (auth). **Frontend:** no Vue build (Playwright run uses the existing dist).

### Task 15: Increment 7 — Explore data hand-off to DataTug

**Id:** inc-7-explore-data
**Verifies:** explore-data-handoff#ac:menu-asks-intent-first, explore-data-handoff#ac:demo-explore-copy, explore-data-handoff#ac:descriptor-and-command, explore-data-handoff#ac:datatug-missing, explore-data-handoff#ac:datatug-app-is-honest, first-run-onboarding#ac:home-shows-options
**Depends-On:** 4, 12, 14
**Status:** planning

- **Goal:** people who want to query their data get the exact, honest next step.
- **User-visible result:** `ovdb explore [--db] [--json]`, `ovdb explore datatug-cli [--db]
  [--collection] [--json]`, `ovdb explore datatug-app [--db] [--print-url]`; TUI and web
  **Explore data** (intent first, copy actions, demo-specific copy); Home's Browse and Explore
  enabled once a database exists; create/connect/demo Results gain **Explore data**.
- **Matrix rows:** 22.
- **Code:** `internal/setup/explore` (`exec.LookPath("datatug")` in the client, descriptor at
  `<OVDB home>/explore/datatug/<db>.json`, command strings from copy keys);
  `GET /api/local/v1/explore/datatug?db=`; S4 findings (e.g. `--no-policies`) baked into the
  command.
- **Tests:** service tests (four-key descriptor, no token, datatug missing); CLI `--json`; TUI and
  Vitest menus; an opt-in integration test that runs the real `datatug` when on `PATH`
  (skipped otherwise); Playwright part of Journey B.
- **Manual journey:** isolation block with the demo; `ovdb explore --db todo`; copy the printed
  commands, run `ovdb token create …` and `datatug query run …`; web Explore data → DataTug.app
  page has no "open database" control (1280×800).
- **Cross-platform:** environment-variable syntax in shown commands per OS (`export` vs
  `$env:`), chosen from the client OS.
- **Gate/compat:** hidden.
- **Model:** sonnet. **Frontend:** yes.

### Task 16: Increment 8 — OpenVaultDB storage skill and TODO AI skill

**Id:** inc-8-agent-skills
**Verifies:** ai-agent-skills#ac:skill-less-agent-learns-options, first-run-onboarding#ac:agent-gets-next-not-prompt, ai-agent-skills#ac:storage-skill-text, ai-agent-skills#ac:todo-skill-maps-requests, ai-agent-skills#ac:install-one-skill-only, ai-agent-skills#ac:web-cannot-target-arbitrary-dir, ai-agent-skills#ac:agent-cannot-install-silently, ai-agent-skills#ac:ui-shows-targets-before-install, local-server-and-web-console#ac:client-resolves-skill-dirs, todo-demo#ac:next-actions-after-install, first-run-onboarding#ac:status-covers-whole-setup, configuration-parity#ac:journey-c-passes, configuration-parity#ac:journey-d-passes
**Depends-On:** 5, 11, 12, 15
**Status:** planning

- **Goal:** agents learn OVDB and change the demo lists, installed only with a person's yes.
- **User-visible result:** `ovdb skills list [--json]`, `ovdb skills install <openvaultdb|todo-demo>
  [--harness]… [--dir] [--dry-run] [--yes]`; TUI and web **AI agent skills** and the consent
  step (purpose, detected harnesses, exact directories, Install not preselected) after the demo
  and as "Connect an app or AI assistant" after create/connect; `ovdb status --json` lists the
  five bootstrap `next` entries and installed skills.
- **Matrix rows:** 20, 21 (agents E6).
- **Code:** `skills/openvaultdb/SKILL.md` (nine instructions, including `--json` writes and the
  `{"key"}` result), `skills/todo-demo/SKILL.md`, embedded with `skillsync.EmbeddedBundle`;
  `internal/setup/skills` using S5's configuration (or `cli-helpers` `OnlyBundles`); client
  resolves directories with `cobracmd.DefaultHarnesses` and sends them; server accepts only
  known harness layouts or a CLI `--dir` under home.
- **Tests:** skill text test (nine instructions); install-one-skill test with an unrelated skill
  present; API refuses a `dir` field from a session; `--dir /etc/x` refused; non-TTY without
  `--yes` → plan printed + `confirmation_required`; `demo install --yes` installs no skill; TUI
  and Vitest consent screens; Journey C script (stdin closed, `CLAUDECODE=1`) and Journey D
  Playwright (agent step simulated by two `ovdb add`).
- **Manual journey:** isolation block with `HOME=$(mktemp -d)` and `~/.claude` created; TUI Try a
  demo → Install TODO AI skill → consent shows `~/.claude/skills/openvaultdb-todo-demo`; then a
  live Claude Code session in a scratch project: "add bananas and coffee to my shopping list"
  while the TODO app is open at 1280×800; a skill-less agent runs `ovdb status --json` and
  relays options.
- **Cross-platform:** harness directories on Windows (`%USERPROFILE%`), `CODEX_HOME`,
  executable bits not needed (markdown only).
- **Gate/compat:** hidden; no command installs skills as a side effect.
- **Model:** opus for install-target restriction and skill text; sonnet for UI. **Frontend:** yes.

### Task 17: Increment 9 — Opt-in telemetry with parity

**Id:** inc-9-telemetry
**Verifies:** telemetry-consent#ac:nothing-sent-by-default, telemetry-consent#ac:enable-then-disable, telemetry-consent#ac:client-env-wins, telemetry-consent#ac:unavailable-build, telemetry-consent#ac:non-tty-enable-needs-confirmation, telemetry-consent#ac:prompt-once-equal-choices, telemetry-consent#ac:buffer-flushed-or-dropped, telemetry-consent#ac:allowlist-enforced, telemetry-consent#ac:channel-derived, telemetry-consent#ac:events-delivered-within-bound, first-run-onboarding#ac:telemetry-question-is-late-and-once, configuration-parity#ac:journey-a-passes, configuration-parity#ac:journey-b-passes
**Depends-On:** 16
**Status:** planning

- **Goal:** measure onboarding without carrying user data, with the same control everywhere.
- **User-visible result:** `ovdb telemetry status [--json]|enable [--confirmed-by-user]|disable`;
  TUI and web Settings → Usage statistics; one dismissible prompt after the first success in TUI
  and web; builds without a key say "unavailable in this build".
- **Matrix rows:** 23, 24 (agents E6).
- **Code:** `internal/telemetry` (closed event structs, opt-out logic copied from specscore
  `CollectOSEnvSignals`, channel detection, synchronous `net/http` POST of one batch to
  `https://eu.i.posthog.com/batch/` with a 2 s timeout, key via `-ldflags -X`); TUI in-memory
  buffer (≤100); web page buffer posted to `POST /api/local/v1/telemetry/events` only after
  Turn on (server validates against the same allowlist and sends with `channel: web`);
  `GET/PUT /api/local/v1/telemetry`; instrumentation calls added to the services and
  presentations of increments 1–8.
- **Tests:** allowlist marshal test with hostile inputs; recording `httptest` endpoint for
  nothing-by-default, flush-on-enable, drop-on-decline, `DO_NOT_TRACK` in the client, 2 s bound
  with a hanging endpoint; CLI non-TTY enable; TUI and Vitest prompt-once; Journey A (TUI model
  script + CLI) and Journey B (Playwright) complete.
- **Manual journey:** isolation block with a dev build whose key and endpoint are set by
  `-ldflags` (endpoint `http://127.0.0.1:9999`, recorder `nc -lk 9999`); TUI first success →
  prompt → No thanks → nothing received; web Settings → Turn on → buffered events arrive;
  `DO_NOT_TRACK=1 ovdb telemetry status` names the reason; `ovdb telemetry disable` removes the
  install id.
- **Cross-platform:** CI detection variables; `os`/`arch` from `runtime`.
- **Gate/compat:** hidden. The release keeps "unavailable in this build" until the founder adds
  `POSTHOG_KEY` and `strongo/cicd` forwards it (deferred).
- **Model:** sonnet for UI and wiring; opus for the allowlist, sender and review.
  **Frontend:** yes.

### Task 18: Increment 10 — Final verification, adversarial review, fixes and re-run

**Id:** inc-10-final-verification
**Verifies:** configuration-parity#ac:tests-per-capability, configuration-parity#ac:journey-a-passes, configuration-parity#ac:journey-b-passes, configuration-parity#ac:journey-c-passes, configuration-parity#ac:journey-d-passes, first-run-onboarding#ac:home-shows-options, first-run-onboarding#ac:web-keyboard-and-contrast
**Depends-On:** 13, 14, 15, 16, 17
**Status:** planning

Run on a release candidate (`goreleaser build --snapshot`) plus the Homebrew build from the last
`ovdb` merge, on Linux (VM), macOS and Windows (founder machines or CI runners). Evidence goes to
`~/.wb/reports/ovdb-onboarding-final/` (commands, outputs, screenshots, TUI captures).

| # | Checklist item | How it is verified |
|---|---|---|
| 1 | All tests pass | `GOMAXPROCS=2 GOFLAGS=-p=2 go test ./...` in ovdb and touched providers; CI green on the OS matrix; Vitest; Playwright journeys |
| 2 | Builds pass | `goreleaser build --snapshot --clean` (all targets, sequential); `go install .` from a clean clone |
| 3 | Vue app embedded | Release binary serves `/`, `/apps/todo/`, hashed assets (AC `routes`); `go install` binary shows not-built page |
| 4 | No Node at runtime | Run journeys with `PATH` stripped of `node`, `pnpm`, `bun`; `ldd`/`otool -L` show no Node |
| 5 | Clean-state onboarding | Fresh `HOME`, `OVDB_HOME`, `OVDB_DATA_HOME`, cache dir: `ovdb` → Home in TUI; piped `ovdb` → five `next` entries |
| 6 | CLI/TUI/Web parity | Registry test green; `tests-per-capability` report; manual matrix walk of rows 1–25 in all three interfaces |
| 7 | `ovdb.localhost` | Chrome, Firefox, Safari, Edge open the login link; fallback link works (S8 evidence refreshed) |
| 8 | Port conflicts | Foreign listener, `[::1]` impostor, our own server, Windows reserved range: correct codes and copy in CLI and TUI |
| 9 | inGitDB | Create, connect existing repo (untouched), add/list/get, files readable on disk |
| 10 | SQLite | Create → schema-first Result; `schema_required` mapping; connect existing file |
| 11 | Providers | `ovdb engines` order and filter; Firestore/MySQL/PostgreSQL manifest-only honesty; manifest connect with missing variable |
| 12 | `ovdb use` | Project scope, walk-up, worktree, global default from web, precedence ladder |
| 13 | `ovdb cd` | All `cd` examples, escaping, `Nothing here yet` |
| 14 | Demo | Install idempotent, conflict refusal, next actions in TUI and web |
| 15 | To buy / To watch web app | Keyboard edit, CLI change within 3 s, text-only rendering, session-ended and stopped copy |
| 16 | TODO skill | Consent step, one-skill install, live agent "add bananas and coffee" |
| 17 | Explore data | Menu, demo copy, descriptor, real `datatug query run`, DataTug.app honesty |
| 18 | PostHog disabled pre-consent | Recording endpoint receives nothing before Turn on; no install id |
| 19 | Telemetry parity | Status/enable/disable identical in CLI, TUI, web; channel values |
| 20 | No sensitive telemetry | Allowlist test + manual capture inspection for ids, paths, messages |
| 21 | Usability review of outputs | A fresh reviewer reads every CLI output, TUI capture (80×24, 120×40) and screenshot (1280×800, 1920×1080, 360) against the copy principles |
| 22 | Final adversarial review | Independent opus reviewer (security, parity, cross-platform) plus a second model if available, reading code and evidence |
| 23 | Fix | Accepted findings fixed in their own commits; spec updated when behaviour changes |
| 24 | Re-run | Items 1–21 re-run after fixes; report to the founder with evidence links and the gate-removal proposal (one isolated change with release notes, founder-approved) |

- **Model:** opus (reviewers, integration); sonnet for evidence collection. **Frontend:**
  Playwright runs only.

## Deferred and Simplified

**Deferred (not in MVP).**

| Item | Spec reference |
|---|---|
| Removing `OVDB_PREVIEW` (separate founder-approved change) | first-run-onboarding `REQ:preview-gate` |
| Login item / OS service; no-terminal cold start for Journey B | decision 0007; local-server Open Questions; `REQ:journey-b-web` |
| Web console stop/restart | parity E2 |
| Record editing in TUI and web; schema/admin UI | parity E5; idea Not Doing |
| `ovdb skills uninstall`, skill refresh after self-update, marketplace publication | ai-agent-skills Open Questions; idea Not Doing |
| DataTug run-now, DataTug.app OVDB route, nested DTQL for demo items | explore-data-handoff External dependencies and Open Questions |
| Guided connect for Firestore/MySQL/PostgreSQL without a manifest; remote OVDB servers as contexts | database-setup Open Questions; decision 0008 |
| Per-storage-folder lock | local-server `REQ:single-server-home-lock` |
| Local HTTPS | decision 0007 |
| `ovdb demo reset`, list sharing in the TODO app | todo-demo Open Questions |
| Log rotation | local-server Open Questions |
| PostHog key in releases (`POSTHOG_KEY` secret + `strongo/cicd` forwarding) | founder answer; telemetry `unavailable` state |
| Languages beyond English; SQLite schemaless | first-run and idea Open Questions |
| wb consuming the lifted detach code from `cli-helpers` | S2 follow-up |

**Deliberate simplifications (flag for review).**

1. Home menus, Result `next` lists and status `next` are filtered by the registry's
   `Implemented` flag, so preview builds show fewer options until increment 8 instead of
   disabled promises.
2. Local-mode auth wraps the unchanged `openvaultdb-go` handler: cookie requests are forwarded
   as the owner with the instance secret, and `/authorize` approval is gated in `ovdb`; no auth
   change in `openvaultdb-go`.
3. Login codes live in memory (lost on restart; a new `ovdb open` is one command).
4. The runtime directory has no override; tests isolate with `XDG_CACHE_HOME`/`HOME`/
   `LOCALAPPDATA` rather than a new `OVDB_RUNTIME_DIR` variable.
5. S5 may make the `skillsync` upstream change unnecessary (one plugin identity per skill).
6. Journey A is automated as a TUI model script plus CLI assertions, no pseudo-terminal test
   (parity Open Question).
7. Web routes live in `web/routes.json` read by the Vue router and the Go parity test instead
   of a YAML matrix generating both (parity Open Question).
8. The `dal-go` DSN fix is non-blocking: the redaction layer and `dsn-never-leaks` test carry the
   requirement.
9. One Vite multi-page build serves both the console and the TODO app from one `web/` package.
10. The connect-flow consent page keeps `openvaultdb-go`'s existing HTML, gated by a session.
11. `{"key"}` for writes uses the CLI's absolute escaped path (`/lists/to-buy/items/x`), which
    differs from the `/v1` `key` string in `get` bodies (no leading slash).

## Open Questions

- Increment 1 is the largest (walking skeleton across three interfaces); if its review stalls,
  should Settings/port (row 7) move to increment 2 and be hidden until then?
- Should `ovdb get --json` also normalize `key` to the absolute path for symmetry with `{"key"}`,
  at the cost of breaking "`/v1` body unchanged"?
- Who runs the manual Safari/Edge check if the S8 CI job is inconclusive — the founder, or a
  rented runner session?
- Risks to watch: agent sandboxes that kill detached children (auto-start fails; guidance
  exists but the first-run experience degrades); the `openvaultdb-go` v0.2.0 → v0.5.1 jump
  touching legacy `token` and `cloud` commands; release pipeline Node availability; TUI copy
  width at 80×24 with long commands; a shared runtime directory across `OVDB_HOME`s in
  developer machines.

---
*This document follows the https://specscore.md/plan-specification*
