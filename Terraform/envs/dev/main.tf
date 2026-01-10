locals {
  # -------------------------
  # Load source CP YAML files
  # -------------------------
  source_cp_files = fileset("${path.module}/connection-profiles/source", "*.yml")

  source_cps_raw = {
    for f in local.source_cp_files :
    trimsuffix(basename(f), ".yml") => yamldecode(file("${path.module}/connection-profiles/source/${f}"))
  }

  # Normalize to map keyed by cp.key (medina/d365)
  source_cp_map = {
    for _, v in local.source_cps_raw :
    v.key => {
      profile_id      = v.profileId
      display_name    = v.displayName
      hostname        = v.sqlserver.hostname
      port            = try(v.sqlserver.port, 1433)
      username        = v.sqlserver.username
      database        = v.sqlserver.database
      password_secret = v.sqlserver.passwordSecret
    }
  }

  # -------------------------------
  # Load destination BigQuery CP YAML files
  # -------------------------------
  dest_cp_files = fileset("${path.module}/connection-profiles/destination", "*.yml")

  dest_cps_raw = {
    for f in local.dest_cp_files :
    trimsuffix(basename(f), ".yml") => yamldecode(file("${path.module}/connection-profiles/destination/${f}"))
  }

  # Normalize to map keyed by cp.key (bq_dev/bq_prod/...)
  dest_cp_map = {
    for _, v in local.dest_cps_raw :
    v.key => {
      profile_id   = v.profileId
      display_name = v.displayName
    }
  }

  # -------------------------
  # Load stream YAML files
  # -------------------------
  stream_files = fileset("${path.module}/streams", "*.yml")

  streams_raw = {
    for f in local.stream_files :
    trimsuffix(basename(f), ".yml") => yamldecode(file("${path.module}/streams/${f}"))
  }

  streams = {
    for k, v in local.streams_raw :
    k => {
      stream_id     = v.stream.id
      display_name  = v.stream.displayName
      desired_state = try(v.stream.desiredState, "PAUSED")

      src_cp_key = v.sourceConnectionProfileKey
      dst_cp_key = v.destinationConnectionProfileKey

      # If you always use CHANGE_TABLES, you can hardcode in module and remove this.
      cdc_method     = try(v.cdc.method, "CHANGE_TABLES")
      cdc_tasks      = try(v.cdc.maxConcurrentCdcTasks, 1)
      backfill_tasks = try(v.cdc.maxConcurrentBackfillTasks, 1)

      bq_write_mode  = v.bigquery.streamWriteMode # MERGE | APPEND_ONLY
      data_freshness = try(v.bigquery.dataFreshness, "900s")

      # Expected shape: [{ schema="dbo", tables=["t1","t2"] }, ...]
      tables = try(v.tables, [])
    }
  }

  # -------------------------
  # Validations
  # -------------------------
  invalid_streams_missing_source_cp = [
    for k, s in local.streams : k
    if !contains(keys(local.source_cp_map), s.src_cp_key)
  ]

  invalid_streams_missing_dest_cp = [
    for k, s in local.streams : k
    if !contains(keys(local.dest_cp_map), s.dst_cp_key)
  ]

  missing_password_secrets = distinct([
    for k, cp in local.source_cp_map : cp.password_secret
    if lookup(var.sql_passwords, cp.password_secret, "") == ""
  ])
}

# Fail if a stream references unknown source cp
resource "null_resource" "validate_stream_source_cp" {
  count = length(local.invalid_streams_missing_source_cp) > 0 ? 1 : 0
  provisioner "local-exec" {
    command = "echo Stream(s) reference missing source CP key(s): ${join(",", local.invalid_streams_missing_source_cp)} && exit 1"
  }
}

# Fail if a stream references unknown destination cp
resource "null_resource" "validate_stream_dest_cp" {
  count = length(local.invalid_streams_missing_dest_cp) > 0 ? 1 : 0
  provisioner "local-exec" {
    command = "echo Stream(s) reference missing destination CP key(s): ${join(",", local.invalid_streams_missing_dest_cp)} && exit 1"
  }
}

# Fail if passwords are missing for any required passwordSecret keys
resource "null_resource" "validate_sql_passwords" {
  count = length(local.missing_password_secrets) > 0 ? 1 : 0
  provisioner "local-exec" {
    command = "echo Missing sql_passwords for passwordSecret key(s): ${join(",", local.missing_password_secrets)} && exit 1"
  }
}

# -------------------------
# Create destination CPs (BigQuery) - multiple
# -------------------------
module "dest_cp_bigquery" {
  source   = "../../modules/connection-profile"
  for_each = local.dest_cp_map

  project_id   = var.project_id
  location     = var.region
  profile_id   = each.value.profile_id
  display_name = each.value.display_name
  labels       = merge(var.labels, { env = var.env, destination = each.key })

  type     = "BIGQUERY"
  bigquery = { dummy = "ok" }
}

# -------------------------
# Create source CPs (SQL Server) - multiple
# -------------------------
module "source_cp_sqlserver" {
  source   = "../../modules/connection-profile"
  for_each = local.source_cp_map

  project_id   = var.project_id
  location     = var.region
  profile_id   = each.value.profile_id
  display_name = each.value.display_name
  labels       = merge(var.labels, { env = var.env, source = each.key })

  type = "SQLSERVER"

  sqlserver = {
    hostname = each.value.hostname
    port     = each.value.port
    username = each.value.username
    password = var.sql_passwords[each.value.password_secret]
    database = each.value.database
  }
}

# -------------------------
# Create streams - multiple
# -------------------------
module "datastream_streams" {
  source   = "../../modules/datastream"
  for_each = local.streams

  project_id    = var.project_id
  location      = var.region
  stream_id     = each.value.stream_id
  display_name  = each.value.display_name
  labels        = merge(var.labels, { env = var.env })

  source_connection_profile      = module.source_cp_sqlserver[each.value.src_cp_key].name
  destination_connection_profile = module.dest_cp_bigquery[each.value.dst_cp_key].name

  desired_state = each.value.desired_state

  sqlserver_source_config = {
    max_concurrent_cdc_tasks      = each.value.cdc_tasks
    max_concurrent_backfill_tasks = each.value.backfill_tasks
    include_objects               = each.value.tables
    exclude_objects               = []
    cdc_method                    = each.value.cdc_method
  }

  bigquery_destination_config = {
    data_freshness    = each.value.data_freshness
    stream_write_mode = each.value.bq_write_mode
  }
}
