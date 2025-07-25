# Azure Terraform Module Code Guidelines (AI-Optimized)

**Purpose of this Document:** These guidelines are specifically structured to assist an AI in generating high-quality, consistent, and maintainable Azure Terraform modules. Adherence to these guidelines is critical. Pay close attention to directives, examples, and structural requirements.

## 1. Module Structure

### 1.1 Required Files

Every module **MUST** contain these core files:

```
module/
├── main.tf           # Primary resource configurations OR coordinator for locals/module calls
├── variables.tf      # Input variable definitions (can be split, see 1.2)
├── outputs.tf        # Output definitions
├── versions.tf       # Provider and Terraform version constraints
├── README.md         # Comprehensive module documentation (see Section 4.2)
└── examples/         # Working examples
    ├── basic/        # A minimal, runnable example
    │   ├── main.tf
    │   └── variables.tf
    ├── complete/     # A comprehensive example showcasing all variables
    │   ├── main.tf
    │   └── variables.tf
    └── (optional) advanced/ # For more complex, specific scenarios
```

### 1.2 Resource-Oriented File Separation (for complex modules)

For modules managing multiple distinct Azure resource types, **YOU MUST** split configurations into resource-oriented files. This improves clarity and maintainability.

*   **Primary File (`main.tf`):**
    *   **Pattern 1 (Main Resource):** Contains the primary/core resource (e.g., `azurerm_storage_account`).
    *   **Pattern 2 (Coordinator):** Contains only `locals` blocks and calls to other local sub-modules if the module is a composition.
*   **Auxiliary Files:** Named after the resource type they manage (e.g., `containers.tf`, `network_rules.tf`, `private_endpoints.tf`).
*   **Variable Files:**
    *   `variables.tf`: For common variables.
    *   Resource-specific variables can be in files like `variables.containers.tf` if it improves organization.

**Example:**
```hcl
# main.tf (Primary resource: azurerm_sql_server)
resource "azurerm_sql_server" "main" { /* ... */ }

# databases.tf (Related resource: azurerm_sql_database)
resource "azurerm_sql_database" "db" {
  server_name = azurerm_sql_server.main.name
  /* ... */
}
```
**AI Rationale:** This separation helps you focus on one resource type at a time, reducing errors and improving dependency tracking.

### 1.3 Telemetry and Monitoring (Diagnostic Settings)

Modules **SHOULD** provide capabilities to configure diagnostic settings for the resources they create.

*   **Input Variables:**
    *   `enable_telemetry` (bool, default `true`): To toggle diagnostic settings.
    *   `log_analytics_workspace_id` (string, default `null`): ID of an *existing* Log Analytics Workspace.
    *   `event_hub_authorization_rule_id` (string, default `null`): ID of an *existing* Event Hub Authorization Rule.
    *   `storage_account_id` (string, default `null`): ID of an *existing* Storage Account for diagnostics.
*   **Resource:** `azurerm_monitor_diagnostic_setting`.
*   **Crucial Constraint:** The module **MUST NOT** create these diagnostic target resources (Log Analytics, Event Hub, Storage Account). It only configures the created primary resource to send diagnostics to them.

```hcl
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = "Controls whether telemetry (diagnostic settings) for the primary resource is enabled."
}
variable "log_analytics_workspace_id" {
  type        = string
  default     = null
  description = "Resource ID of the Log Analytics Workspace to send diagnostics to. Required if enable_telemetry is true."
}
// ... other diagnostic target ID variables ...

resource "azurerm_monitor_diagnostic_setting" "primary_resource_diagnostics" {
  count = var.enable_telemetry && var.log_analytics_workspace_id != null ? 1 : 0
  
  name                       = "diag-${var.name}" // Ensure 'var.name' or a similar unique identifier is available
  target_resource_id         = /* ID of the primary resource created by the module */
  log_analytics_workspace_id = var.log_analytics_workspace_id

  // Configure desired log categories and metrics
  enabled_log { category = "AuditLogs" } // Example
  metric { category = "AllMetrics" }    // Example
}
```

## 2. Variable Management

### 2.1 Variable Definitions

*   **Clarity:** All variables **MUST** have a `description` and a `type`.
*   **Defaults:** Provide `default` values for optional variables.
*   **Reserved Names:** **DO NOT** use reserved meta-argument names: `source`, `version`, `providers`, `count`, `for_each`, `lifecycle`, `depends_on`, `locals`.

```hcl
variable "resource_group_name" {
  description = "The name of the Azure Resource Group where resources will be deployed."
  type        = string
  nullable    = false // Explicitly non-nullable if required
}

variable "tags" {
  description = "A map of tags to assign to the created resources."
  type        = map(string)
  default     = {}
}
```

### 2.2 Complex Variable Types (Objects and Maps)

*   **Use `object({ ... })`** for structured configuration blocks.
*   **Use `optional(type, default_value)`** for optional attributes within objects.
*   **Use `map(object({ ... }))`** for collections of similar structured items (e.g., multiple network rules, multiple containers).

```hcl
variable "blob_properties" {
  description = "Configuration for blob service properties."
  type = object({
    change_feed_enabled           = optional(bool)
    versioning_enabled            = optional(bool, true) // Default true if not specified
    delete_retention_policy = optional(object({
      days = optional(number, 7) // Nested optional with default
    }), { days = 7 }) // Default for the entire object
    // ... other properties
  })
  default = null // The entire blob_properties block is optional
}

variable "containers" {
  description = "A map of storage containers to create. Key is a logical name, value is container config."
  type = map(object({
    name          = string // Name of the container itself
    public_access = optional(string, "None") // e.g., "None", "Blob", "Container"
    metadata      = optional(map(string))
    // ... other container-specific settings
  }))
  default = {}
}
```

### 2.3 Variable Validation

Implement robust validation for all input variables using `validation` blocks. This is critical for user experience and preventing errors.

*   **Specificity:** Each `validation` block should test a single, clear condition.
*   **Error Messages:** `error_message` **MUST** be clear, concise, and actionable.
*   **Common Validations:**
    *   Allowed values: `contains(["value1", "value2"], var.my_var)`
    *   Numeric ranges: `var.number >= 1 && var.number <= 100`
    *   String patterns (length, characters): `can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))`
    *   Resource-specific Azure naming rules.
*   **Complex Types (Maps/Objects):** **YOU MUST split validations.** Instead of one large `validation` block with `alltrue([...])` for a map/object, create multiple smaller `validation` blocks. Each smaller block should validate one aspect across all elements or one specific attribute, providing a targeted error message.

**Example: Splitting Validation for a Map**
```hcl
variable "network_rules" {
  type = map(object({
    name        = string
    priority    = number
    source_cidr = string
  }))
  default = {}

  // GOOD: Specific validation for priority range
  validation {
    condition = alltrue([
      for rule in var.network_rules : rule.priority >= 100 && rule.priority <= 4096
    ])
    error_message = "All network rule priorities must be between 100 and 4096."
  }

  // GOOD: Specific validation for CIDR format
  validation {
    condition = alltrue([
      for rule in var.network_rules : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$", rule.source_cidr))
    ])
    error_message = "All network rule source_cidr values must be valid CIDR blocks."
  }
}
```
**AI Rationale:** Splitting validations allows you to provide much more precise feedback if an input is incorrect, which is invaluable for users.

### 2.4 Nullable Variables

*   `nullable = false`: For variables that **MUST** be provided by the user (cannot be `null`).
*   `nullable = true` (often with `default = null`): For variables that are genuinely optional and can be omitted or explicitly set to `null`.

### 2.5 Ephemeral Variables (Terraform v1.10+)

*   Use `ephemeral = true` for input variables whose values are needed during runtime but **SHOULD NOT** be stored in the Terraform state or plan files (e.g., temporary API tokens, one-time passwords).
*   Often used with `sensitive = true`.

### 2.6 Sensitive Input Variables

*   Set `sensitive = true` for variables containing sensitive data (passwords, API keys). Terraform will redact these values from CLI output.
*   Note: Sensitive values are still stored in the state file unless also marked `ephemeral = true`.

## 3. Resource Organization

### 3.1 Resource Blocks

*   Organize resource blocks logically within their respective files (see 1.2).
*   Use consistent formatting.

### 3.2 Dynamic Blocks

Use `dynamic` blocks to construct repeated nested configuration blocks within a resource (e.g., `settings` blocks, `ip_rule` blocks).

*   **`for_each`:** Iterate over a collection (list or map).
*   **`content { ... }`:** Defines the structure of each generated block.
*   **`try(expression, fallback_value)`:** Use `try()` extensively within `content` to safely access attributes from `for_each` elements that might be optional, providing sensible defaults.
*   **`iterator` (Optional):** Renames the temporary variable for the current item (default is the `dynamic` block's label).
*   **Consideration:** While powerful, avoid overusing `dynamic` blocks if literal blocks are clearer. They cannot generate meta-argument blocks like `lifecycle` or `provisioner`.

```hcl
variable "ip_rules" {
  description = "A list of IP rule objects for a firewall."
  type = list(object({
    name    = string
    address = string
  }))
  default = []
}

resource "azurerm_firewall_network_rule_collection" "example" {
  // ... other arguments ...
  name     = "example-fw-rules"
  priority = 100
  action   = "Allow"

  dynamic "rule" {
    for_each = var.ip_rules
    iterator = ip_rule_item // Custom iterator name
    content {
      name                  = ip_rule_item.value.name
      source_addresses      = [ip_rule_item.value.address]
      destination_ports     = ["*"] // Example
      destination_addresses = ["*"] // Example
      protocols             = ["Any"] // Example
    }
  }
}
```

### 3.3 Resource Collections (Multiple Instances of a Resource)

Use `for_each` directly on a `resource` block to create multiple instances of that resource based on a map or a set of strings.

```hcl
variable "storage_containers_config" {
  description = "Map of storage containers to create. Key is logical name, value is config."
  type = map(object({
    # 'name' attribute for the actual container name is part of the object value
    container_name = string 
    access_type    = optional(string, "private") # "private", "blob", "container"
  }))
  default = {}
}

resource "azurerm_storage_container" "data_container" {
  for_each = var.storage_containers_config

  name                  = each.value.container_name # Use from map value
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = each.value.access_type
}
```

### 3.4 Availability Zone Management

When applicable (e.g., for VMs, AKS node pools, LBs), modules **SHOULD** correctly handle Azure Availability Zones.
*   Allow users to specify zones or let the module distribute across available zones in the region.
*   Use data sources like `data "azurerm_resource_skus"` (though be mindful of its performance for many queries) or rely on provider capabilities to determine zone availability if possible.
*   Often involves `locals` to process and assign zones.

## 4. Documentation Standards

High-quality documentation is paramount. The `README.md` is the primary interface for users.

### 4.1 Output Documentation (`outputs.tf`)

*   **Specificity:** **DO NOT** output entire resource objects (e.g., `value = azurerm_kubernetes_cluster.main`). Instead, output specific, useful attributes (e.g., `value = azurerm_kubernetes_cluster.main.id`, `value = azurerm_kubernetes_cluster.main.kube_config_raw`).
*   **Descriptions:** All outputs **MUST** have a clear `description`.
*   **Sensitive Outputs:** If an output value is sensitive (e.g., a password, a raw Kubernetes config), **YOU MUST** mark it with `sensitive = true`.
*   **Optional Outputs:** Use `try(expression, fallback_value)` if an output might not always be available (e.g., depends on a conditionally created resource). The `fallback_value` is often `null`.

```hcl
output "storage_account_id" {
  description = "The ID of the created Azure Storage Account."
  value       = azurerm_storage_account.main.id
}

output "primary_connection_string" {
  description = "The primary connection string for the storage account."
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "private_endpoint_fqdn" {
  description = "The FQDN of the private endpoint, if created."
  value       = try(azurerm_private_endpoint.main[0].fqdn, null) // Assumes PE is conditional
}
```

### 4.2 README.md Structure

The `README.md` **MUST** be comprehensive and follow this structure. **AI, you are responsible for generating this README content based on the module you create.**

1.  **Module Title and Concise Description:**
    *   Example: `# Terraform Azure Storage Account Module`
    *   Briefly state what the module provisions.
2.  **Version Information (Optional but Recommended):**
    *   A note about SemVer, especially if the module is pre-v1.0.0.
3.  **Features List:**
    *   Bullet points detailing the module's capabilities.
4.  **Limitations and Important Notes (If Any):**
    *   Known limitations, critical prerequisites not covered by inputs, or important operational considerations.
5.  **Requirements:**
    *   List required Terraform version and provider versions (extracted from `versions.tf`).
    ```markdown
    ## Requirements

    | Name      | Version       |
    | --------- | ------------- |
    | terraform | >= 1.11.4     |
    | azurerm   | >= 4.27.0     |
    | random    | ~> 3.5        | 
    ```
6.  **External Dependencies (If Any):**
    *   List Azure resources the module *depends on* but *does not create*, and which input variables supply them.
    *   Example: "Resource Group (provided via `var.resource_group_name`)", "VNet & Subnet (for Private Endpoint, via `var.subnet_id`)".
7.  **Resources Created:**
    *   List all `resource` types and their local names created by the module.
    ```markdown
    ## Resources

    | Type                                  | Name    |
    | ------------------------------------- | ------- |
    | `azurerm_storage_account`             | `main`  |
    | `azurerm_storage_container`           | `data_container` (for_each) |
    | `azurerm_monitor_diagnostic_setting`  | `primary_resource_diagnostics` |
    | `azurerm_role_assignment`             | `storage_roles` (for_each) |
    ```
8.  **Input Variables:**
    *   Document **ALL** input variables.
    *   For each variable: Description, Type, Default value (if any). Mark if Required.
    *   **For complex types (objects, maps of objects):**
        *   Clearly document the structure, including all attributes (and their types, optionality, defaults).
        *   Use Markdown code blocks for the `type` definition and an example `tfvars` or HCL block.
    ```markdown
    ## Inputs

    | Name                  | Description                                       | Type        | Default | Required |
    | --------------------- | ------------------------------------------------- | ----------- | ------- | -------- |
    | `name`                | Base name for the resources.                      | `string`    | n/a     | yes      |
    | `location`            | Azure region for deployment.                      | `string`    | n/a     | yes      |
    | `resource_group_name` | Name of the existing Resource Group.              | `string`    | n/a     | yes      |
    | `tags`                | Tags to apply to resources.                       | `map(string)`| `{}`    | no       |
    | `containers`          | Configuration for storage containers (see below). | `map(object)`| `{}`    | no       |

    ### `containers` variable structure:
    Map of objects, where each object has:
    - `container_name` (string, required): Actual name of the container.
    - `access_type` (string, optional): Access type ("private", "blob", "container"). Defaults to "private".
    - `metadata` (map(string), optional): Metadata for the container.

    Type: `map(object({ container_name = string, access_type = optional(string, "private"), metadata = optional(map(string)) }))`

    Example:
    ```hcl
    containers = {
      docs = { container_name = "documentstore", access_type = "blob" },
      logs = { container_name = "applicationlogs" }
    }
    ```
    ```
9.  **Outputs:**
    *   Document **ALL** outputs.
    *   For each output: Description, Type (implicitly string, bool, list, map, etc., or `sensitive = true`).
    ```markdown
    ## Outputs

    | Name                        | Description                                         | Sensitive |
    | --------------------------- | --------------------------------------------------- | --------- |
    | `storage_account_id`        | The ID of the created Azure Storage Account.        | false     |
    | `primary_connection_string` | The primary connection string for the storage account.| true      |
    | `container_ids`             | A map of created container IDs.                     | false     |
    ```
10. **Usage Examples:**
    *   Provide at least one basic, runnable example in the `examples/basic/` directory.
    *   Reference this example in the README.
    *   Include more examples for advanced features if applicable.

**AI Action:** When generating a module, you **MUST** populate the README.md according to this structure, deriving information from the variables, resources, and outputs you define.

## 5. Best Practices (Common Patterns)

Modules should implement these common Azure patterns where applicable, using standardized input variable structures.

### 5.1 Managed Identities

*   Variable: `managed_identity` (object)
    ```hcl
    variable "managed_identity" {
      description = "Configuration for Managed Identity. Set specific type to enable."
      type = object({
        system_assigned            = optional(bool, false) # Enable System Assigned
        user_assigned_resource_ids = optional(list(string), []) # List of UAMI IDs to assign
      })
      default = {} // By default, no identity is configured unless specified.
      # Add validation: e.g., cannot have both system_assigned=true and user_assigned_resource_ids populated.
    }
    ```
*   Resource: Use the `identity` block on the Azure resource.

### 5.2 Role-Based Access Control (RBAC)

*   Variable: `role_assignments` (map of objects)
    *   Key: Logical name for the role assignment (e.g., "storage_blob_data_contributor_on_sa").
    *   Value (object): `role_definition_id_or_name`, `principal_id`, `principal_type` (optional: User, Group, ServicePrincipal), `scope` (optional, defaults to current resource), `condition`, `condition_version`.
*   Resource: `azurerm_role_assignment`.
*   Scope: Typically, assignments are on the primary resource created by the module, or sub-resources.

```hcl
variable "role_assignments" {
  description = "A map of role assignments to create on the primary resource. Key is a descriptive name for the assignment."
  type = map(object({
    role_definition_id_or_name = string # Built-in role name (e.g., "Reader") or full Role Definition ID
    principal_id               = string # Object ID of the principal
    principal_type             = optional(string) # User, Group, ServicePrincipal, ForeignGroup, Device
    description                = optional(string)
    condition                  = optional(string)
    condition_version          = optional(string)
    # scope is implicitly the main resource, or can be specified if assigning on sub-resources or different scopes
  }))
  default = {}
}

resource "azurerm_role_assignment" "main_resource_roles" {
  for_each = var.role_assignments

  scope                = /* ID of the primary resource created by the module */
  role_definition_name = try(each.value.role_definition_id_or_name, null) # Or use role_definition_id if full ID is provided
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
  description          = each.value.description
  condition            = each.value.condition
  condition_version    = each.value.condition_version
}
```

### 5.3 Private Endpoint Implementation

*   Variable: `private_endpoints` (map of objects)
    *   Key: Logical name for the private endpoint (e.g., "blob_endpoint").
    *   Value (object): `subnet_id` (required), `subresource_names` (list, e.g., `["blob"]`), `private_dns_zone_group_name` (optional), `private_dns_zone_ids` (list, optional), `ip_configurations` (optional).
*   Resource: `azurerm_private_endpoint`.

### 5.4 Customer-Managed Keys (CMK)

*   Variable: `customer_managed_key` (object)
    *   Attributes: `key_vault_resource_id`, `key_name`, `key_version` (optional), `user_assigned_identity_id` (optional, for UAMI access to Key Vault).
*   Resource: e.g., `azurerm_storage_account_customer_managed_key` or relevant CMK block within the main resource.

### 5.5 Version Constraints (`versions.tf`)

**MUST** define `required_providers` with appropriate version constraints (e.g., `~>` for patch, `>=` for minimum) and `required_version` for Terraform itself.

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.27.0" 
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5" # Keep random provider flexible unless specific needs arise
    }
  }
  required_version = ">= 1.11.4"
}
```

### 5.6 Resource Protection and Lifecycle Management (`lifecycle` block)

Use `lifecycle` meta-argument judiciously:
*   `create_before_destroy = true`: For minimizing downtime on updates that require replacement (ensure resource naming allows this).
*   `prevent_destroy = true`: As a safety net for critical resources. **Use sparingly.**
*   `ignore_changes = [...]`: To tell Terraform to ignore changes to specific attributes (e.g., if managed externally or by autoscaling).
*   `replace_triggered_by = [...]` (Terraform v1.2+): Force replacement if specific other resources/attributes change.
*   `precondition { ... }`: Validate assumptions *before* resource operations. **For input validation, prefer `variable validation` blocks.** Use `lifecycle.precondition` for checks on `self.*` or other managed resources.
*   `postcondition { ... }`: Validate guarantees *after* resource operations.

### 5.7 Tag Management

*   Provide a `var.tags` (map(string)) input.
*   Merge `var.tags` with any module-defined default/common tags using a `locals` block. Apply these merged tags to all taggable resources.

```hcl
locals {
  merged_tags = merge(
    var.tags,
    {
      "module_source" = "your_module_repo/module_name" // Example default tag
      "provisioner"   = "Terraform"
    }
  )
}

resource "azurerm_storage_account" "main" {
  // ... other config ...
  tags = local.merged_tags
}
```

### 5.8 Error Handling with `try()`

Use `try(expression, fallback_value)` for safely accessing potentially non-existent attributes in complex data structures (locals, variable values) or optional resource attributes. This prevents errors if an optional part of a structure is not defined.

## 6. Testing and Validation

### 6.1 Example Configurations

*   **`examples/basic/`**: **MUST** provide a minimal, working example that demonstrates the module's core functionality with the fewest required inputs.
*   **`examples/complete/`**: **MUST** provide a comprehensive example that includes all available input variables.
    *   This example serves as a template for users, showing all possible configurations.
    *   Values for variables in this example should be placeholders (e.g., `"REPLACE_WITH_YOUR_VALUE"`, `null` for optional complex objects if not demonstrating a specific feature, or sensible defaults that illustrate usage).
    *   The primary purpose is to give users a clear overview of everything they *can* configure.
*   **`examples/advanced/` (Optional):** Can be used to demonstrate specific complex use cases or integrations.

### 6.2 Validation Mechanisms (Recap for AI)

1.  **`variable validation` blocks (Primary for Inputs):**
    *   **AI Action:** Implement these for all relevant inputs. Focus on clear error messages. Split for complex types.
    *   Supports cross-variable validation (Terraform v1.9.0+).
2.  **`lifecycle.precondition` (Resource State/Dependencies):**
    *   **AI Action:** Use for checks involving `self.*` or other resources during plan/apply.
3.  **`check` Blocks (Post-Deployment Assertions - Terraform v1.5.0+):**
    *   **AI Action:** Consider adding `check` blocks for verifying conditions *after* apply (e.g., health checks). These generate warnings, not errors.
    *   Can use scoped data sources (e.g., `data "http"` to check an endpoint).
4.  **External Test Frameworks (Terratest, etc.):**
    *   Beyond AI's initial generation scope but good to be aware of for module maturity.
5.  **`terraform test` (`*.tftest.hcl` files):**
    *   **AI Action:** While you might not generate `*.tftest.hcl` files initially, the module you create **MUST** be testable. This means clear inputs, outputs, and predictable behavior.

## License

This document is licensed under the MIT License. (Or specify as appropriate)
