variable "project_id" { type = string }
variable "location"   { type = string }
variable "profile_id" { type = string }
variable "display_name" { type = string }
variable "labels" { type = map(string) default = {} }

variable "type" {
  type        = string
  description = "SQLSERVER | BIGQUERY"
  validation {
    condition     = contains(["SQLSERVER", "BIGQUERY"], var.type)
    error_message = "type must be SQLSERVER or BIGQUERY"
  }
}

variable "sqlserver" {
  type = object({
    hostname = string
    port     = number
    username = string
    password = string
    database = string
  })
  default = null
}

variable "bigquery" {
  type    = map(string)
  default = {}
}
