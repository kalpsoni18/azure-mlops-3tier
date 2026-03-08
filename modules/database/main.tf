# =============================================================================
# Database Module - PostgreSQL Flexible Server
# Public access version for cross-region compatibility
# =============================================================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.prefix}-pgflex-kalp-nc"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.pg_version
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup
  public_network_access_enabled = true

  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_all_azure" {
  name             = "allow-all-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
