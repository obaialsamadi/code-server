variable "key-server" {
  type        = string
  default     = "keyserver.ubuntu.com"
  description = "Whenever to allow running Nomad client alongside Nomad server. Not recommended in production by Hashicorp"
}
variable "cluster_size" {
  type        = number
  description = "how many instances to create"
  default     = 3
}

variable "gcp_region" {
  description = "Region in which instance is created."
  default     = "us-central1"
}
variable "network_project_id" {
  description = <<EOF
  The name of the GCP Project where the network is located. 
  Useful when using networks shared between projects. 
  If empty, var.gcp_project_id will be used."
  EOF
  type        = string
  default     = null
}
variable "network_name" {
  type    = string
  default = "default"
}
variable "subnetwork_name" {
  type    = string
  default = null
}
variable "instance_name" {
  description = "The name given to the instances created that show up on GCP"
  default = "code-server"
}
variable "gcp_project_id" {
  type    = string
  default = "<GIVE DEFAULT ID>"
}

variable "gcp_machine_type" {
  default     = "n1-standard-2"
  description = "Instance machine type"
}

variable "gcp_zone" {
  default     = "us-central1-a"
  description = "Google Compute Engine zone to launch instances in"
}

variable "disk_image" {
  default     = "debian-cloud/debian-9"
  description = "Disk image type."
}
variable "disk_size" {
  default     = "150"
  description = "Insance disk size"
}
variable "disk_type" {
  default     = "pd-ssd"
  description = "Instance disk type. Can be pd-standard or pd-ssd"
}

variable "ssh_keys" {
  type = list(object({
    user        = string
    public_key  = string
    private_key = string
  }))
  default = [
    {
      user        = "<username>"
      public_key  = "~/.ssh/id_rsa.pub"
      private_key = "~/.ssh/id_rsa"
    }
  ]
}
variable "firewall_tag" {
  type = list(string)
  description = "keywords from GCP firewall rules. They open ports 80 and 443."
  default     = ["http-server", "https-server"]
}
variable "upstream_port" {
  default = 8080
}
variable "code_server_version" {
  default = "3.2.0"
}
variable "server_password" {
  description = "this is the password you would use to log into code server once deployed."
  default     = "my-password"
}