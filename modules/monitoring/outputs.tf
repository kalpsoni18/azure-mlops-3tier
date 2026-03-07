output "log_analytics_id" { value = azurerm_log_analytics_workspace.main.id }
output "log_analytics_name" { value = azurerm_log_analytics_workspace.main.name }

output "grafana_url" {
  value = var.enable_prometheus ? "kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'" : "disabled"
}

output "prometheus_port_forward" {
  value = "kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090"
}
