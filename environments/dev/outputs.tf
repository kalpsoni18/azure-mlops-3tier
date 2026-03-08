output "resource_group" { value = azurerm_resource_group.main.name }
output "aks_cluster" { value = module.aks.cluster_name }
output "aks_connect" { value = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}" }
output "acr_server" { value = module.acr.login_server }
output "keyvault" { value = module.keyvault.keyvault_name }
output "db_server" { value = module.database.server_fqdn }
output "grafana_url" { value = module.monitoring.grafana_url }
output "prometheus" { value = module.monitoring.prometheus_port_forward }
output "grafana_password_cmd" {
  value       = "az keyvault secret show --vault-name ${module.keyvault.keyvault_name} --name grafana-admin-password --query value -o tsv"
  description = "Run this command to retrieve the auto-generated Grafana admin password"
}
output "loki_endpoint" {
  value = var.enable_prometheus ? "http://loki:3100 (inside cluster) — kubectl port-forward -n monitoring svc/loki 3100:3100" : "disabled"
}
