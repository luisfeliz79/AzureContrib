// Variables
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_location" {
  description = "Location of the virtual machine"
  type        = string
}

variable "vm_rg_name" {
  description = "Resource group name"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "vm_admin_username" {
  description = "Admin username"
  type        = string
}

variable "vm_admin_password" {
  description = "Admin password"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map
}

variable "vm_subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP"
  type        = bool
  default     = false
}

variable "cloudinit" {
  description = "the cloud init for the vm"
  type = string
  default = <<CUSTOM_DATA
#!/bin/bash
sudo apt update -y
exit 0
CUSTOM_DATA
}

