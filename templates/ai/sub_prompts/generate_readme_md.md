## Sub-Prompt Template: Generate `README.md`

**Micro-Task ID:** `{{MICRO_TASK_ID}}`
**Depends On:** `{{LIST_OF_PREVIOUS_COMPLETED_TASK_IDS_INCLUDING_ALL_TF_FILES}}`

### 1. Objective

Generate the complete `README.md` file for the Azure module: `{{MODULE_NAME}}`.
This file must be comprehensive and strictly follow the structure and content requirements outlined in Guideline 4.2 of `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`.
The content for the README should be derived from the already generated and validated `.tf` files (`versions.tf`, `variables.tf`, `main.tf`, auxiliary resource files, `outputs.tf`) and the Module Design Document (MDD).

### 2. Explicit Data for Generation (from MDD and analysis of .tf files)

The "Prompt Engineering AI (Cline)" will need to synthesize information from various sources to populate the placeholders below.

**Module Information:**
*   `MODULE_NAME`: `{{MODULE_NAME}}` (e.g., "Azure Storage Account", "Azure Kubernetes Service Cluster")
*   `MODULE_CONCISE_DESCRIPTION`: `{{MODULE_CONCISE_DESCRIPTION}}` (A brief statement of what the module provisions)
*   `VERSION_INFO_NOTES`: `{{VERSION_INFO_NOTES_OPTIONAL}}` (e.g., "This module follows Semantic Versioning. Pre-v1.0.0 versions are considered unstable.")
*   `FEATURES_LIST`: (Array of strings) `{{FEATURES_LIST_AS_MARKDOWN_BULLETS}}`
*   `LIMITATIONS_NOTES`: `{{LIMITATIONS_AND_IMPORTANT_NOTES_OPTIONAL}}`

**Requirements (from `versions.tf`):**
*   `TERRAFORM_VERSION_CONSTRAINT`: `{{TERRAFORM_VERSION_CONSTRAINT_FROM_VERSIONS_TF}}`
*   `PROVIDERS_TABLE_MARKDOWN`:
    ```markdown
    | Name      | Version       |
    | --------- | ------------- |
    | terraform | {{TERRAFORM_VERSION_CONSTRAINT_FROM_VERSIONS_TF}}     |
    | azurerm   | {{AZURERM_VERSION_CONSTRAINT_FROM_VERSIONS_TF}}     |
    | random    | {{RANDOM_VERSION_CONSTRAINT_FROM_VERSIONS_TF}}    |
    <!-- Add more rows if other providers are used -->
    ```

**External Dependencies (from MDD/`variables.tf` analysis):**
*   `EXTERNAL_DEPENDENCIES_LIST_MARKDOWN`: (Formatted list, e.g., "- Resource Group (provided via `var.resource_group_name`)\n- VNet & Subnet (for Private Endpoint, via `var.subnet_id`)") `{{EXTERNAL_DEPENDENCIES_MARKDOWN}}`

**Resources Created (from analysis of all resource `.tf` files):**
*   `RESOURCES_TABLE_MARKDOWN`:
    ```markdown
    | Type                                  | Name    |
    | ------------------------------------- | ------- |
    | `{{RESOURCE_TYPE_1}}`                 | `{{RESOURCE_LOCAL_NAME_1}}` {{FOR_EACH_NOTE_1_OPTIONAL}} |
    | `{{RESOURCE_TYPE_2}}`                 | `{{RESOURCE_LOCAL_NAME_2}}` {{FOR_EACH_NOTE_2_OPTIONAL}} |
    <!-- Add more rows for all resources created by the module -->
    ```
    *(Note: `{{FOR_EACH_NOTE_OPTIONAL}}` could be "(for_each)" if applicable)*

**Input Variables (from `variables.tf` analysis):**
*   `INPUTS_TABLE_MARKDOWN`: (A table summarizing each variable: Name, Description, Type, Default, Required)
    ```markdown
    | Name                  | Description                                       | Type        | Default | Required |
    | --------------------- | ------------------------------------------------- | ----------- | ------- | -------- |
    | `{{VAR_1_NAME}}`      | {{VAR_1_DESCRIPTION}}                             | `{{VAR_1_TYPE_SIGNATURE}}`    | `{{VAR_1_DEFAULT_DISPLAY}}`    | {{VAR_1_REQUIRED_YES_NO}}      |
    <!-- Add more rows for all variables -->
    ```
*   `COMPLEX_INPUTS_DOCUMENTATION_MARKDOWN`: (Detailed explanation for each complex variable type (objects, maps of objects), including its structure, attributes, and an HCL example, as per Guideline 4.2.8)
    ```markdown
    ### `{{COMPLEX_VAR_1_NAME}}` variable structure:
    {{COMPLEX_VAR_1_STRUCTURE_DESCRIPTION_MARKDOWN}}

    Type: `{{COMPLEX_VAR_1_TYPE_SIGNATURE_HCL}}`

    Example:
    ```hcl
    {{COMPLEX_VAR_1_EXAMPLE_HCL}}
    ```
    <!-- Repeat for each complex variable -->
    ```

**Outputs (from `outputs.tf` analysis):**
*   `OUTPUTS_TABLE_MARKDOWN`: (A table summarizing each output: Name, Description, Sensitive)
    ```markdown
    | Name                        | Description                                         | Sensitive |
    | --------------------------- | --------------------------------------------------- | --------- |
    | `{{OUTPUT_1_NAME}}`         | {{OUTPUT_1_DESCRIPTION}}                            | {{OUTPUT_1_SENSITIVE_TRUE_FALSE}}      |
    <!-- Add more rows for all outputs -->
    ```

**Usage Examples (references to `examples/` directory):**
*   `BASIC_EXAMPLE_REFERENCE_MARKDOWN`: "Refer to the `examples/basic/` directory for a minimal, runnable example." `{{BASIC_EXAMPLE_REFERENCE_MARKDOWN}}`
*   `COMPLETE_EXAMPLE_REFERENCE_MARKDOWN`: "Refer to the `examples/complete/` directory for a comprehensive example showcasing all variables." `{{COMPLETE_EXAMPLE_REFERENCE_MARKDOWN}}`
*   `ADVANCED_EXAMPLES_REFERENCE_MARKDOWN_OPTIONAL`: `{{ADVANCED_EXAMPLES_REFERENCE_MARKDOWN_OPTIONAL}}`

**Instructions for Module-Generating AI:**
*   Construct the `README.md` file by populating the standard sections (Title, Features, Requirements, etc.) using the provided data placeholders.
*   Strictly adhere to the complete structure outlined in Guideline 4.2 of `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`.
*   Ensure all tables (Requirements, Resources, Inputs, Outputs) are correctly formatted in Markdown.
*   For Input Variables, ensure the main table is present, followed by detailed sections for each complex variable type as specified.
*   The "Prompt Engineering AI (Cline)" is responsible for ensuring the accuracy and completeness of the data provided in the placeholders by thoroughly analyzing all previously generated `.tf` files and the MDD.

### 3. Targeted References to Guidelines

*   **Primary Document:** `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`
*   **Key Sections to Adhere To (Strictly):**
    *   Section 4.2: README.md Structure (This is the master guide for this task). Every subsection mentioned in 4.2 must be present and correctly populated.

### 4. References to AzureRM Registry Documentation (Contextual)

*   Not directly used for README generation, but the information in the README (especially resource types, variable purposes) is indirectly derived from understanding these resources.

### 5. Context from Previous (Validated) Micro-Tasks

*   **CRITICAL: All previously generated and validated `.tf` files are the primary source of truth for this task.**
    *   `{{PATH_TO_GENERATED_VERSIONS_TF}}`
    *   `{{PATH_TO_GENERATED_VARIABLES_TF}}`
    *   `{{PATH_TO_GENERATED_MAIN_TF}}`
    *   `{{PATHS_TO_ALL_GENERATED_AUXILIARY_TF_FILES}}`
    *   `{{PATH_TO_GENERATED_OUTPUTS_TF}}`
*   The "Prompt Engineering AI (Cline)" must have parsed these files to extract the necessary information for the placeholders in Section 2.

### 6. Expected Output

*   A single, complete file named `README.md`.
*   The file must be well-formatted Markdown and strictly adhere to all structural and content requirements of Guideline 4.2.

### 7. Information to Capture/Verify for Subsequent Tasks

*   The "Orchestrator" or "Prompt Engineering AI (Cline)" should verify:
    *   The generated `README.md` is complete and accurately reflects the module's inputs, outputs, created resources, and requirements.
    *   All sections from Guideline 4.2 are present.
    *   Markdown formatting is correct.
*   This `README.md` will be the primary documentation for users and will also guide the creation of example usages.

---
