## Sub-Prompt Template: Generate `versions.tf`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_OR_NONE}}`

### 1. Objective

Generate the complete `versions.tf` file for the Azure module: `{{MODULE_NAME}}`.
This file must define the `required_providers` and the `required_version` for Terraform, based on the Module Design Document (MDD) or standard module requirements.

### 2. Explicit Data for Generation (from MDD/Standard Requirements)

The "Prompt Engineering AI (Cline)" will populate this section.

**Terraform Version Requirement:**
*   `required_version`: `{{TERRAFORM_REQUIRED_VERSION_CONSTRAINT}}` (e.g., ">= 1.1.0")

**Provider Requirements (JSON Array):**
```json
[
  {
    "provider_local_name": "azurerm", // e.g., azurerm, random, null
    "source": "hashicorp/azurerm",    // e.g., hashicorp/azurerm, hashicorp/random
    "version_constraint": "{{AZURERM_PROVIDER_VERSION_CONSTRAINT}}" // e.g., ">= 3.0.0", "~> 3.5"
  },
  {
    "provider_local_name": "random",
    "source": "hashicorp/random",
    "version_constraint": "{{RANDOM_PROVIDER_VERSION_CONSTRAINT}}"
  }
  // ... other providers as needed by the module ...
]
```

**Instructions for Module-Generating AI:**
*   Generate a `terraform` block.
*   Inside the `terraform` block, define `required_version` using the value provided.
*   Inside the `terraform` block, define a `required_providers` block.
*   For each provider object in the JSON array above:
    *   Create an entry within `required_providers` using `provider_local_name` as the key.
    *   Set `source` to the value provided.
    *   Set `version` to the `version_constraint` provided.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 5.5: Version Constraints (`versions.tf`) - Ensure exact syntax and structure.

### 4. References to AzureRM Registry Documentation (Contextual)

*   Not typically required for `versions.tf` generation, as provider requirements are usually determined by the resources planned in the MDD.

### 5. Context from Previous (Validated) Micro-Tasks

*   `{{SUMMARY_OF_RELEVANT_OUTPUTS_FROM_PREVIOUS_TASKS_OR_NONE}}`
    *   *(Example: "This is often the very first `.tf` file to be generated. No preceding Terraform code generation tasks for this module yet.")*

### 6. Expected Output

*   A single file named `versions.tf` containing the `terraform` block with `required_version` and `required_providers` defined.
*   The file must be syntactically correct HCL and strictly adhere to Guideline 5.5.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify that:
    *   The `required_version` for Terraform is correctly set.
    *   All specified providers are listed with their correct `source` and `version` constraints.
*   This information is crucial for ensuring `terraform init` will succeed and that the module uses compatible provider versions for the resources it will define.

---
