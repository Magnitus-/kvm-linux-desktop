resource "libvirt_pool" "desktop_vm" {
  count = var.volume_pool.path != null ? 1 : 0
  name = var.volume_pool.name
  type = "dir"
  path = pathexpand(var.volume_pool.path)
}

resource "libvirt_volume" "desktop_vm" {
  name             = var.volume_pool.path != null ? libvirt_pool.desktop_vm.0.name : var.volume_name
  pool             = var.volume_pool.name
  size             = var.vm_specs.disk * 1024 * 1024 * 1024
  format           = "qcow2"
}

resource "libvirt_network" "desktop_vm" {
  count = var.network.id == null ? 1 : 0
  name = var.network.name
  addresses = [var.network.ip_range]
  dhcp {
    enabled = true
  }
  dns {
    enabled = true
  }
}

locals {
  disks = var.os_installed ? [{
      volume_id = libvirt_volume.desktop_vm.id
      file = null
    }] : [{
      volume_id = libvirt_volume.desktop_vm.id
      file = null
    }, {
      volume_id = null
      file = pathexpand(var.os_image_path)
    }]
  boot_device = var.os_installed ? "hd" : "cdrom"
}

resource "libvirt_domain" "desktop_vm" {
  name = var.vm_name

  cpu {
    mode = "host-passthrough"
  }

  vcpu = var.vm_specs.cpu
  memory = var.vm_specs.memory * 1024

  dynamic "disk" {
    for_each = local.disks
    content {
      volume_id = disk.value.volume_id
      file = disk.value.file
    }
  }

  boot_device {
    dev = [local.boot_device]
  }

  network_interface {
    network_id = var.network.id != null ? var.network.id : libvirt_network.desktop_vm.0.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "tcp"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type = "vnc"
    listen_type = "0.0.0.0"
  }

}