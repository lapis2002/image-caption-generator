# Ref: https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/blob/master/examples/simple_autopilot_public
# To define that we will use GCP
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.80.0" // Provider version
    }
  }
  required_version = "1.6.1" // Terraform version
}

// The library with methods for creating and
// managing the infrastructure in GCP, this will
// apply to all the resources in the project
provider "google" {
  project     = var.project_id
  region      = var.region
}


// Google Kubernetes Engine
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.region

  // Enabling Autopilot for this cluster
  # enable_autopilot = true
  
  remove_default_node_pool = true
  initial_node_count       = 1
  // Enable Istio (beta)
  // https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster#nested_istio_config
  // not yet supported on Autopilot mode
  # addons_config {
  #   istio_config {
  #     disabled = false
  #     auth     = "AUTH_NONE"
  #   }
  # }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n2-standard-2" # 2 CPU and 8 GB RAM
  }
}

resource "google_compute_firewall" "default" {
  name    = "firewall-rules"
  network = "${var.self_link}"
  description = "Allow ports for model deployment"

  allow {
    protocol = "tcp"
    ports    = ["30000"]
  }

  direction = "INGRESS"
  
  source_tags = ["web"]
}