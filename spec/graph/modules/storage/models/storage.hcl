// Backend structures (see ../../../../storage/storage-backends.md).

enum "BackendKind" {
  values = ["github-ingitdb", "sqlite", "postgres", "firestore"]
}

entity "Backend" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "kind" {
    type     = "string"
    enum     = "BackendKind"
    required = true
  }

  property "vault" {
    entity   = "vaults.Vault"
    required = true
  }

  property "formatVersion" {
    type     = "string"
    required = true
  }
}
