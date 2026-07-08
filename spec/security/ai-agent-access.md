# AI Agent Access

## Purpose

Define how AI-agent-initiated work is handled by the same API used by websites, applications, CLIs, and services.

## Key Concepts

- Authenticated principal: the user, app, service, CLI credential, or other credentialed subject making the request.
- Caller type: whether the API call is initiated by a website, application, CLI, service, or AI agent. Caller type is informative for the MVP, not an authorization input.
- Confused-agent risk: the agent takes valid actions for the wrong intent.
- Tool boundary: the API surface the agent can call.
- Human approval checkpoint: a required user decision before sensitive action.

## Normative Requirements

- OpenVaultDB APIs MAY be called by websites, applications, CLIs, services, or AI agents.
- Authorization MUST be based on the authenticated principal and granted capabilities, not on whether the caller is implemented as an AI agent.
- MVP audit records MUST identify the authenticated principal and MUST NOT require additional AI-agent identity metadata.
- AI agents MUST NOT receive special privileges beyond the principal and grants used for the call.
- Access MUST be capability-scoped, auditable, and revocable regardless of whether a human, website, application, CLI, service, or AI agent initiated the request.
- High-risk AI-initiated actions MUST follow the same approval policy as equivalent high-risk application actions.
- Agent prompts, tool calls, and chain-of-thought MUST NOT be required audit fields in the MVP.

## MVP Behavior

The MVP does not need a separate API path or audit identity for AI agents. A website, application, CLI, service, or AI agent can call the same API if it uses an authenticated principal with the required capability. Audit records identify that authenticated principal, not a separate AI-agent initiator.

## Risks

- Agents can confidently request unsafe operations.
- Prompt injection can cause data exfiltration through allowed tools.
- Users may over-trust agent-generated migration summaries.
- Incident review may not know whether a human-authored app flow or delegated agent caused a change when both use the same authenticated principal.

## Open Questions

- Should post-MVP profiles add optional AI-agent provenance metadata?
- What prompt/tool metadata, if any, can be stored without creating a privacy leak?

## Acceptance Criteria

- A caller cannot write without an explicit capability, regardless of whether it is a website, application, CLI, or AI agent.
- Audit entries identify the authenticated principal used for the call.
- AI-agent-initiated calls are not granted special capabilities or subject to a separate MVP authorization path.
- Revocation prevents future tool calls even if the agent retains an old token.

## Related Specifications

- [capability-model.md](capability-model.md)
- [permissions-model.md](permissions-model.md)
- [audit-log.md](audit-log.md)
- [../schema/user-visible-migration-flow.md](../schema/user-visible-migration-flow.md)
