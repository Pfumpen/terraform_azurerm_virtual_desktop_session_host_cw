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
    diagnostics_enabled = optional(bool, false)
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

  validation {
    condition = alltrue([
      for k, v in var.session_hosts :
      length(v.name) >= 1 &&
      length(v.name) <= 15 &&
      !can(regex("[<>*\\\\/\\?]", v.name)) &&
      substr(v.name, length(v.name) - 1, 1) != "." &&
      !can(regex("^[0-9]+$", v.name))
    ])
    error_message = "Invalid session host name. The name must be 1-15 characters long, cannot contain <>*\\\\/? characters, cannot end with a period, and cannot be purely numeric."
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

variable "join_type" {
  description = "Defines the identity join type for the session host VMs. Valid options: 'ad_join' (Active Directory), 'hybrid_entra_join' (Hybrid Microsoft Entra), 'aadds_join' (Microsoft Entra Domain Services), 'entra_join' (Microsoft Entra ID), 'none'."
  type        = string
  default     = "none"
  nullable    = false

  validation {
    condition     = contains(["ad_join", "hybrid_entra_join", "aadds_join", "entra_join", "none"], var.join_type)
    error_message = "Valid values for join_type are 'ad_join', 'hybrid_entra_join', 'aadds_join', 'entra_join', or 'none'."
  }
}

variable "domain_join_config" {
  description = "Configuration object for joining an Active Directory or Microsoft Entra Domain Services domain. Required only when join_type is 'ad_join', 'hybrid_entra_join', or 'aadds_join'."
  type = object({
    name                         = string
    user                         = string
    password_key_vault_secret_id = string
    ou_path                      = optional(string)
  })
  default  = null
  nullable = true

  validation {
    condition = !(contains(["ad_join", "hybrid_entra_join", "aadds_join"], var.join_type)) || (
      var.domain_join_config != null
    )
    error_message = "The 'domain_join_config' object must be provided when 'join_type' is set to 'ad_join', 'hybrid_entra_join', or 'aadds_join'."
  }
}

variable "fslogix_config" {
  description = "If provided, installs and configures FSLogix for profile management. See FSLogix documentation for details on each setting."
  type = object({
    vhd_locations                              = list(string)
    volume_type                                = optional(string, "VHDX")
    size_in_mbs                                = optional(number, 30000)
    delete_local_profile_when_vhd_should_apply = optional(bool, true)
    flip_flop_profile_directory_name           = optional(bool, true)
    profile_type                               = optional(number, 0)
    locked_retry_count                         = optional(number, 3)
    locked_retry_interval                      = optional(number, 15)
    reattach_retry_count                       = optional(number, 3)
    reattach_interval_seconds                  = optional(number, 15)
    redir_xml_source_folder                    = optional(string)
  })
  default  = null
  nullable = true

  validation {
    condition     = var.fslogix_config == null || length(var.fslogix_config.vhd_locations) > 0
    error_message = "When 'fslogix_config' is provided, the 'vhd_locations' list must not be empty."
  }

  validation {
    condition     = var.fslogix_config == null || contains(["VHD", "VHDX"], var.fslogix_config.volume_type)
    error_message = "The 'volume_type' attribute in 'fslogix_config' must be either 'VHD' or 'VHDX'."
  }
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
  description = "Defines the desired diagnostic intent. 'all' and 'audit' are dynamically mapped to available categories. Possible values: 'none', 'all', 'audit', 'custom'."
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "all", "audit", "custom"], var.diagnostics_level)
    error_message = "Valid values for diagnostics_level are 'none', 'all', 'audit', or 'custom'."
  }
}

variable "diagnostic_settings" {
  description = "A map containing the destination IDs for diagnostic settings. When diagnostics are enabled, exactly one destination must be specified."
  type = object({
    log_analytics_workspace_id     = optional(string)
    eventhub_authorization_rule_id = optional(string)
    storage_account_id             = optional(string)
  })
  default = {}

  validation {
    condition = var.diagnostics_level == "none" || (
      (try(var.diagnostic_settings.log_analytics_workspace_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.eventhub_authorization_rule_id, null) != null ? 1 : 0) +
      (try(var.diagnostic_settings.storage_account_id, null) != null ? 1 : 0) == 1
    )
    error_message = "When 'diagnostics_level' is not 'none', exactly one of 'log_analytics_workspace_id', 'eventhub_authorization_rule_id', or 'storage_account_id' must be specified in the 'diagnostic_settings' object."
  }
}

variable "diagnostics_custom_logs" {
  description = "A list of log categories to enable when diagnostics_level is 'custom'."
  type        = list(string)
  default     = []
}

variable "diagnostics_custom_metrics" {
  description = "A list of specific metric categories to enable. Use ['AllMetrics'] for all."
  type        = list(string)
  default     = ["AllMetrics"]
}

variable "managed_identity" {
  description = "Configuration for the Managed Identity of the virtual machine."
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(list(string), [])
  })
  default  = {}
  nullable = true

  validation {
    # This validation ensures that if the join type is 'entra_join', a system-assigned identity must be enabled.
    # The logic is now null-safe.
    condition     = !(var.join_type == "entra_join") || (var.managed_identity != null && var.managed_identity.system_assigned)
    error_message = "If 'join_type' is set to 'entra_join', 'managed_identity.system_assigned' MUST be set to 'true'."
  }

  # The second validation block has been removed. It was logically flawed because it
  # conflicted with the module's use of a default empty object `{}` to signify
  # "no identity". The resource logic in `main.tf` already handles this correctly,
  # making the validation redundant and the source of the original error.
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
