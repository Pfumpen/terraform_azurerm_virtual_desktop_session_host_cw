output "session_host_identities" {
  description = "A map of the managed identities for each session host virtual machine. The keys are the logical names of the session hosts."
  value = {
    for k, vm in azurerm_windows_virtual_machine.session_host : k => vm.identity
  }
}

output "session_host_resource_ids" {
  description = "A map of the resource IDs for each session host virtual machine. The keys are the logical names of the session hosts."
  value = {
    for k, vm in azurerm_windows_virtual_machine.session_host : k => vm.id
  }
}

output "admin_password_secret_ids" {
  description = "A map of the secret IDs for the generated admin passwords stored in Azure Key Vault. The keys are the logical names of the session hosts."
  value = {
    for k, secret in azurerm_key_vault_secret.admin_password : k => secret.id
  }
}
