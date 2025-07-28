variable "session_hosts" {
  description = "A map of objects where each key is a unique logical name for a session host. Each object defines the configuration for a single session host VM."
  type = map(object({
    name = string
    size = string
    zone = optional(string)
    network_interface = object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string
      private_ip_address            = optional(string)
    })
    os_disk = object({
      caching              = string
      storage_account_type = string
    })
    image_key              = optional(string)
    source_image_reference = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }))
    admin_username      = string
    diagnostics_enabled = optional(bool)
  }))
  nullable = false

  validation {
    condition = alltrue([
      for k, v in var.session_hosts :
      v.network_interface.private_ip_address_allocation == "Static" ? v.network_interface.private_ip_address != null : true
    ])
    error_message = "The 'private_ip_address' attribute is required when 'private_ip_address_allocation' is 'Static'."
  }

  validation {
    condition = alltrue([
      for k, v in var.session_hosts :
      (v.image_key != null && v.source_image_reference == null) || (v.image_key == null && v.source_image_reference != null)
    ])
    error_message = "For each session host, you must specify either 'image_key' or 'source_image_reference', but not both."
  }

  validation {
    condition = alltrue([
      for k, v in var.session_hosts :
      v.image_key != null ? can(local.avd_images[v.image_key]) : true
    ])
    error_message = "The specified 'image_key' does not exist in the available AVD images map. Please refer to the module's README for a list of valid keys."
  }
}

variable "resource_group_name" {
  description = "The name of the resource group where the resources will be created."
  type        = string
  nullable    = false
}

variable "location" {
  description = "The Azure region where the resources will be created."
  type        = string
  nullable    = false
}

variable "avd_registration_token" {
  description = "The registration token from the AVD Host Pool, required to register the session host."
  type        = string
  sensitive   = true
  nullable    = false
}

variable "host_pool_name" {
  description = "The name of the AVD Host Pool."
  type        = string
  nullable    = false
}

variable "domain_join" {
  description = "Configuration for joining the session hosts to an Active Directory domain. If not provided, the session hosts will not be joined to a domain."
  type = object({
    name                         = string
    user                         = string
    password_key_vault_secret_id = string
  })
  default  = null
  nullable = true
}

variable "admin_password_key_vault_id" {
  description = "The resource ID of the Azure Key Vault where the generated admin passwords for the session hosts will be stored as secrets."
  type        = string
  nullable    = false
}

variable "password_generation_config" {
  description = "Configuration for generating random passwords for the session host administrators."
  type = object({
    length           = optional(number, 32)
    special          = optional(bool, true)
    override_special = optional(string, "!@#$%^&*()-_=+[]{}<>:?")
  })
  default  = {}
  nullable = false
}

variable "tags" {
  description = "A map of tags to apply to all created resources."
  type        = map(string)
  default     = {}
}

variable "diagnostics_level" {
  description = "Defines the detail level for diagnostics. Possible values: 'none', 'basic', 'detailed', 'custom'. 'none' disables diagnostics."
  type        = string
  default     = "basic"
  validation {
    condition     = contains(["none", "basic", "detailed", "custom"], var.diagnostics_level)
    error_message = "Valid values for diagnostics_level are 'none', 'basic', 'detailed', or 'custom'."
  }
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace to send diagnostics to. Required if diagnostics_level is not 'none'."
  type        = string
  default     = null
}

variable "diagnostics_custom_logs" {
  description = "A list of log categories to enable when diagnostics_level is 'custom'."
  type        = list(string)
  default     = []
}

variable "diagnostics_custom_metrics" {
  description = "A list of metric categories to enable when diagnostics_level is 'custom'. Use ['AllMetrics'] for all."
  type        = list(string)
  default     = []
}

variable "managed_identity" {
  description = "Configuration for the Managed Identity of the virtual machine."
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = !(var.managed_identity.system_assigned && length(var.managed_identity.user_assigned_resource_ids) > 0)
    error_message = "A virtual machine can have either a System Assigned identity or User Assigned identities, but not both."
  }
}

variable "role_assignments" {
  description = "A map of role assignments to create on the session host virtual machines. The key is a descriptive name for the assignment."
  type = map(object({
    role_definition_id_or_name = string
    principal_id               = string
    principal_type             = optional(string)
    description                = optional(string)
    condition                  = optional(string)
    condition_version          = optional(string)
  }))
  default = {}
}
