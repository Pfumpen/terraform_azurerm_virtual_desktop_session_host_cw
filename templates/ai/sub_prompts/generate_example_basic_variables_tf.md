## Sub-Prompt Template: Generate `examples/basic/variables.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_BASIC_EXAMPLE_MAIN_TF}}`

### 1. Objective

Generate the `variables.tf` file for the "basic" example of the Azure module: `{{MODULE_NAME}}`, located in `examples/basic/variables.tf`.
This file should define any input variables that the `examples/basic/main.tf` itself requires. Often, for a basic example, this might be minimal (e.g., for a resource group name prefix or location if not hardcoded) or even empty if all values in `examples/basic/main.tf` are hardcoded or intended to be supplied via a `terraform.tfvars` file by the user.

### 2. Explicit Data for Generation (from MDD for the example)

The "Prompt Engineering AI (Cline)" will populate this section if the basic example's design requires its own variables.

**Example-Specific Variables (JSON Array, if any):**
```json
[
  {
    "name": "{{EXAMPLE_VAR_1_NAME}}", // e.g., "resource_group_name_prefix"
    "type_signature": "{{EXAMPLE_VAR_1_TYPE_SIGNATURE}}", // e.g., "string"
    "description": "{{EXAMPLE_VAR_1_DESCRIPTION}}",
    "default_value_hcl": "{{EXAMPLE_VAR_1_DEFAULT_HCL_OR_NULL}}", // e.g., "\"my-module-basic\""
    "nullable": {{true_OR_false_1}}, // boolean: true or false
    "sensitive": {{true_OR_false_1}}, // boolean: true or false
    "validation_rules": [ // Optional validation for example-specific vars
      {
        "condition_hcl": "{{EXAMPLE_VALIDATION_CONDITION_HCL_1A}}",
        "error_message": "{{EXAMPLE_VALIDATION_ERROR_MESSAGE_1A}}"
      }
    ]
  }
  // ... more example-specific variable objects if needed ...
]
```
*(Guidance: Only include variables here if the `examples/basic/main.tf` references them with `var.{{EXAMPLE_VAR_NAME}}`. If `examples/basic/main.tf` hardcodes all its necessary values or uses values directly from supporting resources it creates, then this `variables.tf` might be empty or not needed. The primary purpose of the example is to show how to call the main module.)*

**Instructions for Module-Generating AI:**
*   If `Example-Specific Variables` are provided and the array is not empty:
    *   For each variable object in the JSON array, generate a complete `variable` block in HCL within `examples/basic/variables.tf`.
    *   Follow the same generation logic for `type`, `description`, `default`, `nullable`, `sensitive`, and `validation` as in the main module's `variables.tf` template.
*   If no example-specific variables are defined (i.e., the JSON array is empty or not provided), generate an empty `variables.tf` file or a file with a comment indicating no example-specific variables are defined. Example comment:
    ```hcl
    # No specific variables are defined for this basic example.
    # Values are hardcoded in examples/basic/main.tf or intended to be supplied
    # via a terraform.tfvars file if this example were to be customized.
    # This example primarily demonstrates the minimal call to the root module.
    ```

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (if generating variables):**
    *   Section 2.1: Variable Definitions
    *   Section 2.3: Variable Validation

### 4. Context from Previous (Validated) Micro-Tasks

*   **`examples/basic/main.tf`:** CRITICAL. The content of this file determines if any `var.` references exist that would necessitate definitions in `examples/basic/variables.tf`.
    *   `{{PATH_TO_GENERATED_EXAMPLES_BASIC_MAIN_TF}}`
*   **Main Module's `variables.tf`:** For context, but this file defines variables for the *example itself*, not for the main module.
    *   `{{PATH_TO_MAIN_MODULE_VARIABLES_TF}}`

### 5. Expected Output

*   A single file named `variables.tf` within the `examples/basic/` directory.
*   This file will contain HCL `variable` blocks if the `examples/basic/main.tf` requires them. Otherwise, it may be empty or contain an explanatory comment.

### 6. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" should verify that any `var.` references in `examples/basic/main.tf` have corresponding definitions in this file, or that it's appropriately empty/commented.
*   This completes the `examples/basic` structure.

---
