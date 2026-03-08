output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}
output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}
output "host" {
  value     = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive = true
}
output "cluster_identity" {
  value = azurerm_kubernetes_cluster.main.identity[0].principal_id
}
output "kubelet_identity" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.main.oidc_issuer_url
}
