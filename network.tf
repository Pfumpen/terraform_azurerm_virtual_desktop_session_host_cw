resource "azurerm_network_interface" "session_host" {
  for_each = var.session_hosts

  name                = each.value.network_interface.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.merged_tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.network_interface.subnet_id
    private_ip_address_allocation = each.value.network_interface.private_ip_address_allocation
    private_ip_address            = each.value.network_interface.private_ip_address
  }
}
