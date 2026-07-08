# Audit Log

## Purpose

Define the append-only record of security-relevant events.

## Key Concepts

- Audit event: structured record of an action, decision, denial, or state transition.
- Audit event catalog: OpenVaultDB-owned list of event types and required fields.
- Logging mechanism: implementation library used to emit structured events.
- Actor chain: user, app, agent, extension, and provider context involved in an event.
- Tamper evidence: ability to detect removal, reorder, or alteration of audit entries.
- Redaction: controlled omission or masking of sensitive payload data.

## Normative Requirements

- The audit log MUST be append-only at the logical model level.
- Events MUST include timestamp, event type, actor, subject resource, outcome, and correlation ID.
- Grants, revocations, denied access, high-risk approvals, migrations, key events, exports, and destructive writes MUST be audited.
- Audit entries MUST avoid storing plaintext secrets or unnecessary record payloads.
- OpenVaultDB MUST define the audit event catalog independently of any logging library.
- The Go reference implementation SHOULD use `github.com/strongo/logus` as the structured logging mechanism where appropriate.
- Audit sinks and exports MUST preserve event order and integrity metadata when the selected provider supports export.
- Implementations SHOULD make local tampering detectable, even if total device compromise remains out of scope.

## MVP Behavior

The MVP defines the OpenVaultDB audit event catalog and writes audit events through a provider or logging mechanism. For Go implementations, `logus` is the preferred structured logging mechanism. Concrete export formats are provider-specific; the GitHub/InGitDB provider may store append-only NDJSON under its repository layout.

## Risks

- Audit metadata can reveal sensitive user behavior.
- Excessive redaction can make investigations useless.
- Local attackers may delete the entire vault and audit log.
- Clock changes can weaken event ordering.
- Treating a logging library as the audit schema owner can hide missing required security fields.

## Open Questions

- Should audit events use monotonic counters in addition to wall-clock time?
- How long should audit events be retained by default?
- Which non-Go logging/auditing libraries should be supported by other implementations?

## Acceptance Criteria

- A reviewer can reconstruct permission grant, use, revocation, and migration history.
- Required fields for each audited event type are defined by OpenVaultDB, not by `logus`.
- Audit entries do not include full secret values or unnecessary record bodies.
- Tamper-evidence failure is visible to the user and blocks high-risk operations until acknowledged.

## Related Specifications

- [permissions-model.md](permissions-model.md)
- [ai-agent-access.md](ai-agent-access.md)
- [../cli/commands.md](../cli/commands.md)
- [../testing/security-test-matrix.md](../testing/security-test-matrix.md)
