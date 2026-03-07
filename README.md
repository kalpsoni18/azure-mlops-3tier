# 🏗️ Azure 3-Tier MLOps Infrastructure

[![Terraform CI](https://github.com/YOUR_USERNAME/azure-3tier-mlops/actions/workflows/terraform-ci.yml/badge.svg)](https://github.com/YOUR_USERNAME/azure-3tier-mlops/actions/workflows/terraform-ci.yml)
[![Terraform CD](https://github.com/YOUR_USERNAME/azure-3tier-mlops/actions/workflows/terraform-cd.yml/badge.svg)](https://github.com/YOUR_USERNAME/azure-3tier-mlops/actions/workflows/terraform-cd.yml)
![Terraform](https://img.shields.io/badge/Terraform-v1.9-purple?logo=terraform)
![Azure](https://img.shields.io/badge/Azure-Cloud-0078D4?logo=microsoftazure)
![Prometheus](https://img.shields.io/badge/Prometheus-v2.51-E6522C?logo=prometheus)
![Grafana](https://img.shields.io/badge/Grafana-v10.4-F46800?logo=grafana)
![Loki](https://img.shields.io/badge/Loki-v2.9-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

> **Production-grade, multi-environment (dev/uat/prod) 3-tier cloud infrastructure with full Prometheus + Grafana + Loki observability, defense-in-depth security, zero-hardcoded-secrets policy, and GitHub Actions CI/CD — deployed entirely with Terraform.**

---

## Architecture

```
                            ┌─────────────────────────┐
                            │     GitHub Actions       │
                            │  CI: validate → plan     │
                            │  CD: dev → uat → prod    │
                            └──────────┬──────────────┘
                                       │
                     ┌─────────────────┼─────────────────┐
                     ▼                 ▼                  ▼
              ┌─────────────┐  ┌─────────────┐  ┌──────────────┐
              │  DEV (10.1) │  │  UAT (10.2) │  │  PROD (10.3) │
              └──────┬──────┘  └──────┬──────┘  └──────┬───────┘
                     │                │                 │
        Each environment contains:
        ┌────────────────────────────────────────────────────┐
        │                                                    │
        │   ┌──────────┐    ┌──────────┐    ┌────────────┐  │
        │   │ TIER 1   │    │ TIER 2   │    │ TIER 3     │  │
        │   │ Frontend  │───▶│ Backend  │───▶│ PostgreSQL │  │
        │   │ (AKS)    │    │ (AKS)    │    │ (Private)  │  │
        │   └──────────┘    └──────────┘    └────────────┘  │
        │                                                    │
        │   ┌───────────────────────────────────────────┐   │
        │   │      Full Observability Stack ($0 compute) │   │
        │   │                                           │   │
        │   │  METRICS:  Prometheus ──▶ Grafana         │   │
        │   │  ALERTS:   Alertmanager ──▶ Slack/Email   │   │
        │   │  LOGS:     Promtail ──▶ Loki ──▶ Grafana  │   │
        │   └───────────────────────────────────────────┘   │
        │                                                    │
        │   ┌───────────────────────────────────────────┐   │
        │   │    Security Layers (11 layers)             │   │
        │   │  NSGs │ Private DB │ Key Vault │ RBAC      │   │
        │   │  Managed Identity │ Zero Hardcoded Secrets │   │
        │   └───────────────────────────────────────────┘   │
        └────────────────────────────────────────────────────┘
```

---

## Project Structure

```
azure-3tier-mlops/
├── .github/workflows/
│   ├── terraform-ci.yml           # PR: format → validate → tfsec → plan
│   ├── terraform-cd.yml           # Merge: deploy dev → uat → prod
│   └── terraform-destroy.yml      # Manual: destroy any environment
├── modules/
│   ├── networking/                # VNet, 4 subnets, NSGs, private DNS
│   ├── aks/                       # Kubernetes cluster, RBAC, CSI driver
│   ├── database/                  # PostgreSQL Flex (private, no public access)
│   ├── keyvault/                  # Auto-generated DB + Grafana passwords
│   ├── acr/                       # Container Registry
│   └── monitoring/                # Prometheus + Grafana + Loki + Promtail via Helm
├── environments/
│   ├── dev/                       # 1 node, burstable DB (~$0.40/hr)
│   ├── uat/                       # 2 nodes, GP database (~$0.50/hr)
│   └── prod/                      # 3+ nodes, HA, geo-backup (~$1.20/hr)
├── local-dev/                     # 🆕 Docker Compose — test the stack locally first
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── prometheus/prometheus.yml + alerts.yml
│   ├── alertmanager/alertmanager.yml
│   ├── loki/loki.yml
│   ├── promtail/promtail.yml
│   └── grafana/provisioning/ + dashboards/
└── scripts/bootstrap.sh
```

---

## Security (11 Layers)

| # | Layer | Implementation |
|---|-------|----------------|
| 1 | **Network Segmentation** | 4 subnets (public/private/database/AKS) with dedicated NSGs |
| 2 | **Explicit Deny Rules** | Every NSG ends with `DenyAllInbound` at priority 4096 |
| 3 | **Private Database** | PostgreSQL on delegated subnet, `public_network_access = false` |
| 4 | **Private DNS** | DB hostname resolves only inside the VNet |
| 5 | **Secrets in Key Vault** | Auto-generated 20-char DB password, never in code |
| 6 | **CSI Secrets Driver** | AKS mounts secrets from Key Vault at runtime |
| 7 | **Managed Identities** | Zero stored credentials — AKS uses SystemAssigned identity |
| 8 | **Least Privilege RBAC** | AKS gets `AcrPull` only; Key Vault gets `Get/List` only |
| 9 | **Environment Isolation** | Separate VNet/RG/KeyVault/state per environment |
| 10 | **Security Scanning** | tfsec runs on every PR via GitHub Actions |
| 11 | **🆕 Zero Hardcoded Secrets** | Grafana password auto-generated in Key Vault — retrieved at deploy time via `terraform output` |

---

## Observability Stack

### Metrics + Alerts
- **kube-prometheus-stack** (Prometheus + Grafana + Alertmanager) deployed via Helm
- `node-exporter` for host metrics, `kube-state-metrics` for K8s object state
- 4 custom `PrometheusRule` alerts: HighCPU, HighMemory, PodCrashLoop, DiskPressure
- Alertmanager routes to Slack (#alerts for critical, #warnings for warning) + email

### Logs (🆕 Loki + Promtail)
- **Loki** single-binary log storage (cost-optimised, same architecture as local dev)
- **Promtail** DaemonSet ships all pod logs to Loki automatically
- Loki pre-wired as Grafana datasource — explore logs alongside metrics in one UI
- Per-environment retention: dev=7d, uat=30d, prod=90d

### Local Dev Stack (🆕)

Run the full stack locally before spending money on Azure:

```bash
cd local-dev
cp .env.example .env    # set GRAFANA_ADMIN_PASSWORD
docker compose up -d

open http://localhost:3000   # Grafana  (admin / your password)
open http://localhost:9090   # Prometheus
open http://localhost:9093   # Alertmanager
# Loki available at :3100 (auto-wired to Grafana)

docker compose down
```

Pre-built Infrastructure Overview dashboard loads automatically.

---

## CI/CD Pipeline

```
PR → fmt check → validate (dev/uat/prod) → tfsec scan → plan dev → post comment
Merge → apply dev (auto) → apply uat (auto) → apply prod (manual approval gate)
```

### GitHub Secrets Required

| Secret | Source |
|--------|--------|
| `ARM_CLIENT_ID` | `az ad sp create-for-rbac` → `appId` |
| `ARM_CLIENT_SECRET` | → `password` |
| `ARM_TENANT_ID` | → `tenant` |
| `ARM_SUBSCRIPTION_ID` | `az account show --query id` |

---

## Quick Start

```bash
# 1. Optional: try locally first
cd local-dev && cp .env.example .env && docker compose up -d

# 2. Azure setup
az login && ./scripts/bootstrap.sh && source .env

# 3. Deploy dev (~$1.20 for 3 hours)
cd environments/dev
terraform init && terraform apply

# 4. Get Grafana URL
$(terraform output -raw aks_connect)
kubectl get svc -n monitoring kube-prometheus-stack-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# 5. Get auto-generated Grafana password from Key Vault
$(terraform output -raw grafana_password_cmd)

# 6. Explore logs in Grafana → Explore → Loki
# Query: {namespace="monitoring"} |= "error"

# 7. Clean up
terraform destroy -auto-approve
```

---

## Environment Comparison

| Feature | DEV | UAT | PROD |
|---------|-----|-----|------|
| AKS Nodes | 1× B2s | 2× D2s_v3 | 3× D4s_v3 |
| PostgreSQL | B1ms (burstable) | GP D2s_v3 | GP D4s_v3 |
| DB Backup | 7 days | 14 days | 35 days + geo |
| Prometheus Retention | 3 days | 14 days | 30 days |
| Loki Retention | 7 days | 30 days | 90 days |
| Grafana Access | LoadBalancer | LoadBalancer | ClusterIP (ingress) |
| Hourly Cost | ~$0.40 | ~$0.50 | ~$1.20 |

---

## What This Demonstrates

- **IaC**: Terraform modules, remote state, multi-env tfvars, lifecycle rules
- **Cloud Architecture**: Azure VNet, AKS, PostgreSQL Flex, Key Vault, ACR
- **Kubernetes**: Helm, CSI secrets driver, namespace isolation, DaemonSets
- **CI/CD**: GitHub Actions promotion pipeline with manual prod gates
- **Security**: NSGs, private endpoints, managed identities, zero hardcoded secrets, tfsec
- **Observability**: Prometheus, Grafana, Alertmanager, Loki, Promtail, custom alerts
- **Cost Engineering**: Burstable SKUs for dev, $0-compute observability stack, destroy strategy

---

## Screenshots

> _Deploy and screenshot:_
> - [ ] Grafana Infrastructure Overview dashboard
> - [ ] Grafana Loki log explorer
> - [ ] Alertmanager rules page
> - [ ] Azure Resource Group / AKS / Key Vault in Portal
> - [ ] GitHub Actions CI/CD pipeline run

---

## License

MIT — Inspired by [Piyush Sachdeva's Terraform Azure Course](https://github.com/piyushsachdeva/Terraform-Full-Course-Azure)
