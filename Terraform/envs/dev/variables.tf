variable "project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  description = "Datastream location/region, e.g. europe-west2"
}

variable "env" {
  type        = string
  description = "Environment name, e.g. dev/qa/prod"
}

variable "labels" {
  type        = map(string)
  description = "Base labels applied to resources"
  default     = {}
}

# Map of secret-key -> password
# Example: { "medina_sql_pwd" = "xxxx", "d365_sql_pwd" = "yyyy" }
variable "sql_passwords" {
  type        = map(string)
  description = "SQL Server passwords keyed by passwordSecret from YAML"
  sensitive   = true
  default     = {}
}
