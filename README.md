# Terraform Azure Virtual Desktop Session Host Module

This Terraform module provisions and configures one or more Windows Virtual Machines to act as Azure Virtual Desktop (AVD) session hosts. It handles the complete lifecycle, from VM creation and network configuration to an optional Active Directory domain join and AVD agent installation.

## Features

-   Provisions multiple session hosts using a single `for_each` loop.
-   Configures network interfaces with static or dynamic IP allocation.
-   **Securely generates** a random administrator password for each session host and stores it in a specified Azure Key Vault.
-   **Optionally** performs Active Directory domain join using the `JsonADDomainExtension`.
-   Supports multiple identity join types: Active Directory, Microsoft Entra ID, Hybrid Entra, and Microsoft Entra DS.
-   **Optionally installs and configures FSLogix** for robust user profile management.
-   Installs the AVD agent and bootloader via a PowerShell DSC extension, registering the host with a specified AVD Host Pool.
-   Supports standard Azure VM features: specific VM sizes, OS disk configurations, and custom/Marketplace images.
-   Integrates with Availability Zones for high availability.
-   Supports System-Assigned and User-Assigned Managed Identities.
-   **Advanced, Self-Adapting Diagnostics:** A simple, intent-based interface (`diagnostics_level`) dynamically configures detailed Azure Monitor diagnostics by discovering available log and metric categories at runtime. This eliminates configuration errors and the need for manual updates.
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
-   **FSLogix Profile Share (Optional):** If using `fslogix_config`, you must have an SMB file share (e.g., Azure Files Premium) accessible from the session hosts.

## Resources Created

| Type                                  | Name          |
|---------------------------------------|---------------|
| `azurerm_windows_virtual_machine`     | `session_host` (for_each) |
| `azurerm_network_interface`           | `session_host` (for_each) |
| `random_password`                     | `admin_password` (for_each) |
| `azurerm_key_vault_secret`            | `admin_password` (for_each) |
| `azurerm_virtual_machine_extension`   | `domain_join` | `for_each` (if join type is AD-based) |
| `azurerm_virtual_machine_extension`   | `entra_id_join` | `for_each` (if join type is Entra) |
| `azurerm_virtual_machine_extension`   | `fslogix_setup`    | `fslogix_config` is set (for_each)     |
| `azurerm_virtual_machine_extension`   | `avd_agent` | `for_each` |
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
| `join_type` | Defines the identity join type for the session host VMs. Valid options: 'ad_join', 'hybrid_entra_join', 'aadds_join', 'entra_join', 'none'. | `string` | `"none"` | no |
| `domain_join_config` | Configuration object for joining an AD or AADDS domain. See structure below. | `object` | `null` | yes, if `join_type` is AD-based |
| `fslogix_config` | If provided, installs and configures FSLogix for profile management. If `null`, this step is skipped. | `object` | `null` | no |
| `tags`                 | A map of tags to apply to all created resources.                                                                                       | `map(string)`  | `{}`    | no       |
| `diagnostics_level`    | Defines the desired diagnostic intent. Can be `none`, `all`, `audit`, or `custom`. See the "Diagnostic Settings" section for details. | `string`       | `"none"`  | no       |
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
-   `diagnostics_enabled` (bool, optional): Controls whether diagnostics are enabled for this specific session host. Defaults to `false`. This flag is only effective when `diagnostics_level` is not `none`.

### Diagnostic Settings

This module implements an advanced, self-adapting pattern for diagnostics, driven by user intent and runtime discovery of the Azure resource's capabilities.

1.  **`diagnostics_level`**: This is the primary driver, defining your intent.
    -   `none`: (Default) Disables all diagnostic settings.
    -   `all`: Enables all available log and metric categories. The module discovers all categories supported by the session host at runtime and enables them. For logs, it will preferentially use the `allLogs` category group if available; otherwise, it enables every individual log category.
    -   `audit`: Enables all available "audit" logs. The module discovers all categories in the "audit" group and enables them.
    -   `custom`: Enables only the specific log and metric categories defined in the `diagnostics_custom_logs` and `diagnostics_custom_metrics` variables.

2.  **`diagnostic_settings`**: If `diagnostics_level` is not `none`, this object specifies the destination. **Exactly one** of the following attributes must be provided:
    -   `log_analytics_workspace_id` (string)
    -   `eventhub_authorization_rule_id` (string)
    -   `storage_account_id` (string)

3.  **`diagnostics_enabled` (Per-Host Control)**: Inside the `session_hosts` map, you must set `diagnostics_enabled = true` for each specific host you want to monitor. This provides granular control over which resources generate diagnostic data.

4.  **`diagnostics_custom_logs` & `diagnostics_custom_metrics`**: These lists are used only when `diagnostics_level` is set to `custom`. `diagnostics_custom_metrics` defaults to `["AllMetrics"]`.

### `password_generation_config` variable structure

-   `length` (number, optional): The length of the password. Defaults to `32`.
-   `special` (bool, optional): Whether to include special characters. Defaults to `true`.
-   `override_special` (string, optional): A string of special characters to use. Defaults to `!@#$%^&*()-_=+[]{}<>:?`.

### `domain_join_config` variable structure
Required only when `join_type` is one of `ad_join`, `hybrid_entra_join`, or `aadds_join`.
- `name` (string, required): The FQDN of the domain to join (e.g., `corp.contoso.com`).
- `user` (string, required): The UPN of the user with permissions to join the domain (e.g., `join-user@corp.contoso.com`).
- `password_key_vault_secret_id` (string, required): The full ID of the Key Vault secret containing the user's password.
- `ou_path` (string, optional): The distinguished name of the OU to place the computer object in.

**Type:** `object({ name = string, user = string, password_key_vault_secret_id = string, ou_path = optional(string) })`

**Example:**
```hcl
domain_join_config = {
  name                         = "corp.contoso.com"
  user                         = "corp\\join-account"
  password_key_vault_secret_id = "your_key_vault_secret_id"
  ou_path                      = "OU=AVD,OU=Computers,DC=corp,DC=contoso,DC=com"
}
```

---

### FSLogix Configuration

To enable FSLogix, provide the `fslogix_config` object. The module will then automatically download, install, and configure the FSLogix agent on each session host.

#### `fslogix_config` variable structure

-   `vhd_locations` (list(string), required): A list of UNC paths to the SMB file shares where profiles will be stored. Example: `["\\\\storageaccount.file.core.windows.net\\profiles"]`.
-   `volume_type` (string, optional): The disk format for profile containers. Can be "VHD" or "VHDX". Defaults to `"VHDX"`.
-   `size_in_mbs` (number, optional): The default maximum size of the profile disk in megabytes. Defaults to `30000` (30 GB).
-   `delete_local_profile_when_vhd_should_apply` (bool, optional): If `true`, any existing local Windows profile for a user will be deleted when they first sign in with an FSLogix profile. Defaults to `true`.
-   `flip_flop_profile_directory_name` (bool, optional): If `true`, uses a format for the profile folder that swaps the username and SID, which can help with certain file path length issues. Defaults to `true`.

**Example Usage:**
```hcl
module "session_hosts" {
  source = "./modules/avd-session-host"

  # ... other required variables ...
  
  fslogix_config = {
    vhd_locations = ["\\\\your-storage-account.file.core.windows.net\\profiles"]
    size_in_mbs   = 50000 # 50 GB profiles
  }
}
```

## Outputs

| Name                        | Description                                                                                             |
|-----------------------------|---------------------------------------------------------------------------------------------------------|
| `session_host_resource_ids` | A map of the resource IDs of the created session host virtual machines.                                 |
| `session_host_identities`   | A map of the managed identities for each session host virtual machine.                                  |
| `admin_password_secret_ids` | A map of the secret IDs for the generated admin passwords stored in Azure Key Vault. The keys are the logical names of the session hosts. |

## Usage Examples

Working examples for various join types can be found in the `examples/` directory.

-   **`examples/basic`**: Demonstrates provisioning a session host with no domain join (`join_type = "none"`).
-   **`examples/ad_join`**: Demonstrates a traditional Active Directory domain join (`join_type = "ad_join"`).
-   **`examples/entra_join`**: Demonstrates a cloud-native Microsoft Entra ID join (`join_type = "entra_join"`).
-   **`examples/hybrid_entra_join`**: Demonstrates a Hybrid Microsoft Entra join (`join_type = "hybrid_entra_join"`).
