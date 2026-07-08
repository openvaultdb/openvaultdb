# User-Visible Migration Flow

## Purpose

Define what users see before, during, and after migrations.

## Key Concepts

- Approval screen: user review of requested changes and risks.
- Progress display: live state of migration execution.
- Warning: non-fatal issue that may affect confidence or completeness.
- Recovery prompt: user choice after interruption, failure, or rollback requirement.

## Normative Requirements

- The approval flow MUST show requester, authenticated principal, affected collections, affected record count, estimated duration, risk level, reversibility, backup strategy, rollback strategy, required permissions, and destructive or permission-broadening changes.
- Execution MUST show progress bar, percentage when computable, current phase, processed records, total records where known, ETA where possible, warnings, errors, checkpoint status, and resumability status.
- Destructive changes MUST use explicit language naming the data or access that may be lost.
- Approval prompts MUST distinguish normative facts from estimates.
- Users MUST be able to inspect the migration plan before approving.

## MVP Behavior

The MVP exposes migration review and progress through CLI commands. Interactive approval is required for destructive, non-reversible, permission-broadening, storage backend, and AI-triggered migrations. Encryption and key migrations are post-MVP concerns.

The exact destructive-migration confirmation pattern is deferred to Fable review. Candidate patterns include simple warning, typed confirmation, and risk-tiered confirmation.

## Risks

- Users may approve without understanding risk.
- CLI output can become too dense for high-risk choices.
- ETA may appear more certain than it is.

## Open Questions

- What is the exact wording for non-reversible migrations?
- Should destructive migration approvals use simple warning, typed confirmation, risk tiers, or another Fable-approved pattern?
- How should the CLI present unknown record counts?

## Acceptance Criteria

- A non-expert reviewer can identify what changes, who requested it, and whether rollback is possible.
- Progress reporting remains useful when total record count or ETA is unknown.
- Errors include next action: retry, resume, rollback, inspect, or contact maintainer.

## Related Specifications

- [migrations.md](migrations.md)
- [data-migrations.md](data-migrations.md)
- [../cli/openvaultdb-cli.md](../cli/openvaultdb-cli.md)
- [../security/ai-agent-access.md](../security/ai-agent-access.md)
