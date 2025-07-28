provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-avd-session-hosts-basic-example"
  location = "West Europe"
}

resource "azurerm_key_vault" "example" {
  name                = "kv-avd-sh-basic-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = "d4b72ec1-987c-4f50-ae1a-3c8674481f1c" # Replace with your Tenant ID
  sku_name            = "standard"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-avd-basic-example"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "snet-avd-session-hosts"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "log-avd-sh-basic-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# This is a placeholder for the AVD Host Pool registration token.
# In a real-world scenario, you would obtain this from your AVD Host Pool.
variable "avd_registration_token" {
  description = "Placeholder for AVD registration token."
  type        = string
  default     = "fake-token"
}

module "avd_session_host" {
  source = "../../"

  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  avd_registration_token = var.avd_registration_token
  host_pool_name         = "hp-avd-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  # --- Diagnostic Settings ---
  # Send detailed diagnostics to the Log Analytics Workspace.
  # The module defaults to "basic" if this is not set.
  # Set to "none" to disable.
  diagnostics_level          = "detailed"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  session_hosts = {
    "host1" = {
      name           = "avd-sh-host1"
      size           = "Standard_D2s_v3"
      admin_username = "localadmin"
      network_interface = {
        name                          = "nic-host1"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }
      image_key = "win10-22H2-ms-m365"
    },
    "host2-no-diag" = {
      name                = "avd-sh-host2"
      size                = "Standard_D2s_v3"
      admin_username      = "localadmin"
      diagnostics_enabled = false # Explicitly disable diagnostics for this host
      network_interface = {
        name                          = "nic-host2"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }
      image_key = "win11-23H2-ms-m365"
    }
  }

  tags = {
    "environment" = "example"
    "project"     = "avd-session-host"
  }
}

output "session_host_ids" {
  description = "The resource IDs of the created session host VMs."
  value       = module.avd_session_host.session_host_resource_ids
}

output "admin_password_secret_ids" {
  description = "The IDs of the Key Vault secrets containing the admin passwords."
  value       = module.avd_session_host.admin_password_secret_ids
}
