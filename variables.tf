variable "resource_group_name" {
  type        = string
  description = "Name of an existing resource group where the resources should be deployed to."

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,63}$", var.resource_group_name))
    error_message = "Value must be between 3 to 63 characters long, consisting of alphanumeric characters and hyphens."
  }
}

variable "location" {
  type        = string
  description = "Location used for the deployed resources. Must be the same as the location used for network resources (virtual network, subnet)."
}

variable "active_appliance_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_appliance_name" {
  type        = string
  description = ""
  default     = null
}

variable "size" {
  type        = string
  description = "VM size for the appliance. Size must support SSDs. Default is the smallest size that supports accelerated networking."
  default     = "Standard_DS2_v2"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_]{11,}$", var.size))
    error_message = "The value must be a valid VM size."
  }
}

variable "license_type" {
  type        = string
  description = "Specifies the license type for the deployed appliances."
  default     = "payg"

  validation {
    condition     = contains(["payg", "byol"], lower(var.license_type))
    error_message = "Value of license_type must be either PAYG or BYOL."
  }
}

variable "os_version" {
  type        = string
  description = "Specifies the version number of the FortiOS release to deploy."
  default     = "6.4.5"

  validation {
    condition     = contains(["6.4.5"], var.os_version)
    error_message = "OS version is not supported by this module."
  }
}

variable "active_license_path" {
  type        = string
  description = "Path to a license file used for BYOL deployments. Defaults to license_active.lic in the root module directory."
  default     = null
}

variable "passive_license_path" {
  type        = string
  description = "Path to a license file used for BYOL deployments. Defaults to license_passive.lic in the root module directory."
  default     = null
}

variable "config_path" {
  type        = string
  description = "Path to a custom configuration file used while deploying the firewall. Defaults to the config file provided with the module."
  default     = null
}

variable "log_disk_size_gb" {
  type        = number
  description = "Size (in GB) of the disk used for appliance logs."
  default     = 30
}

variable "admin_username" {
  type        = string
  description = "Username for the default admin account."
  default     = "fgtadmin"
}

variable "admin_password" {
  type        = string
  description = "Password for the default admin account."
  sensitive   = true
}

variable "availability_set_name" {
  type        = string
  description = ""
  default     = null
}

variable "active_public_ip_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_public_ip_name" {
  type        = string
  description = ""
  default     = null
}

variable "active_public_interface_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_public_interface_name" {
  type        = string
  description = ""
  default     = null
}

variable "active_private_interface_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_private_interface_name" {
  type        = string
  description = ""
  default     = null
}

variable "active_public_interface_ip_address" {
  type        = string
  description = ""

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.active_public_interface_ip_address))
    error_message = "The value must be a valid IPv4-address."
  }
}

variable "passive_public_interface_ip_address" {
  type        = string
  description = ""

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.passive_public_interface_ip_address))
    error_message = "The value must be a valid IPv4-address."
  }
}

variable "active_private_interface_ip_address" {
  type        = string
  description = ""

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.active_private_interface_ip_address))
    error_message = "The value must be a valid IPv4-address."
  }
}

variable "passive_private_interface_ip_address" {
  type        = string
  description = ""

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.passive_private_interface_ip_address))
    error_message = "The value must be a valid IPv4-address."
  }
}

variable "active_os_disk_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_os_disk_name" {
  type        = string
  description = ""
  default     = null
}

variable "active_log_disk_name" {
  type        = string
  description = ""
  default     = null
}

variable "passive_log_disk_name" {
  type        = string
  description = ""
  default     = null
}

variable "disk_encryption_set_id" {
  type        = string
  description = "Resource ID of an disk encryption set the appliance should use. Will be skipped if omitted. Note that the managed identity must have access to the encryption key for this to work."
  default     = null

  # validation {
  #   condition     = can(regex("^/(subscriptions/[a-z0-9-]{36}/resourceGroups/[a-zA-Z0-9-]{3,63}/providers/Microsoft.Compute/diskEncryptionSets/[a-z0-9-]{1,80}$", var.disk_encryption_set_id))
  #   error_message = "The value must be a valid disk encryption set resource ID."
  # }
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the managed identity which the appliance will use for the SDN connector functionality and accessing disk encryption keys."

  validation {
    condition     = can(regex("^/subscriptions/[a-z0-9-]{36}/resourceGroups/[a-zA-Z0-9-]{3,63}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/[a-z0-9-]{3,128}$", var.user_assigned_identity_id))
    error_message = "The value must be a valid User Assigned Identity resource ID."
  }
}

variable "public_subnet_id" {
  type        = string
  description = "Resource ID of the subnet where the public (internet facing) NIC will be residing."

  validation {
    condition     = can(regex("^/subscriptions/[a-z0-9-]{36}/resourceGroups/[a-zA-Z0-9-]{3,63}/providers/Microsoft.Network/virtualNetworks/[a-z0-9-]{2,64}/subnets/[a-z0-9-]{1,80}$", var.public_subnet_id))
    error_message = "The value must be a valid subnet resource ID."
  }
}

variable "private_subnet_id" {
  type        = string
  description = "Resource ID of the subnet where the private (non-internet facing) NIC will be residing."

  validation {
    condition     = can(regex("^/subscriptions/[a-z0-9-]{36}/resourceGroups/[a-zA-Z0-9-]{3,63}/providers/Microsoft.Network/virtualNetworks/[a-z0-9-]{2,64}/subnets/[a-z0-9-]{1,80}$", var.private_subnet_id))
    error_message = "The value must be a valid subnet resource ID."
  }
}

variable "cluster_ip_address" {
  type        = string
  description = "Virtual IP-address of the cluster."

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.cluster_ip_address))
    error_message = "The value must be a valid IPv4-address."
  }
}

variable "cluster_public_ip_name" {
  type        = string
  description = ""
  default     = null
}

variable "public_load_balancer_name" {
  type        = string
  description = ""
  default     = null
}

variable "private_load_balancer_name" {
  type        = string
  description = ""
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags that should be added to the deployed resources."
  default     = {}
}

variable "boot_diagnostics_storage_account_uri" {
  type        = string
  description = "URI to storage account primary blob endpoint for boot diagnostic files. Optional."
  default     = null
}
