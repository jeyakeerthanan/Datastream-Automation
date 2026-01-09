variable "project_id" { type = string }
variable "region"     { type = string }

variable "labels" {
  type    = map(string)
  default = {}
}

variable "source_profile_id" { type = string }
variable "bq_profile_id"     { type = string }
variable "stream_id"         { type = string }

variable "desired_state" {
  type    = string
  default = "PAUSED"
  validation {
    condition     = contains(["PAUSED", "RUNNING"], var.desired_state)
    error_message = "desired_state must be PAUSED or RUNNING"
  }
}

variable "mysql_hostname" { type = string }
variable "mysql_port"     { type = number }
variable "mysql_username" { type = string }
variable "mysql_password" { type = string sensitive = true }

# Include/exclude objects as list of databases with tables.
variable "mysql_include_objects" {
  type = list(object({
    database = string
    tables   = list(string)
  }))
  default = []
}

variable "mysql_exclude_objects" {
  type = list(object({
    database = string
    tables   = list(string)
  }))
  default = []
}
