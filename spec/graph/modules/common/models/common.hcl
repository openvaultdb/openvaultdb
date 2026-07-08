// Shared value objects and vocabularies (see ../../../../glossary.md).

component "TimeWindow" {
  field "start" {
    type     = "datetime"
    required = true
  }

  field "end" {
    type = "datetime"
  }
}

component "CorrelationRef" {
  field "correlationId" {
    type     = "string"
    required = true
  }
}

enum "RiskLevel" {
  values = ["low", "medium", "high"]
}
