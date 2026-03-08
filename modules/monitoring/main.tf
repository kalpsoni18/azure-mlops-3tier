# =============================================================================
# Monitoring Module
# Azure Log Analytics + kube-prometheus-stack (Prometheus, Grafana, Alertmanager)
# Prometheus/Grafana = $0 compute (runs on AKS), only PV storage cost
# =============================================================================

# --- Azure Log Analytics (for AKS Container Insights) ---

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.prefix}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = max(30, var.log_retention_days)
  tags                = var.tags
}

resource "azurerm_log_analytics_solution" "containers" {
  solution_name         = "ContainerInsights"
  location              = var.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

# --- Alert Action Group ---

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.prefix}-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  email_receiver {
    name          = "admin"
    email_address = var.alert_email
  }

  tags = var.tags
}

# --- Prometheus + Grafana (deployed via Helm on AKS) ---

resource "kubernetes_namespace" "monitoring" {
  count = var.enable_prometheus ? 1 : 0
  metadata {
    name   = "monitoring"
    labels = { "managed-by" = "terraform" }
  }
}

resource "helm_release" "kube_prometheus" {
  count      = var.enable_prometheus ? 1 : 0
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "65.1.0"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  timeout    = 600
  wait       = true

  # Prometheus
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage
  }
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "managed-premium"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "256Mi"
  }
  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "512Mi"
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues"
    value = "false"
  }

  # Grafana
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }
  set {
    name  = "grafana.service.type"
    value = var.grafana_service_type
  }
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }
  set {
    name  = "grafana.persistence.size"
    value = "2Gi"
  }
  set {
    name  = "grafana.persistence.storageClassName"
    value = "managed-premium"
  }
  set {
    name  = "grafana.defaultDashboardsEnabled"
    value = "true"
  }
  set {
    name  = "grafana.defaultDashboardsTimezone"
    value = "America/Toronto"
  }
  set {
    name  = "grafana.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "grafana.resources.requests.memory"
    value = "128Mi"
  }

  # Alertmanager
  set {
    name  = "alertmanager.alertmanagerSpec.retention"
    value = "72h"
  }
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = "1Gi"
  }
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "managed-premium"
  }

  # Components
  set {
    name  = "nodeExporter.enabled"
    value = "true"
  }
  set {
    name  = "kubeStateMetrics.enabled"
    value = "true"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# --- Custom MLOps Alerts ---

resource "kubernetes_manifest" "custom_alerts" {
  count = 0  # disabled until cluster exists
  count = var.enable_prometheus ? 1 : 0

  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "PrometheusRule"
    metadata = {
      name      = "infra-alerts"
      namespace = "monitoring"
      labels    = { "release" = "kube-prometheus-stack" }
    }
    spec = {
      groups = [{
        name = "infrastructure"
        rules = [
          {
            alert       = "HighCPU"
            expr        = "100 - (avg by(instance)(irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100) > 85"
            for         = "10m"
            labels      = { severity = "warning" }
            annotations = { summary = "Node {{ $labels.instance }} CPU at {{ $value }}%" }
          },
          {
            alert       = "HighMemory"
            expr        = "(1 - node_memory_MemAvailable_bytes/node_memory_MemTotal_bytes) * 100 > 85"
            for         = "10m"
            labels      = { severity = "warning" }
            annotations = { summary = "Node {{ $labels.instance }} memory at {{ $value }}%" }
          },
          {
            alert       = "PodCrashLoop"
            expr        = "rate(kube_pod_container_status_restarts_total[15m]) > 0.05"
            for         = "5m"
            labels      = { severity = "critical" }
            annotations = { summary = "Pod {{ $labels.pod }} crash-looping" }
          },
          {
            alert       = "DiskPressure"
            expr        = "(kubelet_volume_stats_used_bytes/kubelet_volume_stats_capacity_bytes) * 100 > 85"
            for         = "5m"
            labels      = { severity = "critical" }
            annotations = { summary = "PV {{ $labels.persistentvolumeclaim }} at {{ $value }}% capacity" }
          }
        ]
      }]
    }
  }

  depends_on = [helm_release.kube_prometheus]
}

# --- Loki Stack (log aggregation — mirrors local-dev/loki) ---

resource "helm_release" "loki" {
  count      = var.enable_prometheus ? 1 : 0
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "6.6.2"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  timeout    = 600
  wait       = true

  # Single-binary mode (cost-optimised — same as local dev)
  set {
    name  = "deploymentMode"
    value = "SingleBinary"
  }
  set {
    name  = "loki.commonConfig.replication_factor"
    value = "1"
  }
  set {
    name  = "loki.storage.type"
    value = "filesystem"
  }
  set {
    name  = "loki.limits_config.retention_period"
    value = var.loki_retention
  }
  set {
    name  = "singleBinary.replicas"
    value = "1"
  }
  set {
    name  = "singleBinary.persistence.storageClass"
    value = "managed-premium"
  }
  set {
    name  = "singleBinary.persistence.size"
    value = var.loki_storage
  }
  set {
    name  = "singleBinary.resources.requests.cpu"
    value = "50m"
  }
  set {
    name  = "singleBinary.resources.requests.memory"
    value = "128Mi"
  }
  set {
    name  = "singleBinary.resources.limits.memory"
    value = "256Mi"
  }
  # Disable microservice components in single-binary mode
  set {
    name  = "read.replicas"
    value = "0"
  }
  set {
    name  = "write.replicas"
    value = "0"
  }
  set {
    name  = "backend.replicas"
    value = "0"
  }

  depends_on = [helm_release.kube_prometheus]
}

# --- Promtail (ships pod logs to Loki) ---

resource "helm_release" "promtail" {
  count      = var.enable_prometheus ? 1 : 0
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.15.5"
  namespace  = kubernetes_namespace.monitoring[0].metadata[0].name
  timeout    = 300
  wait       = true

  set {
    name  = "config.clients[0].url"
    value = "http://loki-gateway/loki/api/v1/push"
  }
  set {
    name  = "resources.requests.cpu"
    value = "25m"
  }
  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }
  set {
    name  = "resources.limits.memory"
    value = "128Mi"
  }

  depends_on = [helm_release.loki]
}
