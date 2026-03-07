# =============================================================================
# Azure Container Registry
# =============================================================================
resource "azurerm_container_registry" "main" {
  name                = "acr${var.environment}${var.suffix}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.environment == "prod" ? false : true
  tags                = var.tags
}
