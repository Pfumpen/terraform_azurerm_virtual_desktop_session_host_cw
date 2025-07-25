## Sub-Prompt Template: Generate `variables.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_OR_NONE}}`

### 1. Objective

Generate the complete `variables.tf` file for the Azure module: `{{MODULE_NAME}}`.
This file must define all input variables required for the module based on the Module Design Document (MDD) and the user's requirements.

### 2. Explicit Data for Generation (from MDD)

**Module-Level Variables:**

The "Prompt Engineering AI (Cline)" will populate this section with a JSON array detailing each variable. Example structure for one variable:
```json
[
  {
    "name": "{{VAR_NAME_1}}",
    "type_signature": "{{TERRAFORM_TYPE_SIGNATURE_1}}", // e.g., "string", "object({ name = string, size = optional(number, 10) })"
    "description": "{{VAR_DESCRIPTION_1}}",
    "default_value_hcl": "{{DEFAULT_VALUE_AS_HCL_STRING_1_OR_NULL}}", // e.g., "null", "\"default_string\"", "{ name = \"example\", size = 20 }"
    "nullable": {{true_OR_false_1}}, // boolean: true or false
    "sensitive": {{true_OR_false_1}}, // boolean: true or false
    "ephemeral": {{true_OR_false_1}}, // boolean: true or false
    "validation_rules": [ // Array of validation rule objects
      {
        "condition_hcl": "{{VALIDATION_CONDITION_HCL_1A}}", // e.g., "can(regex(\"^[a-z0-9]{3,24}$\", var.{{VAR_NAME_1}}))"
        "error_message": "{{VALIDATION_ERROR_MESSAGE_1A}}"
      },
      {
        "condition_hcl": "{{VALIDATION_CONDITION_HCL_1B}}",
        "error_message": "{{VALIDATION_ERROR_MESSAGE_1B}}"
      }
      // ... more validation rules for VAR_NAME_1
    ]
  }
  // ... more variable objects ...
]
```

**Instructions for Module-Generating AI:**
*   For each variable object provided in the JSON array above, generate a complete `variable` block in HCL.
*   Ensure the `type` in HCL correctly reflects the `type_signature`.
*   If `default_value_hcl` is provided and is not the string "null", include the `default` argument in the HCL block. The value for `default` should be the direct HCL expression (e.g., if `default_value_hcl` is `"{ name = \"example\" }"`, then `default = { name = "example" }`).
*   Include `nullable = true` or `nullable = false` as specified by the boolean value.
*   Include `sensitive = true` or `sensitive = false` as specified.
*   Include `ephemeral = true` or `ephemeral = false` as specified.
*   For each rule object in the `validation_rules` array, generate a corresponding `validation` block with the provided `condition` (HCL string) and `error_message` (string).

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 2.1: Variable Definitions (description, type, defaults, reserved names)
    *   Section 2.2: Complex Variable Types (objects, maps, `optional()`) - Pay close attention to the correct HCL syntax for these types.
    *   Section 2.3: Variable Validation (specificity, error messages, splitting for complex types) - Ensure each validation rule from the MDD is a separate `validation` block.
    *   Section 2.4: Nullable Variables
    *   Section 2.5: Ephemeral Variables
    *   Section 2.6: Sensitive Input Variables

### 4. References to AzureRM Registry Documentation (Contextual)

*   The "Prompt Engineering AI (Cline)" will list paths to relevant, pre-processed AzureRM Registry documentation snippets if they provide crucial context for variable design (e.g., naming constraints, allowed values not covered by simple validation).
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_1_FOR_RESOURCE_A_IF_RELEVANT}}`
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_2_FOR_RESOURCE_B_IF_RELEVANT}}`
    *   *(Guidance: Often, for `variables.tf`, the primary source of truth is the MDD. Registry docs are more for understanding *why* a variable is structured a certain way.)*

### 5. Context from Previous (Validated) Micro-Tasks

*   `{{SUMMARY_OF_RELEVANT_OUTPUTS_FROM_PREVIOUS_TASKS_OR_NONE}}`
    *   *(Example: "This is likely one of the first `.tf` file generation tasks. No preceding Terraform code generation tasks for this module yet. The `versions.tf` might have been generated.")*

### 6. Expected Output

*   A single file named `variables.tf` containing all specified variable blocks, formatted according to Terraform standards.
*   The file must be syntactically correct HCL and strictly adhere to all specified guidelines.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify that:
    *   All variables from the MDD are present in the generated `variables.tf`.
    *   All attributes (type, description, default, nullable, sensitive, ephemeral, validations) are correctly implemented.
*   This verified list of variable names and their full definitions will be critical for:
    *   Generating resource configurations in `main.tf` (and other `.tf` files).
    *   Generating `outputs.tf` if outputs depend on variable structures.
    *   Documenting inputs accurately in `README.md`.
    *   Creating comprehensive examples.
*   Pay special attention to the exact structure of complex variables (objects, maps of objects) as this will directly influence how `for_each` and `dynamic` blocks are constructed in resource files.

---
