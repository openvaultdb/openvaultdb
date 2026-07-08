# AI Agent Access

## Purpose

Define how AI agents may access and change vault data without becoming implicit trusted users.

## Key Concepts

- Delegated agent: an AI principal acting under explicit user or application delegation.
- Confused-agent risk: the agent takes valid actions for the wrong intent.
- Tool boundary: the API surface the agent can call.
- Human approval checkpoint: a required user decision before sensitive action.

## Normative Requirements

- AI agents MUST be registered as distinct principals.
- AI agents MUST NOT receive implicit write, delete, export, migration, or permission-broadening access.
- Agent access MUST be capability-scoped, auditable, and revocable.
- High-risk agent actions MUST require fresh human approval unless an approved policy explicitly allows them.
- Agent prompts, tool calls, and proposed changes SHOULD be summarized in audit records without storing unnecessary sensitive prompt content.
- Agents MUST NOT be allowed to approve their own migrations or permission broadening.

## MVP Behavior

The MVP permits read-only agent access only through explicit delegated capabilities. Agent write access is out of MVP unless Fable review accepts a narrow, user-approved command path.

## Risks

- Agents can confidently request unsafe operations.
- Prompt injection can cause data exfiltration through allowed tools.
- Audit logs may leak prompt or data content.
- Users may over-trust agent-generated migration summaries.

## Open Questions

- Should any agent write capability exist in the MVP?
- What prompt/tool metadata is necessary for audit without creating a privacy leak?
- How should approval screens show agent uncertainty and source context?

## Acceptance Criteria

- An agent cannot write without an explicit capability and approval.
- An agent-triggered migration plan identifies the agent, application, user, and requested capabilities.
- Revocation prevents future tool calls even if the agent retains an old token.

## Related Specifications

- [capability-model.md](capability-model.md)
- [permissions-model.md](permissions-model.md)
- [audit-log.md](audit-log.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
