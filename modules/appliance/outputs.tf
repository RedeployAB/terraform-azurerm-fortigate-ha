output "public_ip_id" {
  value = azurerm_public_ip.appliance.id
}

output "public_interface_id" {
  value = azurerm_network_interface.appliance["public"].id
}

output "private_interface_id" {
  value = azurerm_network_interface.appliance["private"].id
}
