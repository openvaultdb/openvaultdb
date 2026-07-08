// Audit structures (see ../../../../security/audit-log.md).

enum "AuditOutcome" {
  values = ["allowed", "denied", "error"]
}

entity "AuditEntry" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "vault" {
    entity   = "vault.Vault"
    required = true
  }

  property "eventType" {
    type     = "string"
    required = true
  }

  property "outcome" {
    type     = "string"
    enum     = "AuditOutcome"
    required = true
  }

  property "occurredAt" {
    type     = "datetime"
    required = true
  }

  property "correlation" {
    component = "common.CorrelationRef"
    required  = true
  }

  property "actorUser" {
    entity = "identity.User"
  }
}
