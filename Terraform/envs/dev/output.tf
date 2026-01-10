output "source_connection_profiles" {
  value = { for k, m in module.source_cp_sqlserver : k => m.name }
}

output "destination_connection_profiles" {
  value = { for k, m in module.dest_cp_bigquery : k => m.name }
}

output "streams" {
  value = { for k, m in module.datastream_streams : k => m.name }
}
