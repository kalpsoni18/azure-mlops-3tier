# =============================================================================
# PROD — Production-grade. HA, security hardened, monitoring.
# Estimated: ~$20-30/day
# =============================================================================

environment = "prod"
location    = "eastus"

# Networking (10.3.x.x — isolated from dev/uat)
vnet_address_space     = "10.3.0.0/16"
public_subnet_prefix   = "10.3.1.0/24"
private_subnet_prefix  = "10.3.2.0/24"
database_subnet_prefix = "10.3.3.0/24"
aks_subnet_prefix      = "10.3.4.0/22"

# AKS — 3+ nodes, larger VMs
aks_node_vm_size = "Standard_D4s_v3"
aks_node_min     = 3
aks_node_max     = 10

# ACR — premium
acr_sku = "Premium"

# Database — production
db_sku         = "GP_Standard_D4s_v3"
db_storage_mb  = 131072
db_backup_days = 35
db_geo_backup  = true

# Monitoring
log_retention_days   = 90
enable_prometheus    = true
prometheus_retention = "30d"
prometheus_storage   = "50Gi"
grafana_service_type = "ClusterIP"    # Use ingress in prod

# Loki log aggregation
loki_retention = "2160h"   # 90 days for prod
loki_storage   = "20Gi"
