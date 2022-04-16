variable "os_installed" {
  description = "Whether the os is installed. If false, the iso will be mounted and booted from. Else, only the vm volume will be mounted."
  type        = bool
  default     = false
}

variable "os_image_path" {
  description = "Path to os image"
  type        = string
}

variable "volume_pool" {
  description = "Volume pool that will contain the vm. It contains a name and path property. If the path is set to a non-null value, a volume pool will be created at that path otherwise it will be assumed that a volume pool with that name already exists"
  type = object({
    name = string
    path = string
  })
}

variable "volume_name" {
  description = "Name of the vm's volume"
  type        = string
  default     = "desktop-vm"
}

variable "vm_name" {
  description = "Name of the vm"
  type        = string
  default     = "desktop-vm"
}

variable "network" {
  description = "Specs for the vm libvirt network. You can pass a pre-existing libvirt network by defining an id property or otherwise have a new network be created by defining a name and ip_range property."
  type = object({
    id = string
    name = string
    ip_range = string
  })
  default = {
    id = null
    name = "desktop-vm"
    ip_range = "192.168.55.0/24"
  }
}

variable "vm_specs" {
  description = "Specs of the vm. Includes the following fields: cpu, memory and disk"
  type = object({
    cpu = number
    memory = number
    disk = number
  })
  default = {
    //2 cores
    cpu = 2
    //16GB
    memory = 16
    //30GB
    disk = 30
  }
}