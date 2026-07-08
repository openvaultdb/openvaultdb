// Authorization structures (see ../../../../security/capability-model.md).

enum "OperationKind" {
  values = ["read", "query", "write", "delete", "migrate", "export", "register", "revoke", "administer"]
}

entity "Capability" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "operation" {
    type     = "string"
    enum     = "OperationKind"
    required = true
  }

  property "resource" {
    type     = "string"
    required = true
  }
}

entity "Grant" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "capability" {
    entity   = "Capability"
    required = true
  }

  property "subjectApplication" {
    entity = "identity.Application"
  }

  property "risk" {
    type     = "string"
    enum     = "common.RiskLevel"
    required = true
  }

  property "validity" {
    component = "common.TimeWindow"
  }
}
