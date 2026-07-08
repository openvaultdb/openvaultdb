// Vault containment structures (Host -> Vault -> Namespace -> Collection -> Record).

enum "HostKind" {
  values = ["openvaultdb-host", "git-host"]
}

entity "Host" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "kind" {
    type     = "string"
    enum     = "HostKind"
    required = true
  }

  property "baseUrl" {
    type = "string"
  }
}

entity "Vault" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "name" {
    type     = "string"
    required = true
  }

  property "host" {
    entity   = "Host"
    required = true
  }

  property "owner" {
    entity   = "identity.User"
    required = true
  }
}

entity "Namespace" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "vault" {
    entity   = "Vault"
    required = true
  }

  property "application" {
    entity   = "identity.Application"
    required = true
  }
}

entity "Collection" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "namespace" {
    entity   = "Namespace"
    required = true
  }

  property "name" {
    type     = "string"
    required = true
  }
}

entity "Record" {
  key = ["id"]

  property "id" {
    type = "uuid"
  }

  property "collection" {
    entity   = "Collection"
    required = true
  }
}
