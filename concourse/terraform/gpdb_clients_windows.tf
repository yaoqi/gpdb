provider "google" {
  project = "${var.project}"
  region  = "${var.region}"
  zone    = "${var.region_zone}"
}

resource "google_compute_instance" "gpdb-clients" {
  name                      = "gpdb-clients"
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
  name  = "windows2012-boot-disk"
  type  = "pd-ssd"
  zone  = "${var.region_zone}"
  snapshot = "windows2012-core-enable-winrm"
}