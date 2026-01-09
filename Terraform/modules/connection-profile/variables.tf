variable "project_id" { type = string }
variable "location"   { type = string }

variable "profile_id"   { type = string }
variable "display_name" { type = string }

variable "labels" {
  type    = map(string)
  default = {}
}

# MYSQL | ORACLE | POSTGRESQL | BIGQUERY | GCS
variable "type" { type = string }

variable "mysql" {
  type = object({
    hostname = string
    port     = number
    username = string
    password = string
  })
  default = null
}

variable "bigquery" {
  type    = map(string)
  default = null
}
