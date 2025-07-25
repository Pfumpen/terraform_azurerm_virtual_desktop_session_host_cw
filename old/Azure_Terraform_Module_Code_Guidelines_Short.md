# Azure Terraform Module Code Guidelines (Shortened)

This document outlines key guidelines for creating Azure Terraform modules, focusing on conciseness for AI context windows.

## 1. Module Structure

### 1.1 Required Files

Essential files: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, and an `examples/` directory.

### 1.2 Resource-Oriented File Separation

Organize complex modules by resource type (e.g., `sql_server.tf`, `databases.tf`, `firewall_rules.tf`).
`main.tf` can either hold the primary resource or act as a coordinator for `locals` and module calls.

```hcl
# main.tf - Primary resource example
resource "azurerm_sql_server" "example" { /* ... */ }

# databases.tf - Related resource
resource "azurerm_sql_database" "example" { /* ... */ }
```

### 1.3 Telemetry and Monitoring

Include variables for enabling telemetry and specifying diagnostic targets (Log Analytics, Event Hub, Storage Account). Modules should configure sending diagnostics to *existing* targets, not create them.

```hcl
variable "enable_telemetry" { type = bool; default = true; }
variable "log_analytics_workspace_id" { type = string; default = null; }
// ... other diagnostic target IDs ...

resource "azurerm_monitor_diagnostic_setting" "example" {
  count = var.enable_telemetry && var.log_analytics_workspace_id != null ? 1 : 0
  // ... configuration ...
}
```

## 2. Variable Management

### 2.1 Variable Definitions

Define variables with clear types, descriptions, and defaults where appropriate. Avoid reserved names (`source`, `version`, etc.).

```hcl
variable "resource_group_name" { type = string; description = "The name of the resource group"; }
variable "tags" { type = map(string); default = {}; }
```

### 2.2 Complex Variable Types

Use `object` types for complex configurations, supporting nested structures and `optional()` fields. Use `map(object({}))` for collections.

```hcl
variable "blob_properties" {
  type = object({
    versioning_enabled = optional(bool, true)
    delete_retention_policy = optional(object({ days = optional(number, 7) }), { days = 7 })
    // ... other properties ...
  })
  default = null
}
```

### 2.3 Variable Validation

Implement validation rules using `validation` blocks for early error detection.
- Use `contains` for enumerations, range checks for numbers, `can(regex(...))` for formats.
- Provide resource-specific validations (e.g., storage account name, SQL server name).
- For complex types (maps/objects), **split validations into multiple, smaller `validation` blocks**, each with a specific error message for clarity.

```hcl
variable "service_tier" {
  type = string
  validation {
    condition     = contains(["Premium", "Standard"], var.service_tier)
    error_message = "Service tier must be Premium or Standard."
  }
}

variable "network_interfaces" {
  type = map(object({ name = string, ip_address = string }))
  validation { # Check 1: Name format
    condition = alltrue([for k, v in var.network_interfaces : can(regex("^[a-zA-Z0-9-]{1,80}$", v.name))])
    error_message = "Invalid network interface name."
  }
  validation { # Check 2: IP address format
    condition = alltrue([for k, v in var.network_interfaces : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", v.ip_address))])
    error_message = "Invalid IP address."
  }
}
```

### 2.4 Nullable Variables

Explicitly define `nullable = false` for required parameters and `nullable = true` (often with `default = null`) for optional ones.

### 2.5 Ephemeral Variables (Terraform v1.10+)

Use `ephemeral = true` for variables whose values should not be stored in state or plan files (e.g., temporary tokens). Often used with `sensitive = true`.

### 2.6 Sensitive Input Variables

Set `sensitive = true` to prevent display of variable values in `plan` or `apply` output.

## 3. Resource Organization

### 3.1 Resource Blocks

Organize resources logically with consistent formatting.

### 3.2 Dynamic Blocks

Use `dynamic` blocks for repeated nested configurations. Use `try()` for safe access to optional attributes.
- `iterator` argument can rename the loop variable.
- `labels` argument for blocks requiring labels (less common in Azure).
- Avoid overuse; literal blocks are often clearer. Cannot generate meta-argument blocks (`lifecycle`, `provisioner`).

```hcl
resource "azurerm_example" "example" {
  dynamic "backup_policy" {
    for_each = try(var.backup_policy[*], [])
    content {
      frequency = try(backup_policy.value.frequency, "Daily")
      // ...
    }
  }
}
```

### 3.3 Resource Collections

Use `for_each` for creating multiple instances of a resource based on a map or set.

```hcl
resource "azurerm_netapp_pool" "pool" {
  for_each = var.pools // var.pools is a map
  name     = each.value.name
  // ...
}
```

### 3.4 Availability Zone Management

Handle Azure Availability Zones by fetching available zones and distributing resources accordingly, often using `locals` to process zone information.

## 4. Documentation Standards

### 4.1 Output Documentation

- Output specific, meaningful attributes, not entire resource objects.
- Mark sensitive outputs with `sensitive = true`.
- Use `try()` for optional outputs that might not always be available.

```hcl
output "cluster_id" { value = azurerm_kubernetes_cluster.example.id; }
output "client_certificate" { value = azurerm_kubernetes_cluster.example.kube_config.0.client_certificate; sensitive = true; }
```

### 4.2 README Structure

A comprehensive `README.md` is essential. Key sections include:
1.  **Module Title and Description**: What the module does.
2.  **Version Information**: SemVer stability notes.
3.  **Features List**: Capabilities.
4.  **Limitations and Important Notes**: Caveats.
5.  **Requirements**: Terraform and provider versions.
6.  **External Dependencies**: Resources the module needs but doesn't create.
7.  **Resources**: List of resources created by the module.
8.  **Input Variables**: Document all inputs (required/optional, types, defaults, descriptions). For complex types, show structure, mark fields as (Required)/(Optional), provide examples, and show the full Terraform type.
9.  **Outputs**: Document all outputs.
10. **Usage Examples**: Basic and advanced scenarios.

**Best Practices for README:** Use good Markdown, keep it updated, be comprehensive yet concise, include visuals if helpful, and provide working examples.

### 4.3 Variable Documentation (in README)

For complex variables (maps/objects) in the README:
- Document the full structure with all fields.
- Mark each field as "(Required)" or "(Optional)".
- Use hierarchical formatting (indentation, lists).
- Provide clear usage examples.
- Show the complete Terraform `type` definition.

## 5. Best Practices

### 5.1 Error Handling and Telemetry

- **Telemetry**: Implement diagnostic settings as described in section 1.3.
- **Comprehensive Diagnostic Settings**: Allow flexible configuration of diagnostic settings via a map variable if multiple settings are needed.
- **Managed Identity**: Standardize managed identity configuration (system-assigned, user-assigned) via an object variable.

### 5.2 Role-Based Access Control (RBAC)

Provide a standardized way to define role assignments for the main resource and sub-resources using a map variable (e.g., `var.role_assignments`).

### 5.3 Private Endpoint Implementation

Offer a standardized pattern for creating private endpoints, typically via a map variable (`var.private_endpoints`), allowing configuration of subnet, subresource, DNS zones, etc.

### 5.4 Customer-Managed Keys (CMK)

Support CMK by accepting key vault and key details via an object variable (`var.customer_managed_key`).

### 5.5 Resource Management Policies

For resources like storage accounts, allow definition of management policies (e.g., lifecycle rules) through complex input variables.

### 5.6 Version Constraints

Define `required_providers` and `required_version` in `versions.tf`.

```hcl
terraform {
  required_providers { azurerm = { source = "hashicorp/azurerm"; version = ">= 3.0.0"; } }
  required_version = ">= 1.9.0";
}
```

### 5.7 Resource Protection and Lifecycle Management

Use `lifecycle` blocks:
- `create_before_destroy = true`: For zero-downtime updates (if resource supports it).
- `prevent_destroy = true`: For critical resources.
- `ignore_changes = [...]`: To prevent Terraform from managing certain attributes.
- `replace_triggered_by = [...]` (Terraform v1.2+): Force replacement based on other resource changes.
- `precondition { ... }`: Validate assumptions before resource operations. Prefer `variable validation` for input checks.
- `postcondition { ... }`: Validate guarantees after resource operations.

### 5.8 Error Handling (Input Validation)

Primarily use `variable validation` blocks (see 2.3).

### 5.9 Tag Management

Merge user-provided tags with common/default tags using `locals`.

```hcl
locals {
  common_tags = merge(var.tags, { Environment = var.env, ManagedBy = "Terraform" })
}
resource "azurerm_resource_group" "example" { tags = local.common_tags; /* ... */ }
```

### 5.10 Error Handling with try() Function

Use `try(expression, fallback_value)` for safe access to potentially null or non-existent attributes in complex objects or locals, providing default values.

## 6. Testing and Validation

### 6.1 Example Configurations

Provide diverse examples in the `examples/` directory (e.g., `basic/`, `complete/`).

### 6.2 Validation Testing Mechanisms

1.  **`variable` Validation Blocks**: Recommended for most input validations, including cross-variable checks (Terraform v1.9.0+).
2.  **`lifecycle.precondition`**: For resource state validation (using `self.*`) or dependencies.
3.  **`check` Blocks (Terraform v1.5.0+)**: For post-deployment assertions (results in warnings, not errors). Can use scoped data sources.
4.  **External Test Frameworks**: Terratest, kitchen-terraform for functional/integration testing.

### 6.3 Considerations for Module Testing (`terraform test`)

- Use `*.tftest.hcl` files (typically in `tests/`) for structured unit/integration tests.
- `terraform test` provisions, asserts, and destroys infrastructure.
- AI-generated modules should be testable; writing `*.tftest.hcl` files is often a subsequent step.

## License

This document is licensed under the MIT License.
