locals {
  private_frontend_ip_configuration_name = "frontend"
  public_frontend_ip_configuration_name = {
    cluster = "frontend-cluster"
    active  = "frontend-active"
    passive = "frontend-passive"
  }
}

resource "azurerm_public_ip" "cluster" {
  name                = local.cluster_public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_lb" "public_interface" {
  name                = local.public_load_balancer_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  # Cluster PIP used for outbound traffic
  frontend_ip_configuration {
    name                       = local.public_frontend_ip_configuration_name["cluster"]
    public_ip_address_id       = azurerm_public_ip.cluster.id
  }

  # Dedicated active and passive PIPs
  dynamic "frontend_ip_configuration" {
    for_each = local.appliance_config
    content {
      name                       = local.public_frontend_ip_configuration_name[frontend_ip_configuration.key]
      public_ip_address_id       = module.appliance[frontend_ip_configuration.key].public_ip_id
    }
  }

  tags = var.tags

  # Ignore changes to private_ip_address_version to prevent Terraform from trying to add it every apply.
  lifecycle {
    ignore_changes = [
      frontend_ip_configuration[0].private_ip_address_version,
      frontend_ip_configuration[1].private_ip_address_version,
      frontend_ip_configuration[2].private_ip_address_version
    ]
  }
}

resource "azurerm_lb_probe" "public_probe" {
  name                = "lbprobe"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.public_interface.id
  port                = 22
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "public_pool" {
  name            = "backend"
  loadbalancer_id = azurerm_lb.public_interface.id
}

resource "azurerm_network_interface_backend_address_pool_association" "public_pool" {
  for_each = local.appliance_config

  network_interface_id    = module.appliance[each.key].public_interface_id
  ip_configuration_name   = "ipconfig1" # Must be the same as the NIC IP-config name
  backend_address_pool_id = azurerm_lb_backend_address_pool.public_pool.id
}

# resource "azurerm_lb_rule" "public_http_rule" {
#   for_each = local.appliance_config

#   name                           = "lbrule-http-${each.key}"
#   resource_group_name            = var.resource_group_name
#   loadbalancer_id                = azurerm_lb.public_interface.id
#   protocol                       = "Tcp"
#   frontend_port                  = 80
#   backend_port                   = 80
#   enable_floating_ip             = true
#   idle_timeout_in_minutes        = 15
#   probe_id                       = azurerm_lb_probe.public_probe.id
#   frontend_ip_configuration_name = local.public_frontend_ip_configuration_name[each.key]
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.public_pool.id
# }

# resource "azurerm_lb_rule" "public_udp_rule" {
#   name                           = "lbrule-udp10551-active"
#   resource_group_name            = var.resource_group_name
#   loadbalancer_id                = azurerm_lb.public_interface.id
#   protocol                       = "Udp"
#   frontend_port                  = 10551
#   backend_port                   = 10551
#   enable_floating_ip             = false
#   idle_timeout_in_minutes        = 15
#   probe_id                       = azurerm_lb_probe.public_probe.id
#   frontend_ip_configuration_name = local.public_frontend_ip_configuration_name[active]
#   backend_address_pool_id        = azurerm_lb_backend_address_pool.public_pool.id
# }

resource "azurerm_lb_nat_rule" "public_ssh" {
  for_each = local.appliance_config

  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.public_interface.id
  name                           = format("SSH-%s", each.key)
  protocol                       = "Tcp"
  frontend_port                  = 22
  backend_port                   = 22
  enable_floating_ip             = false
  frontend_ip_configuration_name = local.public_frontend_ip_configuration_name[each.key]
}

resource "azurerm_lb_nat_rule" "public_https" {
  for_each = local.appliance_config

  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.public_interface.id
  name                           = format("HTTPS-%s", each.key)
  protocol                       = "Tcp"
  frontend_port                  = 8443
  backend_port                   = 8443
  enable_floating_ip             = false
  frontend_ip_configuration_name = local.public_frontend_ip_configuration_name[each.key]
}

resource "azurerm_network_interface_nat_rule_association" "public_ssh" {
  for_each = local.appliance_config

  network_interface_id  = module.appliance[each.key].public_interface_id
  ip_configuration_name = "ipconfig1" # Must be the same as the NIC IP-config name
  nat_rule_id           = azurerm_lb_nat_rule.public_ssh[each.key].id
}

resource "azurerm_network_interface_nat_rule_association" "public_https" {
  for_each = local.appliance_config

  network_interface_id  = module.appliance[each.key].public_interface_id
  ip_configuration_name = "ipconfig1" # Must be the same as the NIC IP-config name
  nat_rule_id           = azurerm_lb_nat_rule.public_https[each.key].id
}

resource "azurerm_lb_outbound_rule" "public_snat" {
  resource_group_name      = var.resource_group_name
  loadbalancer_id          = azurerm_lb.public_interface.id
  name                     = "outbound"
  protocol                 = "All"
  enable_tcp_reset         = false
  backend_address_pool_id  = azurerm_lb_backend_address_pool.public_pool.id
  idle_timeout_in_minutes  = 4
  allocated_outbound_ports = 32000

  frontend_ip_configuration {
    name = local.public_frontend_ip_configuration_name["cluster"]
  }
}

resource "azurerm_lb" "private_interface" {
  name                = local.private_load_balancer_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = local.private_frontend_ip_configuration_name
    subnet_id                     = var.private_subnet_id
    private_ip_address            = var.cluster_ip_address
    private_ip_address_allocation = "Static"
  }

  tags = var.tags
}

resource "azurerm_lb_probe" "private_probe" {
  name                = "lbprobe"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.private_interface.id
  port                = 22
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "private_pool" {
  name            = "backend"
  loadbalancer_id = azurerm_lb.private_interface.id
}

resource "azurerm_network_interface_backend_address_pool_association" "private_pool" {
  for_each = local.appliance_config

  network_interface_id    = module.appliance[each.key].private_interface_id
  ip_configuration_name   = "ipconfig1" # Must be the same as the NIC IP-config name
  backend_address_pool_id = azurerm_lb_backend_address_pool.private_pool.id
}

resource "azurerm_lb_rule" "private_rule" {
  name                           = "lbrule"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.private_interface.id
  protocol                       = "All"
  frontend_port                  = 0
  backend_port                   = 0
  enable_floating_ip             = true
  idle_timeout_in_minutes        = 15
  probe_id                       = azurerm_lb_probe.private_probe.id
  frontend_ip_configuration_name = local.private_frontend_ip_configuration_name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.private_pool.id
}
