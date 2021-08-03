locals {
  # A selection of supported accelerated networking sizes that
  # most likely covers +90% of the deployment scenarios.
  # enable_accelerated_networking = contains(local.supported_accelerated_networking_sizes, var.size)
  # supported_accelerated_networking_sizes = [
  #   "Standard_F4s_v2",
  #   "Standard_F8s_v2",
  #   "Standard_F16s_v2",
  #   "Standard_D4s_v4",
  #   "Standard_D8s_v4",
  #   "Standard_D16s_v4",
  #   "Standard_DS2_v2",
  #   "Standard_DS3_v2",
  #   "Standard_DS4_v2",
  #   "Standard_DS5_v2",
  #   "Standard_D4s_v3",
  #   "Standard_D8s_v3",
  #   "Standard_D16s_v3"
  # ]

  plan = {
    publisher = "fortinet"
    offer     = "fortinet_fortigate-vm_v5"
    sku = {
      byol = "fortinet_fg-vm"
      payg = "fortinet_fg-vm_payg_20190624"
    }
  }

  # Default resource names
  os_disk_name   = coalesce(var.os_disk_name, "os-${var.name}")
  log_disk_name  = coalesce(var.log_disk_name, "data-${var.name}")
  public_ip_name = coalesce(var.public_ip_name, "pip-${var.name}")
  network_interfaces = {
    public = {
      name               = coalesce(var.public_interface_name, "nic-${var.name}-internet")
      private_ip_address = var.public_interface_ip_address
      gateway_ip_address = cidrhost(data.azurerm_subnet.appliance["public"].address_prefixes[0], 1)
      network_mask       = cidrnetmask(data.azurerm_subnet.appliance["public"].address_prefixes[0])
      subnet_id          = var.public_subnet_id
    }
    private = {
      name               = coalesce(var.private_interface_name, "nic-${var.name}-transit")
      private_ip_address = var.private_interface_ip_address
      gateway_ip_address = cidrhost(data.azurerm_subnet.appliance["private"].address_prefixes[0], 1)
      network_mask       = cidrnetmask(data.azurerm_subnet.appliance["private"].address_prefixes[0])
      subnet_id          = var.private_subnet_id
    }
    hasync = {
      name               = coalesce(var.hasync_interface_name, "nic-${var.name}-hasync")
      private_ip_address = var.hasync_interface_ip_address
      gateway_ip_address = cidrhost(data.azurerm_subnet.appliance["hasync"].address_prefixes[0], 1)
      network_mask       = cidrnetmask(data.azurerm_subnet.appliance["hasync"].address_prefixes[0])
      subnet_id          = var.hasync_subnet_id
    }
    mgmt = {
      name               = coalesce(var.mgmt_interface_name, "nic-${var.name}-mgmt")
      private_ip_address = var.mgmt_interface_ip_address
      gateway_ip_address = cidrhost(data.azurerm_subnet.appliance["mgmt"].address_prefixes[0], 1)
      network_mask       = cidrnetmask(data.azurerm_subnet.appliance["mgmt"].address_prefixes[0])
      subnet_id          = var.mgmt_subnet_id
    }
  }

  subnets = {
    public = {
      name                 = split("/", var.public_subnet_id)[10]
      virtual_network_name = split("/", var.public_subnet_id)[8]
      resource_group_name  = split("/", var.public_subnet_id)[4]
    }
    private = {
      name                 = split("/", var.private_subnet_id)[10]
      virtual_network_name = split("/", var.private_subnet_id)[8]
      resource_group_name  = split("/", var.private_subnet_id)[4]
    }
    hasync = {
      name                 = split("/", var.hasync_subnet_id)[10]
      virtual_network_name = split("/", var.hasync_subnet_id)[8]
      resource_group_name  = split("/", var.hasync_subnet_id)[4]
    }
    mgmt = {
      name                 = split("/", var.mgmt_subnet_id)[10]
      virtual_network_name = split("/", var.mgmt_subnet_id)[8]
      resource_group_name  = split("/", var.mgmt_subnet_id)[4]
    }
  }
}

locals {
  license_path     = coalesce(var.license_path, "${path.root}/license.lic")
  config_path      = coalesce(var.config_path, "${path.module}/bootstrap.conf")
  license_contents = fileexists(local.license_path) ? file(local.license_path) : null
}

