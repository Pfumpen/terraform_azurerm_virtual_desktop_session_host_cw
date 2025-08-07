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

resource "azurerm_virtual_machine_extension" "fslogix_setup" {
  # Will only be created if an FSLogix configuration is provided
  for_each = var.fslogix_config != null ? var.session_hosts : {}

  name                 = "${each.value.name}-fslogix-setup"
  virtual_machine_id   = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  
  auto_upgrade_minor_version = true

  tags = local.merged_tags

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_machine_extension.entra_id_join
  ]

  protected_settings = jsonencode({
    "commandToExecute" = <<EOF
powershell -ExecutionPolicy Unrestricted -Command "
  # === Robust Error Handling and Logging ===
  Start-Transcript -Path 'C:\fslogix_setup.log' -Force

  try {
    # === 1. Check for existing installation and run only if needed ===
    $fslogixExePath = 'C:\Program Files\FSLogix\Apps\frxsvc.exe'
    if (-not (Test-Path $fslogixExePath)) {
        Write-Host 'FSLogix not found. Starting download and installation...'
        $fslogixDownloadUrl = 'https://download.microsoft.com/download/a/3/6/a36519b7-1f50-4853-8557-550b05307a58/FSLogix_Apps_2.9.8784.63912.zip'
        $fslogixZipPath = 'C:\fslogix.zip'
        
        # Removed -UseBasicParsing for better forward compatibility and cleaner logs
        Invoke-WebRequest -Uri $fslogixDownloadUrl -OutFile $fslogixZipPath
        
        $fslogixExtractPath = 'C:\fslogix_extracted'
        Expand-Archive -Path $fslogixZipPath -DestinationPath $fslogixExtractPath -Force
        $installerPath = Join-Path $fslogixExtractPath 'x64\Release\FSLogixAppsSetup.exe'
        Start-Process -FilePath $installerPath -ArgumentList '/install /quiet' -Wait
        
        Write-Host 'FSLogix installation complete. Cleaning up...'
        Remove-Item -Path $fslogixZipPath -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $fslogixExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host 'FSLogix is already installed. Skipping installation.'
    }

    # === 2. Configuration (always runs) ===
    Write-Host 'Applying FSLogix registry configuration...'

    # --- Safely handle variables from Terraform, providing defaults for nulls ---
    
    # REG_MULTI_SZ: Robustly splits and cleans the array
    $vhdLocationsArray = '${join(",", var.fslogix_config.vhd_locations)}'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

    # BOOL to DWORD: Safely handles null values by comparing to the string 'true'
    $deleteLocalProfileDword = if ('${try(var.fslogix_config.delete_local_profile_when_vhd_should_apply, "true")}' -eq 'true') { 1 } else { 0 }
    $flipFlopNameDword = if ('${try(var.fslogix_config.flip_flop_profile_directory_name, "true")}' -eq 'true') { 1 } else { 0 }

    # DWORD: Use try() to provide a default value if the variable is null
    $sizeInMbs = [int]'${try(var.fslogix_config.size_in_mbs, 30000)}'
    $profileType = [int]'${try(var.fslogix_config.profile_type, 0)}'
    $lockedRetryCount = [int]'${try(var.fslogix_config.locked_retry_count, 3)}'
    $lockedRetryInterval = [int]'${try(var.fslogix_config.locked_retry_interval, 15)}'
    $reattachRetryCount = [int]'${try(var.fslogix_config.reattach_retry_count, 3)}'
    $reattachIntervalSeconds = [int]'${try(var.fslogix_config.reattach_interval_seconds, 15)}'
    
    # VolumeType to DWORD: Use try() for a default and correctly map VHD/VHDX to 1/2
    $volumeTypeDword = if ('${try(var.fslogix_config.volume_type, "VHDX")}' -eq 'VHDX') { 2 } else { 1 }

    # REG_SZ: Handle optional string value
    $redirXmlPath = '${try(var.fslogix_config.redir_xml_source_folder, "")}'

    # --- Set Registry Keys ---
    $regPath = 'HKLM:\SOFTWARE\FSLogix\Profiles'
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    
    New-ItemProperty -Path $regPath -Name 'Enabled' -Value 1 -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'VHDLocations' -Value $vhdLocationsArray -PropertyType MultiString -Force
    New-ItemProperty -Path $regPath -Name 'VolumeType' -Value $volumeTypeDword -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'SizeInMBs' -Value $sizeInMbs -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'DeleteLocalProfileWhenVHDShouldApply' -Value $deleteLocalProfileDword -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'FlipFlopProfileDirectoryName' -Value $flipFlopNameDword -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'ProfileType' -Value $profileType -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'LockedRetryCount' -Value $lockedRetryCount -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'LockedRetryInterval' -Value $lockedRetryInterval -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'ReAttachRetryCount' -Value $reattachRetryCount -PropertyType DWord -Force
    New-ItemProperty -Path $regPath -Name 'ReAttachIntervalSeconds' -Value $reattachIntervalSeconds -PropertyType DWord -Force

    if (-not [string]::IsNullOrWhiteSpace($redirXmlPath)) {
        Write-Host "Setting RedirXMLSourceFolder to $redirXmlPath"
        New-ItemProperty -Path $regPath -Name 'RedirXMLSourceFolder' -Value $redirXmlPath -PropertyType String -Force
    }

    Write-Host 'FSLogix configuration applied successfully.'

  } catch {
      Write-Error "An error occurred during FSLogix setup: $_"
      exit 1
  } finally {
      Stop-Transcript
  }
"
EOF
  })

  timeouts {
    create = "1h"
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
