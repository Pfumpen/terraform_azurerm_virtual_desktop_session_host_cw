# In diagnostics.tf

locals {
  global_diagnostics_enabled = var.diagnostics_level != "none"

  # Filter the resources that should have diagnostics enabled based on the per-resource flag.
  resources_with_diagnostics = {
    for k, v in var.session_hosts : k => azurerm_windows_virtual_machine.session_host[k].id if v.diagnostics_enabled
  }
}

# Fetch available diagnostic categories FOR EACH resource where diagnostics are enabled.
data "azurerm_monitor_diagnostic_categories" "this" {
  for_each = local.global_diagnostics_enabled ? local.resources_with_diagnostics : {}
  resource_id = each.value
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = data.azurerm_monitor_diagnostic_categories.this

  name                           = "${var.session_hosts[each.key].name}-diagnostics"
  target_resource_id             = each.value.id
  log_analytics_workspace_id     = try(var.diagnostic_settings.log_analytics_workspace_id, null)
  eventhub_authorization_rule_id = try(var.diagnostic_settings.eventhub_authorization_rule_id, null)
  storage_account_id             = try(var.diagnostic_settings.storage_account_id, null)

  # --- Dynamic Logic to Determine Active Categories per Resource ---
  
  dynamic "enabled_log" {
    for_each = toset(
      var.diagnostics_level == "all" && contains(each.value.log_category_groups, "allLogs") ? ["allLogs"] : (
        var.diagnostics_level == "audit" && contains(each.value.log_category_groups, "audit") ? ["audit"] : []
      )
    )
    content { category_group = enabled_log.value }
  }

  dynamic "enabled_log" {
    for_each = toset(
      var.diagnostics_level == "custom" ? var.diagnostics_custom_logs : (
        var.diagnostics_level == "all" && !contains(each.value.log_category_groups, "allLogs") ? each.value.logs : []
      )
    )
    content { category = enabled_log.value }
  }

  dynamic "metric" {
    for_each = toset(length(each.value.metrics) > 0 ? var.diagnostics_custom_metrics : [])
    content { category = metric.value }
  }
}
