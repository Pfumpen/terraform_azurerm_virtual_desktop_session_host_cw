provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

# Example setup for a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-avd-sh-hybrid-example"
  location = "West Europe"
}

# Example setup for a Key Vault to store the domain join password
resource "azurerm_key_vault" "example" {
  name                = "kv-avd-sh-hybrid-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = "d4b72ec1-987c-4f50-ae1a-3c8674481f1c" # Replace with your Tenant ID
  sku_name            = "standard"
}

# Example of storing the domain join password in Key Vault
resource "azurerm_key_vault_secret" "domain_password" {
  name         = "domain-join-password"
  value        = "YourDomainPassword123!" # Replace with a strong password
  key_vault_id = azurerm_key_vault.example.id
}

# Example setup for a virtual network and subnet
resource "azurerm_virtual_network" "example" {
  name                = "vnet-avd-hybrid-example"
  address_space       = ["10.3.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "snet-avd-session-hosts"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.3.1.0/24"]
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "log-avd-sh-hybrid-example"
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
  host_pool_name         = "hp-avd-hybrid-join-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  # --- Diagnostic Settings ---
  diagnostics_level = "detailed"
  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  }

  session_hosts = {
    "host-hybrid-1" = {
      name           = "avd-hybrid-host"
      size           = "Standard_D4s_v3"
      admin_username = "localadmin"
      network_interface = {
        name                          = "nic-hybrid-host-1"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      image_key = "win11-23H2-ms-m365"
    }
  }

  join_type = "hybrid_entra_join"

  domain_join_config = {
    name                         = "yourdomain.com" # Replace with your domain name
    user                         = "yourdomain\\joinuser" # Replace with your domain join user
    password_key_vault_secret_id = azurerm_key_vault_secret.domain_password.id
    ou_path                      = "OU=AVD,DC=yourdomain,DC=com" # Optional: Replace with your OU path
  }

  tags = {
    "environment" = "example-hybrid-join"
    "project"     = "avd-session-host"
  }
}

output "session_host_ids_hybrid_join" {
  description = "The resource IDs of the created hybrid-joined session host VMs."
  value       = module.avd_session_host.session_host_resource_ids
}

output "admin_password_secret_ids_hybrid_join" {
  description = "The IDs of the Key Vault secrets containing the admin passwords for the hybrid-joined hosts."
  value       = module.avd_session_host.admin_password_secret_ids
}
