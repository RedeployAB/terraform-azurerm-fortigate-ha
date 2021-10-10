# Azure FortiGate Terraform Module

This module deploys a highly-available FortiGate appliance to a virtual network.

* Pre-configured with the Azure SDN connector (using managed identity).
* Supports customer-managed keys for disk encryption.
* Can be used with both PAYG and BYOL.

## Prerequisites

* A resource group where you have Contributor access.
* A virtual network with four subnets and [pre-configured routing][fortigate-azure-routing], which you have join access to.
* A managed identity, which can see the network objects you want to reference in the FortiGate.

## Example deployment

```terraform
# Start by creating the referenced resources

module "fortigate" {
  source = "github.com/RedeployAB/terraform-azurerm-fortigate-ha?ref=v0.1.0"

  name                = "fgtvm"
  resource_group_name = azurerm_resource_group.fortigate.name
  location            = azurerm_resource_group.fortigate.location
  os_version          = "6.4.6"

  # Root credentials
  admin_username = random_string.appliance_admin.result
  admin_password = random_password.appliance_admin.result

  # Subnet references
  public_subnet_id  = azurerm_subnet.existing_network["public"].id
  private_subnet_id = azurerm_subnet.existing_network["private"].id
  hasync_subnet_id  = azurerm_subnet.existing_network["hasync"].id
  mgmt_subnet_id    = azurerm_subnet.existing_network["mgmt"].id

  # IP-address assignments
  cluster_ip_address                   = cidrhost(azurerm_subnet.existing_network["private"].address_prefixes[0], 4)
  active_public_interface_ip_address   = cidrhost(azurerm_subnet.existing_network["public"].address_prefixes[0], 4)
  active_private_interface_ip_address  = cidrhost(azurerm_subnet.existing_network["private"].address_prefixes[0], 5)
  active_hasync_interface_ip_address   = cidrhost(azurerm_subnet.existing_network["hasync"].address_prefixes[0], 4)
  active_mgmt_interface_ip_address     = cidrhost(azurerm_subnet.existing_network["mgmt"].address_prefixes[0], 4)
  passive_public_interface_ip_address  = cidrhost(azurerm_subnet.existing_network["public"].address_prefixes[0], 5)
  passive_private_interface_ip_address = cidrhost(azurerm_subnet.existing_network["private"].address_prefixes[0], 6)
  passive_hasync_interface_ip_address  = cidrhost(azurerm_subnet.existing_network["hasync"].address_prefixes[0], 5)
  passive_mgmt_interface_ip_address    = cidrhost(azurerm_subnet.existing_network["mgmt"].address_prefixes[0], 5)

  # Azure SDN managed identity
  user_assigned_identity_id = azurerm_user_assigned_identity.fortigate.id
}

```

See [`variables.tf`](./variables.tf) for a complete list of the supported variables.

## License

This module is licensed under the [MIT License](./LICENSE).

<!-- References -->

[fortigate-azure-routing]: https://docs.fortinet.com/document/fortigate-public-cloud/6.4.0/azure-administration-guide/609353/azure-routing-and-network-interfaces
