# =============================================================================
# AKS Module - Kubernetes Cluster
# SystemAssigned identity, CSI secrets driver, Container Insights
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.prefix}-aks"
  kubernetes_version  = var.kubernetes_version
  node_resource_group = "${var.prefix}-aks-nodes"

  local_account_disabled = false

  default_node_pool {
    name                        = "system"
    vm_size                     = var.node_vm_size
    os_disk_size_gb             = 30
    vnet_subnet_id              = var.aks_subnet_id
    temporary_name_for_rotation = "tmpsystem"

    auto_scaling_enabled = true
    min_count            = var.node_min_count
    max_count            = var.node_max_count

    node_labels = {
      "environment" = var.environment
      "tier"        = "system"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "azure"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version,
      default_node_pool[0].orchestrator_version
    ]
  }

  tags = var.tags

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# --- RBAC Role Assignments ---

resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_network" {
  scope                = var.resource_group_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_identity" {
  scope                = var.resource_group_id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = 1
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
