resource "google_service_account" "gke-sa" {
  account_id   = format("%s-node-sa", var.cluster_name)
  display_name = "GKE Security Service Account"
  project      = var.project
}

resource "google_project_iam_member" "service-account" {
  count   = length(var.service_account_iam_roles)
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

resource "google_project_iam_member" "service-account-custom" {
  count   = length(var.service_account_custom_iam_roles)
  project = var.project
  role    = element(var.service_account_custom_iam_roles, count.index)
  member  = format("serviceAccount:%s", google_service_account.gke-sa.email)
}

resource "google_project_service" "service" {
  count   = length(var.project_services)
  project = var.project
  service = element(var.project_services, count.index)

  disable_on_destroy = false
}

resource "google_compute_network" "network" {
  name                    = format("%s-network", var.cluster_name)
  project                 = var.project
  auto_create_subnetworks = false

  depends_on = [
    google_project_service.service,
  ]
}

resource "google_compute_subnetwork" "subnetwork" {
  name          = format("%s-subnet", var.cluster_name)
  project       = var.project
  network       = google_compute_network.network.self_link
  region        = var.region
  ip_cidr_range = "10.0.0.0/24"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = format("%s-pod-range", var.cluster_name)
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = format("%s-svc-range", var.cluster_name)
    ip_cidr_range = "10.2.0.0/20"
  }
}

resource "google_compute_address" "nat" {
  name    = format("%s-nat-ip", var.cluster_name)
  project = var.project
  region  = var.region

  depends_on = [
    google_project_service.service,
  ]
}

resource "google_compute_router" "router" {
  name    = format("%s-cloud-router", var.cluster_name)
  project = var.project
  region  = var.region
  network = google_compute_network.network.self_link

  bgp {
    asn = 64514
  }
}

resource "google_compute_router_nat" "nat" {
  name    = format("%s-cloud-nat", var.cluster_name)
  project = var.project
  router  = google_compute_router.router.name
  region  = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnetwork.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      google_compute_subnetwork.subnetwork.secondary_ip_range.0.range_name,
      google_compute_subnetwork.subnetwork.secondary_ip_range.1.range_name,
    ]
  }
}
