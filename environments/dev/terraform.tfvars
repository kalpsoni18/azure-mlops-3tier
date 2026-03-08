# =============================================================================
# DEV — Cheapest possible. Deploy → screenshot → destroy in 2-3 hours.
# Estimated: ~$0.40/hour = ~$1.20 for 3 hours
# =============================================================================

environment = "dev"
location    = "westus2"
db_location = "northcentralus"

# Networking (10.1.x.x)
vnet_address_space     = "10.1.0.0/16"
public_subnet_prefix   = "10.1.1.0/24"
private_subnet_prefix  = "10.1.2.0/24"
database_subnet_prefix = "10.1.3.0/24"
aks_subnet_prefix      = "10.1.4.0/22"

# AKS — 1 small node
aks_node_vm_size = "Standard_DC2s_v3"
aks_node_min     = 1
aks_node_max     = 2

# ACR — cheapest
acr_sku = "Basic"

# Database — burstable, smallest
db_sku         = "B_Standard_B1ms"
db_storage_mb  = 32768
db_backup_days = 7
db_geo_backup  = false

# Monitoring — short retention, small PVs
log_retention_days   = 7
enable_prometheus    = false
prometheus_retention = "3d"
prometheus_storage   = "5Gi"
grafana_service_type = "LoadBalancer"

# Loki log aggregation
loki_retention = "168h" # 7 days for dev
loki_storage   = "5Gi"
