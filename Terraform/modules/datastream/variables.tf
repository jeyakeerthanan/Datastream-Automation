variable "project_id" { type = string }
variable "location"   { type = string }

variable "stream_id"    { type = string }
variable "display_name" { type = string }

variable "labels" {
  type    = map(string)
  default = {}
}

variable "source_connection_profile"      { type = string }
variable "destination_connection_profile" { type = string }

variable "desired_state" {
  type    = string
  default = "PAUSED"
  validation {
    condition     = contains(["PAUSED", "RUNNING"], var.desired_state)
    error_message = "desired_state must be PAUSED or RUNNING"
  }
}

# MySQL source config (reference implementation)
variable "mysql_source_config" {
  type = object({
    max_concurrent_cdc_tasks      = number
    max_concurrent_backfill_tasks = number
    include_objects = list(object({
      database = string
      tables   = list(string)
    }))
    exclude_objects = list(object({
      database = string
      tables   = list(string)
    }))
  })
  default = null
}

variable "bigquery_destination_config" {
  type = object({
    data_freshness = string
  })
  default = null
}
