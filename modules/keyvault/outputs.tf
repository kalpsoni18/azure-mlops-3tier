output "keyvault_id" {
  value = azurerm_key_vault.main.id
}
output "keyvault_name" {
  value = azurerm_key_vault.main.name
}
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
output "grafana_password" {
  value     = random_password.grafana.result
  sensitive = true
}
