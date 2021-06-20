resource "azurerm_availability_set" "appliance" {
  name                = local.availability_set_name
  resource_group_name = var.resource_group_name
  location            = var.location

  platform_update_domain_count = 2
  platform_fault_domain_count  = 2

  tags = var.tags
}

module "appliance" {
  for_each = local.appliance_config
  source   = "github.com/RedeployAB/terraform-azurerm-fortigate-single"

  name                = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = each.value.size
  os_version          = each.value.os_version
  license_type        = each.value.license_type
  license_path        = each.value.license_path
  config_path         = each.value.config_path

  admin_username = var.admin_username
  admin_password = var.admin_password

  attach_public_ip                     = false
  availability_set_id                  = azurerm_availability_set.appliance.id
  disk_encryption_set_id               = var.disk_encryption_set_id
  boot_diagnostics_storage_account_uri = var.boot_diagnostics_storage_account_uri
  log_disk_size_gb                     = var.log_disk_size_gb

  public_subnet_id             = var.public_subnet_id
  public_interface_ip_address  = each.value.public_interface_ip_address
  private_subnet_id            = var.private_subnet_id
  private_interface_ip_address = each.value.private_interface_ip_address

  os_disk_name           = each.value.os_disk_name
  log_disk_name          = each.value.log_disk_name
  public_interface_name  = each.value.public_interface_name
  private_interface_name = each.value.private_interface_name
  public_ip_name         = each.value.public_ip_name

  user_assigned_identity_id = var.user_assigned_identity_id

  tags = var.tags
}
