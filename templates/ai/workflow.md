# Workflow: Creating Azure Terraform Modules

This document outlines the standardized workflow for generating new Azure Terraform modules using the provided templates, guidelines, and AI assistance.

## Steps

1.  **Initialize Repository:**
    *   Use the "Module Generator Template" repository as a base for the new module's GitHub repository. Clone or create a new repository based on this template structure.

2.  **Prepare Contextual Documentation:**
    *   Identify the specific Azure module to be created (e.g., Azure Storage Account, Azure SQL Server).
    *   Navigate the `Terraform Registry Docs/` directory structure to find the subfolder corresponding to the target module.
    *   Copy the relevant `.html.markdown` files (Terraform Registry documentation snippets) for the primary AzureRM resources used in this module.
    *   **Crucially:** Delete the rest of the `Terraform Registry Docs/` directory and its contents from your new module repository to keep it focused solely on the necessary documentation for the current module.

3.  **Initiate AI Prompt Generation:**
    *   The user takes the `templates/ai/First Prompt Generating Massage.md` file.
    *   The user replaces the placeholders `{Module Name}` and `{Liste der primären AzureRM Ressourcen für dieses Modul...}` with the specific details for the target module.
    *   The user provides this *completed* "First Prompt Generating Massage" (containing the target module name and resource list) to a Prompt Engineering AI (like Cline).
    *   The Prompt Engineering AI then performs the analysis described in the "First Prompt Generating Massage" (analyzing Registry Docs for the specified resources, applying the Azure Code Guidelines).
    *   Based on this analysis, the Prompt Engineering AI generates the **final, detailed prompt** by filling out *all* sections of the `templates/ai/terraform_module_ai_prompt_template.md` with the derived requirements (functions, variables with validation details, outputs, examples, file structure, guideline summaries, etc.). This final prompt is what will be used in the next step.

4.  **AI Module Generation:**
    *   Submit the completed, detailed prompt (generated in Step 3 by the Prompt Engineering AI) to the designated module-generating AI model.
    *   The AI will generate the initial Terraform module code, including `.tf` files, `README.md`, and `examples/`.

5.  **AI Module Refinement & Review:**
    *   Use the checklist provided in `templates/ai/Azure_Module_refinement.md` to conduct a thorough review.
    *   Provide the AI-generated module code, the original detailed prompt used for generation (from Step 3), and the `docs/Azure_Terraform_Module_Guidelines.md` to a reviewing AI model (or perform a manual review following the template).
    *   The review must verify strict compliance with *all* aspects of the guidelines and the original prompt requirements (structure, naming, variable validation, documentation format for complex types, best practices like diagnostics, RBAC, private endpoints, etc.).
    *   Document any deviations, inconsistencies, or areas for improvement using the structure defined in the refinement template.

6.  **Implement Corrections:**
    *   Apply all necessary fixes and improvements identified during the refinement step (Step 5) to the module code.
    *   If significant changes were made, consider re-running the refinement/review process.

7.  **Syntax Validation:**
    *   Navigate to the module's root directory in your terminal.
    *   Run the command `terraform validate`.
    *   Address any syntax errors reported by Terraform.

8.  **Functional Testing & Deployment:**
    *   Configure your Azure credentials for a suitable test environment.
    *   Navigate to each directory within `examples/`.
    *   For each example, run `terraform init`, `terraform plan`, and `terraform apply` to deploy the resources.
    *   Thoroughly test the deployed infrastructure:
        *   Verify resource creation and configuration.
        *   Test different variable inputs defined in the examples.
        *   Check for any logical errors or unexpected behavior.
        *   Ensure features like Private Endpoints, RBAC, etc., function as expected.
    *   Identify and fix any functional or logical errors discovered in the module code.
    *   Run `terraform destroy` for each example after testing.

9.  **Finalization:**
    *   Once the module passes all validation and functional tests, commit the final code to the repository.
    *   The module is now ready for use or publishing.
