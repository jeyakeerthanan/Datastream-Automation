resource "google_datastream_connection_profile" "this" {
  provider = google-beta

  project              = var.project_id
  location             = var.location
  connection_profile_id = var.profile_id
  display_name         = var.display_name
  labels               = var.labels

  dynamic "sql_server_profile" {
    for_each = var.type == "SQLSERVER" ? [1] : []
    content {
      hostname = var.sqlserver.hostname
      port     = var.sqlserver.port
      username = var.sqlserver.username
      password = var.sqlserver.password
      database = var.sqlserver.database
    }
  }

  dynamic "bigquery_profile" {
    for_each = var.type == "BIGQUERY" ? [1] : []
    content {}
  }
}
