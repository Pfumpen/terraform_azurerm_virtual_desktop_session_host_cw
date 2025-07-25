## Sub-Prompt Template: Generate `outputs.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_ALL_RESOURCE_TF_FILES}}`

### 1. Objective

Generate the complete `outputs.tf` file for the Azure module: `{{MODULE_NAME}}`.
This file must define all outputs the module should expose, based on the Module Design Document (MDD) and the resources created in previous steps.

### 2. Explicit Data for Generation (from MDD)

The "Prompt Engineering AI (Cline)" will populate this section with a JSON array detailing each output.

**Output Definitions (JSON Array):**
```json
[
  {
    "output_name": "{{OUTPUT_NAME_1}}", // e.g., storage_account_id, primary_blob_endpoint
    "description": "{{OUTPUT_DESCRIPTION_1}}",
    "value_hcl": "{{HCL_EXPRESSION_FOR_OUTPUT_VALUE_1}}", // e.g., "azurerm_storage_account.main.id", "try(azurerm_private_endpoint.blob[0].fqdn, null)"
    "sensitive": {{true_OR_false_1}}, // boolean: true or false
    "depends_on_expressions": ["{{DEPENDS_ON_EXPRESSION_1}}"] // Optional: array of HCL expressions for explicit dependencies if needed, e.g., "[azurerm_role_assignment.example]"
  },
  {
    "output_name": "{{OUTPUT_NAME_2}}",
    // ... similar structure for OUTPUT_NAME_2 ...
  }
  // ... more output objects ...
]
```

**Instructions for Module-Generating AI:**
*   For each output object provided in the JSON array above:
    *   Generate a complete `output "{{output_name}}" { ... }` block.
    *   Set the `description` to the value provided.
    *   Set the `value` to the HCL expression provided in `value_hcl`.
    *   Include `sensitive = true` or `sensitive = false` as specified by the boolean value.
    *   If `depends_on_expressions` is provided and not empty, generate a `depends_on = [{{COMMA_SEPARATED_EXPRESSIONS}}]` argument.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 4.1: Output Documentation (Specificity - avoid outputting entire objects, clear descriptions, sensitive outputs, `try()` for optional outputs).

### 4. References to AzureRM Registry Documentation (Contextual)

*   Not typically required for `outputs.tf` generation itself, but the HCL expressions for `value` will be derived from attributes of resources defined based on Registry documentation. The "Prompt Engineering AI (Cline)" must ensure these expressions are valid.

### 5. Context from Previous (Validated) Micro-Tasks

*   **All `.tf` files containing resource definitions (`main.tf`, auxiliary files):** CRITICAL. The HCL expressions for output `value` attributes **MUST** correctly reference attributes of resources generated in previous steps (e.g., `azurerm_storage_account.main.id`, `azurerm_storage_container.data_containers[*].id`).
    *   `{{PATH_TO_GENERATED_MAIN_TF_OR_SUMMARY_OF_CORE_RESOURCES}}`
    *   `{{PATHS_TO_ALL_GENERATED_AUXILIARY_TF_FILES_OR_SUMMARIES}}`
    *   `{{PATH_TO_GENERATED_VARIABLES_TF_OR_SUMMARY_OF_VARIABLES}}` (in case outputs are derived from or conditional on variables)
*   `{{SUMMARY_OF_OTHER_RELEVANT_OUTPUTS_FROM_PREVIOUS_TASKS_OR_NONE}}`

### 6. Expected Output

*   A single file named `outputs.tf` containing all specified output blocks.
*   The file must be syntactically correct HCL and strictly adhere to Guideline 4.1. Output values should be specific attributes, not entire resource objects. Use `try()` for values from conditionally created resources.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify:
    *   All outputs from the MDD are present in the generated `outputs.tf`.
    *   All attributes (`description`, `value`, `sensitive`, `depends_on`) are correctly implemented.
    *   `value` expressions correctly reference attributes of existing resources and do not expose entire objects unless explicitly justified and documented.
*   This verified list of outputs will be crucial for:
    *   Documenting outputs accurately in `README.md`.
    *   Creating functional examples that consume these outputs.
    *   Inter-module dependencies if this module is called by another.

---
