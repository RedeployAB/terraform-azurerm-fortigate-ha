resource "random_string" "appliance_admin" {
  length  = 8
  upper   = false
  special = false
}

resource "random_password" "appliance_admin" {
  length           = 32
  special          = true
  override_special = "!@$-_"
}

resource "random_id" "deployment" {
  byte_length = 2
}

resource "random_id" "appliance" {
  for_each    = toset(["active", "passive"])
  byte_length = 2
}

locals {
  deployment_name = "test-fgtvm-${random_id.deployment.hex}"
}

module "test_deployment" {
  source = "../../."

  active_fw_name             = format("${local.deployment_name}-%s", random_id.appliance["active"].hex)
  passive_fw_name            = format("${local.deployment_name}-%s", random_id.appliance["passive"].hex)
  availability_set_name      = "as-${local.deployment_name}"
  public_load_balancer_name  = "lb-${local.deployment_name}"
  private_load_balancer_name = "lb-${local.deployment_name}-internal"
  cluster_public_ip_name     = "pip-${local.deployment_name}"
  resource_group_name        = azurerm_virtual_network.test_environment.resource_group_name
  location                   = azurerm_virtual_network.test_environment.location
  size                       = var.size
  os_version                 = var.os_version

  admin_username = random_string.appliance_admin.result
  admin_password = random_password.appliance_admin.result

  public_subnet_id                     = azurerm_subnet.test_environment["public"].id
  private_subnet_id                    = azurerm_subnet.test_environment["private"].id
  cluster_ip_address                   = cidrhost(azurerm_subnet.test_environment["private"].address_prefixes[0], 4)
  active_public_interface_ip_address   = cidrhost(azurerm_subnet.test_environment["public"].address_prefixes[0], 4)
  active_private_interface_ip_address  = cidrhost(azurerm_subnet.test_environment["private"].address_prefixes[0], 5)
  passive_public_interface_ip_address  = cidrhost(azurerm_subnet.test_environment["public"].address_prefixes[0], 5)
  passive_private_interface_ip_address = cidrhost(azurerm_subnet.test_environment["private"].address_prefixes[0], 6)

  user_assigned_identity_id = azurerm_user_assigned_identity.test_environment.id

  tags = data.azurerm_resource_group.test_environment.tags
}
