# =============================================================================
# Database Module - PostgreSQL Flexible Server
# Private subnet, no public access, auto-generated password from Key Vault
# =============================================================================

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "${var.prefix}-pgflex"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = var.pg_version
  delegated_subnet_id           = var.database_subnet_id
  private_dns_zone_id           = var.private_dns_zone_id
  administrator_login           = var.admin_username
  administrator_password        = var.admin_password
  storage_mb                    = var.storage_mb
  sku_name                      = var.sku_name
  backup_retention_days         = var.backup_retention_days
  geo_redundant_backup_enabled  = var.geo_redundant_backup
  public_network_access_enabled = false
  zone                          = "1"

  lifecycle {
    ignore_changes = [zone, high_availability[0].standby_availability_zone]
  }

  tags = var.tags
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}
