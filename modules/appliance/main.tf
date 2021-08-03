resource "azurerm_public_ip" "appliance" {
  name                = local.public_ip_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"

  tags = var.tags
}

resource "azurerm_network_interface" "appliance" {
  for_each = local.network_interfaces

  name                          = each.value.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  enable_accelerated_networking = true
  enable_ip_forwarding          = each.key == "public" || each.key == "private" ? true : false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip_address
    public_ip_address_id          = each.key == "mgmt" && var.attach_public_ip ? azurerm_public_ip.appliance.id : null
  }

  tags = var.tags
}

resource "azurerm_linux_virtual_machine" "appliance" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  size                            = var.size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password
  disable_password_authentication = false
  availability_set_id             = var.availability_set_id

  custom_data = base64encode(data.template_file.config.rendered)

  # Interface order must be specified so the public interface
  # is selected as the primary interface.
  network_interface_ids = [
    azurerm_network_interface.appliance["public"].id,
    azurerm_network_interface.appliance["private"].id,
    azurerm_network_interface.appliance["hasync"].id,
    azurerm_network_interface.appliance["mgmt"].id
  ]

  source_image_reference {
    publisher = local.plan.publisher
    offer     = local.plan.offer
    sku       = local.plan.sku[var.license_type]
    version   = var.os_version
  }

  plan {
    name      = local.plan.sku[var.license_type]
    publisher = local.plan.publisher
    product   = local.plan.offer
  }

  os_disk {
    name                   = local.os_disk_name
    caching                = "ReadWrite"
    storage_account_type   = "Premium_LRS"
    disk_encryption_set_id = var.disk_encryption_set_id
  }

  # Setting storage_account_uri to null creates a
  # managed boot diagnostic storage account.
  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_account_uri
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.user_assigned_identity_id]
  }

  tags = var.tags
}

resource "azurerm_managed_disk" "logs" {
  name                = local.log_disk_name
  resource_group_name = var.resource_group_name
  location            = var.location

  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = var.log_disk_size_gb
  disk_encryption_set_id = var.disk_encryption_set_id

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "logs" {
  managed_disk_id    = azurerm_managed_disk.logs.id
  virtual_machine_id = azurerm_linux_virtual_machine.appliance.id
  lun                = 0
  caching            = "ReadWrite"
}

data "azurerm_subnet" "appliance" {
  for_each = local.subnets

  name                 = each.value.name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.resource_group_name
}

data "template_file" "config" {
  template = file(var.config_path)
  vars = {
    license_type               = var.license_type
    license_file_contents      = local.license_contents
    public_gateway_ip_address  = local.network_interfaces["public"].gateway_ip_address
    private_gateway_ip_address = local.network_interfaces["private"].gateway_ip_address
    mgmt_gateway_ip_address    = local.network_interfaces["mgmt"].gateway_ip_address
    hasync_priority            = var.hasync_priority
    hasync_peer_ip_address     = var.hasync_peer_ip_address
  }
}
