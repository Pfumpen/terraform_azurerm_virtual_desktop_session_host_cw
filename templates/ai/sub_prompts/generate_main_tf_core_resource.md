## Sub-Prompt Template: Generate `main.tf` (Core Resource(s))

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_VARIABLES_TF}}`

### 1. Objective

Generate the `main.tf` file for the Azure module: `{{MODULE_NAME}}`.
This file should define the primary/core Azure resource(s) managed by this module, as specified in the Module Design Document (MDD). It may also include `locals` blocks for common values or transformations.

### 2. Explicit Data for Generation (from MDD)

The "Prompt Engineering AI (Cline)" will populate this section.

**Local Values (JSON Array, if any):**
```json
[
  {
    "local_name": "{{LOCAL_NAME_1}}",
    "hcl_expression": "{{HCL_EXPRESSION_FOR_LOCAL_1}}" // e.g., "format(\"res-%s\", var.name_prefix)"
  }
  // ... more local value objects ...
]
```

**Core Resource Definitions (JSON Array):**
```json
[
  {
    "resource_type": "azurerm_storage_account", // Terraform resource type
    "local_name": "main", // Local name for this resource block
    "arguments": { // Key-value pairs of arguments for the resource
      "name": "var.storage_account_name", // Can be direct values or var references
      "resource_group_name": "var.resource_group_name",
      "location": "var.location",
      "account_tier": "var.account_tier",
      "account_replication_type": "local.replication_type", // Example using a local
      // ... other arguments ...
    },
    "dynamic_blocks": [ // Array of dynamic block definitions
      {
        "block_name": "network_rules", // e.g., network_rules, settings
        "for_each_expression": "var.network_rules_object", // HCL expression for iteration
        "iterator_name": "rule", // Optional: custom iterator name
        "labels": [], // Optional: labels for the dynamic block, if any
        "content_arguments": { // Arguments within the content {} block
          "default_action": "rule.value.action",
          "ip_rules": "rule.value.ip_rules"
          // ... other content arguments ...
        }
      }
      // ... more dynamic blocks ...
    ],
    "lifecycle_block": { // Optional: lifecycle configuration
      "create_before_destroy": {{true_OR_false_OR_null}},
      "prevent_destroy": {{true_OR_false_OR_null}},
      "ignore_changes": ["{{ATTRIBUTE_TO_IGNORE_1}}", "{{ATTRIBUTE_TO_IGNORE_2}}"], // or null/empty array
      "replace_triggered_by": ["{{RESOURCE_OR_VAR_TRIGGER_1}}"] // or null/empty array
    },
    "depends_on_expressions": ["{{DEPENDS_ON_EXPRESSION_1}}"] // Optional: array of HCL expressions, e.g., "[azurerm_resource_group.example.name]"
  }
  // ... more core resource objects ...
]
```

**Instructions for Module-Generating AI:**
*   If `Local Values` are provided, generate a `locals { ... }` block containing all specified local values.
*   For each `Core Resource Definition` object:
    *   Generate a `resource "{{resource_type}}" "{{local_name}}" { ... }` block.
    *   Populate the resource block with all key-value pairs from `arguments`. Ensure that values are treated as direct HCL expressions (e.g., `var.name`, `local.value`, `"static_string"`).
    *   For each `dynamic_block` object:
        *   Generate a `dynamic "{{block_name}}" { ... }` block.
        *   Set `for_each = {{for_each_expression}}`.
        *   If `iterator_name` is provided, include `iterator = {{iterator_name}}`.
        *   If `labels` are provided and not empty, include them (e.g., `labels = ["setting"]`).
        *   Inside the `content { ... }` block, set all arguments from `content_arguments`.
    *   If `lifecycle_block` is provided and contains non-null values:
        *   Generate a `lifecycle { ... }` block.
        *   Include `create_before_destroy`, `prevent_destroy`, `ignore_changes`, and `replace_triggered_by` as specified if their values are not null/empty.
    *   If `depends_on_expressions` is provided and not empty, generate a `depends_on = [{{COMMA_SEPARATED_EXPRESSIONS}}]` argument.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 1.2: Resource-Oriented File Separation (if `main.tf` is a coordinator, this template might be less relevant, or used for the primary resource file).
    *   Section 1.3: Telemetry and Monitoring (if diagnostic settings are for the core resource and managed here).
    *   Section 3.1: Resource Blocks.
    *   Section 3.2: Dynamic Blocks (pay attention to `try()` for optional attributes within `content`).
    *   Section 3.3: Resource Collections (if `for_each` is used directly on a resource block, the MDD structure for `Core Resource Definitions` should reflect this, possibly by having the `for_each` expression at the top level of the resource definition object).
    *   Section 5.1: Managed Identities (if the `identity` block is part of the core resource).
    *   Section 5.6: Resource Protection and Lifecycle Management.
    *   Section 5.7: Tag Management (ensure `tags = local.merged_tags` or similar is used if tags are managed via locals).
    *   Section 5.8: Error Handling with `try()`.

### 4. References to AzureRM Registry Documentation (Crucial)

*   The "Prompt Engineering AI (Cline)" will list paths to relevant, pre-processed AzureRM Registry documentation snippets for each core resource type being generated. These are essential for understanding argument names, types, and valid values.
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_FOR_RESOURCE_TYPE_1}}`
    *   `{{PATH_TO_REGISTRY_DOC_SNIPPET_FOR_RESOURCE_TYPE_2}}`

### 5. Context from Previous (Validated) Micro-Tasks

*   **`versions.tf`:** Assume provider versions are set.
*   **`variables.tf`:** CRITICAL. All `var.*` references in the `arguments`, `dynamic_blocks`, and `locals` sections **MUST** correspond to variables defined in the (already generated and validated) `variables.tf`. The "Prompt Engineering AI (Cline)" must ensure the MDD uses correct variable names.
    *   `{{PATH_TO_GENERATED_VARIABLES_TF_OR_SUMMARY_OF_VARIABLES}}`
*   `{{SUMMARY_OF_OTHER_RELEVANT_OUTPUTS_FROM_PREVIOUS_TASKS_OR_NONE}}`

### 6. Expected Output

*   A single file named `main.tf` containing the `locals` block (if any) and all specified core resource blocks.
*   The file must be syntactically correct HCL, use variables defined in `variables.tf`, and strictly adhere to all specified guidelines.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify:
    *   All specified `locals` and `resource` blocks are generated correctly.
    *   All resource arguments, dynamic blocks, and lifecycle configurations match the MDD.
    *   All variable references (`var.*`) are valid based on the `variables.tf` content.
    *   All local references (`local.*`) are valid.
*   Key information for `outputs.tf` generation: The names and types of resources created (e.g., `azurerm_storage_account.main`).
*   Key information for `README.md`: List of resources created (`azurerm_storage_account.main`).

---
