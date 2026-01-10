terraform {
  required_version = ">= 1.6.0"

  # Optional: backend config can be provided at init time:
  # terraform init -backend-config="bucket=..." -backend-config="prefix=..."
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}
