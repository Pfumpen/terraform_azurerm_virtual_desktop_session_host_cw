## Sub-Prompt Template: Generate `examples/complete/main.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_ALL_MODULE_TF_FILES_AND_README}}`

### 1. Objective

Generate the `main.tf` file for the "complete" example of the Azure module: `{{MODULE_NAME}}`.
This example should instantiate the main module and demonstrate the usage of **all or most** of its input variables, providing a comprehensive configuration. Placeholder values should be used for sensitive or user-specific data.

### 2. Explicit Data for Generation (from MDD and analysis of module's `variables.tf`)

The "Prompt Engineering AI (Cline)" will populate this section.

**Module Information:**
*   `MODULE_SOURCE_PATH`: `"../../"`
*   `MODULE_NAME_IN_EXAMPLE`: `"complete_example_{{MODULE_NAME_SNAKE_CASE}}"`

**All Module Variables with Example/Placeholder Values (from main module's `variables.tf`):**
The "Prompt Engineering AI (Cline)" must list every variable from the main module's `variables.tf` and provide a suitable example or placeholder value for each.
```json
[
  {
    "variable_name": "{{MODULE_VAR_1_NAME}}", // e.g., resource_group_name
    "example_value_hcl": "{{EXAMPLE_HCL_PLACEHOLDER_FOR_VAR_1}}" // e.g., "azurerm_resource_group.example.name", "\"REPLACE_WITH_YOUR_RG_NAME\""
  },
  {
    "variable_name": "{{MODULE_VAR_2_NAME}}", // e.g., location
    "example_value_hcl": "{{EXAMPLE_HCL_PLACEHOLDER_FOR_VAR_2}}" // e.g., "azurerm_resource_group.example.location", "\"East US\""
  },
  {
    "variable_name": "{{MODULE_VAR_3_NAME_COMPLEX}}", // e.g., blob_properties (an object)
    // For complex types, provide a full HCL structure with placeholders for nested values
    "example_value_hcl": "{ versioning_enabled = true, delete_retention_policy = { days = 7 }, change_feed_enabled = false }"
  },
  {
    "variable_name": "{{MODULE_VAR_4_NAME_MAP_OF_OBJECTS}}", // e.g., containers
    "example_value_hcl": <<EOT
{
  "docs" = {
    container_name = "documentstore-complete"
    access_type    = "blob"
    metadata       = {
      env = "production"
    }
  },
  "logs" = {
    container_name = "applogs-complete"
  }
}
EOT
  },
  {
    "variable_name": "{{MODULE_VAR_5_NAME_SENSITIVE}}", // e.g., admin_password
    "example_value_hcl": "\"REPLACE_WITH_SECURE_PASSWORD\"" // Clear placeholder for sensitive data
  }
  // ... ALL variables from the main module ...
]
```
*(Guidance: For variables with defaults in the main module, this complete example should still explicitly set them to demonstrate their usage, possibly with non-default values if it adds clarity. For sensitive data, use clear placeholders like "REPLACE_WITH_YOUR_...". For complex objects or maps, provide a representative structure.)*

**Supporting Resources for the Example (if any):**
Define any resources needed by this comprehensive example (e.g., resource group, VNet, Key Vault for CMK demo).
```json
[
  {
    "resource_type": "azurerm_resource_group",
    "local_name": "example",
    "arguments": {
      "name": "\"rg-{{MODULE_NAME_SNAKE_CASE}}-complete-example\"",
      "location": "\"{{EXAMPLE_LOCATION_FOR_RG_OR_VAR_REF}}\"" // e.g., "East US" or a var from examples/complete/variables.tf
    }
  }
  // ... other supporting resources ...
]
```

**Instructions for Module-Generating AI:**
*   Generate a `terraform { required_providers { ... } }` block, mirroring the main module's `versions.tf`.
*   If `Supporting Resources for the Example` are provided, generate `resource` blocks for each.
*   Generate a `module "{{MODULE_NAME_IN_EXAMPLE}}" { ... }` block.
    *   Set `source = "{{MODULE_SOURCE_PATH}}"`.
    *   For **every** variable listed in `All Module Variables with Example/Placeholder Values`, add an argument to the module block: `{{variable_name}} = {{example_value_hcl}}`.
*   Define `output` blocks in this example `main.tf` for all outputs exposed by the main module. This helps verify that all outputs are working and demonstrates how to consume them. The value for each example output should be `module.{{MODULE_NAME_IN_EXAMPLE}}.{{OUTPUT_NAME_FROM_MODULE}}`.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To:**
    *   Section 1.1: Required Files (structure of `examples/complete/`).
    *   Section 6.1: Example Configurations (purpose of `examples/complete/` - showcase all variables).

### 4. Context from Previous (Validated) Micro-Tasks

*   **Main Module's `variables.tf`:** CRITICAL. All variables from this file must be represented in the example.
    *   `{{PATH_TO_MAIN_MODULE_VARIABLES_TF}}`
*   **Main Module's `outputs.tf`:** CRITICAL. All outputs from this file should be re-exported by the example.
    *   `{{PATH_TO_MAIN_MODULE_OUTPUTS_TF}}`
*   **Main Module's `versions.tf`:** To replicate provider requirements.
    *   `{{PATH_TO_MAIN_MODULE_VERSIONS_TF}}`
*   **Main Module's `README.md`:** For understanding variable purposes and overall module functionality.
    *   `{{PATH_TO_MAIN_MODULE_README_MD}}`

### 5. Expected Output

*   A single file named `main.tf` within the `examples/complete/` directory.
*   This file should contain:
    *   A `terraform { required_providers { ... } }` block.
    *   Definitions for any necessary supporting resources.
    *   A `module` block instantiating the main module, explicitly setting arguments for all (or most) of the main module's input variables using illustrative or placeholder values.
    *   `output` blocks that re-export all outputs from the main module.
*   The primary purpose is to serve as a comprehensive template for users. It might not be directly runnable without replacing placeholders, but it should be syntactically correct.

### 6. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" should verify that this example is comprehensive, correctly instantiates the module with all its variables, and re-exports all outputs.
*   This example serves as a detailed usage guide.

---
