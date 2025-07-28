resource "azurerm_virtual_machine_extension" "avd_agent" {
  for_each = var.session_hosts

  name                       = "${each.value.name}-avd_dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  tags                       = local.merged_tags

  settings = <<-SETTINGS
    {
      "modulesUrl": "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02714.342.zip",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName":"${var.host_pool_name}"
      }
    }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${var.avd_registration_token}"
    }
  }
  PROTECTED_SETTINGS

  depends_on = [
    azurerm_virtual_machine_extension.domain_join
  ]
}
