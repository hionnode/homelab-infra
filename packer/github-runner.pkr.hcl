packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "proxmox_url" {
  type    = string
  default = "https://your-proxmox-host:8006/api2/json"
}

variable "proxmox_username" {
  type    = string
  default = "root@pam"
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "github_repo_url" {
  type    = string
  default = "https://github.com/YOUR_ORG/YOUR_REPO"
}

variable "runner_version" {
  type    = string
  default = "2.311.0"
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = number
  default = 4096
}

source "proxmox-clone" "github-runner" {
  # Proxmox connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  password                 = var.proxmox_password
  insecure_skip_tls_verify = true
  
  # Template settings
  template_name     = "rocky-9"
  template_storage  = "local"
  
  # Container settings
  container_id      = "999"  # Temporary ID for building
  hostname          = "github-runner-template"
  cores             = var.cores
  memory            = var.memory
  storage           = "local-lvm"
  disk_size         = "20G"
  
  # Network
  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  # Container type
  os                = "rocky"
  unprivileged      = true
  
  # SSH settings for provisioning
  ssh_username = "root"
  ssh_timeout  = "20m"
}

build {
  sources = ["source.proxmox-clone.github-runner"]
  
  # Update system
  provisioner "shell" {
    inline = [
      "dnf update -y",
      "dnf install -y curl wget git jq"
    ]
  }
  
  # Install Docker
  provisioner "shell" {
    inline = [
      "curl -fsSL https://get.docker.com -o get-docker.sh",
      "sh get-docker.sh",
      "usermod -aG docker root",
      "rm get-docker.sh"
    ]
  }
  
  # Install Node.js
  provisioner "shell" {
    inline = [
      "curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -",
      "dnf install -y nodejs"
    ]
  }
  
  # Install additional tools commonly needed
  provisioner "shell" {
    inline = [
      "dnf install -y python3 python3-pip",
      "pip3 install --upgrade pip",
      "dnf install -y awscli"
    ]
  }
  
  # Download and setup GitHub Actions Runner
  provisioner "shell" {
    inline = [
      "mkdir -p /opt/actions-runner",
      "cd /opt/actions-runner",
      "curl -o actions-runner-linux-x64-${var.runner_version}.tar.gz -L https://github.com/actions/runner/releases/download/v${var.runner_version}/actions-runner-linux-x64-${var.runner_version}.tar.gz",
      "tar xzf ./actions-runner-linux-x64-${var.runner_version}.tar.gz",
      "rm actions-runner-linux-x64-${var.runner_version}.tar.gz",
      "./bin/installdependencies.sh",
      "chown -R root:root /opt/actions-runner"
    ]
  }
  
  # Create runner registration script
  provisioner "file" {
    content = templatefile("${path.root}/scripts/register-runner.sh.tpl", {
      github_repo_url = var.github_repo_url
    })
    destination = "/opt/actions-runner/register-runner.sh"
  }
  
  provisioner "shell" {
    inline = [
      "chmod +x /opt/actions-runner/register-runner.sh"
    ]
  }
  
  # Create systemd service
  provisioner "file" {
    source      = "${path.root}/scripts/github-runner.service"
    destination = "/etc/systemd/system/github-runner.service"
  }
  
  # Create auto-shutdown script
  provisioner "file" {
    source      = "${path.root}/scripts/auto-shutdown.sh"
    destination = "/opt/actions-runner/auto-shutdown.sh"
  }
  
  provisioner "shell" {
    inline = [
      "chmod +x /opt/actions-runner/auto-shutdown.sh",
      "systemctl enable github-runner.service",
      "systemctl daemon-reload"
    ]
  }
  
  # Cleanup
  provisioner "shell" {
    inline = [
      "dnf clean all",
      "rm -rf /tmp/*",
      "rm -rf /var/tmp/*",
      "history -c"
    ]
  }
}