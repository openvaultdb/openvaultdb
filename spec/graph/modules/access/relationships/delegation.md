---
kind: relationship
id: delegation
name: delegation
status: draft
from: identity.ai-agent
to: identity.user
cardinality: many-to-one
metadata:
  validity: modelspec://common.TimeWindow
summary: An AI agent acts on behalf of a user within explicit limits.
---

# Relationship: delegation

## Description

Delegated capabilities are never broader than the source authority, and
audit records preserve the delegation chain (see
[AI agent access](../../../../security/ai-agent-access.md)).

## Open Questions

None at this time.
