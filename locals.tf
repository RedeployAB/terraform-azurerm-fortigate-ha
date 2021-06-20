locals {
  # Default resource names
  availability_set_name      = coalesce(var.availability_set_name, "as-fw")
  public_load_balancer_name  = coalesce(var.public_load_balancer_name, "lb-fw")
  private_load_balancer_name = coalesce(var.private_load_balancer_name, "lb-fw-internal")
  cluster_public_ip_name     = coalesce(var.cluster_public_ip_name, "pip-fw")

  fw_name = {
    active  = coalesce(var.active_fw_name, "fw01")
    passive = coalesce(var.passive_fw_name, "fw02")
  }

  appliance_config = {
    active = {
      name                         = local.fw_name.active
      size                         = var.size
      os_version                   = var.os_version
      license_type                 = var.license_type
      license_path                 = coalesce(var.active_license_path, "${path.root}/active-license.lic")
      config_path                  = var.config_path
      public_interface_ip_address  = var.active_public_interface_ip_address
      private_interface_ip_address = var.active_private_interface_ip_address
      public_ip_name               = coalesce(var.active_public_ip_name, "pip-${local.fw_name.active}")
      public_interface_name        = coalesce(var.active_public_interface_name, "nic-${local.fw_name.active}-01")
      private_interface_name       = coalesce(var.active_private_interface_name, "nic-${local.fw_name.active}-02")
      os_disk_name                 = coalesce(var.active_os_disk_name, "os-${local.fw_name.active}")
      log_disk_name                = coalesce(var.active_log_disk_name, "data-${local.fw_name.active}-01")
    }
    passive = {
      name                         = local.fw_name.passive
      size                         = var.size
      os_version                   = var.os_version
      license_type                 = var.license_type
      license_path                 = coalesce(var.passive_license_path, "${path.root}/passive-license.lic")
      config_path                  = var.config_path
      public_interface_ip_address  = var.passive_public_interface_ip_address
      private_interface_ip_address = var.passive_private_interface_ip_address
      public_ip_name               = coalesce(var.passive_public_ip_name, "pip-${local.fw_name.passive}")
      public_interface_name        = coalesce(var.passive_public_interface_name, "nic-${local.fw_name.passive}-01")
      private_interface_name       = coalesce(var.passive_private_interface_name, "nic-${local.fw_name.passive}-02")
      os_disk_name                 = coalesce(var.passive_os_disk_name, "os-${local.fw_name.passive}")
      log_disk_name                = coalesce(var.passive_log_disk_name, "data-${local.fw_name.passive}-01")
    }
  }
}
