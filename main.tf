locals {
  merged_tags = merge(
    var.tags,
    {
      "provisioner"   = "Terraform"
    }
  )
}

resource "random_password" "admin_password" {
  for_each = var.session_hosts

  length           = var.password_generation_config.length
  special          = var.password_generation_config.special
  override_special = var.password_generation_config.override_special
}

resource "azurerm_key_vault_secret" "admin_password" {
  for_each = var.session_hosts

  name         = "${each.value.name}-admin-password"
  value        = random_password.admin_password[each.key].result
  key_vault_id = var.admin_password_key_vault_id
  tags         = local.merged_tags

}

resource "azurerm_windows_virtual_machine" "session_host" {
  for_each = var.session_hosts

  name                = each.value.name
  computer_name       = each.value.name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = each.value.size
  tags                = local.merged_tags
  zone                = each.value.zone

  admin_username = each.value.admin_username
  admin_password = random_password.admin_password[each.key].result

  network_interface_ids = [
    azurerm_network_interface.session_host[each.key].id,
  ]

  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = each.value.image_key != null ? local.avd_images[each.value.image_key].publisher : each.value.source_image_reference.publisher
    offer     = each.value.image_key != null ? local.avd_images[each.value.image_key].offer : each.value.source_image_reference.offer
    sku       = each.value.image_key != null ? local.avd_images[each.value.image_key].sku : each.value.source_image_reference.sku
    version   = each.value.image_key != null ? local.avd_images[each.value.image_key].version : each.value.source_image_reference.version
  }

  dynamic "identity" {
for_each = var.managed_identity != null && (var.managed_identity.system_assigned || length(var.managed_identity.user_assigned_resource_ids) > 0) ? [1] : []

    content {
      type = (var.managed_identity.system_assigned && length(var.managed_identity.user_assigned_resource_ids) > 0) ? "SystemAssigned, UserAssigned" : (
        var.managed_identity.system_assigned ? "SystemAssigned" : "UserAssigned"
      )
      
      identity_ids = var.managed_identity.user_assigned_resource_ids
    }
  }
}
