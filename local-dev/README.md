# Local Dev Monitoring Stack

A complete Docker Compose mirror of the AKS `kube-prometheus-stack` + Loki deployment.
Use this to test dashboards, alerts, and log queries before deploying to Azure.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Grafana | http://localhost:3000 | Dashboards + log explorer |
| Prometheus | http://localhost:9090 | Metrics + alert rules |
| Alertmanager | http://localhost:9093 | Alert routing |
| Loki | http://localhost:3100 | Log storage (internal) |
| Node Exporter | http://localhost:9100/metrics | Host metrics |
| cAdvisor | http://localhost:8080 | Container metrics |

## Setup

```bash
cp .env.example .env
# Edit .env:
#   GRAFANA_ADMIN_PASSWORD=YourSecurePassword123!
#   GRAFANA_SECRET_KEY=$(openssl rand -base64 24)
#   SLACK_WEBHOOK_URL=https://hooks.slack.com/...  (optional)

docker compose up -d
docker compose ps   # verify all healthy
```

## Pre-built Dashboards

The **Infrastructure Overview** dashboard auto-loads with panels for:
- CPU / Memory / Disk / Container count at-a-glance (stat panels)
- CPU usage over time (per core + system + iowait)
- Memory breakdown (used / available / cached)
- Network I/O (rx/tx per interface)
- Container CPU usage (per container)
- Firing alerts table

## Exploring Logs

In Grafana → Explore → select **Loki** datasource:

```logql
# All logs from this stack
{project="prometheus-grafana-stack"}

# Error logs from any container
{project="prometheus-grafana-stack"} |= "error"

# Prometheus logs
{container="prometheus"}

# Filter by log level
{container="grafana"} | json | level="warn"
```

## Alert Testing

Trigger a test alert in Alertmanager:
```bash
curl -X POST http://localhost:9093/api/v2/alerts \
  -H "Content-Type: application/json" \
  -d '[{"labels":{"alertname":"TestAlert","severity":"warning"},"annotations":{"summary":"Test alert from local dev"}}]'
```

## Mirroring to AKS

This stack intentionally mirrors the Helm values in `modules/monitoring/main.tf`:

| Local | AKS (Helm) |
|-------|-----------|
| `prometheus/prometheus.yml` | `prometheus.prometheusSpec` |
| `prometheus/alerts.yml` | `kubernetes_manifest.custom_alerts` (PrometheusRule) |
| `alertmanager/alertmanager.yml` | `alertmanager.alertmanagerSpec` |
| `loki/loki.yml` | `helm_release.loki` values |
| `promtail/promtail.yml` | `helm_release.promtail` values |

## Cleanup

```bash
docker compose down -v   # -v removes volumes (clears all data)
```
