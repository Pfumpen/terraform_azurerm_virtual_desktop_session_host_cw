## Sub-Prompt Template: Generate `examples/basic/main.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_ALL_MODULE_TF_FILES_AND_README}}`

### 1. Objective

Generate the `main.tf` file for the "basic" example of the Azure module: `{{MODULE_NAME}}`.
This example should demonstrate the module's core functionality with the fewest required inputs, providing a minimal, runnable configuration. It should instantiate the main module.

### 2. Explicit Data for Generation (from MDD and analysis of module's `variables.tf`)

The "Prompt Engineering AI (Cline)" will populate this section.

**Module Information:**
*   `MODULE_SOURCE_PATH`: `"../../"` (Standard relative path to the root module from within `examples/basic/`)
*   `MODULE_NAME_IN_EXAMPLE`: `"basic_example_{{MODULE_NAME_SNAKE_CASE}}"` (A descriptive name for the module block in the example)

**Required Variables for Basic Example (Subset of module's variables):**
The "Prompt Engineering AI (Cline)" must identify the absolute minimum set of variables from the main module's `variables.tf` that need to be set for a basic, functional deployment. For other non-required variables with defaults, they should be omitted in this basic example to rely on those defaults.

```json
[
  {
    "variable_name": "{{REQUIRED_VAR_1_NAME}}", // e.g., resource_group_name
    "example_value_hcl": "{{EXAMPLE_HCL_VALUE_FOR_VAR_1}}" // e.g., "\"rg-basic-example\"", "azurerm_resource_group.example.name"
  },
  {
    "variable_name": "{{REQUIRED_VAR_2_NAME}}", // e.g., location
    "example_value_hcl": "{{EXAMPLE_HCL_VALUE_FOR_VAR_2}}" // e.g., "\"East US\""
  },
  {
    "variable_name": "{{REQUIRED_VAR_3_NAME_IF_COMPLEX_BUT_NEEDED}}", // e.g., a minimal but required object
    "example_value_hcl": "{{EXAMPLE_HCL_VALUE_FOR_COMPLEX_VAR_3}}" // e.g., "{ name = \"basic-item\" }"
  }
  // ... only the essential variables for a basic run ...
]
```
*(Note: The example values might be static strings, numbers, or references to other resources defined *within this example's `main.tf`* if necessary, like a resource group).*

**Supporting Resources for the Example (if any):**
Sometimes, even a basic example needs a resource group or a VNet. These should be defined *within this example's `main.tf`*.
```json
[
  {
    "resource_type": "azurerm_resource_group",
    "local_name": "example",
    "arguments": {
      "name": "\"rg-{{MODULE_NAME_SNAKE_CASE}}-basic-example\"",
      "location": "\"{{EXAMPLE_LOCATION_FOR_RG_OR_VAR_REF}}\"" // e.g., "East US" or a var defined in examples/basic/variables.tf
    }
  }
  // ... other supporting resources like VNet, Subnet if absolutely essential for basic functionality ...
]
```

**Provider Configuration for Example (if different from root, usually not):**
*   Typically, examples inherit provider configurations. If specific settings are needed for the example (e.g., a different `azurerm` provider block with specific features), list them here. Usually, this section will be empty, and the example will just have a `terraform { required_providers { ... } }` block matching the main module's `versions.tf` for `azurerm`.

**Instructions for Module-Generating AI:**
*   Generate a `terraform { required_providers { ... } }` block. This should typically mirror the provider requirements from the main module's `versions.tf` (especially for `azurerm`). The "Prompt Engineering AI (Cline)" should provide these details.
*   If `Supporting Resources for the Example` are provided, generate `resource` blocks for each.
*   Generate a `module "{{MODULE_NAME_IN_EXAMPLE}}" { ... }` block.
    *   Set `source = "{{MODULE_SOURCE_PATH}}"`.
    *   For each variable in `Required Variables for Basic Example`, add an argument to the module block: `{{variable_name}} = {{example_value_hcl}}`.
*   Optionally, define simple `output` blocks in this example `main.tf` if it helps demonstrate that the module call was successful (e.g., outputting an ID from the module).

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To:**
    *   Section 1.1: Required Files (structure of `examples/basic/`).
    *   Section 6.1: Example Configurations (purpose of `examples/basic/`).

### 4. Context from Previous (Validated) Micro-Tasks

*   **Main Module's `variables.tf`:** CRITICAL. The "Prompt Engineering AI (Cline)" must have analyzed this to determine which variables are truly required for a basic example and which can rely on defaults.
    *   `{{PATH_TO_MAIN_MODULE_VARIABLES_TF}}`
*   **Main Module's `versions.tf`:** To replicate provider requirements.
    *   `{{PATH_TO_MAIN_MODULE_VERSIONS_TF}}`
*   **Main Module's `README.md`:** For understanding the module's purpose and core functionality.
    *   `{{PATH_TO_MAIN_MODULE_README_MD}}`

### 5. Expected Output

*   A single file named `main.tf` within the `examples/basic/` directory.
*   This file should contain:
    *   A `terraform { required_providers { ... } }` block.
    *   Definitions for any essential supporting resources (like a resource group).
    *   A `module` block instantiating the main module with only the necessary input variables for a basic scenario.
    *   Optional: Basic outputs to verify deployment.
*   The file must be runnable (`terraform init && terraform apply` should work, assuming necessary Azure credentials and any variables defined in `examples/basic/variables.tf` are configured).

### 6. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" should verify that this example is minimal, functional, and correctly instantiates the module.
*   This example serves as a primary test case for the module's core functionality.

---
