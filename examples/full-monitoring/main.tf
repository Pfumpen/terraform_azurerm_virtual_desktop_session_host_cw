provider "azurerm" {
  features {}
  subscription_id = "f965ed2c-e6b3-4c40-8bea-ea3505a01aa2" # Replace with your Subscription ID
}

resource "azurerm_resource_group" "example" {
  name     = "rg-avd-mon-example"
  location = "West Europe"
}

resource "azurerm_key_vault" "example" {
  name                = "kv-avd-mon-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  tenant_id           = "d4b72ec1-987c-4f50-ae1a-3c8674481f1c" # Replace with your Tenant ID
  sku_name            = "standard"
}

resource "azurerm_virtual_network" "example" {
  name                = "vnet-avd-mon-example"
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
  name                = "log-avd-mon-example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --- Placeholder for a completely separate, user-managed Data Collection Rule ---
# This demonstrates the override mechanism where a specific host can use a custom DCR.
resource "azurerm_monitor_data_collection_rule" "custom_dcr_for_special_host" {
  name                = "dcr-avd-special-financial-host"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.example.id
      name                  = "la-destination-special"
    }
  }
  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 300 # Custom interval
      counter_specifiers            = ["\\Memory\\Committed Bytes"] # Only one specific counter
      name                          = "perfCounters-special"
    }
  }
  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["la-destination-special"]
  }
}

variable "avd_registration_token" {
  description = "Placeholder for AVD registration token."
  type        = string
  default     = "fake-token"
}

module "avd_session_host" {
  source = "../../"

  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  join_type              = "none"
  avd_registration_token = var.avd_registration_token
  host_pool_name         = "hp-avd-mon-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  # --- Full Monitoring Diagnostic Settings ---
  # The global switch is set to "all". This means any host with `diagnostics_enabled = true`
  # will receive the most comprehensive, pre-configured set of platform metrics and guest OS logs.
  diagnostics_level = "all"

  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  }

  session_hosts = {
    "standard-monitored-host" = {
      name                = "avd-mon-host1"
      size                = "Standard_D4s_v3"
      admin_username      = "localadmin"
      # This host participates in diagnostics. Because `diagnostics_level` is "all",
      # it will be associated with the shared DCR created by the module using the "all" preset.
      diagnostics_enabled = true
      network_interface = {
        name                          = "nic-mon-host1"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      image_key = "win11-23H2-ms-m365"
    },
    "custom-dcr-host" = {
      name           = "avd-mon-host2"
      size           = "Standard_D4s_v3"
      admin_username = "localadmin"
      # This host also participates in diagnostics. However, it specifies its own DCR ID.
      # The module will detect this and associate this specific VM with the provided DCR
      # instead of using the shared DCR from the "all" preset.
      diagnostics_enabled      = true
      data_collection_rule_id = azurerm_monitor_data_collection_rule.custom_dcr_for_special_host.id
      network_interface = {
        name                          = "nic-mon-host2"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
      }
      image_key = "win11-23H2-ms-m365"
    },
    "unmonitored-host" = {
      name           = "avd-mon-host3"
      size           = "Standard_D2s_v3"
      admin_username = "localadmin"
      # This host has diagnostics explicitly disabled. It will not have the AMA agent
      # installed or be associated with any DCR.
      diagnostics_enabled = false
      network_interface = {
        name                          = "nic-mon-host3"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }
      image_key = "win10-22H2-ms"
    }
  }


  tags = {
    "environment" = "example"
    "project"     = "avd-full-monitoring"
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
