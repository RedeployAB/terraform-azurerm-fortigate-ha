resource "azurerm_public_ip" "cluster" {
  name                = local.cluster_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_lb" "interface" {
  for_each = local.lb_config

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  dynamic "frontend_ip_configuration" {
    for_each = each.value.frontend_ip_configuration

    content {
      name                          = frontend_ip_configuration.value.name
      subnet_id                     = frontend_ip_configuration.value.subnet_id
      public_ip_address_id          = frontend_ip_configuration.value.public_ip_address_id
      private_ip_address            = frontend_ip_configuration.value.private_ip_address
      private_ip_address_allocation = frontend_ip_configuration.value.private_ip_address_allocation
    }
  }

  tags = var.tags

  # Ignore changes to private_ip_address_version to prevent Terraform from trying to add it every apply.
  lifecycle {
    ignore_changes = [
      frontend_ip_configuration[0].private_ip_address_version,
      frontend_ip_configuration[1].private_ip_address_version
    ]
  }
}

resource "azurerm_lb_probe" "http_probe" {
  for_each = local.lb_ids

  name                = "http-probe"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = each.value
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "pool" {
  for_each = local.lb_ids

  name            = "backend"
  loadbalancer_id = azurerm_lb.interface[each.key].id
}

# TODO: Merge these two pool associations into one, flatten and for_each
resource "azurerm_network_interface_backend_address_pool_association" "public_pool" {
  for_each = local.appliance_config

  network_interface_id    = module.appliance[each.key].public_interface_id
  ip_configuration_name   = "ipconfig1" # Must be the same as the NIC IP-config name
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool["public"].id
}

resource "azurerm_network_interface_backend_address_pool_association" "private_pool" {
  for_each = local.appliance_config

  network_interface_id    = module.appliance[each.key].private_interface_id
  ip_configuration_name   = "ipconfig1" # Must be the same as the NIC IP-config name
  backend_address_pool_id = azurerm_lb_backend_address_pool.pool["private"].id
}

resource "azurerm_lb_outbound_rule" "public_snat" {
  name                     = "outbound"
  resource_group_name      = var.resource_group_name
  loadbalancer_id          = azurerm_lb.interface["public"].id
  protocol                 = "All"
  enable_tcp_reset         = false
  backend_address_pool_id  = azurerm_lb_backend_address_pool.pool["public"].id
  idle_timeout_in_minutes  = 4
  allocated_outbound_ports = 32000 # half per instance

  frontend_ip_configuration {
    name = local.lb_config["public"].frontend_ip_configuration[0].name
  }
}


resource "azurerm_lb_rule" "private_rule" {
  name                           = "lbrule"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.interface["private"].id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 15
  probe_id                       = azurerm_lb_probe.http_probe["private"].id
  frontend_ip_configuration_name = local.lb_config["private"].frontend_ip_configuration[0].name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.pool["private"].id
}
