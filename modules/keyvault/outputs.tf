output "vault_id" { value = azurerm_key_vault.main.id }
output "vault_name" { value = azurerm_key_vault.main.name }
output "vault_uri" { value = azurerm_key_vault.main.vault_uri }
output "db_password" { value = random_password.db.result; sensitive = true }
output "grafana_password" { value = random_password.grafana.result; sensitive = true }
output "grafana_password_secret_name" { value = azurerm_key_vault_secret.grafana_password.name }
