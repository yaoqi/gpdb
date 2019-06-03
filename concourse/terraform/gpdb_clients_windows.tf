provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.region_zone}"
}

resource "random_id" "id" {
  byte_length = 8
}

resource "google_compute_instance" "gpdb-clients" {
  name                      = "instance-${random_id.id.hex}"
  allow_stopping_for_update = "true"
  machine_type              = "n1-standard-2"

  boot_disk {
    source = "${google_compute_disk.windows2012.name}"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    scopes = ["storage-ro"]
  }
}
output "gpdb-clients-ip" {
  value = "${google_compute_instance.gpdb-clients.network_interface.0.access_config.0.nat_ip}"
}

resource "google_compute_disk" "windows2012" {
  name  = "disk-${random_id.id.hex}"
  type  = "pd-ssd"
  zone  = "${var.region_zone}"
  snapshot = "gpdb-win-remote-test"
}
