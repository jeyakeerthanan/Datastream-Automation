resource "google_datastream_stream" "this" {
  provider = google-beta

  project      = var.project_id
  location     = var.location
  stream_id    = var.stream_id
  display_name = var.display_name
  labels       = var.labels

  desired_state = var.desired_state

  source_config {
    source_connection_profile = var.source_connection_profile

    sql_server_source_config {
      max_concurrent_cdc_tasks      = var.sqlserver_source_config.max_concurrent_cdc_tasks
      max_concurrent_backfill_tasks = var.sqlserver_source_config.max_concurrent_backfill_tasks

      include_objects {
        dynamic "schemas" {
          for_each = var.sqlserver_source_config.include_objects
          content {
            schema = schemas.value.schema
            dynamic "tables" {
              for_each = toset(schemas.value.tables)
              content {
                table = tables.value
              }
            }
          }
        }
      }

      dynamic "exclude_objects" {
        for_each = length(var.sqlserver_source_config.exclude_objects) > 0 ? [1] : []
        content {
          dynamic "schemas" {
            for_each = var.sqlserver_source_config.exclude_objects
            content {
              schema = schemas.value.schema
              dynamic "tables" {
                for_each = toset(schemas.value.tables)
                content {
                  table = tables.value
                }
              }
            }
          }
        }
      }

      dynamic "change_tables" {
        for_each = var.sqlserver_source_config.cdc_method == "CHANGE_TABLES" ? [1] : []
        content {}
      }

      dynamic "transaction_logs" {
        for_each = var.sqlserver_source_config.cdc_method == "TRANSACTION_LOGS" ? [1] : []
        content {}
      }
    }
  }

  destination_config {
    destination_connection_profile = var.destination_connection_profile

    bigquery_destination_config {
      data_freshness    = var.bigquery_destination_config.data_freshness
      stream_write_mode = var.bigquery_destination_config.stream_write_mode
    }
  }

  backfill_all {}
}
