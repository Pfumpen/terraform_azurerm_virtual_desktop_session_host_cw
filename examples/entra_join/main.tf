provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

resource "azurerm_resource_group" "example" {
  name     = "rg-avd-sh-entra-join-example"
  location = "West Europe"
}

resource "azurerm_key_vault" "example" {
  name                = "kv-avd-sh-entra-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = "d4b72ec1-987c-4f50-ae1a-3c8674481f1c" # Replace with your Tenant ID
  sku_name            = "standard"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-avd-entra-example"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "snet-avd-session-hosts"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.2.1.0/24"]
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "log-avd-sh-entra-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Placeholder for the AVD registration token
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
  host_pool_name         = "hp-avd-entra-join-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  # --- Join Configuration ---
  join_type = "entra_join"

  # A System-Assigned Managed Identity is required for Entra Join.
  managed_identity = {
    system_assigned = true
  }
  # --------------------------

  # --- Diagnostic Settings ---
  diagnostics_level = "all"
  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  }

  session_hosts = {
    "host-entra-1" = {
      name                = "avd-entra-host"
      size                = "Standard_D2s_v3"
      admin_username      = "localadmin"
      diagnostics_enabled = true
      network_interface = {
        name                          = "nic-entra-host-1"
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
    "environment" = "example-entra-join"
    "project"     = "avd-session-host"
  }
}

output "session_host_ids_entra_join" {
  description = "The resource IDs of the created Entra-joined session host VMs."
  value       = module.avd_session_host.session_host_resource_ids
}

output "admin_password_secret_ids_entra_join" {
  description = "The IDs of the Key Vault secrets containing the admin passwords for the Entra-joined hosts."
  value       = module.avd_session_host.admin_password_secret_ids
}
