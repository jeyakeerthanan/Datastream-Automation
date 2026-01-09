terraform {
  required_version = ">= 1.6.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# ---------- Connection Profiles ----------

module "source_cp_mysql" {
  source = "../../modules/connection-profile"

  project_id  = var.project_id
  location    = var.region
  profile_id  = var.source_profile_id
  display_name = "mysql-source-cp"
  labels      = var.labels

  type = "MYSQL"

  mysql = {
    hostname = var.mysql_hostname
    port     = var.mysql_port
    username = var.mysql_username
    password = var.mysql_password
  }
}

module "dest_cp_bigquery" {
  source = "../../modules/connection-profile"

  project_id  = var.project_id
  location    = var.region
  profile_id  = var.bq_profile_id
  display_name = "bq-destination-cp"
  labels      = var.labels

  type = "BIGQUERY"

  bigquery = {
    # Datastream BigQuery connection profile doesn't require much besides project.
    # Keep this object for consistency/extension.
    dummy = "ok"
  }
}

# ---------- Stream ----------

module "datastream_stream" {
  source = "../../modules/datastream"

  project_id = var.project_id
  location   = var.region
  stream_id  = var.stream_id
  display_name = "mysql-to-bq-stream"
  labels     = var.labels

  source_connection_profile = module.source_cp_mysql.name
  destination_connection_profile = module.dest_cp_bigquery.name

  # Recommended: keep PAUSED in Terraform and start/pause via ops workflow.
  desired_state = var.desired_state

  # MySQL → BigQuery configuration
  mysql_source_config = {
    max_concurrent_cdc_tasks      = 5
    max_concurrent_backfill_tasks = 12

    include_objects = var.mysql_include_objects
    exclude_objects = var.mysql_exclude_objects
  }

  bigquery_destination_config = {
    data_freshness = "900s" # 15 minutes (example)
  }
}
