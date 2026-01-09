project_id = "topcrops"
region     = "us-central1"

labels = {
  env  = "dev"
  app  = "datastream-automation"
  team = "data-platform"
}

# IDs must be lowercase, numbers, hyphen. Keep them stable.
source_profile_id = "mysql-source-dev"
bq_profile_id     = "bq-dest-dev"
stream_id         = "mysql-to-bq-dev"

# Stream desired state controlled by Terraform (keep PAUSED, then start via workflow)
desired_state = "PAUSED"

# MySQL source connection
mysql_hostname = "10.10.10.10"   # change
mysql_port     = 3306
mysql_username = "datastream_user"
mysql_password = "REPLACE_ME"     # For production: use Secret Manager, not plaintext.

# Objects to replicate (THIS is where you "add tables")
mysql_include_objects = [
  {
    database = "medina"
    tables = [
      "customers",
      "orders"
    ]
  }
]

# Optional exclusions
mysql_exclude_objects = []
