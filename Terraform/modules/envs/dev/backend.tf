terraform {
  backend "gcs" {
    bucket = "topcrops-tfstate"
    prefix = "datastream/dev"
  }
}
