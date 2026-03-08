# =============================================================================
# UAT — Medium. Pre-production validation.
# Estimated: ~$8-12/day
# =============================================================================

environment = "uat"
location    = "eastus"

# Networking (10.2.x.x — isolated from dev)
vnet_address_space     = "10.2.0.0/16"
public_subnet_prefix   = "10.2.1.0/24"
private_subnet_prefix  = "10.2.2.0/24"
database_subnet_prefix = "10.2.3.0/24"
aks_subnet_prefix      = "10.2.4.0/22"

# AKS — 2 nodes
aks_node_vm_size = "Standard_D2s_v3"
aks_node_min     = 2
aks_node_max     = 4

# ACR
acr_sku = "Standard"

# Database — general purpose
db_sku         = "GP_Standard_D2s_v3"
db_storage_mb  = 65536
db_backup_days = 14
db_geo_backup  = false

# Monitoring
log_retention_days   = 30
enable_prometheus    = true
prometheus_retention = "14d"
prometheus_storage   = "20Gi"
grafana_service_type = "LoadBalancer"

# Loki log aggregation
loki_retention = "720h" # 30 days for UAT
loki_storage   = "10Gi"

# AKS version & DB location fixes
kubernetes_version = "1.32.0"
db_location        = "centralus"
