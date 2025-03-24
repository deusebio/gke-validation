resource "google_compute_instance" "vm" {
  name         = "spark-gke-vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"
  project      = var.project_id

  tags = ["gke-access"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.default.id
    subnetwork = google_compute_subnetwork.default.id
    access_config {} # Enables external IP
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }

  metadata_startup_script = templatefile("${path.module}/setup_vm.sh", {
    cluster_name  = google_container_cluster.default.name
    cluster_region = google_container_cluster.default.location
    project_id    = var.project_id
  })

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Create a service account for the VM
resource "google_service_account" "vm_sa" {
  account_id   = "gke-vm-access-sa"
  display_name = "GKE Access VM Service Account"
  project      = var.project_id
}

# Grant the VM service account permissions to access GKE
resource "google_project_iam_binding" "gke_access" {
  project = var.project_id
  role    = "roles/container.admin"

  members = [
    "serviceAccount:${google_service_account.vm_sa.email}"
  ]
}

resource "google_compute_firewall" "open_ssh" {
  name    = "allow-open-ssh"
  network = google_compute_network.default.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"] # Open to everyone
  target_tags   = ["gke-access"]
}