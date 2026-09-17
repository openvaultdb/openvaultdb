---
format: https://specscore.md/decisions-index-specification
---

# Decisions

## Decisions

| # | Decision | Status | Date | Tags | Affected |
|---|----------|--------|------|------|----------|
| [0001](0001-canonical-specification-repository.md) | Canonical Specification Repository | Draft | 2026-07-08 | repository,specification | — |
| [0002](0002-github-ingitdb-first-generator-layout.md) | GitHub InGitDB First Generator Layout | Approved | 2026-07-08 | storage,github,ingitdb,generator | — |
| [0003](0003-modelspec-cli-diagnostics.md) | ModelSpec CLI Diagnostics | Approved | 2026-07-08 | modelspec,cli,diagnostics | — |
| [0005](0005-openvaultdb-is-an-independent-and-isolated-project.md) | OpenVaultDB is an independent and isolated project | Approved | 2026-09-16 | governance,identity,authentication,independence,provider-neutrality | [Sneat.app Space Export to GitHub](../features/sneat-space-export/README.md) — its, [Cloud CLI device login](../features/cloud-cli-device-login/README.md) — the machine, `openvaultdb-com/spec/decisions/0001-auth-architecture.md` and |
| [0006](0006-three-equal-configuration-interfaces.md) | Three equal configuration interfaces over one shared capability layer | Draft | 2026-09-17 | onboarding,cli,tui,web-ui,architecture,parity | [First-run onboarding](../features/first-run-onboarding/README.md) — shared information architecture rendered by TUI and web., [Configuration parity](../features/configuration-parity/README.md) — capability matrix, machine contracts, external changes, tests., [Local server and web console](../features/local-server-and-web-console/README.md) — hosts the services, local API and assets., [Database setup and storage choices](../features/database-setup-and-providers/README.md) — first capability exposed through all interfaces., [Telemetry consent](../features/telemetry-consent/README.md) — settings parity across CLI, TUI and web. |
| [0007](0007-local-ovdb-server-and-web-address.md) | Local OVDB server model and web address | Draft | 2026-09-17 | onboarding,local-server,web-ui,security,networking | [Local server and web console](../features/local-server-and-web-console/README.md) — implements modes, auth, hardening, lifecycle and conflicts., [First-run onboarding](../features/first-run-onboarding/README.md) — server option, landing page and journeys., [Database context and navigation](../features/database-context-navigation/README.md) — data commands use the server with auto-start., [AI agent skills](../features/ai-agent-skills/README.md) — agents hand out login links. |
| [0008](0008-database-context-scope.md) | Database context scope for `ovdb use`, `ovdb cd` and `ovdb pwd` | Draft | 2026-09-17 | onboarding,cli,context,ai-agents | [Database context and navigation](../features/database-context-navigation/README.md) — implements use, cd, pwd, data verbs and browse., [Configuration parity](../features/configuration-parity/README.md) — records the web context exception., [AI agent skills](../features/ai-agent-skills/README.md) — skills use absolute paths and `--db`. |
| [0009](0009-opt-in-product-telemetry.md) | Opt-in product telemetry with PostHog | Draft | 2026-09-17 | telemetry,privacy,onboarding,ai-agents | [Telemetry consent](../features/telemetry-consent/README.md) — states, parity, events and copy., [First-run onboarding](../features/first-run-onboarding/README.md) — when consent is asked., [AI agent skills](../features/ai-agent-skills/README.md) — agents relay, never infer, consent. |
| [0010](0010-built-in-todo-demo.md) | Built-in TODO demo is the first-run demo | Draft | 2026-09-17 | onboarding,demo,ai-agents | [TODO demo](../features/todo-demo/README.md) — implements this decision., [AI agent skills](../features/ai-agent-skills/README.md) — TODO skill., [Explore data hand-off](../features/explore-data-handoff/README.md) — demo next action. |

## Open Questions

- Which provisional decisions in [../decision-log.md](../decision-log.md) should become ADRs immediately after Fable review?
- Should ADR acceptance require at least one security reviewer?

---
*This document follows the https://specscore.md/decisions-index-specification*
