# Revised Workflow: Azure Terraform Module Generation with Micro-Tasks

This document outlines an enhanced workflow for generating Azure Terraform modules, emphasizing iterative development through micro-tasks, automated checks, and precise AI context management to improve code quality.

## Core Principles

*   **Orchestration:** A controlling entity (script, AI model, or user) manages the sequence of micro-tasks.
*   **Scoped Context per Micro-Task:** Each AI call for module generation receives only the necessary context for that specific task.
*   **Iterative Quality Assurance:** Automated checks are performed frequently, ideally after each micro-task or small group of tasks.

## Orchestration Logic

The successful execution of this micro-task workflow relies on a clear orchestration logic:

1.  **Orchestrator Role:** This can be a human user, a dedicated script, or a higher-level AI model (like Cline acting as an orchestrator). The orchestrator is responsible for:
    *   Initiating Phase 0.
    *   Sequentially triggering each micro-task based on the plan from Phase 0, Step 2.
    *   Providing the correct sub-prompt and necessary context (e.g., paths to relevant guideline documents, previously generated code snippets) to the Module-Generating AI for each micro-task.
    *   Triggering automated checks (`terraform fmt`, `terraform validate`, `tflint`) after code generation steps.
    *   Collecting results (generated code, error messages, linting reports) from each step.
    *   Managing the feedback loop: If an automated check fails, the orchestrator provides the error details back to the Module-Generating AI for correction, potentially with a refined sub-prompt.
    *   Deciding when a micro-task is successfully completed and proceeding to the next.
    *   Initiating comprehensive review and final testing phases.

2.  **State Management:** The orchestrator needs to maintain the state of the module generation process, including:
    *   The current micro-task plan.
    *   The code generated so far (stored in the file system).
    *   The results of validation and linting checks for each part.

3.  **Data Flow:**
    *   **Input to Module-Generating AI:** Specific sub-prompt, references to guidelines/docs, relevant previously generated code.
    *   **Output from Module-Generating AI:** Generated code (file content or snippets).
    *   **Input to Automated Checks:** Paths to the generated code.
    *   **Output from Automated Checks:** Success/failure status, error messages, linting reports.

4.  **Decision Points:**
    *   **Micro-Task Completion:** A micro-task is considered complete when the generated code passes all associated automated checks (fmt, validate, tflint for that specific part) and, if applicable, a focused mini-review.
    *   **Retry Mechanism:** If a micro-task repeatedly fails automated checks even after correction attempts by the Module-Generating AI, the orchestrator might flag this for manual intervention or a change in strategy for that specific part.

---

## Phase 0: Preparation & Design (Once per new module type)

### 1. Initialization & Base Context
    *   Initialize the module repository using the standard template structure.
    *   Collect and prepare relevant AzureRM Terraform Registry documentation snippets for the primary Azure resources the module will manage. Store these in a dedicated, temporary location for the current module generation process.
    *   Keep the full `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md` readily available as the primary reference document.

### 2. Module Design & Micro-Task Plan Creation (Responsibility: Prompt Engineering AI, e.g., Cline)
    *   **Input:** User provides an initial request (e.g., using a simplified version of `templates/ai/First_Prompt_Generating_Message.md`) specifying:
        *   The target Azure resource type for the module (e.g., "Azure Storage Account", "Azure SQL Server").
        *   A list of primary AzureRM Terraform resources to be included (e.g., `azurerm_storage_account`, `azurerm_storage_container`).
        *   Key functionalities or features the module should support (e.g., "private endpoints", "customer-managed keys", "specific diagnostic settings").
        *   Optionally, references to specific sections of the AzureRM Registry documentation if particular details need emphasis.
    *   **Process (by Prompt Engineering AI - Cline):**
        1.  **Analyze Requirements:** Understand the core resource and desired functionalities.
        2.  **Consult Guidelines & Registry Docs:** Review `Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md` and the provided/referenced AzureRM Registry documentation for the specified resources.
        3.  **Deconstruct into Files:** Based on Guideline 1.2 (Resource-Oriented File Separation), determine the necessary `.tf` files (e.g., `main.tf`, `variables.tf`, `outputs.tf`, resource-specific files like `storage_container.tf`, `private_endpoint.tf`). Also plan for `versions.tf`, `README.md`, and standard `examples/` structure.
        4.  **Define Variables:** For each planned `.tf` file that will contain resources, identify all necessary input variables. For each variable:
            *   Determine its name, `type`, and a clear `description`.
            *   Infer `default` values where appropriate.
            *   Determine `nullable`, `sensitive`, and `ephemeral` attributes based on guidelines and resource nature.
            *   Crucially, define the **specific validation rules** (regex, ranges, allowed values, cross-variable checks if identifiable at this stage) required for each variable, referencing Guideline 2.3, 2.4.1, and the Registry Docs.
        5.  **Define Outputs:** Identify key outputs the module should expose, following Guideline 4.1.
        6.  **Outline Resource Logic:** For `main.tf` and other resource-specific `.tf` files, sketch out the primary resources and their main configuration blocks, noting where dynamic blocks or `for_each` loops might be needed.
        7.  **Plan README Structure:** Outline the sections for the `README.md` as per Guideline 4.2.
        8.  **Plan Examples:** Define the scope for `examples/basic/main.tf` and `examples/complete/main.tf`.
    *   **Output (from Prompt Engineering AI - Cline):**
        *   A **Comprehensive Module Design Document (MDD)**. This MDD is internal to the AI process and serves as the blueprint. It includes:
            *   A **list of all files** to be generated.
            *   A **sequence of micro-tasks**, where each task corresponds to generating one or a small group of related files (e.g., "Generate `variables.tf`", "Generate `main.tf` for core resource", "Generate `outputs.tf`", "Generate `README.md`").
        *   For **each micro-task**, a **specific, concise sub-prompt**. This sub-prompt must include:
            *   The **exact objective** (e.g., "Generate the complete `variables.tf` file for the Azure Storage Account module. Include variables for `name`, `location`, `account_tier`, `blob_properties`, `containers`, etc., with their full type definitions, descriptions, defaults, and all necessary `validation` blocks as previously designed in the MDD. Refer to Guideline 2.X and relevant Registry Docs for `azurerm_storage_account`.").
            *   **Explicit data for generation**: For `variables.tf`, this would be the detailed list of variables with all their attributes (name, type, description, default, nullable, sensitive, ephemeral, and specific validation logic). For resource files, it would be the resource types, names, and key arguments. For `README.md`, it would be the structured content derived from other generated files.
            *   **Targeted references** to specific, relevant sections of `Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md` and the prepared AzureRM Registry documentation snippets.
            *   (If applicable for later tasks) A **brief summary of outputs/results from previously completed and validated micro-tasks** that are relevant to the current task (e.g., "The `variables.tf` file has been generated and validated, containing `var.storage_account_name` and `var.location`. Use these in the `azurerm_storage_account` resource block.").

---

## Phase 1: Iterative Module Generation & Automated Checks

*This cycle is repeated for each micro-task defined in Phase 0, Step 2.*

### 3. Execute Micro-Task (Responsibility: Module-Generating AI)
    *   The orchestrator provides the specific sub-prompt for the current micro-task to the Module-Generating AI.
    *   The Module-Generating AI generates the code snippet or file(s) for this micro-task.

### 4. Automated Base Validation & Formatting (Immediate, Post-Generation)
    *   **Command:** `terraform fmt -check -recursive ./` (executed in the context of the module's root directory).
        *   **Feedback Loop:** If errors occur, the AI receives the error output and is prompted to correct the formatting.
    *   **Command (Conditional):** `terraform validate ./` (executed in the module's root directory, if the generated code forms a syntactically valid partial module).
        *   **Feedback Loop:** If errors occur, the AI receives the error output and is prompted to correct syntax errors.

### 5. Automated `tflint` Check (Post-Generation of `.tf` files)
    *   **Prerequisite (One-time/Periodic):** Develop and maintain a custom `tflint` ruleset (`.tflint.hcl`) that codifies as many rules from `Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md` as possible.
    *   **Command:** `tflint --config=.tflint.hcl ./` (executed in the module's root directory).
    *   **Analysis:** The output from `tflint` (errors and warnings) is captured.
    *   **Feedback Loop:** If rule violations are detected, the AI receives specific feedback (violated rule, file/line, message) and is prompted to correct the code.

### 6. (Optional) Focused Mini-Review
    *   A brief, targeted review of the micro-task's output against its specific sub-prompt.
    *   **Focus:** Was the precise objective of the micro-task achieved?
    *   Can be manual or performed by a specialized, fast review AI.

---

## Phase 2: Integration, Comprehensive Review & Testing

### 7. `README.md` Generation (Dedicated Micro-Task)
    *   **Timing:** After all core `.tf` files (variables, resources, outputs) have been generated and passed initial automated checks.
    *   **Sub-Prompt Example:** "Generate the `README.md` for Module X. Base the content on the already generated and validated `variables.tf`, `main.tf`, `outputs.tf` (content will be provided or paths given). Strictly adhere to Guideline 4.2 for overall structure and detailed variable documentation (including complex types)."

### 8. Example Code Generation (Dedicated Micro-Tasks per Example)
    *   For each example (e.g., `examples/basic/main.tf`, `examples/complete/main.tf`).
    *   **Sub-Prompt Example:** "Create a functional `main.tf` (and `variables.tf` if needed) for the 'basic' example of Module X. This example should demonstrate [specific core functionality]. Utilize the variables and outputs defined in the main module (definitions will be provided or paths given)."

### 9. Comprehensive Module Review (As per `templates/ai/Azure_Module_Refinement.md`)
    *   **Timing:** After all module files (including README and examples) have been generated and passed their respective micro-task checks.
    *   **Input:** The complete generated module, original high-level prompt/requirements, `Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md`, and the `Azure_Module_Refinement.md` template.
    *   **Focus:** Logic, complex interactions, adherence to advanced guidelines, overall coherence, and any items not caught by automated checks.

### 10. Implement Corrections from Comprehensive Review
    *   Apply fixes identified in Step 9.

### 11. Final Validation & Functional Testing (As per original workflow)
    *   `terraform validate ./` for the complete module.
    *   `terraform init`, `terraform plan`, `terraform apply`, and `terraform destroy` for all examples in their respective directories (e.g., `cd examples/basic && terraform apply && cd ../..`).
    *   Thorough manual verification of deployed resources and functionality.

### 12. Finalization
    *   Commit final code. Module is ready for use/publishing.

---

## Considerations for Implementation

*   **Context Management for Sub-Prompts:** The Prompt Engineering AI must be adept at creating sub-prompts that are self-contained enough or provide precise references, minimizing the need for the Module-Generating AI to re-process entire large documents for each micro-task. Summaries of previous steps are key.
*   **Orchestration Logic:** Determine how the flow between micro-tasks, automated checks, and feedback loops will be managed (e.g., via a master script, a dedicated orchestrator AI).
*   **`tflint` Ruleset Development:** This is a significant upfront investment but offers high returns in automated quality control. Start with rules for the most common or critical guideline violations.
*   **Feedback Granularity:** Ensure feedback to the AI after a failed check is specific enough for it to make targeted corrections.
