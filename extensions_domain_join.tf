resource "azurerm_virtual_machine_extension" "domain_join" {
  for_each = var.domain_join != null ? var.session_hosts : {}

  name                 = "${each.value.name}-domain-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  tags                 = local.merged_tags

  settings = jsonencode({
    Name = var.domain_join.name
    User = var.domain_join.user
  })

  protected_settings = jsonencode({
    Password = data.azurerm_key_vault_secret.domain_join_password[0].value
  })
}
