## Sub-Prompt Template: Generate Auxiliary Resource `.tf` File

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Target File Name:** `{{TARGET_FILENAME_TF}}` (e.g., `containers.tf`, `network_rules.tf`, `private_endpoints.tf`)
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_VARIABLES_TF_AND_MAIN_TF}}`

### 1. Objective

Generate the auxiliary Terraform file `{{TARGET_FILENAME_TF}}` for the Azure module: `{{MODULE_NAME}}`.
This file should define specific Azure resource(s) related to the core module functionality, as specified in the Module Design Document (MDD). It may also include `locals` blocks if specific transformations are needed for these auxiliary resources.

### 2. Explicit Data for Generation (from MDD)

The "Prompt Engineering AI (Cline)" will populate this section.

**Local Values (JSON Array, if any, specific to this file's scope):**
```json
[
  {
    "local_name": "{{LOCAL_NAME_1}}",
    "hcl_expression": "{{HCL_EXPRESSION_FOR_LOCAL_1}}" // e.g., "flatten([for k, v in var.container_settings : v.permissions])"
  }
  // ... more local value objects ...
]
```

**Auxiliary Resource Definitions (JSON Array):**
```json
[
  {
    "resource_type": "azurerm_storage_container", // Terraform resource type
    "local_name": "data_containers", // Local name for this resource block
    "for_each_expression": "var.containers", // Optional: if creating multiple instances
    "arguments": { // Key-value pairs of arguments for the resource
      "name": "each.value.name", // Example if using for_each
      "storage_account_name": "azurerm_storage_account.main.name", // Reference to core resource
      "container_access_type": "each.value.access_type",
      // ... other arguments ...
    },
    "dynamic_blocks": [ // Array of dynamic block definitions, if any
      // ... similar structure to main.tf dynamic_blocks ...
    ],
    "lifecycle_block": { // Optional: lifecycle configuration
      // ... similar structure to main.tf lifecycle_block ...
    },
    "depends_on_expressions": ["{{DEPENDS_ON_EXPRESSION_1}}"] // Optional
  }
  // ... more auxiliary resource objects for this file ...
]
```

**Instructions for Module-Generating AI:**
*   If `Local Values` are provided, generate a `locals { ... }` block containing all specified local values.
*   For each `Auxiliary Resource Definition` object:
    *   Generate a `resource "{{resource_type}}" "{{local_name}}" { ... }` block.
    *   If `for_each_expression` is provided, include `for_each = {{for_each_expression}}` in the resource block.
    *   Populate the resource block with all key-value pairs from `arguments`. Ensure values are treated as direct HCL expressions (e.g., `var.name`, `local.value`, `each.value.attribute`, `"static_string"`, `azurerm_resource.main.attribute`).
    *   Implement `dynamic_blocks` and `lifecycle_block` as specified, similar to the `main.tf` (Core Resource) template.
    *   If `depends_on_expressions` is provided and not empty, generate a `depends_on = [{{COMMA_SEPARATED_EXPRESSIONS}}]` argument.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 1.2: Resource-Oriented File Separation (this template embodies this principle).
    *   Section 3.1: Resource Blocks.
    *   Section 3.2: Dynamic Blocks.
    *   Section 3.3: Resource Collections (especially if `for_each` is used).
    *   Section 5.6: Resource Protection and Lifecycle Management.
    *   Section 5.7: Tag Management (if these auxiliary resources are taggable, ensure `tags = local.merged_tags` or similar is used, assuming `local.merged_tags` is defined in `main.tf` or another central place and accessible).
    *   Section 5.8: Error Handling with `try()`.

### 4. References to AzureRM Registry Documentation (Crucial)

*   The "Prompt Engineering AI (Cline)" will list paths to relevant, pre-processed AzureRM Registry documentation snippets for each auxiliary resource type being generated in this file.
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_FOR_AUX_RESOURCE_TYPE_1}}`
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_FOR_AUX_RESOURCE_TYPE_2}}`

### 5. Context from Previous (Validated) Micro-Tasks

*   **`versions.tf`:** Assume provider versions are set.
*   **`variables.tf`:** CRITICAL. All `var.*` references **MUST** correspond to variables defined in `variables.tf`.
    *   `{{PATH_TO_GENERATED_VARIABLES_TF_OR_SUMMARY_OF_VARIABLES}}`
*   **`main.tf` (and other preceding resource files):** CRITICAL. References to other resources (e.g., `azurerm_storage_account.main.name`) **MUST** be valid based on resources generated in previous steps.
    *   `{{PATH_TO_GENERATED_MAIN_TF_OR_SUMMARY_OF_CORE_RESOURCES}}`
    *   `{{PATHS_TO_OTHER_RELEVANT_GENERATED_TF_FILES_OR_SUMMARIES}}`
*   `{{SUMMARY_OF_OTHER_RELEVANT_OUTPUTS_FROM_PREVIOUS_TASKS_OR_NONE}}`

### 6. Expected Output

*   A single file named `{{TARGET_FILENAME_TF}}` containing the `locals` block (if any) and all specified auxiliary resource blocks.
*   The file must be syntactically correct HCL, use variables defined in `variables.tf`, correctly reference any resources from `main.tf` or other files, and strictly adhere to all specified guidelines.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify:
    *   All specified `locals` and `resource` blocks are generated correctly in `{{TARGET_FILENAME_TF}}`.
    *   All resource arguments, `for_each` expressions, dynamic blocks, and lifecycle configurations match the MDD for this file.
    *   All variable references (`var.*`) are valid.
    *   All local references (`local.*`) are valid (either defined in this file or accessible from `main.tf` if structured that way).
    *   All references to other resources (e.g., `azurerm_storage_account.main.id`) are correct.
*   Key information for `outputs.tf` generation: The names and types of resources created in this file (e.g., `azurerm_storage_container.data_containers`).
*   Key information for `README.md`: List of resources created in this file.

---
