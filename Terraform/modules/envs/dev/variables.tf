variable "project_id" { type = string }
variable "region"     { type = string }
variable "env"        { type = string default = "dev" }

variable "labels" {
  type    = map(string)
  default = {}
}

# Secret name -> password (provided by workflow)
variable "sql_passwords" {
  type      = map(string)
  sensitive = true
  default   = {}
}
