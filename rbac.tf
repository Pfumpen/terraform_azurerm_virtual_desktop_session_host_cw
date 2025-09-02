locals {
  flat_role_assignments = flatten([
    for vm_key, vm in azurerm_windows_virtual_machine.session_host : [
      for role_key, role in var.role_assignments : {
        assignment_key = "${vm_key}-${role_key}"

        vm_id                      = vm.id
        role_definition_id_or_name = role.role_definition_id_or_name
        principal_id               = role.principal_id
        principal_type             = role.principal_type
        description                = role.description
        condition                  = role.condition
        condition_version          = role.condition_version
      }
    ]
  ])
}

resource "azurerm_role_assignment" "session_host" {
  for_each = { for assignment in local.flat_role_assignments : assignment.assignment_key => assignment }

  scope                = each.value.vm_id
  role_definition_name = each.value.role_definition_id_or_name
  principal_id         = each.value.principal_id
  principal_type       = each.value.principal_type
  description          = each.value.description
  condition            = each.value.condition
  condition_version    = each.value.condition_version
}
