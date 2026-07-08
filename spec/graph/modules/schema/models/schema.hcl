// Schema governance structures (see ../../../../schema/schema-model.md).

entity "SchemaVersion" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "namespace" {
    entity   = "vaults.Namespace"
    required = true
  }

  property "moduleId" {
    type     = "string"
    required = true
  }

  property "version" {
    type     = "string"
    required = true
  }
}

entity "Projection" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "schemaVersion" {
    entity   = "SchemaVersion"
    required = true
  }

  property "backendKind" {
    type = "string"
  }
}

component "ModelSource" {
  field "format" {
    type     = "string"
    required = true
  }

  field "payload" {
    type     = "json"
    required = true
  }
}
