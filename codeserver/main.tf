resource "google_compute_project_metadata" "ssh_injector" {
  metadata = merge(
    {
      ssh-keys = join("\n", [for k, v in var.ssh_keys : "${var.ssh_keys[k].user}:${file("${var.ssh_keys[k].public_key}")}"])
    }
  )
}

provider "google" {
  version = "3.22.0"
  # use your credentials here
  credentials = file(<YOUR JSON CREDS>)

  project = "${var.gcp_project_id}"
  region  = "${var.gcp_region}"
  zone    = "${var.gcp_zone}"
}

#WARNING: templatefile() function can be used only with files that already exist on disk at the beginning of a Terraform run.
data "template_file" "nginx-source" {
  template = templatefile("${path.root}/nginx.tmpl", { port = 8080, ip_addrs = ["10.0.0.1", "10.0.0.2"] })
}

data "template_file" "key-installer" {
  template = templatefile("${path.root}/key-installer.tmpl", { port = 8080, ip_addrs = ["10.0.0.3", "10.0.0.4"] })
}

resource "google_compute_instance" "step_0" {
  // public IP
  // self.network_interface[0].access_config[0].nat_ip
  // private IP
  // self.network_interface.0.network_ip
  depends_on   = [google_compute_project_metadata.ssh_injector]
  name         = "${var.instance_name}-${count.index}"
  machine_type = "${var.gcp_machine_type}"
  zone         = "${var.gcp_zone}"
  count        = "${var.cluster_size}"
  tags         = "${var.firewall_tag}"
  boot_disk {
    initialize_params {
      image = "${var.disk_image}"
      size  = "${var.disk_size}"
      type  = "${var.disk_type}"
    }
  }
  network_interface {
    network            = var.subnetwork_name != null ? null : var.network_name
    subnetwork         = var.subnetwork_name != null ? var.subnetwork_name : null
    subnetwork_project = var.network_project_id != null ? var.network_project_id : var.gcp_project_id
    access_config {
      nat_ip = ""
    }
  }
  metadata = merge(

    {
      ssh-keys = "${var.ssh_keys[0].user}:${file("${var.ssh_keys[0].public_key}")}"
    }
  )
}
resource "null_resource" "step_1" {
  depends_on = [google_compute_instance.step_0]
  # Change trigger word to anything else when you make a change to tell Terraform to adopt change when you Terraform apply
  triggers = {
    foo = "bar"
  }
  count = "${var.cluster_size}"
  provisioner "remote-exec" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    inline = ["echo hello-world && echo ${google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip}"]
  }
  provisioner file {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    content     = "${data.template_file.nginx-source.rendered}"
    destination = "/tmp/nginx.list"
  }
  provisioner file {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    content     = "${data.template_file.key-installer.rendered}"
    destination = "/tmp/key-installer"
  }

  provisioner "remote-exec" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    inline = [
      "DEBIAN_FRONTEND=noninteractive; sudo mv /tmp/nginx.list /etc/apt/sources.list.d/nginx.list",
      "DEBIAN_FRONTEND=noninteractive; sudo mv /tmp/key-installer /usr/local/bin/key-installer",
      "DEBIAN_FRONTEND=noninteractive; sudo chmod +x /usr/local/bin/key-installer",
      "DEBIAN_FRONTEND=noninteractive; sudo key-installer",
      "DEBIAN_FRONTEND=noninteractive; sudo apt-get update -q ",
      "DEBIAN_FRONTEND=noninteractive; sudo apt-get install nginx ufw wget curl -yq",
      "DEBIAN_FRONTEND=noninteractive; sudo systemctl daemon-reload || true",
      "DEBIAN_FRONTEND=noninteractive; sudo systemctl enable nginx || true",
    ]
  }


}
resource "null_resource" "step_2" {
  # Change trigger word to anything else when you make a change to tell Terraform to adopt change.
  triggers = {
    foo = "buzz"
  }

  depends_on = [google_compute_instance.step_0, null_resource.step_1]
  count      = "${var.cluster_size}"
  provisioner "file" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    content     = <<EOF
    proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=codeserver_cache:10m max_size=3g inactive=120m use_temp_path=off;
    server {
    listen 80;
    listen [::]:80;
    server_name    ${google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip};
    location / {
        proxy_pass http://127.0.0.1:${var.upstream_port}/;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Accept-Encoding gzip;
        client_max_body_size 50M;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Real-Port $server_port;
        proxy_set_header X-Real-Scheme $scheme;
        proxy_set_header X-Frame-Options SAMEORIGIN;
        proxy_buffers 256 16k;
        proxy_buffer_size 16k;
        proxy_read_timeout 600s;
        proxy_cache codeserver_cache;
        proxy_cache_revalidate on;
        proxy_cache_min_uses 2;
        proxy_cache_use_stale timeout;
        proxy_cache_lock on;
    }
}

    EOF
    destination = "/tmp/code-server.conf"
  }
  provisioner "remote-exec" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    # When dealing with older nginx versions(1.14 and before), the default service is in sites-available and
    # sites-enabled. In newer versions it'll be under conf.d. In either case when you want to have your own service,
    # make sure you delete the default service because it'll overwrite your service. That's what I did in first two lines.
    inline = [
      "sudo rm -rf /etc/nginx/sites-available/default",
      "sudo rm -rf /etc/nginx/sites-enabled/default",
      "sudo rm -rf /etc/nginx/conf.d/default.conf",
      "sudo mv /tmp/code-server.conf /etc/nginx/conf.d/",
      "sudo nginx -t",
      "sudo systemctl restart nginx",
    ]
  }

}

resource "null_resource" "step_3" {
  depends_on = [google_compute_instance.step_0, null_resource.step_1, null_resource.step_2]
  count      = "${var.cluster_size}"
  provisioner "remote-exec" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    # Must keep wget command in one line, multi line is causing errors.
    inline = [
      "sudo rm -f /opt/code-server.tar.gz",
      "sudo wget -q -O /opt/code-server.tar.gz https://github.com/cdr/code-server/releases/download/${var.code_server_version}/code-server-${var.code_server_version}-linux-x86_64.tar.gz",
      "sudo mkdir -p /opt/code-server",
      "sudo tar -xvzf /opt/code-server.tar.gz -C /opt/code-server --strip-components=1",
      "sudo rm -rf /opt/code-server.tar.gz",
    ]
  }
}
# Change trigger word to anything else when you make a change to tell Terraform to adopt change.
resource "null_resource" "step_4" {
  triggers = {
    foo = "buzz"
  }
  depends_on = [google_compute_instance.step_0, null_resource.step_1, null_resource.step_2, null_resource.step_3]
  count      = "${var.cluster_size}"
  provisioner "file" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface[0].access_config[0].nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    # Must keep wget command in one line, multi line is causing errors.
    content     = <<EOF

      [Unit]
      Description=Code-Server
      After= syslog.target network.target nginx.target
      
      [Service]
      Type=simple
      Environment=PASSWORD=${var.server_password}
      WorkingDirectory=/opt/code-server
      ExecStart=/opt/code-server/code-server --bind-addr 0.0.0.0:${var.upstream_port} --extensions-dir /var/lib/code-server/extensions/ --user-data-dir /var/lib/code-server/user-data/ --auth password
      ExecReload=/bin/kill -s HUP $MAINPID
      User=root
      Restart=on-failure
      RestartSec=5
      LimitNOFILE=infinity
      LimitNPROC=infinity
      LimitCORE=infinity
      TimeoutStartSec=0
      KillMode=process
      
      [Install]
      WantedBy=multi-user.target


    EOF
    destination = "/tmp/code-server.service"
  }
  provisioner "remote-exec" {
    connection {
      host        = google_compute_instance.step_0[count.index].network_interface.0.access_config.0.nat_ip
      type        = "ssh"
      agent       = false
      user        = var.ssh_keys[0].user
      private_key = "${file("${var.ssh_keys[0].private_key}")}"
      timeout     = "2m"
    }
    inline = [
      "sudo mv /tmp/code-server.service /lib/systemd/system/code-server.service",
      "sudo rm -f /etc/systemd/system/multi-user.target.wants/code-server.service",
      "sudo ln -s /lib/systemd/system/code-server.service /etc/systemd/system/multi-user.target.wants/code-server.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable --now code-server",
      "sudo systemctl start code-server",
    ]
  }
}


