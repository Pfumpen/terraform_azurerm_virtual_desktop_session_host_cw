# Azure Terraform Module AI Prompt Template

You are an expert in Azure Terraform Modules. Your task is to generate a complete Azure Terraform module *strictly* according to the specifications and guidelines below. Deviations are only allowed if explicitly stated.

This template serves as the basis for creating AI prompts for generating Azure Terraform modules according to the Azure Terraform Module Guidelines.

## Prompt Template

```
Create an Azure Terraform module for [RESOURCE TYPE] according to the Azure Terraform Module Guidelines with the following specifications:

## RESOURCE TYPE
[Exact designation of the Azure resource type, e.g., "Azure SQL Server", "Azure Kubernetes Service", "Azure Virtual Network"]

## FUNCTIONS
- [Function 1, e.g., "SQL Server with configurable settings"]
- [Function 2, e.g., "Firewall rules"]
- [Function 3, e.g., "Azure AD integration"]
- [Function 4, e.g., "Support for Availability Zones (if relevant)"]
...

## DEPENDENCIES
- [Dependency 1, e.g., "Key Vault module (optional for encryption)"]
- [Dependency 2, e.g., "Virtual Network module (optional for Private Endpoints)"]
...

## SPECIAL REQUIREMENTS
- [Requirement 1, e.g., "Support for private endpoints"]
- [Requirement 2, e.g., "High availability configuration"]
...

## VARIABLES
- [Variable 1 with type and description, e.g., "server_name (string): Name of the SQL server. Ensure correct `nullable` (Guideline 2.5) and `sensitive` (Guideline 2.7) settings. Consider if `ephemeral` (Guideline 2.6) is applicable for any temporary/non-state data."]
- [Variable 2 with type and description, e.g., "sku (string): SKU for the SQL server (Basic, Standard, Premium). Ensure correct `nullable` setting."]
...

## OUTPUTS
- [Output 1 with description, e.g., "server_id: The ID of the created SQL server"]
- [Output 2 with description, e.g., "connection_string: The connection string for the SQL server"]
...

## EXAMPLES
- [Example 1, e.g., "Basic example with minimal configuration"]
- [Example 2, e.g., "Complete example with all options"]
- [Example 3, e.g., "Example with private endpoints"]
...

## FILES
Please create the following files, organized by resource type (not by functionality):
1. main.tf - Main resource (e.g., Azure SQL Server)
2. [resourcetype1].tf - Dependent resources of type 1 (e.g., databases.tf for SQL Databases)
3. [resourcetype2].tf - Dependent resources of type 2 (e.g., firewall.tf for Firewall Rules)
4. variables.tf - General variable definitions
5. variables.[resourcetype1].tf - Resource-specific variables for type 1
6. variables.[resourcetype2].tf - Resource-specific variables for type 2
7. outputs.tf - Output definitions
8. versions.tf - Version constraints
9. README.md - Module documentation
10. Examples in examples/basic/ and examples/complete/

IMPORTANT: Ensure that the generated file structure *strictly* follows the resource-oriented organization specified above (files named after resource types like 'sql_server.tf', 'databases.tf'). Choose the appropriate pattern (Main Resource vs. Coordinator) based on the module's complexity (Guideline 1.2). Do *not* organize files by functionality (e.g., 'security.tf', 'networking.tf').

## TERRAFORM REGISTRY DOCUMENTATION
I have copied the documentation from the Terraform Registry for the following resources:
- [List of resources, e.g., "azurerm_data_protection_backup_vault"]
- [List of further resources, e.g., "azurerm_data_protection_backup_policy_postgresql"]
...

You must use the documentation texts provided below from the Terraform Registry as the primary source for resource arguments, attribute names, types, and validation logic. Do not invent arguments or guess types. Implement variables and resources exactly as described in the documentation.

## VARIABLE VALIDATIONS
IMPORTANT: Implement robust validation rules (validation { ... }) for every single input variable according to the Azure Terraform Module Guidelines.
The validations must be as specific as possible and closely adhere to the allowed values and formats from the Azure documentation and the Terraform Registry.
Ensure that:

1. All string variables with limited values have a contains() validation
2. All numeric variables have range validations
3. All names and identifiers have regex validations for Azure naming conventions
4. All complex objects have nested validations for their fields. **Split large validation checks for complex types (maps/objects) into multiple, smaller `validation` blocks, each with a specific error message, to improve debuggability (Guideline 2.4.1).**
5. All IP addresses, CIDR blocks, versions, and other formatted strings have corresponding regex validations

**Validation Strategy (Guideline 6.2):**
- Use `variable validation` blocks for:
    - Checks involving a **single variable** (e.g., format, length, allowed values).
    - **Cross-variable validation** (checks depending on multiple input variables, especially with Terraform v1.9.0+).
- Use `lifecycle.precondition` primarily for validating conditions related to:
    - The **state or attributes of a resource itself (`self.*`)**.
    - Its dependencies on other resources/data sources.
    - Complex input variable relationships if not using `variable validation` for cross-variable checks (e.g., pre-TF v1.9.0 or for very complex logic better expressed near the resource).
- Consider `check` blocks for **post-deployment assertions** (warnings, not errors) for ongoing health checks or compliance validation (Guideline 6.2). While the primary task is `.tf` file generation, the module should be designed to support such checks.
- Avoid redundancy between these validation mechanisms.

Use the examples from the Azure Terraform Module Guidelines as a reference for implementing the validations.

## GUIDELINES
Follow these guidelines:
- Use dynamic blocks for repeated configurations (consider `iterator` and `labels` if needed for clarity or complex scenarios - Guideline 3.2).
- Implement error handling with try() (Guideline 5.10) and robust validations for ALL variables (Guideline 2.3, 2.4.1, 6.2).
- Define complex variable types with object() and optional() (Guideline 2.2). Set `nullable` (Guideline 2.5), `sensitive` (Guideline 2.7), and consider `ephemeral` (Guideline 2.6) correctly.
- Ensure all outputs are secure (specific attributes, `sensitive = true` for sensitive data) and defined with clear descriptions (Guideline 4.1).
- Implement comprehensive `lifecycle` management for resources: `create_before_destroy`, `prevent_destroy`, `ignore_changes`, `replace_triggered_by`, `precondition`, and `postcondition` as appropriate (Guideline 5.7).
- Implement standardized tagging with `local.common_tags = merge(var.tags, {...})` (Guideline 5.9).
- Create a comprehensive README.md with all required sections (Guideline 4.2).
- Consider the Terraform Registry documentation for the correct implementation of variables and validation rules.

## DOCUMENTATION GUIDELINES
When generating the README.md, pay meticulous attention to the following additional guidelines for documenting variables, especially for complex types (map/object):

- Clearly divide variables into "Required Inputs" and "Optional Inputs" sections
- For each complex variable (map or object), ensure the documentation *exactly* follows Guideline 4.2 and the example in Guideline 5.3 ("Variable Documentation for Complex Types"):
  - Document the complete structure with all nested fields.
  - **Explicitly mark each field within the complex variable's description (e.g., in the hierarchical list) as "(Required)" or "(Optional)"**.
  - Specify the exact type of each field (string, number, bool, etc.).
  - Use indentation (e.g., markdown lists with hyphens) to clearly represent the hierarchy of fields.
  - Provide practical examples for using complex variables.
  - Show the complete Terraform `type` definition of the variable (with all nested types).
  - The documentation must contain the exact structure, types, (Required)/(Optional) status of all nested fields, and examples according to the provided format (Guideline 4.2 / 5.3).

Example for documenting a complex variable:

```markdown
### <a name="input_network_interfaces"></a> [network_interfaces](#input_network_interfaces)

Description: A map of objects representing the network interfaces of the virtual machine

- `<map key>` - Use a custom map key for each network interface
  - `name` = (Required) The name of the network interface. Changing this forces a new resource to be created.
  - `ip_configurations` - (Required) A map of objects defining the IP configurations of the interface
    - `<map key>` - Use a custom map key for each IP configuration
      - `name` = (Required) A name for this IP configuration.
      - `private_ip_address` = (Optional) The static IP address to use.
      - `private_ip_address_allocation` = (Optional) The allocation method for the private IP address. Possible values are Dynamic and Static.

Example Inputs:

```hcl
network_interfaces = {
  network_interface_1 = {
    name = "testnic1"
    ip_configurations = {
      ip_configuration_1 = {
        name                          = "testnic1-ipconfig1"
        private_ip_subnet_resource_id = azurerm_subnet.this_subnet_1.id
      }
    }
  }
}
```

Type:

```hcl
map(object({
    name = string
    ip_configurations = map(object({
      name = string
      private_ip_address = optional(string)
      private_ip_address_allocation = optional(string, "Dynamic")
    }))
}))
```
```

## ADVANCED GUIDELINES
- Implement comprehensive Diagnostic Settings for all resources with configurable log categories and destinations
- Add standardized Private Endpoint support with DNS zone groups
- Implement Role-Based Access Control (RBAC) for main and sub-resources
- Support Customer-Managed Keys for encryption where applicable
- Implement resource management policies for lifecycle management
- Use deeply nested object types with multiple optional fields for complex configurations
- Add support for Managed Identities (System- and User-Assigned)
- Implement standardized error handling for all resources
- Consider resource collections with for_each and dynamic blocks
```

## Example Prompt for an Azure SQL Server

```
Create an Azure Terraform module for Azure SQL Server according to the Azure Terraform Module Guidelines with the following specifications:

## RESOURCE TYPE
Azure SQL Server

## FUNCTIONS
- SQL Server with configurable settings (version, administrator, authentication)
- SQL databases with various service tiers and performance levels
- Firewall rules for network access
- Azure AD integration for authentication
- Auditing and advanced threat detection
- Transparent Data Encryption (TDE)
- Backup configuration with configurable retention periods
- Private Endpoint support for secure access

## DEPENDENCIES
- Key Vault module (optional for secure storage of credentials)
- Virtual Network module (optional for Private Endpoints)

## SPECIAL REQUIREMENTS
- Support for private endpoints
- High availability configuration with Failover Groups
- Geo-replication for disaster recovery
- Point-in-time recovery configuration
- Scalability through auto-scaling options
- Compliance settings for GDPR, HIPAA, etc.

## VARIABLES
- server_name (string): Name of the SQL server. Must be globally unique.
- server_version (string): Version of the SQL server (12.0 for SQL Server 2017, etc.)
- administrator_login (string): Administrator username for the SQL server
- administrator_login_password (string): Administrator password for the SQL server (sensitive, ephemeral if it's a one-time setup token)
- location (string): Azure region for the SQL server
- resource_group_name (string): Name of the resource group
- databases (map(object)): Map of databases to be created with configurations (ensure detailed validation per Guideline 2.4.1)
- firewall_rules (map(object)): Map of firewall rules for access (ensure detailed validation per Guideline 2.4.1)
- azure_ad_administrator (object): Configuration for Azure AD administrator
- auditing_settings (object): Configuration for Auditing
- threat_detection_settings (object): Configuration for advanced threat detection
- backup_settings (object): Configuration for backups
- private_endpoint (object): Configuration for Private Endpoint (follow Guideline 5.3 structure)
- tags (map(string)): Tags for the resources (validate max 50 tags per Guideline 2.3.2)
- enable_telemetry (bool): Controls telemetry (Guideline 1.3)
- log_analytics_workspace_id (string): Workspace ID for diagnostics (Guideline 1.3)

## OUTPUTS
- server_id: The ID of the created SQL server
- server_name: The name of the created SQL server
- server_fqdn: The fully qualified domain name of the SQL server
- database_ids: Map of database names to their IDs
- connection_strings: Map of database names to their connection strings (sensitive)
- private_endpoint_id: The ID of the created Private Endpoint (if configured)
- private_dns_zone_id: The ID of the created Private DNS Zone (if configured)

## EXAMPLES
- Basic example with one SQL server and one database
- Complete example with multiple databases, firewall rules, and Azure AD integration
- Example with Private Endpoint for secure access
- Example with high availability configuration and geo-replication
- Example with auditing and advanced threat detection

## FILES
Please create the following files, organized by resource type (not by functionality):
1. main.tf - Main resource (SQL Server)
2. databases.tf - SQL databases resources
3. firewall.tf - Firewall rules resources
4. private_endpoint.tf - Private Endpoint resources
5. auditing.tf - Auditing and threat detection resources
6. variables.tf - General variable definitions
7. variables.databases.tf - Variable definitions for databases
8. variables.firewall.tf - Variable definitions for firewall rules
9. variables.private_endpoint.tf - Variable definitions for Private Endpoints
10. variables.auditing.tf - Variable definitions for auditing and threat detection
11. outputs.tf - Output definitions
12. versions.tf - Version constraints
13. README.md - Module documentation
14. examples/basic/main.tf - Basic example
15. examples/complete/main.tf - Complete example
16. examples/private_endpoint/main.tf - Example with Private Endpoint
17. examples/high_availability/main.tf - Example with high availability configuration
18. examples/auditing/main.tf - Example with auditing and threat detection

## TERRAFORM REGISTRY DOCUMENTATION
I have copied the documentation from the Terraform Registry for the following resources:
- [List of resources, e.g., "azurerm_sql_server"]
- [List of further resources, e.g., "azurerm_sql_database"]
...

Please use this documentation as a reference for implementing the variables with correct validation rules and for configuring the resources.

## APPLICABLE GUIDELINES AND BEST PRACTICES
Follow these guidelines:
- Use dynamic blocks for repeated configurations like databases and firewall rules
- Implement error handling with try() (Guideline 5.10) and validations for all input parameters (following Guideline 2.3, 2.4.1, and the validation strategy in 6.2).
- Define complex variable types with object() and optional() for flexible configurations (Guideline 2.2). Ensure `nullable`, `sensitive`, and `ephemeral` are correctly applied (Guidelines 2.5, 2.6, 2.7).
- Ensure all outputs are secure and defined with clear descriptions (Guideline 4.1).
- Add comprehensive lifecycle management for critical resources (Guideline 5.7), including `precondition` and `postcondition` where appropriate.
- Create a comprehensive README.md with all required sections (Guideline 4.2), paying special attention to the detailed documentation format for complex variables (Guideline 4.2 / 5.3).
- Consider the Terraform Registry documentation for the correct implementation of variables and validation rules.
- Implement version constraints in `versions.tf` (Guideline 5.6).

# ADVANCED GUIDELINES
- Implement comprehensive Diagnostic Settings for all resources with configurable log categories and destinations
- Add standardized Private Endpoint support with DNS zone groups
- Implement Role-Based Access Control (RBAC) for main and sub-resources
- Support Customer-Managed Keys for encryption where applicable
- Implement resource management policies for lifecycle management
- Use deeply nested object types with multiple optional fields for complex configurations
- Add support for Managed Identities (System- and User-Assigned)
- Implement standardized error handling for all resources
- Consider resource collections with for_each and dynamic blocks
