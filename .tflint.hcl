# This .tflint.hcl file is generated based on the Azure Terraform Module Code Guidelines.
# It aims to enforce as many guidelines as possible using standard tflint rules and the AzureRM ruleset.
# For full coverage of all guidelines, custom tflint plugins/rules (written in Go) might be necessary.

# General tflint configuration
config {
  # Automatically load plugins from the plugin cache or download them if they are not installed.
  autoinstall = true

  # Force all plugins to be the latest version.
  # Consider pinning to specific versions for stability in a CI/CD environment.
  force = true

  # Only report issues with a severity of "error" or "warning".
  # "notice" and "debug" issues are hidden.
  # severity = ["error", "warning"]

  # Enable module inspection. This allows tflint to inspect module blocks.
  # This is crucial for checking module source versions, etc.
  module = true

  # Variables can be passed to tflint, e.g., for conditional rule enablement.
  # Not used in this initial configuration.
  # variable "example_var" {
  #   type    = string
  #   default = "example_value"
  # }
}

# Plugin for AzureRM specific rules
# Guideline: General Azure best practices
plugin "azurerm" {
  enabled = true
  # version = "0.25.0" # Removed to allow force = true to manage the version
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
  # Configure specific AzureRM rules if needed, e.g.:
  # rule "azurerm_storage_account_secure_transfer_required" {
  #   enabled = true
  # }
}

# Standard Terraform rules provided by tflint core.
# Many of these align with the provided Azure Module Code Guidelines.

# Guideline 2.1: Variable Definitions (Clarity: description and type)
rule "terraform_variable_description" {
  enabled = true
  # severity = "error" # Default is error
}

rule "terraform_typed_variables" {
  enabled = true
  # severity = "error" # Default is error
}

# Guideline 2.6: Sensitive Input Variables
rule "terraform_sensitive_variables" {
  enabled  = true
  # severity = "warning" # Default is warning. Consider "error" for stricter enforcement.
  # This rule checks if variables commonly named like "password", "token", "secret" are marked sensitive.
  # It does not enforce that ALL sensitive variables are marked, as "sensitive" is context-dependent.
}

# Guideline 4.1: Output Documentation (Specificity and Descriptions)
rule "terraform_outputs_description" {
  enabled = true
  # severity = "error" # Default is error
}
# Note: Checking for *not* outputting entire resource objects (Guideline 4.1)
# would require a custom rule. Standard tflint cannot easily distinguish
# `value = azurerm_resource.main` from `value = azurerm_resource.main.id`.

# Guideline 5.5: Version Constraints (versions.tf)
rule "terraform_required_providers" {
  enabled = true
  # severity = "error" # Default is error
}

rule "terraform_required_version" {
  enabled = true
  # severity = "error" # Default is error
}

# Guideline 5.7: Tag Management
# This rule checks if resources that support tags are actually tagged.
# It does not enforce the specific `local.merged_tags` pattern from the guidelines.
# Enforcing that specific pattern would require a custom rule.
rule "terraform_tagged_resources" {
  enabled  = true
  severity = "warning" # Consider "error" if tags are mandatory.
  # You can specify a list of default tags that should be present,
  # but this doesn't fully cover the "merged_tags" concept.
  # default_tags = ["environment", "project"]
}

# Guideline 1.1: Module Structure (Required Files - partially covered)
# This rule checks for common Terraform files like main.tf, variables.tf, outputs.tf.
# It does not enforce the full directory structure including `examples/` as per the guidelines.
# Full enforcement of file/directory structure is beyond typical tflint capabilities.
rule "terraform_standard_module_structure" {
  enabled  = true
  severity = "warning"
}

# Guideline 5.6: Resource Protection and Lifecycle Management (prevent_destroy)
# This rule warns if `lifecycle.prevent_destroy` is used.
# The guidelines state "Use sparingly", so a warning is appropriate.
rule "terraform_lifecycle_prevent_destroy" {
  enabled  = true
  severity = "warning"
}

# Additional rules that might be useful based on general best practices
# often implied by comprehensive guidelines:

# Checks for unused declarations (variables, locals, outputs).
rule "terraform_unused_declarations" {
  enabled  = true
  severity = "warning"
}

# Checks for deprecated syntax.
rule "terraform_deprecated_syntax" {
  enabled = true
  # severity = "error" # Default is error
}

# Checks for invalid naming conventions (e.g. resource names).
# This is a generic rule; Azure-specific naming conventions are better
# handled by the azurerm plugin or custom rules if very specific.
rule "terraform_naming_convention" {
  enabled = false # Disabled by default as it's highly opinionated.
                  # Enable and configure if you have a strict naming scheme.
  # severity = "warning"
  # format = "snake_case" # or "camel_case", "pascal_case", "kebab_case"
}

# --- Areas for Potential Custom Rules (Beyond Standard tflint Capabilities) ---
# The following guidelines are difficult to enforce with standard tflint rulesets
# and would likely require custom Go plugins:

# 1.2 Resource-Oriented File Separation:
#    - Enforcing specific file names based on resource types.

# 1.3 Telemetry and Monitoring (Diagnostic Settings):
#    - Ensuring `azurerm_monitor_diagnostic_setting` does NOT create its own target resources.
#    - Validating specific log/metric categories are configured.

# 2.2 Complex Variable Types (Objects and Maps) & 2.3 Variable Validation:
#    - Enforcing the *style* of validation splitting for complex types.
#    - Deep validation of specific attribute patterns within complex objects beyond basic type checks.

# 3.2 Dynamic Blocks:
#    - Enforcing the use of `try()` within dynamic block content for optional attributes.

# 4.1 Output Documentation (Specificity):
#    - Preventing output of entire resource objects (e.g., `value = azurerm_storage_account.main`).

# 4.2 README.md Structure:
#    - tflint does not lint non-Terraform files like README.md.

# 5.1 Managed Identities, 5.2 RBAC, 5.3 Private Endpoints, 5.4 CMK:
#    - While the azurerm plugin might cover some aspects, enforcing the exact
#      variable structures (`var.managed_identity`, `var.role_assignments`, etc.)
#      as defined in the guidelines would need custom rules.

# 5.7 Tag Management (Specific Pattern):
#    - Enforcing the exact `local.merged_tags` pattern.

# 6.1 Example Configurations:
#    - Ensuring the existence and content structure of `examples/basic` and `examples/complete`.

# --- End of .tflint.hcl ---
