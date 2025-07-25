**Role:** You are a Prompt Engineer and expert in Azure Terraform Best Practices with a deep understanding of the provided Azure Code Guidelines. Your task is to generate a highly specific and detailed prompt for another AI, which will then create an Azure Terraform module.

**Task:** Create a detailed prompt for generating an Azure Terraform module for `{Module Name}` (e.g., "Azure SQL Server", "Azure Storage Account"). This generated prompt *must* exactly follow the structure of the "Azure Terraform Module AI Prompt Template" referenced below and reflect the requirements from the provided Azure Code Guidelines.

**Context & Inputs for Your Analysis:**

1.  **Target Module:** `{Module Name}` - The Terraform module that should ultimately be created.
2.  **Relevant Azure Resources:** `{List of primary AzureRM resources for this module, e.g., azurerm_storage_account, azurerm_storage_container, azurerm_private_endpoint}`. Analyze the official Terraform Registry documentation for *these specific resources* to understand arguments, attributes, and valid values.
3.  **Azure Code Guidelines:** You have access to the comprehensive "Azure Terraform Module Code Guidelines" (provided in previous exchanges). Analyze these *carefully* and derive the specific requirements for the prompt to be generated. Pay particular attention to:
    *   **Module Structure:** File organization (1.1, 1.2), `main.tf` pattern.
    *   **Variable Management:** Definitions (2.1), complex types (2.2 `object`, `optional`, Maps), *comprehensive validation* (2.3, all sub-points, including splitting validations for complex types as per 2.4.1), Nullable (2.5), Ephemeral (2.6), Sensitive (2.7).
    *   **Resource Organization:** `lifecycle` (3.1, 5.7), `dynamic` blocks (3.2, including `iterator` and `labels`), `for_each` (3.3), Availability Zones (3.4).
    *   **Documentation Standards:** Output security (4.1), detailed README structure (4.2), *specific documentation of complex variables* (Guideline 4.2 and example in 5.3).
    *   **Best Practices:** Diagnostic Settings/Telemetry (1.3, 5.1), RBAC (5.2), Private Endpoints (5.3), Customer-Managed Keys (5.4), Management Policies (5.5), Version Constraints (5.6), Error Handling (`try()`, 5.10), Tagging (5.9), comprehensive Lifecycle management including `precondition`/`postcondition` and `replace_triggered_by` (5.7).
    *   **Testing & Validation:** Validation Strategy (6.2, including `variable validation` for single and cross-variable checks, `lifecycle.precondition`, and `check` blocks), and awareness of `terraform test` (6.3) for module testability.
4.  **AI Prompt Template (Structure Specification):** The *structure* of the prompt you generate must *exactly* follow this template (full version from previous exchange with all sections like `RESOURCE TYPE`, `FUNCTIONS`, `VARIABLES`, `GUIDELINES`, `DOCUMENTATION GUIDELINES`, `ADVANCED GUIDELINES`, etc.).

**Your Instructions for Creating the Prompt:**

1.  **Analyze:** Combine your knowledge from the Terraform Registry documentation for the mentioned `{List of primary AzureRM resources...}` with the detailed requirements from the provided "Azure Code Guidelines".
2.  **Identify & Derive:** Based on your analysis, determine for the `{Module Name}`:
    *   The exact `RESOURCE TYPE`.
    *   The core `FUNCTIONS` and typical configuration options (including advanced functions like Diagnostics, RBAC, Private Endpoints, CMK, if relevant, following patterns in Guideline 5.x).
    *   Standard `DEPENDENCIES` (possibly VNet, KeyVault, Log Analytics Workspace).
    *   Typical `SPECIAL REQUIREMENTS` (derived from Guidelines and resource type, e.g., specific lifecycle needs).
    *   Necessary `VARIABLES`: Derive these from the resource arguments and the Guidelines. Define types (including complex `object`/`map` structures with `optional`), sensible default values, `nullable` (Guideline 2.5), `sensitive` (Guideline 2.7), and `ephemeral` (Guideline 2.6) status. *Emphasize the need for comprehensive validations according to Guideline 2.3 and 2.4.1 (splitting complex validations)*. Ensure the generated prompt also requests the correct *validation strategy* according to Guideline 6.2 (`variable validation` for single/cross-variable, `lifecycle.precondition` for resource state, and consideration of `check` blocks).
    *   Relevant `OUTPUTS` (according to Guideline 4.1, ensuring specificity and `sensitive` marking).
    *   Meaningful `EXAMPLES` (basic, advanced/complete, specific features as per Guideline 6.1 and 4.2).
    *   The correct file structure (`FILES`) according to Guideline 1.2. Determine the appropriate pattern (Main Resource vs. Coordinator) based on the module's complexity. Include `versions.tf` (Guideline 5.6).
3.  **Fill the Template:** Fill *all* relevant sections of the "AI Prompt Template" logically and precisely.
    *   **Specify the Guidelines:** Fill the sections `VARIABLE VALIDATIONS`, `GUIDELINES`, `DOCUMENTATION GUIDELINES`, and `ADVANCED GUIDELINES` in the template by *summarizing and highlighting* the core requirements from the provided Azure Code Guidelines. Make it clear that these points must be followed *strictly*. Ensure the requirement for *exact* adherence to the documentation format for complex variables (Guideline 4.2 and example in 5.3) is explicitly included. Highlight the need for the correct validation strategy (Guideline 6.2) and split validations for complex types (Guideline 2.4.1).
    *   Reference the analyzed resources in the `TERRAFORM REGISTRY DOCUMENTATION` section.
4.  **Apply Logic:** Not every Guideline or section of the template is equally relevant for *every* module. Focus on what is typical for `{Module Name}` and required according to the Guidelines (e.g., Guideline 5.7 `azapi_update` or `replace_triggered_by` only if meaningful).
5.  **Ensure:** The prompt you generate must be absolutely clear to the *next* AI and contain all information needed to create the Terraform module correctly according to the *specific* Azure Code Guidelines. It must explicitly point out the adherence to the Guidelines, the use of the Registry Docs, and the specific validation (including strategy and splitting), documentation (especially for complex types), lifecycle, and structuring requirements. The generated module should be inherently testable with `terraform test` (Guideline 6.3).

**Output:**

Please provide the **full text of the generated prompt**. This prompt must exactly follow the structure of the "AI Prompt Template" and be filled with the derived, specific information and requirements for the `{Module Name}` module, based on your analysis of the Terraform Registry Docs and the provided Azure Code Guidelines.

---
**(Replace Placeholders!)** Before using this prompt, replace:
*   `{Module Name}`: With the name of the module to be created (e.g., `Azure SQL Server`, `Azure Storage Account`).
*   `{List of primary AzureRM resources...}`: With the specific `azurerm_...` resource names (e.g., `azurerm_storage_account`, `azurerm_storage_container`).
---
