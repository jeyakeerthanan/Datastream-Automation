locals {
  is_mysql = var.mysql_source_config != null
}

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

    dynamic "mysql_source_config" {
      for_each = local.is_mysql ? [1] : []
      content {
        max_concurrent_cdc_tasks      = var.mysql_source_config.max_concurrent_cdc_tasks
        max_concurrent_backfill_tasks = var.mysql_source_config.max_concurrent_backfill_tasks

        mysql_objects {
          dynamic "database_datastream_objects" {
            for_each = var.mysql_source_config.include_objects
            content {
              database = database_datastream_objects.value.database

              dynamic "table_datastream_objects" {
                for_each = toset(database_datastream_objects.value.tables)
                content {
                  table = table_datastream_objects.value
                }
              }
            }
          }
        }

        dynamic "exclude_objects" {
          for_each = length(var.mysql_source_config.exclude_objects) > 0 ? [1] : []
          content {
            mysql_objects {
              dynamic "database_datastream_objects" {
                for_each = var.mysql_source_config.exclude_objects
                content {
                  database = database_datastream_objects.value.database

                  dynamic "table_datastream_objects" {
                    for_each = toset(database_datastream_objects.value.tables)
                    content {
                      table = table_datastream_objects.value
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = var.destination_connection_profile

    dynamic "bigquery_destination_config" {
      for_each = var.bigquery_destination_config != null ? [1] : []
      content {
        data_freshness = var.bigquery_destination_config.data_freshness
      }
    }
  }

  backfill_all {}
}
