# =============================================================================
# Environment Orchestrator — DEV
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}



data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  prefix = "${var.project}-${var.environment}-${random_string.suffix.result}"
  tags = merge(var.extra_tags, {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Repository  = "azure-3tier-mlops"
  })
}

resource "azurerm_resource_group" "main" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
  tags     = local.tags
}

# =============================================================================
# 1. Log Analytics (standalone — no dependencies)
# =============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.prefix}-law"
  location = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = max(30, var.log_retention_days)
  tags                = local.tags
}

# =============================================================================
# 2. Networking (no dependencies)
# =============================================================================

module "networking" {
  source = "../../modules/networking"

  prefix                 = local.prefix
  resource_group_name    = azurerm_resource_group.main.name
  location = var.location
  vnet_address_space     = var.vnet_address_space
  public_subnet_prefix   = var.public_subnet_prefix
  private_subnet_prefix  = var.private_subnet_prefix
  database_subnet_prefix = var.database_subnet_prefix
  aks_subnet_prefix      = var.aks_subnet_prefix
  tags                   = local.tags
}

# =============================================================================
# 3. ACR (no dependencies)
# =============================================================================

module "acr" {
  source = "../../modules/acr"

  environment         = var.environment
  suffix              = random_string.suffix.result
  resource_group_name = azurerm_resource_group.main.name
  location = var.location
  sku                 = var.acr_sku
  tags                = local.tags
}

# =============================================================================
# 4. AKS (needs networking + acr + log analytics)
# =============================================================================

module "aks" {
  source = "../../modules/aks"

  prefix                     = local.prefix
  resource_group_name        = azurerm_resource_group.main.name
  resource_group_id          = azurerm_resource_group.main.id
  location = var.location
  environment                = var.environment
  aks_subnet_id              = module.networking.aks_subnet_id
  kubernetes_version         = var.kubernetes_version
  node_vm_size               = var.aks_node_vm_size
  node_min_count             = var.aks_node_min
  node_max_count             = var.aks_node_max
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  acr_id                     = module.acr.acr_id
  tags                       = local.tags

  depends_on = [module.networking]
}

# =============================================================================
# 5. Key Vault (needs aks — generates its own passwords, no database dep)
# =============================================================================

module "keyvault" {
  source = "../../modules/keyvault"

  environment             = var.environment
  suffix                  = random_string.suffix.result
  resource_group_name     = azurerm_resource_group.main.name
  location = var.location
  aks_identity_id         = module.aks.cluster_identity
  aks_csi_identity_id     = module.aks.cluster_identity
  aks_kubelet_identity_id = module.aks.kubelet_identity
  db_username             = var.db_username
  db_name                 = var.db_name
  db_fqdn                 = ""
  tags                    = local.tags

  depends_on = [module.aks]
}

# =============================================================================
# 6. Database (needs networking + keyvault password)
# =============================================================================

module "database" {
  source = "../../modules/database"

  prefix                = local.prefix
  resource_group_name   = azurerm_resource_group.main.name
  location = var.db_location
  database_subnet_id    = module.networking.database_subnet_id
  private_dns_zone_id   = module.networking.private_dns_zone_id
  admin_username        = var.db_username
  admin_password        = module.keyvault.db_password
  db_name               = var.db_name
  sku_name              = var.db_sku
  storage_mb            = var.db_storage_mb
  backup_retention_days = var.db_backup_days
  geo_redundant_backup  = var.db_geo_backup
  tags                  = local.tags

  depends_on = [module.networking, module.keyvault]
}

# =============================================================================
# 7. Monitoring Helm stack (needs aks + keyvault)
# =============================================================================

module "monitoring" {
  source = "../../modules/monitoring"

  prefix               = local.prefix
  resource_group_name  = azurerm_resource_group.main.name
  location             = var.location
  log_retention_days   = var.log_retention_days
  alert_email          = var.alert_email
  enable_prometheus    = var.enable_prometheus
  prometheus_retention = var.prometheus_retention
  prometheus_storage   = var.prometheus_storage
  grafana_password     = module.keyvault.grafana_password
  grafana_service_type = var.grafana_service_type
  loki_retention       = var.loki_retention
  loki_storage         = var.loki_storage
  tags                 = local.tags

  depends_on = [module.aks, module.keyvault]
}

provider "helm" {
  kubernetes {
    host                   = module.aks.cluster_endpoint
    client_certificate     = base64decode(module.aks.client_certificate)
    client_key             = base64decode(module.aks.client_key)
    cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  host                   = module.aks.cluster_endpoint
  client_certificate     = base64decode(module.aks.client_certificate)
  client_key             = base64decode(module.aks.client_key)
  cluster_ca_certificate = base64decode(module.aks.cluster_ca_certificate)
}
