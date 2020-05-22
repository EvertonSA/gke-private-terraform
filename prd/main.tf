resource "google_container_cluster" "cluster" {
  provider = google-beta

  name     = var.cluster_name
  project  = var.project
  location = var.zone

  network    = google_compute_network.network.self_link
  subnetwork = google_compute_subnetwork.subnetwork.self_link

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  remove_default_node_pool = "true"
  initial_node_count       = 1

  addons_config {
    kubernetes_dashboard {
      disabled = true
    }

    network_policy_config {
      disabled = false
    }
  }

  workload_identity_config {
    identity_namespace = format("%s.svc.id.goog", var.project)
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = "false"
    }
  }

  network_policy {
    enabled = "true"
  }

  ip_allocation_policy {
    use_ip_aliases                = true
    cluster_secondary_range_name  = google_compute_subnetwork.subnetwork.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.subnetwork.secondary_ip_range.1.range_name
  }

  private_cluster_config {
    enable_private_endpoint = "false"
    enable_private_nodes    = "true"
    master_ipv4_cidr_block  = "172.16.0.16/28"
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = [
    google_project_service.service,
    google_project_iam_member.service-account,
    google_project_iam_member.service-account-custom,
    google_compute_router_nat.nat,
  ]

}

resource "google_container_node_pool" "private-np-1" {
  provider = google-beta

  name       = var.node_pool_name
  location   = var.zone
  cluster    = google_container_cluster.cluster.name
  node_count = "0"

  management {
    auto_repair  = "true"
    auto_upgrade = "false"
  }

  node_config {
    machine_type = var.node_machine_type
    disk_type    = "pd-ssd"
    disk_size_gb = 30
    image_type   = "COS"

    service_account = google_service_account.gke-sa.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]

    labels = {
      cluster = var.cluster_name
    }

    workload_metadata_config {
      node_metadata = "GKE_METADATA_SERVER"
    }

    metadata = {
      google-compute-enable-virtio-rng = "true"
      disable-legacy-endpoints = "true"
    }
  }

  depends_on = [
    google_container_cluster.cluster,
  ]
}
