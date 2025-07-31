provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2"
}

# Example setup for a resource group
resource "azurerm_resource_group" "example" {
  name     = "rg-avd-fslogix-example"
  location = "West Europe"
}

# Example setup for a Key Vault to store the domain join password
resource "azurerm_key_vault" "example" {
  name                = "kv-avd-sh-fslogix-ex"
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
  name                = "vnet-avd-fslogix-example"
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

# Example setup for Azure Files (for FSLogix profiles)
resource "azurerm_storage_account" "example" {
  name                     = "stfslogixexample"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  account_kind             = "FileStorage"
}

resource "azurerm_storage_share" "example" {
  name                 = "profiles"
  storage_account_name = azurerm_storage_account.example.name
  quota                = 100 # in GB
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
  host_pool_name         = "hp-avd-fslogix-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  session_hosts = {
    "host-fslogix-1" = {
      name           = "avd-fslogixhost"
      size           = "Standard_D4s_v3"
      admin_username = "localadmin"
      network_interface = {
        name                          = "nic-host-fslogix-1"
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

  # --- Identity and Domain Join ---
  join_type = "ad_join"

  domain_join_config = {
    name                         = "yourdomain.com" # Replace with your domain name
    user                         = "yourdomain\\joinuser" # Replace with your domain join user
    password_key_vault_secret_id = azurerm_key_vault_secret.domain_password.id
    ou_path                      = "OU=AVD,DC=yourdomain,DC=com" # Optional: Replace with your OU path
  }

  # --- FSLogix Configuration ---
  fslogix_config = {
    vhd_locations = ["\\\\${azurerm_storage_account.example.name}.file.core.windows.net\\${azurerm_storage_share.example.name}"]
    size_in_mbs   = 20000 # 20 GB profiles
    volume_type   = "VHDX"
  }

  tags = {
    "environment" = "example-fslogix"
    "project"     = "avd-session-host"
  }
}

output "session_host_ids_fslogix" {
  description = "The resource IDs of the created session host VMs with FSLogix."
  value       = module.avd_session_host.session_host_resource_ids
}

output "admin_password_secret_ids_fslogix" {
  description = "The IDs of the Key Vault secrets containing the admin passwords for the FSLogix hosts."
  value       = module.avd_session_host.admin_password_secret_ids
}
