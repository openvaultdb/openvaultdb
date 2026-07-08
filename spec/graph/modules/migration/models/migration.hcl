// Migration structures (see ../../../../schema/migrations.md).

entity "MigrationPlan" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "vault" {
    entity   = "vault.Vault"
    required = true
  }

  property "sourceSchema" {
    entity = "schema.SchemaVersion"
  }

  property "targetSchema" {
    entity   = "schema.SchemaVersion"
    required = true
  }

  property "risk" {
    type     = "string"
    enum     = "common.RiskLevel"
    required = true
  }

  property "window" {
    component = "common.TimeWindow"
  }
}

entity "Checkpoint" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "plan" {
    entity   = "MigrationPlan"
    required = true
  }

  property "phase" {
    type     = "string"
    required = true
  }

  property "processedRecords" {
    type = "int"
  }
}
