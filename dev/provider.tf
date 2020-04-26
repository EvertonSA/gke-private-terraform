terraform {
  backend "gcs" {
    bucket = "bucket-mmcafe-dev-001"
  }
}

provider "google" {
  version = "~> 2.12.0"
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  version = "~> 2.12.0"
  project = var.project
  region  = var.region
  zone    = var.zone
}

data "google_client_config" "current" {}
