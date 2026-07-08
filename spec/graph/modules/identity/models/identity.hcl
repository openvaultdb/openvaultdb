// Principal structures (see ../../../../architecture/overview.md).

entity "User" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "email" {
    type   = "string"
    format = "email"
  }
}

entity "Application" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "name" {
    type     = "string"
    required = true
  }
}

entity "AiAgent" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "operator" {
    entity   = "User"
    required = true
  }
}

entity "ServiceAccount" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }
}
