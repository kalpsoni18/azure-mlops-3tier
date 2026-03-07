# =============================================================================
# Key Vault Module - Secrets Management
# Dynamic access policies, auto-generated DB password, CSI integration
# =============================================================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-${substr(var.environment, 0, 3)}-${var.suffix}"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod" ? true : false

  # Terraform operator - full access
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
    key_permissions    = ["Get", "List", "Create", "Delete"]
  }

  # AKS cluster identity - read only
  dynamic "access_policy" {
    for_each = var.aks_identity_id != "" ? [1] : []
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = var.aks_identity_id
      secret_permissions = ["Get", "List"]
    }
  }

  # AKS CSI driver - read only
  dynamic "access_policy" {
    for_each = var.aks_csi_identity_id != "" ? [1] : []
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = var.aks_csi_identity_id
      secret_permissions = ["Get", "List"]
    }
  }

  # AKS kubelet - read only
  dynamic "access_policy" {
    for_each = var.aks_kubelet_identity_id != "" ? [1] : []
    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      object_id          = var.aks_kubelet_identity_id
      secret_permissions = ["Get", "List"]
    }
  }

  tags = var.tags
}

# --- Auto-generated database password ---

resource "random_password" "db" {
  length  = 20
  special = true
  upper   = true
}

resource "azurerm_key_vault_secret" "db_username" {
  name         = "db-username"
  value        = var.db_username
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "db_name" {
  name         = "db-name"
  value        = var.db_name
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
}

resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "postgresql://${var.db_username}:${random_password.db.result}@${var.db_fqdn}:5432/${var.db_name}?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"
}

# --- Auto-generated Grafana admin password (replaces hardcoded default) ---

resource "random_password" "grafana" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}?"
  upper            = true
}

resource "azurerm_key_vault_secret" "grafana_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana.result
  key_vault_id = azurerm_key_vault.main.id
  content_type = "text/plain"

  tags = merge(var.tags, {
    Component = "monitoring"
    Note      = "Retrieve with: az keyvault secret show --vault-name <kv> --name grafana-admin-password --query value -o tsv"
  })
}
