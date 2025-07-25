## Sub-Prompt Template: Generate `examples/complete/variables.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_COMPLETE_EXAMPLE_MAIN_TF}}`

### 1. Objective

Generate the `variables.tf` file for the "complete" example of the Azure module: `{{MODULE_NAME}}`, located in `examples/complete/variables.tf`.
This file should define any input variables that the `examples/complete/main.tf` itself requires (e.g., for a resource group name prefix, location, or other parameters that might be configurable for the example itself).

### 2. Explicit Data for Generation (from MDD for the example)

The "Prompt Engineering AI (Cline)" will populate this section if the complete example's design requires its own variables.

**Example-Specific Variables (JSON Array, if any):**
```json
[
  {
    "name": "{{EXAMPLE_VAR_1_NAME}}", // e.g., "example_resource_group_location"
    "type_signature": "{{EXAMPLE_VAR_1_TYPE_SIGNATURE}}", // e.g., "string"
    "description": "{{EXAMPLE_VAR_1_DESCRIPTION}}",
    "default_value_hcl": "{{EXAMPLE_VAR_1_DEFAULT_HCL_OR_NULL}}", // e.g., "\"East US\""
    "nullable": {{true_OR_false_1}},
    "sensitive": {{true_OR_false_1}},
    "validation_rules": [
      {
        "condition_hcl": "{{EXAMPLE_VALIDATION_CONDITION_HCL_1A}}",
        "error_message": "{{EXAMPLE_VALIDATION_ERROR_MESSAGE_1A}}"
      }
    ]
  },
  {
    "name": "{{EXAMPLE_VAR_2_NAME_FOR_PLACEHOLDER_REPLACEMENT}}", // e.g., "admin_username_for_example"
    "type_signature": "string",
    "description": "Username for administrative access in this example. Will be used to replace a placeholder in the module call.",
    "default_value_hcl": "\"exampleadmin\""
  }
  // ... more example-specific variable objects if needed ...
]
```
*(Guidance: Include variables here if `examples/complete/main.tf` references them with `var.{{EXAMPLE_VAR_NAME}}`. This might be for values that are good to make configurable at the example level, even if they are then passed into the module which uses placeholders. If `examples/complete/main.tf` hardcodes all its necessary values for supporting resources, this file might be empty or contain only a comment.)*

**Instructions for Module-Generating AI:**
*   If `Example-Specific Variables` are provided and the array is not empty:
    *   For each variable object in the JSON array, generate a complete `variable` block in HCL within `examples/complete/variables.tf`.
    *   Follow the same generation logic for `type`, `description`, `default`, `nullable`, `sensitive`, and `validation` as in the main module's `variables.tf` template.
*   If no example-specific variables are defined, generate an empty `variables.tf` file or a file with a comment. Example comment:
    ```hcl
    # No specific variables are defined for this complete example.
    # Values for supporting resources are hardcoded in examples/complete/main.tf.
    # The main module call in examples/complete/main.tf uses placeholders for
    # user-specific values, which should be replaced in a terraform.tfvars file
    # or by direct modification for actual deployment.
    ```

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (if generating variables):**
    *   Section 2.1: Variable Definitions
    *   Section 2.3: Variable Validation

### 4. Context from Previous (Validated) Micro-Tasks

*   **`examples/complete/main.tf`:** CRITICAL. The content of this file determines if any `var.` references exist that would necessitate definitions in `examples/complete/variables.tf`.
    *   `{{PATH_TO_GENERATED_EXAMPLES_COMPLETE_MAIN_TF}}`
*   **Main Module's `variables.tf`:** For context.
    *   `{{PATH_TO_MAIN_MODULE_VARIABLES_TF}}`

### 5. Expected Output

*   A single file named `variables.tf` within the `examples/complete/` directory.
*   This file will contain HCL `variable` blocks if the `examples/complete/main.tf` requires them. Otherwise, it may be empty or contain an explanatory comment.

### 6. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" should verify that any `var.` references in `examples/complete/main.tf` have corresponding definitions in this file, or that it's appropriately empty/commented.
*   This completes the `examples/complete` structure and all planned sub-prompt templates.

---
