# Terraform Azure Module Generator Template

## Purpose

This repository serves as a **template and workflow definition** for generating standardized Terraform modules for various Azure resources. It leverages a structured, AI-assisted process to ensure that generated modules adhere to strict coding guidelines, best practices, and documentation standards.

The goal is to streamline the creation of high-quality, consistent, and maintainable Azure Terraform modules by combining predefined templates, comprehensive guidelines, and AI capabilities for code generation and refinement.

## How to Use as a Template

This repository is not a module itself but a **starter kit** for creating new Azure Terraform modules. The process involves using the provided guidelines and AI prompt templates to generate the actual module code.

The workflow is detailed in `templates/ai/workflow.md` and involves the following key steps:

1.  **Initialize:** Use this repository as a template on GitHub to create a new repository for your specific Azure module (e.g., `terraform-azurerm-storage-account`).
2.  **Prepare Context:** Gather the relevant Terraform Registry documentation snippets for the primary AzureRM resources your module will manage and place them in the (initially cleaned) `Terraform Registry Docs/` directory within your new repository.
3.  **Generate Detailed Prompt:**
    *   Use the `templates/ai/First_Prompt_Generating_Message.md` to instruct a Prompt Engineering AI.
    *   This AI analyzes the `docs/Azure_Terraform_Module_Code_Guidelines.md`, the gathered Terraform Registry documentation, and the target module requirements.
    *   The AI then generates a detailed, structured prompt by filling out the `templates/ai/terraform_module_ai_prompt_template.md`.
4.  **AI Module Generation:** Submit the detailed prompt (from step 3) to a suitable code-generating AI model to create the initial Terraform module files (`.tf`, `README.md`, `examples/`).
5.  **AI Refinement & Review:** Use the checklist in `templates/ai/Azure_Module_Refinement.md` along with the guidelines and the original prompt to have a reviewing AI (or perform a manual review) meticulously check the generated code for compliance and quality.
6.  **Implement Corrections:** Apply any necessary fixes identified during the review.
7.  **Validate & Test:** Run `terraform validate` and perform thorough functional testing using the `examples/` provided or created for the module.
8.  **Finalize:** Commit the validated and tested module code to your repository.

## Key Components

*   **`docs/`**:
    *   `Azure_Terraform_Module_Code_Guidelines.md`: The comprehensive set of rules and best practices that generated modules must follow.
*   **`templates/ai/`**: Contains the core templates driving the AI workflow:
    *   `workflow.md`: The detailed step-by-step generation process.
    *   `First_Prompt_Generating_Message.md`: Meta-prompt for initiating the detailed prompt generation.
    *   `terraform_module_ai_prompt_template.md`: The structure for the detailed prompt fed to the code generation AI.
    *   `Azure_Module_Refinement.md`: Checklist and template for the review phase.
*   **`templates/module/`**: Basic file structures or examples for a module (e.g., test file examples).
*   **`templates/pipeline/`**: Example CI/CD pipeline configuration for testing.
*   **`Terraform Registry Docs/`**: Contains *examples* of Terraform Registry documentation snippets used as context during generation. When using this template, this directory should be cleaned and populated only with the docs relevant to the specific module being generated.

By following the defined workflow and utilizing the provided templates and guidelines, you can efficiently generate robust and standardized Azure Terraform modules.
