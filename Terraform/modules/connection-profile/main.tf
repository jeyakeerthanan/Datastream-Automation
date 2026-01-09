resource "google_datastream_connection_profile" "this" {
  provider = google-beta

  project                 = var.project_id
  location                = var.location
  connection_profile_id   = var.profile_id
  display_name            = var.display_name
  labels                  = var.labels

  dynamic "mysql_profile" {
    for_each = var.type == "MYSQL" ? [1] : []
    content {
      hostname = var.mysql.hostname
      port     = var.mysql.port
      username = var.mysql.username
      password = var.mysql.password
    }
  }

  dynamic "bigquery_profile" {
    for_each = var.type == "BIGQUERY" ? [1] : []
    content {}
  }
}
