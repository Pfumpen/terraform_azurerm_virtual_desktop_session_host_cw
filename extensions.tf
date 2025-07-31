# extensions.tf

# 1. Conditional data source to fetch the domain join password
data "azurerm_key_vault_secret" "domain_join_password" {
  # This resource is only created if an AD-based join is selected and configured.
  count = contains(["ad_join", "hybrid_entra_join", "aadds_join"], var.join_type) && var.domain_join_config != null ? 1 : 0

  name         = basename(var.domain_join_config.password_key_vault_secret_id)
  key_vault_id = trimsuffix(var.domain_join_config.password_key_vault_secret_id, "/secrets/${basename(var.domain_join_config.password_key_vault_secret_id)}")
}

# 2. Conditional resource for AD-based joins (JsonADDomainExtension)
resource "azurerm_virtual_machine_extension" "domain_join" {
  for_each = contains(["ad_join", "hybrid_entra_join", "aadds_join"], var.join_type) && var.domain_join_config != null ? var.session_hosts : {}

  name                 = "${each.value.name}-domain-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"
  tags                 = local.merged_tags

  settings = jsonencode({
    Name = var.domain_join_config.name
    User = var.domain_join_config.user
    OU   = try(var.domain_join_config.ou_path, null)
  })

  protected_settings = jsonencode({
    Password = data.azurerm_key_vault_secret.domain_join_password[0].value
  })

  timeouts {
    create = "30m"
    delete = "15m"
  }
}

# 3. Conditional resource for Microsoft Entra ID Join (AADLoginForWindows)
resource "azurerm_virtual_machine_extension" "entra_id_join" {
  for_each = var.join_type == "entra_join" ? var.session_hosts : {}

  name                       = "${each.value.name}-entra-join"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = local.merged_tags
}

# Conditional resource for FSLogix Installation and Configuration
resource "azurerm_virtual_machine_extension" "fslogix_setup" {
  # This resource is only created if fslogix_config is provided by the user.
  for_each = var.fslogix_config != null ? var.session_hosts : {}

  name                 = "${each.value.name}-fslogix-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  tags                 = local.merged_tags

  # This ensures FSLogix is installed AFTER the machine has joined a domain.
  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_machine_extension.entra_id_join
  ]

  # The script downloads, installs, and configures FSLogix via registry keys.
  protected_settings = jsonencode({
    "commandToExecute" = <<EOF
powershell -ExecutionPolicy Unrestricted -Command "
  Start-Transcript -Path C:\fslogix_install.log

  # Variables from Terraform
  $vhdLocations = '${join("','", var.fslogix_config.vhd_locations)}' -split ','
  $volumeType = '${var.fslogix_config.volume_type}'
  $sizeInMBs = ${var.fslogix_config.size_in_mbs}
  $deleteLocalProfile = $(${var.fslogix_config.delete_local_profile_when_vhd_should_apply})
  $flipFlopName = $(${var.fslogix_config.flip_flop_profile_directory_name})

  # Download FSLogix
  $fslogixZipPath = 'C:\fslogix.zip'
  $fslogixDownloadUrl = 'https://aka.ms/fslogix_download'
  Invoke-WebRequest -Uri $fslogixDownloadUrl -OutFile $fslogixZipPath
  
  # Extract and Install
  $fslogixExtractPath = 'C:\fslogix_extracted'
  Expand-Archive -Path $fslogixZipPath -DestinationPath $fslogixExtractPath
  $installerPath = Join-Path $fslogixExtractPath 'x64\Release\FSLogixAppsSetup.exe'
  Start-Process -FilePath $installerPath -ArgumentList '/install /quiet' -Wait

  # Configure FSLogix Registry Keys
  $regPath = 'HKLM:\SOFTWARE\FSLogix\Profiles'
  New-Item -Path $regPath -Force | Out-Null
  
  New-ItemProperty -Path $regPath -Name 'Enabled' -Value 1 -PropertyType 'DWord' -Force | Out-Null
  New-ItemProperty -Path $regPath -Name 'VHDLocations' -Value $vhdLocations -PropertyType 'MultiString' -Force | Out-Null
  New-ItemProperty -Path $regPath -Name 'VolumeType' -Value $volumeType -PropertyType 'String' -Force | Out-Null
  New-ItemProperty -Path $regPath -Name 'SizeInMBs' -Value $sizeInMBs -PropertyType 'DWord' -Force | Out-Null
  New-ItemProperty -Path $regPath -Name 'DeleteLocalProfileWhenVHDShouldApply' -Value ($deleteLocalProfile ? 1 : 0) -PropertyType 'DWord' -Force | Out-Null
  New-ItemProperty -Path $regPath -Name 'FlipFlopProfileDirectoryName' -Value ($flipFlopName ? 1 : 0) -PropertyType 'DWord' -Force | Out-Null

  # Clean up
  Remove-Item -Path $fslogixZipPath -Force
  Remove-Item -Path $fslogixExtractPath -Recurse -Force

  Stop-Transcript
"
EOF
  })

  timeouts {
    create = "30m"
    delete = "15m"
  }
}


# 5. MODIFIED: AVD Agent resource with corrected dependencies
resource "azurerm_virtual_machine_extension" "avd_agent" {
  for_each = var.session_hosts

  name                       = "${each.value.name}-avd-dsc"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  tags                       = local.merged_tags

  # This depends_on clause ensures the AVD agent is installed only AFTER the
  # appropriate join process AND FSLogix setup have been completed.
  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_machine_extension.entra_id_join,
    azurerm_virtual_machine_extension.fslogix_setup
  ]

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
}
