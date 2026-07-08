---
kind: module
id: vault
name: Vault
status: draft
dependsOn: [identity]
summary: Hosts, vaults, namespaces, collections, and records.
---

# Module: Vault

## Description

The unit of user ownership. A vault lives on a host, contains app-owned namespaces, and namespaces hold schema-governed collections of records (Host -> Vault -> Namespace; see the vault model notes and [schema model](../../../schema/schema-model.md)).

## Open Questions

None at this time.
