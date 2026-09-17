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
| [First-run onboarding](first-run-onboarding/README.md) | Draft | The first thing a person sees when they run `ovdb` or open `http://ovdb.localhost:6832`: one question, "What would you like to do?", four clear options, and after every action a plain statement of what happened and what to do next. Non-interactive callers (AI agents, scripts) get a compact status and the next commands instead of a prompt. |
| [Local server and web console](local-server-and-web-console/README.md) | Draft | One local OVDB server per user serves every registered database, the embedded web console at `http://ovdb.localhost:6832` and the local API that the web console, TUI and CLI share. It starts in the background with one command, reports conflicts in plain language, and accepts browser traffic only from its own pages. |
| [Database setup and storage choices](database-setup-and-providers/README.md) | Draft | Create a new database or connect existing storage from the CLI, TUI or web console, by choosing where to store data from a catalogue that lists only storage engines OVDB really supports, with sensible names and locations and an honest note about each engine's limits. |
| [Database context and navigation](database-context-navigation/README.md) | Draft | `ovdb use` remembers which database a project works with, `ovdb cd` and `ovdb pwd` move around inside it with filesystem-like paths, and five small data commands (`list`, `get`, `set`, `add`, `delete`) read and write records over the existing HTTP API. Together they let a person or an AI agent work with stored data in a few short commands. |
| [TODO demo](todo-demo/README.md) | Draft | A built-in demo with two lists, **To buy** and **To watch**, stored as readable files on the person's computer, a small web app to use them, and an optional AI skill so an agent can change the same lists. It shows in about a minute what OpenVaultDB is for: apps and agents sharing data the person owns. |
| [AI agent skills](ai-agent-skills/README.md) | Draft | `ovdb` ships two Agent Skills: an **OpenVaultDB storage skill** that teaches an AI agent what OVDB is, how to help the person set it up (in the terminal, in the browser, or by running the commands itself) and how to store and read data; and a **TODO demo skill** that lets an agent manage the demo lists. Skills are installed only when a person explicitly agrees, using the same installer engine as `wb skills sync`. |
| [Explore data hand-off](explore-data-handoff/README.md) | Draft | "Explore data" asks where the person wants to look at their data — in the terminal with DataTug CLI or in the browser with DataTug.app — and then hands over exactly what that tool needs, stating honestly what works today. OVDB does not build its own data browser. |
| [Telemetry consent](telemetry-consent/README.md) | Draft | Anonymous product usage statistics for onboarding, sent to PostHog (EU) only after a person turns them on. The same state, the same explanation of what is and is not collected, and the same on/off control exist in the CLI, the TUI and the web console. AI agents never turn it on by themselves. |
| [Configuration parity](configuration-parity/README.md) | Draft | The normative capability matrix for OVDB onboarding and configuration across the CLI, the TUI, the web console and AI agents, the documented exceptions with their reasons, how parity is tested, and the four canonical journeys every increment is checked against. |

## Open Questions

None at this time.

---
*This document follows the https://specscore.md/features-index-specification*
