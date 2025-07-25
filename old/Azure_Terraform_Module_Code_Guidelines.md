# Azure Terraform Module Code Guidelines

This document outlines comprehensive guidelines for creating Azure Terraform modules, based on best practices and real-world implementation patterns. These guidelines incorporate patterns from production-ready modules like the Azure Storage Account module.

## 1. Module Structure

### 1.1 Required Files

Every module should contain these core files:

```
module/
├── main.tf           # Primary resource configurations
├── variables.tf      # Input variable definitions
├── outputs.tf        # Output definitions
├── versions.tf       # Version constraints
├── README.md         # Module documentation
└── examples/         # Example implementations
    ├── basic/
    └── advanced/
```

### 1.2 Resource-Oriented File Separation

Split complex modules into resource-oriented files, organizing by resource type rather than by functionality:

```
module/
├── main.tf                      # Primary/core resource (e.g., Azure SQL Server) OR locals and module calls
├── databases.tf                 # Related resource type (e.g., SQL Databases)
├── firewall.tf                  # Related resource type (e.g., Firewall Rules)
├── variables.tf                 # Common variables
├── variables.databases.tf       # Resource-specific variables
├── variables.firewall.tf        # Resource-specific variables
└── ...
```

There are two common patterns for organizing `main.tf`:
1. **Main Resource Pattern**: Place the primary/core resource in `main.tf` and related resources in separate files
2. **Coordinator Pattern**: Place only `locals` and calls to other local modules in `main.tf` when all resources are in separate files

The first approach (Main Resource Pattern) is very common and works well for most modules.

Example of resource-oriented separation:
```hcl
# main.tf - Primary resource
resource "azurerm_sql_server" "example" {
  name                         = var.server_name
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = var.server_version
  administrator_login          = var.administrator_login
  administrator_login_password = var.administrator_login_password
}

# databases.tf - Database resources
resource "azurerm_sql_database" "example" {
  name                = var.database_name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.example.name
  edition             = var.database_edition
  # ...
}
```

This approach is critical for Terraform modules because:
1. Terraform treats resources as the primary organizational unit
2. Resources that are directly related should be defined together
3. The resource dependency graph is clearer when organized by resource type
4. It improves maintainability and readability of the code

### 1.3 Telemetrie und Monitoring

Implementiere Telemetrie und Monitoring-Funktionen:

```hcl
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Steuert, ob Telemetrie für das Modul aktiviert ist"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of the Log Analytics Workspace to send diagnostics to"
}

variable "event_hub_authorization_rule_id" {
  type        = string
  default     = null
  description = "Resource ID of the Event Hub Authorization Rule for diagnostics"
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Resource ID of the Storage Account for diagnostics"
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.enable_telemetry && var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "amds-${var.name}"
  target_resource_id         = azurerm_resource.example.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditLogs"
  }
  
  metric {
    category = "AllMetrics"
  }
}
```

> **Important**: Diagnostic targets like Log Analytics Workspace, Event Hub, or Storage Account should be provided as input variables to the module and not created within the module itself. This allows for better dependency management and separation of concerns. The module should only configure diagnostic settings to send data to these existing targets.

## 2. Variable Management

### 2.1 Variable Definitions

Define variables with clear types and descriptions:

```hcl
variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

# Note on Reserved Variable Names
# Avoid using the following reserved names for variables, as they are used for meta-arguments in module configuration blocks:
# `source`, `version`, `providers`, `count`, `for_each`, `lifecycle`, `depends_on`, `locals`.
```

### 2.2 Complex Variable Types

Use object types for complex configurations, including deeply nested structures with optional fields:

```hcl
variable "active_directory" {
  description = "Active Directory configuration"
  type = object({
    dns_servers     = list(string)
    domain          = string
    smb_server_name = string
    username        = string
    password        = string
    # Optional fields
    organizational_unit = optional(string)
    site_name           = optional(string)
  })
  default = null
}

# Example of deeply nested object with multiple optional fields
variable "blob_properties" {
  description = "Configuration for blob service properties"
  type = object({
    change_feed_enabled           = optional(bool)
    change_feed_retention_in_days = optional(number)
    default_service_version       = optional(string)
    last_access_time_enabled      = optional(bool)
    versioning_enabled            = optional(bool, true)
    
    container_delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), { days = 7 })

    cors_rule = optional(list(object({
      allowed_headers    = list(string)
      allowed_methods    = list(string)
      allowed_origins    = list(string)
      exposed_headers    = list(string)
      max_age_in_seconds = number
    })))
    
    delete_retention_policy = optional(object({
      days = optional(number, 7)
    }), { days = 7 })
    
    restore_policy = optional(object({
      days = number
    }))
  })
  default = null
}

# Example of map-based variable for resource collections
variable "containers" {
  description = "Map of storage containers to create"
  type = map(object({
    public_access                  = optional(string, "None")
    metadata                       = optional(map(string))
    name                           = string
    default_encryption_scope       = optional(string)
    deny_encryption_scope_override = optional(bool)
    
    immutable_storage_with_versioning = optional(object({
      enabled = bool
    }))

    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
    })), {})
  }))
  default = {}
}
```

### 2.3 Variable Validation

Implementiere Validierungsregeln für alle Variablen, um Fehler frühzeitig zu erkennen und klare Fehlermeldungen zu liefern:

#### 2.3.1 Grundlegende Validierungen

```hcl
# Validierung für begrenzte Werte (Enumerationen)
variable "service_tier" {
  description = "Service tier for the resource"
  type        = string
  validation {
    condition     = contains(["Premium", "Standard", "Basic"], var.service_tier)
    error_message = "Service tier must be Premium, Standard, or Basic."
  }
}

# Validierung für numerische Bereiche
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}

# Validierung für Formate mit Regex
variable "subnet_address_prefix" {
  description = "The address prefix for the subnet"
  type        = string
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.subnet_address_prefix))
    error_message = "Must be a valid CIDR notation (e.g., 10.0.1.0/24)."
  }
}
```

#### 2.3.2 Ressourcenspezifische Validierungen

```hcl
# Azure Storage Account Name
variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage Account Name must be 3-24 characters long and may only contain lowercase letters and numbers."
  }
}

# Azure SQL Server Name
variable "sql_server_name" {
  type        = string
  description = "Name of the SQL Server"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$", var.sql_server_name))
    error_message = "SQL Server Name must be 1-63 characters long, start and end with a lowercase letter or number, and may only contain lowercase letters, numbers, or hyphens."
  }
}

# Azure Kubernetes Version
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (major.minor format)"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Version must be in 'major.minor' format (e.g., '1.28')"
  }
}

# Azure VM Size
variable "vm_size" {
  type        = string
  description = "Size of the virtual machine"
  validation {
    condition     = contains(["Standard_B1s", "Standard_B2s", "Standard_D2s_v3", "Standard_D4s_v3", "Standard_D8s_v3"], var.vm_size)
    error_message = "Invalid VM size. Allowed values: Standard_B1s, Standard_B2s, Standard_D2s_v3, Standard_D4s_v3, Standard_D8s_v3."
  }
}

# Azure Resource Tags
variable "tags" {
  type        = map(string)
  description = "Tags for the resource"
  validation {
    condition     = length(var.tags) <= 50
    error_message = "Azure allows a maximum of 50 tags per resource."
  }
}
```

#### 2.3.3 Validierungen für Netzwerkkonfigurationen

```hcl
# IP-Adresse
variable "ip_address" {
  type        = string
  description = "IP address"
  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.ip_address))
    error_message = "Must be a valid IPv4 address."
  }
}

# Port-Nummer
variable "port" {
  type        = number
  description = "Port number"
  validation {
    condition     = var.port > 0 && var.port < 65536
    error_message = "Port must be between 1 and 65535."
  }
}

# DNS-Name
variable "dns_name" {
  type        = string
  description = "DNS name"
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.dns_name))
    error_message = "DNS name must comply with RFC 1123 conventions."
  }
}
```

### 2.4 Advanced Variable Validation

Use multiple conditions in validation blocks for complex objects:

```hcl
variable "complex_object" {
  description = "Complex object with nested validation rules"
  type = object({
    backup = object({
      frequency = optional(string)
      time      = optional(string)
    })
    retention = optional(object({
      count    = number
      weekdays = list(string)
    }))
  })

  validation {
    condition = alltrue([
      try(var.complex_object.backup.frequency == null ? true : 
          contains(["Daily", "Weekly"], var.complex_object.backup.frequency), true),
      try(var.complex_object.retention == null ? true :
          var.complex_object.retention.count >= 1 && 
          var.complex_object.retention.count <= 99, true)
    ])
    error_message = "Invalid configuration values."
  }

  # Multiple validation blocks for different aspects
  validation {
    condition = alltrue([
      try(var.complex_object.retention == null ? true :
        alltrue([for day in var.complex_object.retention.weekdays :
          contains(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"], day)
        ]), true)
    ])
    error_message = "Invalid weekday value. Must be one of: Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday."
  }
}

#### 2.4.1 Splitting Validations for Complex Types (Maps and Objects)

When validating complex variables like maps or objects with many attributes, it can be tempting to create a single large `validation` block that checks multiple conditions using functions like `alltrue([...])` or complex boolean logic.

**Problem:** This approach often leads to a generic `error_message` that doesn't pinpoint the exact validation failure, making debugging difficult for the module user. If any one of the many checks fails, the user only sees the broad error message.

**Recommendation:** Instead, it is strongly recommended to **split large validation checks into multiple, smaller `validation` blocks.** Each block should focus on validating a single condition or a small group of closely related conditions across the elements of the map or object.

**Benefit:** This allows for specific, targeted `error_message`s that clearly indicate which validation rule failed and often which element(s) are problematic.

**Guideline:** As a general rule, consider splitting validations when:
*   You are checking more than a few (e.g., 5-7) distinct attributes or conditions within the complex type.
*   A single validation block's `error_message` would become too broad or ambiguous to be helpful.

**Example: Validating a Map of Network Interfaces**

Consider a variable defining multiple network interfaces:

```hcl
variable "network_interfaces" {
  type = map(object({
    name                = string
    ip_address          = string
    enable_ip_forwarding = optional(bool, false)
    dns_servers         = optional(list(string))
  }))
  default = {}

  # --- BAD APPROACH: Single large validation block ---
  # validation {
  #   condition = alltrue([
  #     for k, v in var.network_interfaces : (
  #       # Check name format
  #       can(regex("^[a-zA-Z0-9-]{1,80}$", v.name)) &&
  #       # Check IP format
  #       can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", v.ip_address)) &&
  #       # Check DNS servers list is not empty if provided
  #       (v.dns_servers == null || length(v.dns_servers) > 0) &&
  #       # Check IP forwarding is boolean (implicit in type, but example)
  #       (v.enable_ip_forwarding == true || v.enable_ip_forwarding == false)
  #       # ... potentially more checks ...
  #     )
  #   ])
  #   # This error message is too generic if any check fails!
  #   error_message = "One or more network interface configurations are invalid. Check name format, IP address format, DNS server list, and IP forwarding setting."
  # }

  # --- GOOD APPROACH: Multiple specific validation blocks ---
  validation {
    # Check 1: Name format for each interface
    condition = alltrue([
      for k, v in var.network_interfaces : can(regex("^[a-zA-Z0-9-]{1,80}$", v.name))
    ])
    error_message = "Invalid network interface name detected. Names must be 1-80 characters long and contain only letters, numbers, and hyphens."
  }

  validation {
    # Check 2: IP address format for each interface
    condition = alltrue([
      for k, v in var.network_interfaces : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", v.ip_address))
    ])
    error_message = "Invalid network interface IP address detected. All 'ip_address' values must be valid IPv4 addresses."
  }

  validation {
    # Check 3: DNS servers list (if provided) should not be empty
    condition = alltrue([
      for k, v in var.network_interfaces : (v.dns_servers == null || length(v.dns_servers) > 0)
    ])
    error_message = "Invalid DNS configuration detected. If 'dns_servers' is provided for a network interface, the list cannot be empty."
  }

  # Add more specific validation blocks as needed...
}
```

By splitting the validation, if only the IP address format is wrong for one interface, the user will receive the specific error message related to IP addresses, making it much easier to fix.


# Example for version validation
variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version (major.minor format)"
  
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Version must be in 'major.minor' format (e.g., '1.28')"
  }
}
```

### 2.5 Nullable Variables

Definiere explizit, ob Variablen null sein dürfen:

```hcl
variable "required_parameter" {
  type        = string
  description = "Ein erforderlicher Parameter"
  nullable    = false
}

variable "optional_parameter" {
  type        = string
  description = "Ein optionaler Parameter"
  default     = null
  nullable    = true
}
```

### 2.6 Ephemeral Variables

(Available since Terraform v1.10)

The `ephemeral` argument for an input variable allows its value to be available during runtime, but Terraform will omit the value from state and plan files. This is particularly useful for data that is temporary or should not be persisted, such as short-lived authentication tokens.

Mark an input variable as ephemeral by setting the `ephemeral` argument to `true`:

```hcl
variable "session_token" {
  description = "A temporary session token for API authentication. Not stored in state."
  type        = string
  sensitive   = true // Ephemeral values are often sensitive
  ephemeral   = true
  nullable    = false // Or true if genuinely optional and might not be provided
}
```
Ephemeral variables can only be referenced in specific contexts (e.g., write-only arguments, other ephemeral variables, local values that become implicitly ephemeral, ephemeral resources, ephemeral outputs, provider configurations, provisioner and connection blocks). Referencing them elsewhere will result in an error.

### 2.7 Sensitive Input Variables

To prevent Terraform from showing a variable's value in `plan` or `apply` output, set the `sensitive` argument to `true`. While Terraform still records sensitive values in the state file (use `ephemeral` to avoid state storage), this helps protect sensitive data from being displayed in logs or console outputs.

```hcl
variable "api_key" {
  description = "The API key for accessing a third-party service."
  type        = string
  sensitive   = true
  nullable    = false // Assuming the API key is required
}

variable "secure_credentials" {
  description = "Secure credentials for a service."
  type = object({
    username = string
    password = string // This will be treated as sensitive due to the variable's sensitive flag
  })
  sensitive = true
  nullable  = false
}
```
Any expressions whose results depend on a sensitive variable will also be treated as sensitive. If a sensitive variable is used in an output, the output itself must also be marked as sensitive.

## 3. Resource Organization

### 3.1 Resource Blocks

Organize resources logically and use consistent formatting:

```hcl

resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}
```

### 3.2 Dynamic Blocks

Use dynamic blocks for repeated nested blocks with sophisticated error handling:

```hcl
resource "azurerm_example" "example" {
  # Base configuration...

  dynamic "backup_policy" {
    for_each = try(var.backup_policy[*], [])
    content {
      frequency = try(backup_policy.value.frequency, "Daily")
      time      = try(backup_policy.value.time, "04:00")
      
      dynamic "retention" {
        for_each = try(backup_policy.value.retention[*], [])
        content {
          count    = retention.value.count
          weekdays = try(retention.value.weekdays, ["Sunday"])
        }
      }
    }
  }

  # Conditional block based on type
  dynamic "additional_policy" {
    for_each = var.policy_type != "Basic" ? [1] : []
    content {
      type = "Advanced"
      settings {
        enabled = true
        retention_days = 7
      }
    }
  }

  # Multiple dynamic blocks with dependencies
  dynamic "active_directory" {
    for_each = var.active_directory != null ? [var.active_directory] : []
    content {
      dns_servers     = active_directory.value.dns_servers
      domain          = active_directory.value.domain
      smb_server_name = active_directory.value.smb_server_name
      username        = active_directory.value.username
      password        = active_directory.value.password
    }
  }
}

# Additional `dynamic` Block Arguments and Considerations

Beyond `for_each` and `content`, `dynamic` blocks offer a few more arguments and have important considerations:

-   **`iterator` Argument (Optional):**
    You can use the `iterator` argument to set a custom name for the temporary variable representing the current element of the `for_each` collection. If omitted, the iterator variable defaults to the label of the `dynamic` block (e.g., `setting` in `dynamic "setting" {...}`). Renaming the iterator can be useful for clarity, especially in nested `dynamic` blocks or when the default name is ambiguous.

    ```hcl
    variable "custom_rules" {
      description = "A list of custom rule objects."
      type = list(object({
        name     = string
        priority = number
        action   = string
      }))
      default = []
    }

    resource "azurerm_firewall_application_rule_collection" "example" {
      # ... other arguments ...
      name      = "app-rule-collection"
      priority  = 100
      action    = "Allow"

      dynamic "rule" {
        for_each = var.custom_rules
        iterator = current_rule // Custom iterator name
        content {
          name        = current_rule.value.name
          description = "Rule ${current_rule.value.name} with priority ${current_rule.value.priority}"
          source_addresses = ["*"]
          target_fqdns     = ["example.com"]
          protocol {
            port = "80"
            type = "Http"
          }
        }
      }
    }
    ```

-   **`labels` Argument (Optional):**
    The `labels` argument is a list of strings that specifies the block labels, in order, to use for each generated block. This is used when the nested block type being generated itself requires one or more labels. Most Azure resource nested blocks do not require labels (they are identified by their type), so this is less common in Azure modules but is available if needed.

-   **Considerations for `dynamic` Blocks:**
    While powerful, overuse of `dynamic` blocks can make configurations difficult to read and maintain. It's recommended to use them primarily when abstracting details to build a clean user interface for a reusable module. Where possible, writing nested blocks literally is often clearer. If a module's `dynamic` blocks are merely iterating over an input variable and mapping its attributes directly without adding significant logic or abstraction, it might be simpler for the calling configuration to define the resource directly.

-   **Limitation: Cannot Generate Meta-Argument Blocks:**
    `dynamic` blocks can only generate arguments and nested blocks that are defined by the resource type, data source, provider, or provisioner being configured. It is **not** possible to dynamically generate meta-argument blocks such as `lifecycle` or `provisioner` blocks, as Terraform needs to process these before expressions can be safely evaluated.

```

### 3.3 Resource Collections

Use for_each for resource collections:

```hcl
# locals block for pool_names removed

resource "azurerm_netapp_pool" "pool" {
  for_each = var.pools
  
  # Naming logic removed - assumes 'name' is provided directly or handled differently
  name                = lookup(var.custom_pool_names, each.key, each.value.name) # Example: Use name from pool definition or custom map
  account_name        = azurerm_netapp_account.account.name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_level       = each.value.service_level
  size_in_tb         = each.value.size_in_tb
  # Removed large locals block containing naming and complex validation logic.
  # Assumes necessary validations are handled elsewhere or inputs are guaranteed.
}
```

### 3.4 Availability Zone Management

Implement proper handling of Azure Availability Zones:

```hcl
# Get available zones for VM SKU
data "azurerm_resource_skus" "example" {
  resource_type = "virtualMachines"
  location      = var.location
}

locals {
  # Filter zones removing any restrictions
  available_zones = setsubtract(
    data.azurerm_resource_skus.example.zones,
    local.restricted_zones
  )
  
  # Apply zones to node pools
  node_pools_with_zones = {
    for pool_name, pool in var.node_pools : pool_name => merge(
      pool, 
      { zones = local.available_zones }
    )
  }
}

# Dynamic node pool creation with zones
locals {
  node_pools = flatten([
    for pool in local.node_pools_with_zones : [
      for zone in pool.zones : {
        name = "${substr(pool.name, 0, 10)}${zone}"
        zone = [zone]
        vm_size = pool.vm_size
        # Additional configurations
      }
    ]
  ])
}

resource "azurerm_kubernetes_cluster_node_pool" "example" {
  for_each = {
    for pool in local.node_pools : pool.name => pool
  }

  kubernetes_cluster_id = azurerm_kubernetes_cluster.example.id
  name                  = each.value.name
  vm_size               = each.value.vm_size
  zones                 = each.value.zone
}
```

## 4. Documentation Standards

### 4.1 Output Documentation

Guidelines for safe and effective output definitions:

```hcl
# DO NOT output entire resource objects
# BAD:
output "cluster" {
  value = azurerm_kubernetes_cluster.example
}

# GOOD: Output specific attributes
output "cluster_id" {
  description = "The Kubernetes Managed Cluster ID"
  value       = azurerm_kubernetes_cluster.example.id
}

# Handle sensitive values appropriately
output "client_certificate" {
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster"
  value       = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate
  sensitive   = true
}

# Use try() for optional outputs
output "private_fqdn" {
  description = "The FQDN for the Kubernetes Cluster when private link has been enabled"
  value       = try(azurerm_kubernetes_cluster.example.private_fqdn, null)
}
```

### 4.2 README Structure

Every module should have a comprehensive README.md that follows a standardized structure. A well-documented README is essential for module usability, maintainability, and adoption. The README should include the following sections:

#### 1. Module Title and Description

Start with a clear title and concise description of what the module does:

```markdown
# Terraform Azure Storage Account Module

This Terraform module is designed to create Azure Storage Accounts and its related resources, including blob containers, queues, tables, and file shares. It also supports the creation of a storage account private endpoint which provides secure and direct connectivity to Azure Storage over a private network.
```

#### 2. Version Information

Include information about the module's version stability using SemVer principles:

```markdown
> **Warning**
>
> Major version Zero (0.y.z) is for initial development. Anything MAY change at any time. A module SHOULD NOT be considered stable till at least it is major version one (1.0.0) or greater. Changes will always be via new versions being published and no changes will be made to existing published versions. For more details please go to https://semver.org/
```

#### 3. Features List

Provide a comprehensive list of features that clearly communicates the module's capabilities:

```markdown
## Features

- Create a storage account with various configuration options such as account kind, tier, replication type, network rules, and identity settings.
- Create blob containers, queues, tables, and file shares within the storage account.
- Support for customer-managed keys for encrypting the data in the storage account.
- Enable private endpoint for the storage account, providing secure access over a private network.
```

#### 4. Limitations and Important Notes

Document any known limitations or important considerations:

```markdown
## Limitations

- The storage account name must be globally unique.
- The module creates resources in the same region as the storage account.

> **IMPORTANT** We recommend using Azure AD authentication over Shared Key for provisioning Storage Containers, Blobs, and other items. To achieve this, add the storage_use_azuread flag in the Provider block. However, it's important to note that not all Azure Storage services support Active Directory authentication. In the absence of the storage_use_azuread flag, you will need to enable Shared Key Access by setting the shared_access_key_enabled flag True.
```

#### 5. Requirements

List all required providers and their versions:

```markdown
## Requirements

The following requirements are needed by this module:

- terraform (>= 1.7.0)
- azapi (>= 1.14.0, < 3.0.0)
- azurerm (>= 3.116.0, < 5.0.0)
- modtm (~> 0.3)
- random (>= 3.5.0, < 4.0.0)
```

#### 6. External Dependencies

List all external Azure resources that this module depends on but does not create. This helps users understand the prerequisites needed before using the module.

```markdown
## External Dependencies

This module requires the following external resources to be created and provided as input:

- **Resource Group**: The target resource group for deployment. (Input: `resource_group_name`)
- **Virtual Network & Subnet**: Required if deploying network-dependent resources like VMs or Private Endpoints. (Inputs: `vnet_id`, `subnet_id`)
- **Log Analytics Workspace**: Required if diagnostics are enabled. (Input: `log_analytics_workspace_id`)
- **Key Vault**: Required if using Customer-Managed Keys. (Input: `customer_managed_key.key_vault_resource_id`)
- **User Assigned Managed Identity**: Required for specific authentication scenarios (e.g., CMK). (Input: `customer_managed_key.user_assigned_identity.resource_id`)
```

#### 7. Resources

List all resources created *by* the module:

```markdown
## Resources

The following resources are used by this module:

- azapi_resource.containers (resource)
- azurerm_storage_account.this (resource)
- azurerm_storage_account_customer_managed_key.this (resource)
- azurerm_private_endpoint.this (resource)
- azurerm_role_assignment.storage_account (resource)
```

#### 7. Input Variables

Document all input variables, clearly indicating which are required and which are optional:

```markdown
## Required Inputs

The following input variables are required:

### location

Description: Azure region where the resource should be deployed.
If null, the location will be inferred from the resource group location.

Type: `string`

### name

Description: The name of the resource.

Type: `string`

### resource_group_name

Description: The resource group where the resources will be deployed.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### account_kind

Description: (Optional) Defines the Kind of account. Valid options are BlobStorage, BlockBlobStorage, FileStorage, Storage and StorageV2. Defaults to StorageV2.

Type: `string`

Default: `"StorageV2"`

### account_replication_type

Description: (Required) Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS. Defaults to ZRS

Type: `string`

Default: `"ZRS"`
```

For complex variable types, use detailed documentation with examples:

```markdown
### customer_managed_key

Description: Defines a customer managed key to use for encryption.

```hcl
object({  
  key_vault_resource_id              = (Required) - The full Azure Resource ID of the key_vault where the customer managed key will be referenced from.  
  key_name                           = (Required) - The key name for the customer managed key in the key vault.  
  key_version                        = (Optional) - The version of the key to use  
  user_assigned_identity_resource_id = (Optional) - The user assigned identity to use when access the key vault
})
```

Example Inputs:
```terraform
customer_managed_key = {
  key_vault_resource_id = "/subscriptions/0000000-0000-0000-0000-000000000000/resourceGroups/test-resource-group/providers/Microsoft.KeyVault/vaults/example-key-vault"
  key_name              = "sample-customer-key"
}
```

Type:

```hcl
object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
```

Default: `null`
```

#### 8. Outputs

Document all outputs from the module:

```markdown
## Outputs

The following outputs are exported:

### containers

Description: Map of storage containers that are created.

### fqdn

Description: Fqdns for storage services.

### name

Description: The name of the storage account

### resource_id

Description: The ID of the Storage Account.
```

#### 9. Usage Examples

Provide basic and advanced usage examples:

```markdown
## Usage Examples

### Basic Storage Account

```hcl
module "storage" {
  source = "path/to/module"

  name                = "examplestorage"
  resource_group_name = "example-rg"
  location            = "westeurope"
}
```

### Storage Account with Blob Containers and Private Endpoint

```hcl
module "storage" {
  source = "path/to/module"

  name                = "examplestorage"
  resource_group_name = "example-rg"
  location            = "westeurope"
  
  account_kind        = "StorageV2"
  account_tier        = "Standard"
  
  containers = {
    "data" = {
      name = "data"
    },
    "logs" = {
      name = "logs"
    }
  }
  
  private_endpoints = {
    "endpoint1" = {
      subnet_resource_id = "/subscriptions/.../resourceGroups/example-rg/providers/Microsoft.Network/virtualNetworks/example-vnet/subnets/example-subnet"
      subresource_name   = "blob"
      private_dns_zone_resource_ids = [
        "/subscriptions/.../resourceGroups/example-rg/providers/Microsoft.Network/privateDnsZones/privatelink.blob.core.windows.net"
      ]
    }
  }
}
```
```

#### Best Practices for README Documentation

1. **Use Markdown Formatting Effectively**
   - Use headers, lists, code blocks, and tables to organize information
   - Use syntax highlighting for code examples
   - Use blockquotes for important notes or warnings

2. **Keep Documentation Updated**
   - Ensure the README is updated whenever the module changes
   - Version the README along with the module

3. **Be Comprehensive but Concise**
   - Include all necessary information without being overly verbose
   - Use clear, direct language

4. **Include Visual Elements When Helpful**
   - Diagrams for complex architectures
   - Screenshots for visual confirmation of expected results

5. **Provide Working Examples**
   - Include examples that users can copy and use with minimal modification
   - Cover both simple and advanced use cases

### 5.2 Variable Documentation

Document all variables with clear descriptions:

```hcl
variable "pools" {
  description = <<EOT
Map of NetApp pools to create. Each pool supports:
- service_level: Premium, Standard, or Ultra
- size_in_tb: Size between 1 and 2048
- qos_type: Auto or Manual
- encryption_type: Single or Double
EOT
  type = map(object({
    service_level   = string
    size_in_tb      = number
    qos_type        = optional(string)
    encryption_type = optional(string)
  }))
}
```

### 5.3 Variable Documentation for Complex Types

Für komplexe Variablentypen wie Maps und Objects ist eine detaillierte Dokumentation erforderlich, die die vollständige Struktur und alle Optionen beschreibt. Folgen Sie diesen Richtlinien:

1. **Vollständige Struktur dokumentieren**: Dokumentieren Sie alle Felder innerhalb komplexer Variablen, einschließlich verschachtelter Objekte.

2. **Required/Optional kennzeichnen**: Kennzeichnen Sie jedes Feld innerhalb komplexer Variablen explizit als "(Required)" oder "(Optional)".

3. **Hierarchische Darstellung**: Verwenden Sie Einrückungen und Listen, um die Hierarchie der Felder darzustellen.

4. **Beispiele bereitstellen**: Fügen Sie praktische Beispiele für die Verwendung komplexer Variablen hinzu.

5. **Vollständigen Typ anzeigen**: Zeigen Sie den vollständigen Terraform-Typ der Variable an, einschließlich aller verschachtelten Typen.

Beispiel für die Dokumentation einer komplexen Variable:

```markdown
### <a name="input_virtual_network_peerings"></a> [virtual_network_peerings](#input_virtual_network_peerings)

Description: Map of Virtual Network Peerings to create

- `<map key>` - Use a custom map key to define each peering
  - `remote_virtual_network_id` = (Required) The Azure Resource ID of the remote virtual network
  - `allow_forwarded_traffic` = (Optional) Whether to allow forwarded traffic from the remote virtual network
  - `allow_gateway_transit` = (Optional) Whether gateway links can be used in the remote virtual network
  - `use_remote_gateways` = (Optional) Whether remote gateways can be used on the local virtual network

Example Inputs:

```hcl
virtual_network_peerings = {
  peer-to-hub = {
    remote_virtual_network_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/hub-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet"
    allow_forwarded_traffic   = true
    use_remote_gateways       = true
  }
}
```

Type:

```hcl
map(object({
  remote_virtual_network_id = string
  allow_forwarded_traffic   = optional(bool, false)
  allow_gateway_transit     = optional(bool, false)
  use_remote_gateways       = optional(bool, false)
}))
```

Default: `{}`
```

Diese Dokumentationsstruktur:
- Macht die Hierarchie der Variablen klar ersichtlich
- Kennzeichnet jedes Feld als Required oder Optional
- Zeigt Standardwerte für optionale Felder
- Bietet praktische Beispiele für die Verwendung
- Zeigt den vollständigen Terraform-Typ für Entwickler

## 5. Best Practices

### 5.1 Error Handling and Telemetry

#### Telemetry Implementation
```hcl
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Enable/disable telemetry collection"
}

variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of the Log Analytics Workspace to send diagnostics to"
}

resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.enable_telemetry && var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${var.name}"
  target_resource_id         = azurerm_resource.example.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditLogs"
  }
  
  metric {
    category = "AllMetrics"
  }
}

# Note: The following code would typically belong in a dedicated Log Analytics Workspace module,
# not in every module that sends diagnostic data
# Log Analytics workspace tables
# locals {
#   log_analytics_tables = [
#     "AuditLogs",
#     "OperationalLogs",
#     "SecurityLogs"
#   ]
# }
# 
# resource "azurerm_log_analytics_workspace_table" "example" {
#   for_each = toset(local.log_analytics_tables)
# 
#   name                    = each.value
#   workspace_id            = azurerm_log_analytics_workspace.example.id
#   plan                    = "Basic"
#   total_retention_in_days = 30
# }
```

#### Comprehensive Diagnostic Settings
```hcl
variable "diagnostic_settings_storage_account" {
  description = "A map of diagnostic settings to create on the Storage Account"
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default = {}
}

# Implementation for multiple diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  for_each = var.diagnostic_settings_storage_account

  name                           = coalesce(each.value.name, "diag-${var.name}")
  target_resource_id             = azurerm_storage_account.this.id
  log_analytics_workspace_id     = each.value.workspace_resource_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  storage_account_id             = each.value.storage_account_resource_id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  partner_solution_id            = each.value.marketplace_partner_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_log" {
    for_each = each.value.log_groups
    content {
      category_group = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}
```

#### Managed Identity Best Practices
```hcl
variable "managed_identities" {
  description = "Controls the Managed Identity configuration on this resource"
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default = {}
}

locals {
  managed_identities = {
    user_assigned = length(var.managed_identities.user_assigned_resource_ids) > 0 ? {
      type = "UserAssigned"
      user_assigned_resource_ids = var.managed_identities.user_assigned_resource_ids
    } : null
    
    system_assigned = var.managed_identities.system_assigned ? {
      type = "SystemAssigned"
    } : null
  }
}

resource "azurerm_user_assigned_identity" "example" {
  count = local.managed_identities.user_assigned == null ? 1 : 0

  name                = "uami-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

resource "azurerm_role_assignment" "example" {
  principal_id         = local.managed_identities.user_assigned != null ? 
                        local.managed_identities.user_assigned.principal_id :
                        azurerm_user_assigned_identity.example[0].principal_id
  scope                = var.scope_id
  role_definition_name = "Contributor"
}
```

### 5.2 Role-Based Access Control (RBAC)

Implement standardized role assignments for resources and sub-resources:

```hcl
variable "role_assignments" {
  description = "A map of role assignments to create on the resource"
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default = {}
}

# Role assignments for the main resource
resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  scope                                   = azurerm_resource.example.id
  role_definition_id                      = try(length(regexall("^/subscriptions/", each.value.role_definition_id_or_name)) > 0, false) ? each.value.role_definition_id_or_name : null
  role_definition_name                    = try(length(regexall("^/subscriptions/", each.value.role_definition_id_or_name)) > 0, false) ? null : each.value.role_definition_id_or_name
  principal_id                            = each.value.principal_id
  condition                               = each.value.condition
  condition_version                       = each.value.condition_version
  skip_service_principal_aad_check        = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id  = each.value.delegated_managed_identity_resource_id
  principal_type                          = each.value.principal_type
  description                             = each.value.description
}

# Role assignments for sub-resources
resource "azurerm_role_assignment" "sub_resource" {
  for_each = { for idx, assignment in local.sub_resource_role_assignments : idx => assignment }

  scope                                   = each.value.scope
  role_definition_id                      = try(length(regexall("^/subscriptions/", each.value.role_definition_id_or_name)) > 0, false) ? each.value.role_definition_id_or_name : null
  role_definition_name                    = try(length(regexall("^/subscriptions/", each.value.role_definition_id_or_name)) > 0, false) ? null : each.value.role_definition_id_or_name
  principal_id                            = each.value.principal_id
  condition                               = each.value.condition
  condition_version                       = each.value.condition_version
  skip_service_principal_aad_check        = each.value.skip_service_principal_aad_check
  delegated_managed_identity_resource_id  = each.value.delegated_managed_identity_resource_id
  principal_type                          = each.value.principal_type
  description                             = each.value.description
}
```

### 5.3 Private Endpoint Implementation

Implement standardized private endpoint configuration:

```hcl
variable "private_endpoints" {
  description = "A map of private endpoints to create on the resource"
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default = {}
}

variable "private_endpoints_manage_dns_zone_group" {
  description = "Whether to manage private DNS zone groups with this module"
  type        = bool
  default     = true
}

# Create private endpoints
resource "azurerm_private_endpoint" "this" {
  for_each = { for k, v in var.private_endpoints : k => v if var.private_endpoints_manage_dns_zone_group }

  name                = coalesce(each.value.name, "pe-${var.name}-${each.key}")
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_group_name)
  subnet_id           = each.value.subnet_resource_id
  tags                = each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "psc-${var.name}-${each.key}")
    private_connection_resource_id = azurerm_resource.example.id
    is_manual_connection           = false
    subresource_names              = [each.value.subresource_name]
  }

  dynamic "private_dns_zone_group" {
    for_each = length(each.value.private_dns_zone_resource_ids) > 0 ? [1] : []
    content {
      name                 = each.value.private_dns_zone_group_name
      private_dns_zone_ids = each.value.private_dns_zone_resource_ids
    }
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = each.value.subresource_name
      member_name        = each.value.subresource_name
    }
  }
}

# Create private endpoints without DNS zone groups
resource "azurerm_private_endpoint" "this_unmanaged_dns_zone_groups" {
  for_each = { for k, v in var.private_endpoints : k => v if !var.private_endpoints_manage_dns_zone_group }

  name                = coalesce(each.value.name, "pe-${var.name}-${each.key}")
  location            = coalesce(each.value.location, var.location)
  resource_group_name = coalesce(each.value.resource_group_name, var.resource_group_name)
  subnet_id           = each.value.subnet_resource_id
  tags                = each.value.tags

  private_service_connection {
    name                           = coalesce(each.value.private_service_connection_name, "psc-${var.name}-${each.key}")
    private_connection_resource_id = azurerm_resource.example.id
    is_manual_connection           = false
    subresource_names              = [each.value.subresource_name]
  }

  dynamic "ip_configuration" {
    for_each = each.value.ip_configurations
    content {
      name               = ip_configuration.value.name
      private_ip_address = ip_configuration.value.private_ip_address
      subresource_name   = each.value.subresource_name
      member_name        = each.value.subresource_name
    }
  }
}

# Associate application security groups with private endpoints
resource "azurerm_private_endpoint_application_security_group_association" "this" {
  for_each = {
    for idx, assoc in local.private_endpoint_application_security_group_associations : idx => assoc
  }

  private_endpoint_id           = each.value.private_endpoint_id
  application_security_group_id = each.value.application_security_group_id
}
```

### 5.4 Customer-Managed Keys

Implement support for customer-managed keys:

```hcl
variable "customer_managed_key" {
  description = "Defines a customer managed key to use for encryption"
  type = object({
    key_vault_resource_id = string
    key_name              = string
    key_version           = optional(string, null)
    user_assigned_identity = optional(object({
      resource_id = string
    }), null)
  })
  default = null
}

resource "azurerm_storage_account_customer_managed_key" "this" {
  count = var.customer_managed_key != null ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id
  key_vault_id       = var.customer_managed_key.key_vault_resource_id
  key_name           = var.customer_managed_key.key_name
  key_version        = var.customer_managed_key.key_version

  dynamic "user_assigned_identity" {
    for_each = var.customer_managed_key.user_assigned_identity != null ? [1] : []
    content {
      key_vault_id = var.customer_managed_key.key_vault_resource_id
      identity_id  = var.customer_managed_key.user_assigned_identity.resource_id
    }
  }
}
```

### 5.5 Resource Management Policies

Implement lifecycle management policies for resources:

```hcl
variable "storage_management_policy_rule" {
  description = "Storage account management policy rules"
  type = map(object({
    enabled = bool
    name    = string
    actions = object({
      base_blob = optional(object({
        auto_tier_to_hot_from_cool_enabled                             = optional(bool)
        delete_after_days_since_creation_greater_than                  = optional(number)
        delete_after_days_since_last_access_time_greater_than          = optional(number)
        delete_after_days_since_modification_greater_than              = optional(number)
        tier_to_archive_after_days_since_creation_greater_than         = optional(number)
        tier_to_archive_after_days_since_last_access_time_greater_than = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_archive_after_days_since_modification_greater_than     = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
        tier_to_cold_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cold_after_days_since_modification_greater_than        = optional(number)
        tier_to_cool_after_days_since_creation_greater_than            = optional(number)
        tier_to_cool_after_days_since_last_access_time_greater_than    = optional(number)
        tier_to_cool_after_days_since_modification_greater_than        = optional(number)
      }))
      snapshot = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation_greater_than                  = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
      version = optional(object({
        change_tier_to_archive_after_days_since_creation               = optional(number)
        change_tier_to_cool_after_days_since_creation                  = optional(number)
        delete_after_days_since_creation                               = optional(number)
        tier_to_archive_after_days_since_last_tier_change_greater_than = optional(number)
        tier_to_cold_after_days_since_creation_greater_than            = optional(number)
      }))
    })
    filters = object({
      blob_types   = set(string)
      prefix_match = optional(set(string))
      match_blob_index_tag = optional(set(object({
        name      = string
        operation = optional(string)
        value     = string
      })))
    })
  }))
  default = {}
}

resource "azurerm_storage_management_policy" "this" {
  count = length(var.storage_management_policy_rule) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.storage_management_policy_rule
    content {
      name    = rule.value.name
      enabled = rule.value.enabled

      dynamic "actions" {
        for_each = rule.value.actions != null ? [rule.value.actions] : []
        content {
          dynamic "base_blob" {
            for_each = actions.value.base_blob != null ? [actions.value.base_blob] : []
            content {
              auto_tier_to_hot_from_cool_enabled                             = base_blob.value.auto_tier_to_hot_from_cool_enabled
              delete_after_days_since_creation_greater_than                  = base_blob.value.delete_after_days_since_creation_greater_than
              delete_after_days_since_last_access_time_greater_than          = base_blob.value.delete_after_days_since_last_access_time_greater_than
              delete_after_days_since_modification_greater_than              = base_blob.value.delete_after_days_since_modification_greater_than
              tier_to_archive_after_days_since_creation_greater_than         = base_blob.value.tier_to_archive_after_days_since_creation_greater_than
              tier_to_archive_after_days_since_last_access_time_greater_than = base_blob.value.tier_to_archive_after_days_since_last_access_time_greater_than
              tier_to_archive_after_days_since_last_tier_change_greater_than = base_blob.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_archive_after_days_since_modification_greater_than     = base_blob.value.tier_to_archive_after_days_since_modification_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = base_blob.value.tier_to_cold_after_days_since_creation_greater_than
              tier_to_cold_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cold_after_days_since_last_access_time_greater_than
              tier_to_cold_after_days_since_modification_greater_than        = base_blob.value.tier_to_cold_after_days_since_modification_greater_than
              tier_to_cool_after_days_since_creation_greater_than            = base_blob.value.tier_to_cool_after_days_since_creation_greater_than
              tier_to_cool_after_days_since_last_access_time_greater_than    = base_blob.value.tier_to_cool_after_days_since_last_access_time_greater_than
              tier_to_cool_after_days_since_modification_greater_than        = base_blob.value.tier_to_cool_after_days_since_modification_greater_than
            }
          }

          dynamic "snapshot" {
            for_each = actions.value.snapshot != null ? [actions.value.snapshot] : []
            content {
              change_tier_to_archive_after_days_since_creation               = snapshot.value.change_tier_to_archive_after_days_since_creation
              change_tier_to_cool_after_days_since_creation                  = snapshot.value.change_tier_to_cool_after_days_since_creation
              delete_after_days_since_creation_greater_than                  = snapshot.value.delete_after_days_since_creation_greater_than
              tier_to_archive_after_days_since_last_tier_change_greater_than = snapshot.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = snapshot.value.tier_to_cold_after_days_since_creation_greater_than
            }
          }

          dynamic "version" {
            for_each = actions.value.version != null ? [actions.value.version] : []
            content {
              change_tier_to_archive_after_days_since_creation               = version.value.change_tier_to_archive_after_days_since_creation
              change_tier_to_cool_after_days_since_creation                  = version.value.change_tier_to_cool_after_days_since_creation
              delete_after_days_since_creation                               = version.value.delete_after_days_since_creation
              tier_to_archive_after_days_since_last_tier_change_greater_than = version.value.tier_to_archive_after_days_since_last_tier_change_greater_than
              tier_to_cold_after_days_since_creation_greater_than            = version.value.tier_to_cold_after_days_since_creation_greater_than
            }
          }
        }
      }

      dynamic "filters" {
        for_each = rule.value.filters != null ? [rule.value.filters] : []
        content {
          blob_types   = filters.value.blob_types
          prefix_match = filters.value.prefix_match

          dynamic "match_blob_index_tag" {
            for_each = filters.value.match_blob_index_tag != null ? filters.value.match_blob_index_tag : []
            content {
              name      = match_blob_index_tag.value.name
              operation = match_blob_index_tag.value.operation
              value     = match_blob_index_tag.value.value
            }
          }
        }
      }
    }
  }
}
```

### 5.6 Version Constraints

Specify version constraints in versions.tf:

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
  required_version = ">= 1.9.0"
}
```

### 5.7 Resource Protection and Lifecycle Management

Use `lifecycle` blocks within resource definitions to customize resource behavior during creation, updates, and deletion.

**Key `lifecycle` Arguments:**

*   **`create_before_destroy` (bool):**
    *   If `true`, Terraform creates a replacement resource before destroying the old one during updates that require replacement.
    *   Useful for minimizing downtime, but ensure your resource and Azure constraints (e.g., unique naming) allow concurrent existence.
    *   Note: Destroy-time provisioners do not run on the old resource if this is enabled. This behavior also propagates to dependencies.
    *   Example:
        ```hcl
        resource "azurerm_service_plan" "example" {
          # ... configuration ...
          lifecycle {
            create_before_destroy = true
          }
        }
        ```

*   **`prevent_destroy` (bool):**
    *   If `true`, Terraform will reject any plan that would destroy this resource.
    *   Use sparingly as a safety measure for critical, hard-to-recreate resources (e.g., production databases).
    *   This does not prevent destruction if the entire `resource` block is removed from the configuration.
    *   Example:
        ```hcl
        resource "azurerm_cosmosdb_account" "critical_db" {
          # ... configuration ...
          lifecycle {
            prevent_destroy = true
          }
        }
        ```

*   **`ignore_changes` (list of attribute names or `all`):**
    *   Instructs Terraform to ignore changes to specified attributes or all attributes (`all`) when planning updates.
    *   Useful when external processes manage certain attributes post-creation, or for attributes that change frequently but shouldn't trigger updates (e.g., a timestamp tag).
    *   Example:
        ```hcl
        resource "azurerm_kubernetes_cluster" "example" {
          # ... configuration ...
          lifecycle {
            ignore_changes = [
              tags["LastModifiedByAgent"], // Ignore a tag updated by an external agent
              default_node_pool[0].node_count, // If node count is managed by cluster autoscaler
            ]
          }
        }
        ```

*   **`replace_triggered_by` (list of resource or attribute references - Terraform v1.2+):**
    *   Forces replacement of the resource when any of the referenced managed resources, instances, or their attributes change.
    *   Useful when a resource needs to be recreated based on changes in dependencies that wouldn't normally trigger a replacement.
    *   You can use `terraform_data` to track changes in plain variables or local values if needed.
    *   Example:
        ```hcl
        resource "terraform_data" "custom_image_version" {
          input = var.vm_custom_image_id # Track changes to this variable
        }

        resource "azurerm_linux_virtual_machine" "example" {
          # ... configuration ...
          source_image_id = var.vm_custom_image_id

          lifecycle {
            replace_triggered_by = [
              terraform_data.custom_image_version.output
            ]
          }
        }
        ```
        The example above with `azapi_update_resource` and `null_resource.version_keeper` is a valid pattern for triggering updates based on variable changes, especially for resources managed by `azapi`. `replace_triggered_by` offers a more direct way for resource replacement.

**Custom Conditions (`precondition` and `postcondition`):**

*   **`precondition`:**
    *   Validates assumptions *before* a resource operation (create, update, destroy) proceeds.
    *   For input variable validation (including cross-variable checks since Terraform v1.9.0+), prefer `variable validation` blocks (see Section 2.3 and 6.2) as they fail earlier and are more targeted for inputs.
    *   `lifecycle.precondition` is best for validating conditions related to the resource's own attributes (`self.*`) or its dependencies on other managed resources/data sources during the plan/apply phase.
    *   Example:
        ```hcl
        resource "azurerm_storage_container" "example" {
          # ... configuration ...
          lifecycle {
            precondition {
              condition     = var.storage_account_kind == "StorageV2" || var.storage_account_kind == "BlobStorage"
              error_message = "Container creation is only supported for StorageV2 or BlobStorage account kinds."
            }
          }
        }
        ```

*   **`postcondition`:**
    *   Validates guarantees *after* a resource operation has completed.
    *   Useful for ensuring the resource is in the expected state post-provisioning.
    *   Example:
        ```hcl
        resource "azurerm_public_ip" "example" {
          # ... configuration ...
          lifecycle {
            postcondition {
              condition     = self.sku == "Standard" || !var.require_standard_sku_for_public_ip
              error_message = "Public IP SKU must be Standard if standard SKU is required."
            }
          }
        }
        ```

**Note on Literal Values:**
Arguments within a `lifecycle` block (e.g., `create_before_destroy = true`, `ignore_changes = ["tags"]`) must generally be literal values. They are processed early in Terraform's graph construction, before full expression evaluation is always possible. Exceptions include the `condition` expressions in `precondition` and `postcondition`, and the list of references in `replace_triggered_by`.

```hcl
# Example showing various lifecycle arguments
resource "azurerm_kubernetes_cluster" "example" {
  # ... configuration ...
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.dns_prefix

  lifecycle {
    create_before_destroy = var.enable_zero_downtime_upgrade
    prevent_destroy     = var.protect_cluster_from_deletion
    ignore_changes = [
      kubernetes_version,    # If using Azure's auto-upgrade feature
      tags["DeployedAt"],    # If a tag is set dynamically at deploy time
    ]
    replace_triggered_by = [
      # Replace cluster if the associated VNet is replaced (hypothetical example)
      # module.network.vnet_id 
    ]
    precondition {
      condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.dns_prefix)) && length(var.dns_prefix) <= 63
      error_message = "DNS prefix must be valid and between 1-63 characters."
    }
    postcondition {
      condition     = self.private_cluster_enabled == var.expect_private_cluster
      error_message = "Cluster private status (private_cluster_enabled: ${self.private_cluster_enabled}) does not match expected (expect_private_cluster: ${var.expect_private_cluster})."
    }
  }
}

# Version update mechanism (alternative to replace_triggered_by for some scenarios)
# The existing example for azapi_update_resource is a valid pattern for specific update scenarios.
# resource "null_resource" "version_keeper" {
#   triggers = {
#     version = var.kubernetes_version
#   }
# }
# 
# resource "azapi_update_resource" "post_create" {
#   type = "Microsoft.ContainerService/managedClusters@2024-02-01"
#   body = jsonencode({
#     properties = {
#       kubernetesVersion = var.kubernetes_version
#     }
#   })
#   resource_id = azurerm_kubernetes_cluster.example.id
# 
#   lifecycle {
#     replace_triggered_by = [null_resource.version_keeper.id]
#   }
# }
```

### 5.8 Error Handling

Implement proper error handling through variable validation:

```hcl
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
  
  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 365
    error_message = "Backup retention must be between 7 and 365 days."
  }
}
```

### 5.9 Tag Management

Implement consistent tagging:

```hcl
locals {
  common_tags = merge(
    var.tags,
    {
      Environment = var.env
      ManagedBy   = "Terraform"
    }
  )
}

resource "azurerm_resource_group" "example" {
  # ... configuration ...
  tags = local.common_tags
}
```

### 5.10 Error Handling with try() Function

Implement safe access to optional nested values:

```hcl
locals {
  # Simple fallback values
  backup_frequency = try(var.backup_policy.frequency, "Daily")
  retention_days   = try(var.backup_policy.retention.count, 7)
  
  # Multiple fallbacks with cascading defaults
  backup_time = try(
    var.backup_policy.time,
    var.default_backup_time,
    "04:00"
  )
  
  # Complex transformations with try
  retention_settings = try({
    count    = var.backup_policy.retention.count
    weekdays = var.backup_policy.retention.weekdays
  }, {
    count    = 7
    weekdays = ["Sunday"]
  })

  # Conditional transformations
  backup_settings = {
    enabled = true
    policy = try(
      var.policy_type == "Advanced" ? {
        type = "Advanced"
        settings = var.advanced_settings
      } : {
        type = "Basic"
        settings = var.basic_settings
      },
      {
        type = "Basic"
        settings = {}
      }
    )
  }
}

# Using try with dynamic configuration
resource "azurerm_example" "example" {
  # Naming logic removed
  name = try(
    var.custom_name,
    # local.is_using_naming ? module.naming.names["resource"] : null, # REMOVED
    "default-name"
  )

  dynamic "configuration" {
    for_each = try(var.config[*], [])
    content {
      setting_a = try(configuration.value.a, "default_a")
      setting_b = try(configuration.value.b, "default_b")
    }
  }
}
```

## 6. Testing and Validation

### 6.1 Example Configurations

Provide various example configurations:

```
examples/
├── basic/
│   ├── main.tf
│   └── variables.tf
├── complete/
│   ├── main.tf
│   └── variables.tf
└── custom/
    ├── main.tf
    └── variables.tf
```

### 6.2 Validation Testing

Implement robust validation to catch configuration errors early. Use the appropriate mechanism based on the complexity of the check and the Terraform version being targeted.

1.  **`variable` Validation Blocks (Recommended for most input validations):**
    *   Use for checks involving a **single variable** (e.g., format, length, allowed values) AND for **cross-variable validation** (checks depending on multiple input variables).
    *   **Terraform v1.9.0 and later:** `validation` blocks within a `variable` can refer to other input variables, making this the primary and recommended method for most input-driven validation logic.
    *   These are defined directly within the `variable` block.
    *   This approach provides clear, contextual error messages tied directly to the input variables.
    *   Example (single variable):
        ```hcl
        variable "account_tier" {
          type        = string
          description = "Storage account tier."
          validation {
            condition     = contains(["Standard", "Premium"], var.account_tier)
            error_message = "Account tier must be either Standard or Premium."
          }
        }
        ```
    *   Example (cross-variable validation - Terraform v1.9.0+):
        ```hcl
        variable "provision_vm_agent" {
          type        = bool
          description = "Should the Azure VM Agent be provisioned."
          default     = true
          validation {
            # Valid if agent is provisioned OR if no extensions are defined.
            condition     = var.provision_vm_agent || length(var.vm_extensions) == 0
            error_message = "If 'provision_vm_agent' is false, 'vm_extensions' must be empty."
          }
        }

        variable "vm_extensions" {
          type        = map(any) # Example type
          description = "VM extensions to install."
          default     = {}
          validation {
            # Valid if no extensions are defined OR if agent is provisioned.
            condition     = length(var.vm_extensions) == 0 || var.provision_vm_agent
            error_message = "If 'vm_extensions' are defined, 'provision_vm_agent' must be true."
          }
        }
        ```

2.  **`lifecycle.precondition` for Resource State Validation:**
    *   Use `lifecycle.precondition` primarily for validating conditions related to the **state or attributes of a resource itself (using `self.*`) or its dependencies on other resources/data sources**, especially for conditions that can only be checked after a resource is planned or applied.
    *   **Terraform v1.9.0 and later:** Precondition expressions *must refer to at least one object from elsewhere in the configuration* (e.g., `self.*`, another resource, a data source, or an input variable in a way that isn't purely static). Purely static conditions (like `false`) or conditions based *solely* on `local` variables derived only from other input variables might not trigger reliably or as expected for plan-time input validation.
    *   For validating relationships between input variables, prefer `variable` validation blocks (see point 1).
    *   Example (validating a resource attribute):
        ```hcl
        resource "azurerm_kubernetes_cluster" "example" {
          # ... configuration ...

          lifecycle {
            precondition {
              condition     = self.power_state == "Running" || var.allow_stopped_cluster
              error_message = "Cluster must be in a running state unless 'allow_stopped_cluster' is true."
            }
            # ... other lifecycle settings ...
          }
        }
        ```

3.  **`check` Blocks for Post-Deployment Assertions (Terraform v1.5.0+):**
    *   Use `check` blocks to assert conditions about your infrastructure *after* planning or applying changes. Failed assertions result in **warnings**, not errors, and **do not block** the plan or apply operation. This contrasts with `lifecycle.postcondition` failures, which would halt the Terraform operation.
    *   They are ideal for ongoing health checks, compliance validation, or verifying conditions that depend on the interaction of multiple resources, without halting Terraform's execution if a check fails.
    *   `check` blocks can include **scoped data sources** to query external systems or the state of provisioned resources as part of the validation. Errors from scoped data sources are also treated as warnings. Use `depends_on` within scoped data sources to ensure they run only after the necessary resources are provisioned or updated. This is crucial to avoid premature failure warnings during initial provisioning or when a depended-on resource is undergoing changes, ensuring the check queries the service only when it's expected to be in the desired state.
    *   Example (Simple Assertion):
        ```hcl
        # Checks if a potentially created Public IP is null (e.g., for an internal service)
        check "public_ip_exposure" {
          assert {
            # Assumes azurerm_public_ip.internal_service might be created conditionally
            condition     = try(azurerm_public_ip.internal_service.ip_address, null) == null
            error_message = "A public IP was unexpectedly created for the internal service."
          }
        }
        ```
    *   Example (Using Scoped Data Source for Health Check):
        ```hcl
        # Checks if a provisioned App Service responds successfully to a health endpoint
        check "app_service_health" {
          # Scoped data source: Only runs if the check block is evaluated.
          # Errors fetching data are warnings.
          data "http" "app_service_probe" {
            # Assumes azurerm_linux_web_app.example exists in the configuration
            url = "https://${azurerm_linux_web_app.example.default_hostname}/health"
            # Ensure this runs only after the app service is potentially available
            depends_on = [azurerm_linux_web_app.example]
          }

          assert {
            condition     = data.http.app_service_probe.status_code == 200
            error_message = "App Service ${data.http.app_service_probe.url} health check failed, received status ${data.http.app_service_probe.status_code}."
          }
          assert {
            condition     = contains(data.http.app_service_probe.response_body, "Healthy")
            error_message = "App Service ${data.http.app_service_probe.url} health check response did not contain 'Healthy'."
          }
        }
        ```

4.  **External Test Frameworks:**
    *   Use tools like Terratest or kitchen-terraform for functional testing (e.g., deploying examples and verifying outputs) within a CI/CD pipeline.

A comprehensive testing strategy should combine these approaches: `variable` validation blocks for most input checks, `lifecycle.precondition` for resource state checks, `check` blocks for post-deployment assertions, and functional/integration testing with external tools.

### 6.3 Considerations for Module Testing (`terraform test`)

While the AI's primary role is to generate the core module configuration files (`.tf`), a complete and robust module should also include tests using the native `terraform test` command. These tests are crucial for verifying the module's behavior across different scenarios and ensuring its long-term maintainability.

**Key Points:**

*   **Purpose**: `terraform test` allows for writing structured unit and integration tests for your Terraform modules.
*   **Execution**: These tests are executed explicitly by running the `terraform test` command and are not part of the regular `terraform plan` or `terraform apply` lifecycle, unless those operations trigger validations that are also checked by `terraform test`.
*   **Test Files**: Tests are defined in `*.tftest.hcl` files. It is a common practice to place these files in a `tests/` subdirectory within the module.
*   **Functionality**: Test files allow you to:
    *   Define `run` blocks for different test scenarios.
    *   Override input variables to test various configurations.
    *   Write `assert` conditions to check expected outcomes, such as specific resource attributes, output values, or the successful evaluation of `check` blocks defined in the module.
*   **Workflow**: Typically, `terraform test` will provision the necessary infrastructure for the test, run assertions, and then automatically destroy the provisioned infrastructure.
*   **Guideline for AI**: For AI-driven module generation, the initial focus is on the core `.tf` files. The creation of comprehensive `*.tftest.hcl` files is often a subsequent step, potentially human-driven or a separate AI-assisted task, to ensure module quality. The guidelines for writing these `.tf` files should, however, result in a module that is inherently testable.

## License

This document is licensed under the MIT License.
