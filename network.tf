resource "google_compute_network" "default" {
  name = "spark-gke-network"

  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
  project = var.project_id
}

resource "google_compute_subnetwork" "default" {
  name    = "spark-gke-subnetwork"
  project = var.project_id

  ip_cidr_range = "10.0.0.0/16"
  region        = "us-central1"

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "INTERNAL"

  network = google_compute_network.default.id

  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = "192.168.0.0/24"
  }

  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = "192.168.16.0/20"  # Correctly aligned CIDR block
  }
}