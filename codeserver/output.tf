output "external-ips" {
  value = tolist(google_compute_instance.step_0.*.network_interface.0.access_config.0.nat_ip)
}
output "internal-ips" {
  value = tolist(google_compute_instance.step_0.*.network_interface.0.network_ip)
}