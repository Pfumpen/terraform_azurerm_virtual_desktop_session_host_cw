
locals {
  diagnostics_presets = {
    basic = {
      logs    = ["AuditLogs"]
      metrics = ["AllMetrics"]
    },
    detailed = {
      logs    = ["AuditLogs", "Checkpoint", "Error", "Management", "Connection", "HostRegistration"]
      metrics = ["AllMetrics"]
    },
    custom = {
      logs    = var.diagnostics_custom_logs
      metrics = var.diagnostics_custom_metrics
    }
  }

  active_log_categories    = lookup(local.diagnostics_presets, var.diagnostics_level, { logs = [] }).logs
  active_metric_categories = lookup(local.diagnostics_presets, var.diagnostics_level, { metrics = [] }).metrics
  global_diagnostics_enabled = var.diagnostics_level != "none"
  filtered_session_hosts = {
    for k, v in azurerm_windows_virtual_machine.session_host : k => v if coalesce(try(var.session_hosts[k].diagnostics_enabled, null), true)
  }
}

resource "azurerm_monitor_diagnostic_setting" "session_host" {
  for_each = local.global_diagnostics_enabled ? local.filtered_session_hosts : {}

  name                           = "${each.value.name}-diagnostics"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  dynamic "enabled_log" {
    for_each = toset(local.active_log_categories)
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = toset(local.active_metric_categories)
    content {
      category = metric.value
    }
  }
}
