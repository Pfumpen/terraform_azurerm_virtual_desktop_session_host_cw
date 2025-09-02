locals {
  # --- Global Switches & Filters ---
  global_diagnostics_enabled = var.diagnostics_level != "none"

  # Filter for VM keys where diagnostics are explicitly enabled.
  vms_with_diagnostics_config = {
    for k, v in var.session_hosts : k => v if lookup(v, "diagnostics_enabled", false) == true
  }

  # --- Logic for Guest OS Diagnostics (Azure Monitor Agent) ---

  # Determines if the shared DCR needs to be created.
  create_shared_dcr = local.global_diagnostics_enabled

  # --- Presets for AMA Performance Counters ---
  perf_counters_presets = {
    "audit" = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\Available MBytes"],
    "all"   = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\Available MBytes", "\\LogicalDisk(_Total)\\% Free Space", "\\Network Interface(*)\\Bytes Total/sec"]
  }

  # --- Presets for AMA Windows Event Logs ---
  event_log_presets = {
    "audit" = ["System!*[System[(Level=1 or Level=2)]]", "Security!*", "Application!*[System[(Level=1 or Level=2)]]"],
    "all"   = ["System!*[System[(Level=1 or Level=2 or Level=3)]]", "Security!*", "Application!*[System[(Level=1 or Level=2 or Level=3)]]"]
  }

  # --- Logic to select the correct AMA configuration for the shared DCR ---
  selected_perf_counters = var.diagnostics_level == "custom" ? var.diagnostics_custom_perf_counters : lookup(local.perf_counters_presets, var.diagnostics_level, [])
  selected_event_logs    = var.diagnostics_level == "custom" ? var.diagnostics_custom_event_logs : lookup(local.event_log_presets, var.diagnostics_level, [])
}

#--------------------------------------------------------------------------
# Layer 1: Platform Diagnostics (Host-level metrics)
#--------------------------------------------------------------------------
data "azurerm_monitor_diagnostic_categories" "this" {
  for_each    = local.vms_with_diagnostics_config
  resource_id = azurerm_windows_virtual_machine.session_host[each.key].id
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = data.azurerm_monitor_diagnostic_categories.this

  name                           = "${var.session_hosts[each.key].name}-diag-settings"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  dynamic "enabled_log" {
    for_each = toset(
      var.diagnostics_level == "all" && contains(try(each.value.log_category_groups, []), "allLogs") ? ["allLogs"] : (
      var.diagnostics_level == "audit" && contains(try(each.value.log_category_groups, []), "audit") ? ["audit"] : [])
    )
    content { category_group = enabled_log.value }
  }

  dynamic "enabled_log" {
    for_each = toset(
      var.diagnostics_level == "custom" ? var.diagnostics_custom_logs : (
      var.diagnostics_level == "all" && !contains(try(each.value.log_category_groups, []), "allLogs") ? try(each.value.logs, []) : [])
    )
    content { category = enabled_log.value }
  }

  dynamic "metric" {
    for_each = toset(
      var.diagnostics_level == "custom" ? var.diagnostics_custom_metrics : (
      var.diagnostics_level != "none" ? try(each.value.metrics, []) : [])
    )
    content { category = metric.value }
  }
}

#--------------------------------------------------------------------------
# Layer 2: Guest OS Diagnostics (Azure Monitor Agent)
#--------------------------------------------------------------------------

resource "azurerm_monitor_data_collection_rule" "shared" {
  count = local.create_shared_dcr ? 1 : 0

  name                = "dcr-avd-session-hosts-${var.host_pool_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      workspace_resource_id = var.diagnostic_settings.log_analytics_workspace_id
      name                  = "la-destination"
    }
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = local.selected_perf_counters
      name                          = "perfCounters-source"
    }
    windows_event_log {
      streams        = ["Microsoft-WindowsEvent"]
      x_path_queries = local.selected_event_logs
      name           = "eventlog-source"
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-WindowsEvent"]
    destinations = ["la-destination"]
  }
}

resource "azurerm_virtual_machine_extension" "ama_agent" {
  for_each = local.vms_with_diagnostics_config

  name                       = "${azurerm_windows_virtual_machine.session_host[each.key].name}-AzureMonitorAgent"
  virtual_machine_id         = azurerm_windows_virtual_machine.session_host[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorWindowsAgent"
  type_handler_version       = "1.37.0"
  auto_upgrade_minor_version = true
}

resource "azurerm_monitor_data_collection_rule_association" "this" {
  for_each = local.vms_with_diagnostics_config

  name               = "${azurerm_windows_virtual_machine.session_host[each.key].name}-dcr-association"
  target_resource_id = azurerm_windows_virtual_machine.session_host[each.key].id

  data_collection_rule_id = try(each.value.data_collection_rule_id, null) != null ? each.value.data_collection_rule_id : azurerm_monitor_data_collection_rule.shared[0].id

  description = try(each.value.data_collection_rule_id, null) != null ? "Associates this Session Host with a custom-provided DCR." : "Associates this Session Host with the shared AVD DCR."
}
