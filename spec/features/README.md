---
format: https://specscore.md/features-index-specification
---

# Features

Feature specifications for this project.

## Index

| Feature | Status | Description |
|---------|--------|-------------|
| [Sneat.app Space Export to GitHub](sneat-space-export/README.md) | Draft | OpenVaultDB receives a complete Sneat.app Space snapshot and opens a repository-wide validated pull request in a user-selected private GitHub repository. |
| [Cloud CLI device login](cloud-cli-device-login/README.md) | Implementing | Authenticate first-party command-line clients through a browser-approved OAuth 2.0 device authorization flow. |
| [First-run onboarding](first-run-onboarding/README.md) | Approved | The first thing a person sees when they run `ovdb` or open the web console: one question, "What would you like to do?", four clear options, and after every action a plain statement of what happened and what to do next. Non-interactive callers (AI agents, scripts) get a compact status and the same next options as data instead of a prompt. |
| [Local server and web console](local-server-and-web-console/README.md) | Approved | One authenticated local OVDB server per user runs every onboarding service and serves the registered databases, the web console at `http://ovdb.localhost:6832`, the TODO app, the local API and the connect flow. It starts in the background on demand, proves its identity to clients, lets browsers in through one-time login links, and reports conflicts in plain language. Legacy `ovdb serve` is unchanged. |
| [Database setup and storage choices](database-setup-and-providers/README.md) | Approved | Create a new database, connect an existing inGitDB folder or SQLite file, or connect any engine with a manifest file, from the CLI, TUI or web console, choosing from a catalogue of storage engines OVDB really supports, with sensible names and locations and plain notes about each engine's limits. |
| [Database context and navigation](database-context-navigation/README.md) | Approved | `ovdb use` remembers which database a project works with, `ovdb cd` and `ovdb pwd` move inside it with file-like paths, and five small data commands (`list`, `get`, `set`, `add`, `delete`) read and write records through the local server. The TUI and web console offer a read-only **Browse data** view so people can see their own data without a terminal. |
| [TODO demo](todo-demo/README.md) | Approved | A built-in demo with two lists, **To buy** and **To watch**, stored as readable files on the person's computer, a small web app to use them, and an optional AI skill so an agent can change the same lists. It shows in about a minute what OpenVaultDB is for: apps and agents sharing data the person owns. |
| [AI agent skills](ai-agent-skills/README.md) | Approved | `ovdb` ships two Agent Skills: an **OpenVaultDB storage skill** that teaches an AI agent what OVDB is, how to help the person set it up (in the terminal, in the browser, or by running the commands itself) and how to store and read data safely; and a **TODO demo skill** for the demo lists. Skills are installed only after a person explicitly agrees, using the same installer engine as `wb skills sync`. Agents without a skill still learn the setup options from `ovdb status --json`. |
| [Explore data hand-off](explore-data-handoff/README.md) | Approved | "Explore data" asks where the person wants to explore — in the terminal with DataTug CLI or in the browser with DataTug.app — and hands over exactly what that tool needs, stating honestly what works today. OVDB's own read-only Browse data covers simple viewing; DataTug is for querying. |
| [Telemetry consent](telemetry-consent/README.md) | Approved | Anonymous onboarding usage statistics, sent to PostHog (EU) only after a person turns them on. The same state, explanation and control exist in the CLI, TUI and web console. AI agents never turn it on by themselves. |
| [Configuration parity](configuration-parity/README.md) | Approved | The normative capability matrix across CLI, TUI, web console and AI agents; the machine contracts every interface shares (errors, JSON, exit codes, local API, copy); the upstream changes and increment-0 spikes the work depends on; how parity is tested; and the four canonical journeys. |

## Open Questions

None at this time.

---
*This document follows the https://specscore.md/features-index-specification*
