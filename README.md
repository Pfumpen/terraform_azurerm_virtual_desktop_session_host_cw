# Terraform Azure Virtual Desktop Session Host Module

This Terraform module provisions and configures one or more Windows Virtual Machines to act as Azure Virtual Desktop (AVD) session hosts. It handles the complete lifecycle, from VM creation and network configuration to an optional Active Directory domain join and AVD agent installation.

## Features

-   Provisions multiple session hosts using a single `for_each` loop.
-   Configures network interfaces with static or dynamic IP allocation.
-   **Securely generates** a random administrator password for each session host and stores it in a specified Azure Key Vault.
-   **Optionally** performs Active Directory domain join using the `JsonADDomainExtension`.
-   Installs the AVD agent and bootloader via a PowerShell DSC extension, registering the host with a specified AVD Host Pool.
-   Supports standard Azure VM features: specific VM sizes, OS disk configurations, and custom/Marketplace images.
-   Integrates with Availability Zones for high availability.
-   Supports System-Assigned and User-Assigned Managed Identities.
-   **Flexible Diagnostic Settings:** Configure diagnostics with simple presets (`basic`, `detailed`) or a fully `custom` configuration. Diagnostics can be enabled/disabled globally and also on a per-session-host basis.
-   Applies standardized and custom tags to all created resources.
-   Allows for optional RBAC role assignments on the session host VMs.

## AVD Image Selection

To simplify deployment, this module includes a curated list of common AVD images. You can select an image by providing its key in the `image_key` attribute of a `session_hosts` entry. This removes the need to manually specify the `publisher`, `offer`, `sku`, and `version`.

Alternatively, you can still specify a custom image by providing the full `source_image_reference` object.

**You must use either `image_key` or `source_image_reference`, but not both.**

### Available Image Keys

| Key                                | Description                                             |
|------------------------------------|---------------------------------------------------------|
| `win11-23H2-ms-m365`               | **Recommended:** Win 11 23H2 Multi-session + M365 Apps  |
| `win11-23H2-ms`                    | Win 11 23H2 Multi-session (no M365 Apps)                |
| `win10-22H2-ms-m365`               | Win 10 22H2 Multi-session + M365 Apps                   |
| `win10-22H2-ms`                    | Win 10 22H2 Multi-session (no M365 Apps)                |
| `win2022-datacenter-g2`            | Windows Server 2022 Datacenter (Gen2)                   |
| `win2022-datacenter-azure-edition` | Windows Server 2022 Datacenter Azure Edition (Hotpatch) |
| `win2019-datacenter-g2`            | Windows Server 2019 Datacenter (Gen2)                   |

## Requirements

| Name      | Version |
|-----------|---------|
| terraform | >= 1.11.0 |
| azurerm   | >= 4.31.0 |
| random    | >= 3.1.0  |

## External Dependencies

-   **Azure Resource Group:** An existing Resource Group must be provided via `var.resource_group_name`.
-   **Virtual Network & Subnet:** An existing VNet and Subnet are required. The Subnet ID is provided via the `network_interface.subnet_id` attribute in the `var.session_hosts` map.
-   **Active Directory Domain (Optional):** If performing a domain join, the Subnet must have network connectivity to an Active Directory domain controller.
-   **AVD Host Pool:** An existing AVD Host Pool is required to generate the `avd_registration_token` and to provide the `host_pool_name`.
-   **Azure Key Vault:** An Azure Key Vault is required. It is used to store the generated administrator passwords and, if applicable, to retrieve the domain join password.

## Resources Created

| Type                                  | Name          |
|---------------------------------------|---------------|
| `azurerm_windows_virtual_machine`     | `session_host` (for_each) |
| `azurerm_network_interface`           | `session_host` (for_each) |
| `random_password`                     | `admin_password` (for_each) |
| `azurerm_key_vault_secret`            | `admin_password` (for_each) |
| `azurerm_virtual_machine_extension`   | `domain_join` (for_each, optional)  |
| `azurerm_virtual_machine_extension`   | `avd_agent` (for_each)    |
| `azurerm_monitor_diagnostic_setting`  | `session_host` (for_each, optional) |
| `azurerm_role_assignment`             | `session_host` (for_each, optional) |
| `data.azurerm_key_vault_secret`       | `domain_join_password` (optional) |

## Input Variables

| Name                   | Description                                                                                                                            | Type           | Default | Required |
|------------------------|----------------------------------------------------------------------------------------------------------------------------------------|----------------|---------|----------|
| `session_hosts`        | A map of objects where each key is a unique logical name for a session host. Each object defines the configuration for a single VM.      | `map(object)`  | n/a     | yes      |
| `resource_group_name`  | The name of the resource group where the resources will be created.                                                                    | `string`       | n/a     | yes      |
| `location`             | The Azure region where the resources will be created.                                                                                  | `string`       | n/a     | yes      |
| `host_pool_name`       | The name of the AVD Host Pool to which the session hosts will be registered.                                                           | `string`       | n/a     | yes      |
| `avd_registration_token`| The registration token from the AVD Host Pool.                                                                                         | `sensitive(string)` | n/a     | yes      |
| `admin_password_key_vault_id` | The resource ID of the Azure Key Vault where the generated admin passwords for the session hosts will be stored as secrets.        | `string`       | n/a     | yes      |
| `password_generation_config` | Configuration for generating random passwords for the session host administrators.                                                 | `object`       | `{}`    | no       |
| `domain_join`          | Configuration for joining the session hosts to an Active Directory domain. If not provided (`null`), the step is skipped.              | `object`       | `null`  | no       |
| `tags`                 | A map of tags to apply to all created resources.                                                                                       | `map(string)`  | `{}`    | no       |
| `diagnostics_level`    | Defines the detail level for diagnostics. Can be `none`, `basic`, `detailed`, or `custom`. See "Diagnostic Settings" section. | `string`       | `"basic"` | no       |
| `diagnostic_settings`  | Configures the destination for diagnostics. Required if `diagnostics_level` is not `none`. See "Diagnostic Settings" section.      | `object`       | `{}`    | no       |
| `diagnostics_custom_logs` | A list of log categories to enable when `diagnostics_level` is `custom`.                                                         | `list(string)` | `[]`    | no       |
| `diagnostics_custom_metrics` | A list of metric categories to enable when `diagnostics_level` is `custom`. Use `["AllMetrics"]` for all.                       | `list(string)` | `[]`    | no       |
| `managed_identity`     | Configuration for the Managed Identity of the virtual machine.                                                                         | `object`       | `{}`    | no       |
| `role_assignments`     | A map of role assignments to create on the session host virtual machines.                                                              | `map(object)`  | `{}`    | no       |

### `session_hosts` variable structure

A map of objects, where each object has the following attributes:

-   `name` (string, required): The specific name for the virtual machine and its associated resources.
-   `size` (string, required): The VM SKU size (e.g., "Standard_D2s_v3").
-   `zone` (string, optional): The Availability Zone to deploy the VM into.
-   `network_interface` (object, required):
    -   `name` (string, required): The name of the network interface.
    -   `subnet_id` (string, required): The resource ID of the subnet to connect to.
    -   `private_ip_address_allocation` (string, required): "Static" or "Dynamic".
    -   `private_ip_address` (string, optional): Required if allocation is "Static".
-   `os_disk` (object, required):
    -   `caching` (string, required): Caching mode.
    -   `storage_account_type` (string, required): Storage SKU.
-   `image_key` (string, optional): A key corresponding to a pre-defined image map (e.g., "win11-23H2-ms-m365"). See the "AVD Image Selection" section for available keys.
-   `source_image_reference` (object, optional): Used for custom images if `image_key` is not specified.
    -   `publisher` (string, required)
    -   `offer` (string, required)
    -   `sku` (string, required)
    -   `version` (string, required)
-   `admin_username` (string, required): The administrator username. The password will be randomly generated.
-   `diagnostics_enabled` (bool, optional): Controls whether diagnostics are enabled for this specific session host. Defaults to `true`. If set to `false`, this host will be excluded, even if global diagnostics are enabled.

### Diagnostic Settings

This module provides control for diagnostics through a combination of variables.

1.  **`diagnostics_level`**: This is the master switch and defines the verbosity.
    -   `none`: Disables all diagnostic settings.
    -   `basic`: (Default) Enables a minimal set of logs (`AuditLogs`) and all metrics.
    -   `detailed`: Enables a comprehensive set of logs for troubleshooting.
    -   `custom`: Enables only the specific log and metric categories defined in `diagnostics_custom_logs` and `diagnostics_custom_metrics`.

2.  **`diagnostic_settings`**: If `diagnostics_level` is not `none`, this object specifies the destination for the diagnostics. **Exactly one** of the following attributes must be provided:
    -   `log_analytics_workspace_id` (string): The resource ID of a Log Analytics Workspace.
    -   `eventhub_authorization_rule_id` (string): The resource ID of an Event Hubs authorization rule.
    -   `storage_account_id` (string): The resource ID of a Storage Account.

3.  **`diagnostics_enabled` (Per-Host Control)**: Inside the `session_hosts` map, you can set `diagnostics_enabled = false` for any host you wish to exclude from logging. By default, it's `true`.

### `password_generation_config` variable structure

-   `length` (number, optional): The length of the password. Defaults to `32`.
-   `special` (bool, optional): Whether to include special characters. Defaults to `true`.
-   `override_special` (string, optional): A string of special characters to use. Defaults to `!@#$%^&*()-_=+[]{}<>:?`.

### `domain_join` variable structure

If provided, this object enables the Active Directory domain join. It has the following attributes:

-   `name` (string, required): The FQDN of the domain to join (e.g., "corp.contoso.com").
-   `user` (string, required): The UPN of the user for the domain join.
-   `password_key_vault_secret_id` (sensitive(string), required): The Key Vault secret ID for the domain join password.

## Outputs

| Name                        | Description                                                                                             |
|-----------------------------|---------------------------------------------------------------------------------------------------------|
| `session_host_resource_ids` | A map of the resource IDs of the created session host virtual machines.                                 |
| `session_host_identities`   | A map of the managed identities for each session host virtual machine.                                  |
| `admin_password_secret_ids` | A map of the secret IDs for the generated admin passwords stored in Azure Key Vault. The keys are the logical names of the session hosts. |

## Usage Examples

Working examples can be found in the `examples/` directory.

-   **`examples/basic`**: Demonstrates how to provision a session host **without** an Active Directory domain join.
-   **`examples/with_domain_join`**: Demonstrates how to provision a session host **with** an Active Directory domain join.

### Basic Example (No Domain Join)

```hcl
# In examples/basic/main.tf

module "avd_session_host" {
  source = "../../"

  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  avd_registration_token = "your-fake-token"
  host_pool_name         = "hp-avd-example"

  # Provide the Key Vault ID to store the generated passwords
  admin_password_key_vault_id = azurerm_key_vault.example.id

  # --- Diagnostic Settings Example ---
  # Send detailed diagnostics to a Log Analytics Workspace
  diagnostics_level = "detailed"
  diagnostic_settings = {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
  }
  # -----------------------------------

  session_hosts = {
    "host1" = {
      name           = "avd-sh-host1"
      size           = "Standard_D2s_v3"
      admin_username = "localadmin"
      # Diagnostics for this host will be enabled based on the global setting.
      network_interface = {
        name                          = "nic-host1"
        subnet_id                     = azurerm_subnet.example.id
        private_ip_address_allocation = "Dynamic"
      }
      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }
      image_key = "win11-23H2-ms-m365"
    },
    "host2-no-diag" = {
      name                = "avd-sh-host2"
      size                = "Standard_D2s_v3"
      admin_username      = "localadmin"
      diagnostics_enabled = false # Explicitly disable diagnostics for this host.
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
}
```

### With Domain Join Example

```hcl
# In examples/with_domain_join/main.tf

module "avd_session_host" {
  source = "../../"

  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  avd_registration_token = "your-fake-token"
  host_pool_name         = "hp-avd-domain-join-example"

  admin_password_key_vault_id = azurerm_key_vault.example.id

  domain_join = {
    name                         = "yourdomain.com"
    user                         = "yourdomain\\joinuser"
    password_key_vault_secret_id = azurerm_key_vault_secret.domain_password.id
  }

  session_hosts = {
    "host-dj-1" = {
      name           = "avd-dj-host-1"
      size           = "Standard_D4s_v3"
      admin_username = "localadmin"
      network_interface = {
        name                          = "nic-host-dj-1"
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
}
