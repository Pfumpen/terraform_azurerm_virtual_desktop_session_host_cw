````markdown
# Cline Workflow: Azure Terraform Module Orchestrator

This workflow guides Cline (acting as the orchestrator, prompt engineer, and module generator) through the process of creating a new Azure Terraform module. It is based on the "Revised Workflow: Azure Terraform Module Generation with Micro-Tasks" and "Azure Terraform Module Code Guidelines (AI-Optimized)".

## Workflow Parameters

You will be prompted for the following parameters when this workflow starts:

1.  `module_name_pascal_case`: The name of the module in PascalCase (e.g., "StorageAccount", "KubernetesCluster"). This will be used for generating descriptive names and comments.
2.  `module_name_snake_case`: The name of the module in snake_case (e.g., "storage_account", "kubernetes_cluster"). This is often used for file or resource naming.
3.  `module_output_directory`: The directory where the generated module will be saved (e.g., `./generated_modules/terraform-azurerm-storage-account`). This path is relative to the current working directory.
4.  `primary_azure_resource_type_description`: A descriptive name for the main Azure resource type the module will manage (e.g., "Azure Storage Account", "Azure SQL Server"). Used for documentation and prompts.
5.  `primary_azurerm_resources_list`: A comma-separated list of the primary AzureRM Terraform resource types to be included in the module (e.g., "azurerm_storage_account, azurerm_storage_container").
6.  `key_features_list`: A comma-separated list of key functionalities or features the module should support (e.g., "private endpoints, customer-managed keys, diagnostic settings").
7.  `azure_rm_docs_snippets_paths`: (Optional) A comma-separated list of paths to any pre-collected AzureRM Registry documentation snippets relevant to the primary resources. Leave empty if not applicable.
8.  `terraform_version_constraint`: The required Terraform version constraint (e.g., ">= 1.1.0").
9.  `azurerm_provider_version_constraint`: The AzureRM provider version constraint (e.g., ">= 3.0.0").
10. `random_provider_version_constraint`: The Random provider version constraint (e.g., "~> 3.5"). (And other providers if needed)

---

## Phase 0: Preparation & Design

### Step 0.1: Initialize Module Directory Structure

Create the necessary directory structure for the new module.

```xml
<execute_command>
<command>New-Item -Path '{{module_output_directory}}/examples/basic' -ItemType Directory -Force; New-Item -Path '{{module_output_directory}}/examples/complete' -ItemType Directory -Force; New-Item -Path '{{module_output_directory}}/.cline_artifacts/prompts' -ItemType Directory -Force</command>
<requires_approval>false</requires_approval>
</execute_command>
````

*(Cline: This command creates the main module directory, `examples/basic`, `examples/complete` subdirectories, and a `.cline_artifacts/prompts` directory for storing generated prompt files. PowerShell's `New-Item -Force` creates parent directories if they don't exist.)*

### Step 0.2: Generate Module Design Document (MDD) and Detailed Sub-Prompt Files (AI Call 1)

__Cline (You), act as the Prompt Engineering AI.__ Based on the workflow parameters provided by the user and the content of `docs/Azure_Terraform_Module_Code_Guidelines_Ai_Optimized.md` and any provided AzureRM Registry documentation snippets:

1. __Analyze Requirements:__ Understand the core resource(s) and desired functionalities.
2. __Consult Guidelines & Registry Docs:__ Thoroughly review the coding guidelines and relevant parts of the AzureRM provider documentation.
3. __Deconstruct into Files:__ Determine all necessary `.tf` files (e.g., `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, and any resource-specific files like `storage_container.tf` or `private_endpoint.tf`). Also plan for `README.md` and the standard `examples/` structure.
4. __Define Variables:__ For each planned `.tf` file that will contain resources, identify and detail all necessary input variables. For each variable, determine its name, `type` (including full object structures), `description`, `default` value (if any), `nullable` status, `sensitive` status, `ephemeral` status, and all specific `validation` rules (regex, ranges, allowed values, etc.).
5. __Define Outputs:__ Identify and detail all key outputs the module should expose, following Guideline 4.1 (specific attributes, descriptions, sensitivity).
6. __Outline Resource Logic:__ For `main.tf` and other resource-specific `.tf` files, sketch out the primary resources, their arguments, any `dynamic` blocks, `for_each` loops, and `lifecycle` configurations.
7. __Plan README Structure:__ Outline all sections for the `README.md` as per Guideline 4.2.
8. __Plan Examples:__ Define the scope and content for `examples/basic/main.tf` (and its `variables.tf` if needed) and `examples/complete/main.tf` (and its `variables.tf` if needed).

__Output (Generated Artifacts):__ You will generate the content for and **write out** the following files:
    1.  **Main Module Design Document (MDD):** Saved to `{{module_output_directory}}/.cline_artifacts/module_design_document.md`. This file will contain the overall plan, list of all files to be generated, high-level design decisions, variable and output summaries, etc.
        ```xml
        <write_to_file>
        <path>{{module_output_directory}}/.cline_artifacts/module_design_document.md</path>
        <content>
        # Module Design Document: {{module_name_pascal_case}}
        
        ## Overview
        ... (Overall plan, primary resources: {{primary_azurerm_resources_list}}, key features: {{key_features_list}}) ...
        
        ## Files to be Generated
        - versions.tf
        - variables.tf
        - main.tf
        - outputs.tf
        - README.md
        - examples/basic/main.tf
        - examples/basic/variables.tf
        - examples/complete/main.tf
        - examples/complete/variables.tf
        {{#if auxiliary_files_planned}}
        {{#each auxiliary_file_list}}
        - {{this}}
        {{/each}}
        {{/if}}
        
        ## Variable Definitions
        ... (Summary of all variables, types, descriptions, defaults, validations) ...
        
        ## Output Definitions
        ... (Summary of all outputs, descriptions) ...
        
        ## Resource Logic Outline
        ... (High-level logic for main.tf and auxiliary files) ...
        
        ## README Structure
        ... (Outline of README sections) ...
        
        ## Example Plans
        ... (Scope for basic and complete examples) ...
        </content>
        </write_to_file>
        ```
    2.  **Individual Sub-Prompt Files:** For *each* module file to be generated, a dedicated Markdown file containing its specific, detailed generation prompt will be created. These will be saved in `{{module_output_directory}}/.cline_artifacts/prompts/`. These prompts will be fully fleshed out, incorporating all details derived from this analysis and the templates in `templates/ai/sub_prompts/`.
        *   Example for `versions.tf_prompt.md`:
            ```xml
            <write_to_file>
            <path>{{module_output_directory}}/.cline_artifacts/prompts/versions_tf_prompt.md</path>
            <content>
            # Sub-Prompt: Generate versions.tf for {{module_name_pascal_case}} Module

            Based on the Module Design Document and the `generate_versions_tf.md` template, generate the `versions.tf` file.

            **Workflow Parameters to use:**
            - Terraform Version Constraint: `{{terraform_version_constraint}}`
            - AzureRM Provider Version Constraint: `{{azurerm_provider_version_constraint}}`
            - Random Provider Version Constraint: `{{random_provider_version_constraint}}`
            (Include other providers if specified in parameters)

            **Content Requirements:**
            - Include a `terraform` block with the `required_version` set to `{{terraform_version_constraint}}`.
            - Include a `required_providers` block specifying `azurerm` (source: `hashicorp/azurerm`, version: `{{azurerm_provider_version_constraint}}`) and `random` (source: `hashicorp/random`, version: `{{random_provider_version_constraint}}`).
            - Ensure all provider blocks are correctly formatted.
            </content>
            </write_to_file>
            ```
        *   *(Cline: You will generate similar `<write_to_file>` calls for all other prompt files, e.g., `variables_tf_prompt.md`, `main_tf_core_resource_prompt.md`, `readme_md_prompt.md`, etc., filling them with detailed instructions based on your MDD and the sub-prompt templates.)*

```xml
<ask_followup_question>
<question>I have generated the Module Design Document (MDD) into '{{module_output_directory}}/.cline_artifacts/module_design_document.md' and all necessary individual sub-prompt files into '{{module_output_directory}}/.cline_artifacts/prompts/'. Shall I proceed to Phase 1: Iterative Module Generation using these artifacts?</question>
<options>["Yes, proceed to Phase 1", "No, I need to adjust parameters (restart workflow)"]</options>
</ask_followup_question>
```

---

## Phase 1: Iterative Module Generation & Automated Checks

__Cline (You), now act as the Module-Generating AI for each file, and Orchestrator for validation. Each micro-task below represents a separate, independent AI call. For each call, you will use a dedicated, pre-filled prompt file that was generated in Phase 0.__

For each file in the following micro-tasks:

1. __Load and Review Prompt:__ Read the content of the specific, pre-filled prompt file for the current target module file from the `{{module_output_directory}}/.cline_artifacts/prompts/` directory.
2. __Generate Content:__ Generate the complete HCL or Markdown content for the file based *solely* on the instructions within this loaded prompt file.
3. Use the `<write_to_file>` tool to save the generated content to the correct path within `{{module_output_directory}}`.
4. Use `<execute_command>` to run validation tools (`terraform fmt -check -recursive`, `terraform validate`, `tflint`).
5. If validation fails, analyze the errors, revise the content based on the loaded prompt file and the errors, and repeat the write and validate steps for that file.

### Micro-Task 1: Generate `versions.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/versions_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/versions.tf</path>
   <content>
   # Cline: Paste generated versions.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}} &amp;&amp; terraform fmt -check -recursive</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If formatting issues, regenerate content and retry. `terraform validate` and `tflint` are not typically run on `versions.tf` alone.)*

### Micro-Task 2: Generate `variables.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/variables_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/variables.tf</path>
   <content>
   # Cline: Paste generated variables.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}} &amp;&amp; terraform fmt -check -recursive &amp;&amp; tflint --config=../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content and retry. `terraform validate` might be too early here.)*

### Micro-Task 3: Generate `main.tf` (Core Resource(s))

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/main_tf_core_resource_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/main.tf</path>
   <content>
   # Cline: Paste generated main.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}} &amp;&amp; terraform fmt -check -recursive &amp;&amp; terraform validate &amp;&amp; tflint --config=../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content and retry.)*

### Micro-Task 4: Generate Auxiliary Resource `.tf` Files (If Any)

__Cline (You):__ Consult your MDD. Identify all auxiliary resource files (e.g., `containers.tf`, `network_rules.tf`, `private_endpoints.tf`, `diagnostic_settings.tf`) that need to be generated.

```xml
<ask_followup_question>
<question>Based on your MDD, please list the filenames for all auxiliary .tf files that need to be generated (comma-separated, e.g., "containers.tf,network_rules.tf"), or type "none" if no auxiliary files are planned.</question>
</ask_followup_question>
```

*(Cline: You will respond with the list of filenames. The workflow will then conceptually loop through each one. For this workflow, we will handle one explicitly named by you, and you can re-trigger this section if more are needed or adapt it.)*

Let's assume you provided `{{aux_file_name_1}}`. If more, you'll repeat these steps.

__For `{{aux_file_name_1}}` (if not "none"):__

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/{{aux_file_name_1}}_prompt.md`. (Ensure Phase 0 generated a `{{aux_file_name_1}}_prompt.md` for each auxiliary file).

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/{{aux_file_name_1}}</path>
   <content>
   # Cline: Paste generated {{aux_file_name_1}} content here
   </content>
   </write_to_file>
   ```

3. __Validate:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}} &amp;&amp; terraform fmt -check -recursive &amp;&amp; terraform validate &amp;&amp; tflint --config=../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content for `{{aux_file_name_1}}` and retry.)* *(Repeat for any other auxiliary files identified from your MDD by re-invoking a similar process or by you handling them sequentially now.)*

### Micro-Task 5: Generate `outputs.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/outputs_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/outputs.tf</path>
   <content>
   # Cline: Paste generated outputs.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}} &amp;&amp; terraform fmt -check -recursive &amp;&amp; terraform validate &amp;&amp; tflint --config=../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content and retry.)*

---

## Phase 2: Integration, Comprehensive Review & Testing

__Cline (You), continue to act as the Module-Generating AI for each file, and Orchestrator for validation. Each micro-task below represents a separate, independent AI call using a dedicated, pre-filled prompt file from Phase 0.__

### Micro-Task 6: Generate `README.md`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/readme_md_prompt.md`. (This prompt may instruct to reference already generated `.tf` files for content like inputs/outputs).

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/README.md</path>
   <content>
   # Cline: Paste generated README.md content here
   </content>
   </write_to_file>
   ```

   *(Cline: Markdown validation is typically manual or uses linters not covered by default Terraform tools.)*

### Micro-Task 7: Generate `examples/basic/variables.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/examples_basic_variables_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/examples/basic/variables.tf</path>
   <content>
   # Cline: Paste generated examples/basic/variables.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate (Syntax Only):__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/basic &amp;&amp; terraform fmt -check -recursive</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

### Micro-Task 8: Generate `examples/basic/main.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/examples_basic_main_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/examples/basic/main.tf</path>
   <content>
   # Cline: Paste generated examples/basic/main.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate Basic Example:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/basic &amp;&amp; terraform fmt -check -recursive &amp;&amp; terraform init -backend=false &amp;&amp; terraform validate &amp;&amp; tflint --config=../../../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content for basic example files and retry.)*

### Micro-Task 9: Generate `examples/complete/variables.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/examples_complete_variables_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/examples/complete/variables.tf</path>
   <content>
   # Cline: Paste generated examples/complete/variables.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate (Syntax Only):__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/complete &amp;&amp; terraform fmt -check -recursive</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

### Micro-Task 10: Generate `examples/complete/main.tf`

1. __Generate Content:__ Based on the content of the specific prompt file: `{{module_output_directory}}/.cline_artifacts/prompts/examples_complete_main_tf_prompt.md`.

2. __Write File:__

   ```xml
   <write_to_file>
   <path>{{module_output_directory}}/examples/complete/main.tf</path>
   <content>
   # Cline: Paste generated examples/complete/main.tf content here
   </content>
   </write_to_file>
   ```

3. __Validate Complete Example:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/complete &amp;&amp; terraform fmt -check -recursive &amp;&amp; terraform init -backend=false &amp;&amp; terraform validate &amp;&amp; tflint --config=../../../.tflint.hcl .</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: If issues, regenerate content for complete example files and retry.)*

### Step 2.3: Comprehensive Module Review (Optional AI Call)

__Cline (You):__ Perform a comprehensive review of the fully generated module located in `{{module_output_directory}}`.
This can be an optional, distinct AI call.
**Input for AI Review Call:**
- All generated module files in `{{module_output_directory}}`.
- The main Module Design Document: `{{module_output_directory}}/.cline_artifacts/module_design_document.md`.
- The refinement guidelines: `templates/ai/Azure_Module_Refinement.md`.
**AI Action:** Analyze the module against the refinement guidelines and the original design intent (from MDD). Report any discrepancies, suggest improvements, or identify areas requiring manual attention.

*(Cline: If corrections are needed based on this review, you would typically re-run parts of Phase 1 for specific files (using their existing prompt files) or use `<replace_in_file>` for minor targeted edits. For this workflow, note any required changes.)*

```xml
<ask_followup_question>
<question>Comprehensive review step: Have you identified any changes needed after reviewing against 'templates/ai/Azure_Module_Refinement.md'?</question>
<options>["No, module looks good", "Yes, minor changes needed (I'll handle manually or restart parts)", "Yes, major changes needed (consider restarting workflow)"]</options>
</ask_followup_question>
```

### Step 2.4: Final Validation & Functional Testing

1. __Basic Example - Plan:__

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/basic &amp;&amp; terraform plan -out=tfplan.out</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: Review the plan output for correctness.)*

2. __Basic Example - Apply & Destroy (User Confirmation):__

   ```xml
   <ask_followup_question>
   <question>The 'basic' example plan for module '{{module_name_pascal_case}}' has been generated and saved to 'tfplan.out'. Would you like to APPLY and then DESTROY these resources for a functional test? (Requires Azure credentials to be configured)</question>
   <options>["Yes, apply and destroy basic example", "No, skip functional test for basic example"]</options>
   </ask_followup_question>
   ```

   *(Cline: If user selects "Yes..." and the previous plan was successful):*

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/basic &amp;&amp; terraform apply -auto-approve tfplan.out &amp;&amp; terraform destroy -auto-approve</command>
   <requires_approval>true</requires_approval>
   </execute_command>
   ```

3. __Complete Example - Plan:__ The `complete` example often uses placeholders like `"REPLACE_WITH_YOUR_VALUE"`. A direct `terraform plan` might fail if these placeholders are for required attributes or are not valid values.

   ```xml
   <ask_followup_question>
   <question>The 'complete' example (in '{{module_output_directory}}/examples/complete/') likely contains placeholders. Attempting a 'terraform plan' might require you to first create a 'terraform.tfvars' file in that directory with actual values, or it might fail. Do you want to attempt to run 'terraform plan' for the complete example?</question>
   <options>["Yes, attempt to plan complete example", "No, skip complete example plan"]</options>
   </ask_followup_question>
   ```

   *(Cline: If user selects "Yes..." ):*

   ```xml
   <execute_command>
   <command>cd {{module_output_directory}}/examples/complete &amp;&amp; terraform plan -out=tfplan.out</command>
   <requires_approval>false</requires_approval>
   </execute_command>
   ```

   *(Cline: Review plan output. Applying/destroying the complete example is usually done manually after replacing placeholders.)*

---

## Workflow Completion

The Azure Terraform module generation process, guided by this workflow, is now complete. The generated module is located in: `{{module_output_directory}}`. Please review all generated files, console outputs, and test results thoroughly.
