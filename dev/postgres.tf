resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = format("%s-priv-ip", var.cluster_name)
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.network.self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.network.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_service_account" "access_postgres" {
  account_id = format("%s-pg-sa", var.cluster_name)
}

data "google_iam_policy" "access_postgres" {
  binding {
    role = "roles/iam.workloadIdentityUser"

    members = [
      format("serviceAccount:%s.svc.id.goog[%s/%s]", var.project, var.k8s_namespace, var.k8s_sa_name)
    ]
  }
}

resource "google_service_account_iam_policy" "access_postgres" {
  service_account_id = google_service_account.access_postgres.name
  policy_data        = data.google_iam_policy.access_postgres.policy_data
}

resource "google_project_iam_binding" "access_postgres" {
  project = var.project
  role    = "roles/cloudsql.client"

  members = [
    format("serviceAccount:%s", google_service_account.access_postgres.email)
  ]
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "default" {
  project          = var.project
  name             = format("%s-pg-%s", var.cluster_name, random_id.db_name_suffix.hex)
  database_version = "POSTGRES_9_6"
  region           = var.region

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  settings {
    tier              = "db-f1-micro"
    activation_policy = "ALWAYS"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = google_compute_network.network.self_link
    }

    disk_autoresize = false
    disk_size       = "10"
    disk_type       = "PD_SSD"
    pricing_plan    = "PER_USE"

    location_preference {
      zone = var.zone
    }
  }

  timeouts {
    create = "10m"
    update = "10m"
    delete = "10m"
  }
}

resource "google_sql_database" "default" {
  name       = "default"
  project    = var.project
  instance   = google_sql_database_instance.default.name
  collation  = "en_US.UTF8"
  depends_on = [google_sql_database_instance.default]
}

resource "random_id" "user-password" {
  keepers = {
    name = google_sql_database_instance.default.name
  }

  byte_length = 8
  depends_on  = [google_sql_database_instance.default]
}

resource "google_sql_user" "default" {
  name       = var.db_username
  project    = var.project
  instance   = google_sql_database_instance.default.name
  password   = random_id.user-password.hex
  depends_on = [google_sql_database_instance.default]
}
