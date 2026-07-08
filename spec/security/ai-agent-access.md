# AI Agent Access

## Purpose

Define how AI agents are represented when they access or change vault data through the same API used by websites and applications.

## Key Concepts

- Delegated agent: an AI principal acting under explicit user or application delegation.
- Caller type: whether the API call is initiated by a website, application, CLI, service, or AI agent.
- Confused-agent risk: the agent takes valid actions for the wrong intent.
- Tool boundary: the API surface the agent can call.
- Human approval checkpoint: a required user decision before sensitive action.

## Normative Requirements

- OpenVaultDB APIs MAY be called by websites, applications, CLIs, services, or AI agents.
- Authorization MUST be based on the authenticated principal and granted capabilities, not on whether the caller is implemented as an AI agent.
- Where OpenVaultDB can identify that an AI agent is acting as a delegated actor, audit records SHOULD preserve that delegation chain.
- AI agents MUST NOT receive special privileges beyond the principal and grants used for the call.
- Agent access MUST be capability-scoped, auditable, and revocable.
- High-risk agent actions SHOULD follow the same approval policy as equivalent high-risk application actions unless Fable review defines stricter agent-specific rules.
- Agent prompts, tool calls, and proposed changes SHOULD be summarized in audit records without storing unnecessary sensitive prompt content.
- Agents MUST NOT be allowed to approve their own migrations or permission broadening.

## MVP Behavior

The MVP does not need a separate API path for AI agents. A website, application, CLI, or AI agent can call the same API if it has the required capability. The open design question is how much agent-specific identity must be captured for audit and review.

## Risks

- Agents can confidently request unsafe operations.
- Prompt injection can cause data exfiltration through allowed tools.
- Audit logs may leak prompt or data content.
- Users may over-trust agent-generated migration summaries.
- If agent calls are indistinguishable from application calls, incident review may not know whether a human-authored app flow or delegated agent caused a change.

## Open Questions

- Should MVP require callers to declare when an AI agent initiated the action?
- What prompt/tool metadata is necessary for audit without creating a privacy leak?
- Should Fable define stricter approval rules for agent-initiated destructive operations?

## Acceptance Criteria

- A caller cannot write without an explicit capability, regardless of whether it is a website, application, CLI, or AI agent.
- When an agent is known, an agent-triggered migration plan identifies the agent, application, user, and requested capabilities.
- Revocation prevents future tool calls even if the agent retains an old token.

## Related Specifications

- [capability-model.md](capability-model.md)
- [permissions-model.md](permissions-model.md)
- [audit-log.md](audit-log.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
