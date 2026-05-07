variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-terraform-demo"
}

variable "location" {
  description = "Azure region — eastus2 has better B-series availability than eastus"
  type        = string
  default     = "eastus2"
}

variable "project_name" {
  description = "Short name used to prefix all resources"
  type        = string
  default     = "demo"
}

variable "vm_size" {
  description = "VM SKU — Standard_DS1_v2 is widely available across all regions"
  type        = string
  default     = "Standard_DS1_v2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to your SSH public key file on your local machine"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "my_ip_address" {
  description = "Your public IP in CIDR notation e.g. 203.0.113.5/32 — restricts SSH access"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    Environment = "demo"
    ManagedBy   = "Terraform"
    Project     = "terraform-azure-demo"
  }
}