locals {
  # Default resource names
  availability_set_name      = coalesce(var.availability_set_name, "as-fw")
  public_load_balancer_name  = coalesce(var.public_load_balancer_name, "lb-fw-public")
  private_load_balancer_name = coalesce(var.private_load_balancer_name, "lb-fw-internal")
  cluster_public_ip_name     = coalesce(var.cluster_public_ip_name, "pip-fw")
  appliance_name = {
    active  = coalesce(var.active_appliance_name, "fw01")
    passive = coalesce(var.passive_appliance_name, "fw02")
  }

  appliance_config = {
    active = {
      name                         = local.appliance_name.active
      size                         = var.size
      os_version                   = var.os_version
      license_type                 = var.license_type
      license_path                 = coalesce(var.active_license_path, "${path.root}/license_active.lic")
      config_path                  = coalesce(var.active_config_path, "${path.module}/bootstrap.conf")
      public_interface_ip_address  = var.active_public_interface_ip_address
      private_interface_ip_address = var.active_private_interface_ip_address
      hasync_interface_ip_address  = var.active_hasync_interface_ip_address
      mgmt_interface_ip_address    = var.active_mgmt_interface_ip_address
      hasync_peer_ip_address       = var.passive_hasync_interface_ip_address
      public_ip_name               = coalesce(var.active_public_ip_name, "pip-${local.appliance_name.active}")
      public_interface_name        = coalesce(var.active_public_interface_name, "nic-${local.appliance_name.active}-01")
      private_interface_name       = coalesce(var.active_private_interface_name, "nic-${local.appliance_name.active}-02")
      hasync_interface_name        = coalesce(var.active_hasync_interface_name, "nic-${local.appliance_name.active}-03")
      mgmt_interface_name          = coalesce(var.active_mgmt_interface_name, "nic-${local.appliance_name.active}-04")
      os_disk_name                 = coalesce(var.active_os_disk_name, "os-${local.appliance_name.active}")
      log_disk_name                = coalesce(var.active_log_disk_name, "data-${local.appliance_name.active}-01")
    }
    passive = {
      name                         = local.appliance_name.passive
      size                         = var.size
      os_version                   = var.os_version
      license_type                 = var.license_type
      license_path                 = coalesce(var.passive_license_path, "${path.root}/license_passive.lic")
      config_path                  = coalesce(var.passive_config_path, "${path.module}/bootstrap.conf")
      public_interface_ip_address  = var.passive_public_interface_ip_address
      private_interface_ip_address = var.passive_private_interface_ip_address
      hasync_interface_ip_address  = var.passive_hasync_interface_ip_address
      mgmt_interface_ip_address    = var.passive_mgmt_interface_ip_address
      hasync_peer_ip_address       = var.active_hasync_interface_ip_address
      public_ip_name               = coalesce(var.passive_public_ip_name, "pip-${local.appliance_name.passive}")
      public_interface_name        = coalesce(var.passive_public_interface_name, "nic-${local.appliance_name.passive}-01")
      private_interface_name       = coalesce(var.passive_private_interface_name, "nic-${local.appliance_name.passive}-02")
      hasync_interface_name        = coalesce(var.passive_hasync_interface_name, "nic-${local.appliance_name.passive}-03")
      mgmt_interface_name          = coalesce(var.passive_mgmt_interface_name, "nic-${local.appliance_name.passive}-04")
      os_disk_name                 = coalesce(var.passive_os_disk_name, "os-${local.appliance_name.passive}")
      log_disk_name                = coalesce(var.passive_log_disk_name, "data-${local.appliance_name.passive}-01")
    }
  }

  lb_ids = {
    public  = azurerm_lb.interface["public"].id
    private = azurerm_lb.interface["private"].id
  }

  lb_config = {
    public = {
      name = local.public_load_balancer_name
      frontend_ip_configuration = [{
        name                          = "frontend-cluster"
        subnet_id                     = null
        public_ip_address_id          = azurerm_public_ip.cluster.id
        private_ip_address            = null
        private_ip_address_allocation = null
      }]
    }
    private = {
      name = local.private_load_balancer_name
      frontend_ip_configuration = [{
        name                          = "frontend"
        subnet_id                     = var.private_subnet_id
        public_ip_address_id          = null
        private_ip_address            = var.cluster_ip_address
        private_ip_address_allocation = "Static"
      }]
    }
  }
}
