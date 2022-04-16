# About

This terraform module allows you to manage a linux desktop vm (tested with ubuntu).

It allows you to manage the initial installation cycle as well.

# Usage

## Input Variables

- **os_installed**: Should be initially set to false and then true once the installation phase is complete. If set to false, your distribution iso file will be loaded as a disk and given boot priority. Otherwise, only your vm volume will be attached to your vm.
- **os_image_path**: Path to an os iso file you downloaded on your machine.
- **volume_pool**: Information about the volume pool that vm volume will be created in. Contains the following properties:
  - **name**: Name of the volume pool
  - **path**: Filesystem path of the volume pool. If defined, a volume pool will be created at that path. If set to null, it is assumed that the volume pool already exists and it won't be created.
- **volume_name**: Name of the volume that will be assigned to the vm. Defaults to **desktop-vm**.
- **vm_name**: Name of the vm. Defaults to **desktop-vm**
- **network**: Properties of the libvirt network the vm will be connected to. It contains the following properties:
  - **id**: If set to a non-null value, it is assumed that a network with the given id already exists and the vm will be connected to it. Otherwise, a new network will be generated.
  - **name**: Name to give to the generated network.
  - **ip_range**: Ip range to give to the network. An example value would be **192.168.55.0/24**
- **vm_specs**: Resources to allocated to the vm. It contains the following properties:
  - **cpu**: Number of cpu core the vm can use.
  - **memory**: Amount of memory (in GiB) the vm can use
  - **disk**: Amount of space (in GiB) the vm's volume can use.

## Example

Suppose I downloaded an ubuntu iso in my download folder, I could **terraform apply** the following orchestration:

```
module "ubuntu" {
  source = "git::https://github.com/Magnitus-/kvm-linux-desktop.git"
  os_image_path = "~/Downloads/kvm-linux-desktop/ubuntu-20.04.4-desktop-amd64.iso"
  volume_pool={
    name = "vm-desktop",
    path="~/kvm-linux-desktop"
  }
  os_installed=false
}
```

Then, after accessing the vm's installer menu with **virt-manager** and completing the installation, I can change the orchestration to this and run **terraform apply** again:

```
module "ubuntu" {
  source = "git::https://github.com/Magnitus-/kvm-linux-desktop.git"
  os_image_path = "~/Downloads/kvm-linux-desktop/ubuntu-20.04.4-desktop-amd64.iso"
  volume_pool={
    name = "vm-desktop",
    path="~/kvm-linux-desktop"
  }
  os_installed=true
}
```

# Gotchas

## Cleanup on Failure

The libvirt terraform provider have been known to leave dangling resources definitions (domains, volumes and volume pools) when the provisioner encounters errors after it started provisioning a resource.

If you encounter such a situation, you can delete dangling resources with **virsh**.

You can cleanup with the following commands...

Domains:
```
virsh list --all
virsh undefine <name of the domain>
```

Volume pools:
```
virsh pool-list --all
virsh pool-undefine <name of the pool>
```

Volumes:
```
virsh vol-list <name of the pool>
virsh vol-delete <name of the volume> --pool <name of the pool>
```

## Volume Permissions

I've encountered permission errors when provisioning volumes in pools with ubuntu.

To prevent those errors, you need to setup libvirt apparmor permissions for your volume pool path in the **/etc/apparmor.d/libvirt/TEMPLATE.qemu** file as follows:

```
#
# This profile is for the domain whose UUID matches this file.
#

#include <tunables/global>

profile LIBVIRT_TEMPLATE flags=(attach_disconnected) {
  #include <abstractions/libvirt-qemu>  
  "<path of your pool>/" r,
  "<path of your pool>/**" rwk,
}
```

For example, given that my volume pool is located at **/home/eric/kvm-linux-desktop/**, the file on my machine looks like this:

```
#
# This profile is for the domain whose UUID matches this file.
#

#include <tunables/global>

profile LIBVIRT_TEMPLATE flags=(attach_disconnected) {
  #include <abstractions/libvirt-qemu>  
  "/home/eric/kvm-linux-desktop/" r,
  "/home/eric/kvm-linux-desktop/**" rwk,
}
```

See: 
- https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/1677398
- https://bugs.launchpad.net/ubuntu/+source/libvirt/+bug/1677398/comments/43