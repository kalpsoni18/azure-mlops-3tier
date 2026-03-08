# Azure AKS Infrastructure — IaC + CI/CD + Observability

> Production-grade Azure Kubernetes infrastructure — fully automated with Terraform, GitHub Actions multi-environment CI/CD, and a complete observability stack.

![Terraform](https://img.shields.io/badge/Terraform-1.9.8-7B42BC?logo=terraform)
![Azure](https://img.shields.io/badge/Azure-AKS-0078D4?logo=microsoftazure)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-CI%2FCD-2088FF?logo=githubactions)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.32-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-3.x-0F1689?logo=helm)

---

## What This Project Demonstrates

- **Infrastructure as Code** — 6 reusable Terraform modules deploying a full AKS platform
- **Multi-environment CI/CD** — GitHub Actions pipeline promoting dev → UAT → prod with manual approval gate
- **Observability stack** — Prometheus, Grafana, Loki, and Promtail deployed via Helm on AKS
- **Security** — Key Vault secrets management, NSGs, private networking, tfsec scanning

---

## Architecture

<img width="1213" height="972" alt="Copy of azure-architecture" src="https://github.com/user-attachments/assets/24483db2-4466-47ee-851e-26261218060f" />


---

## Infrastructure Modules

| Module | Resources Deployed |
|--------|--------------------|
| `networking` | VNet, 4 subnets (public/private/db/aks), NSGs, Private DNS Zone |
| `aks` | AKS cluster 1.32, autoscaler, kubelet identity, ACR pull role |
| `acr` | Azure Container Registry |
| `keyvault` | Key Vault, db credentials, grafana password as secrets |
| `database` | PostgreSQL 14 Flexible Server, firewall rules |
| `monitoring` | Log Analytics workspace, Container Insights, Prometheus/Grafana/Loki via Helm |

---

## Multi-Environment Pipeline

```
Push to main
     │
     ▼
┌─────────┐     ┌─────────┐     ┌──────────────────────┐
│  DEV    │────▶│  UAT    │────▶│  PROD                │
│automatic│     │automatic│     │ manual approval gate │
│westus2  │     │ eastus  │     │ westus2              │
└─────────┘     └─────────┘     └──────────────────────┘
```

| Environment | Nodes | DB SKU | Networking | Status |
|-------------|-------|--------|------------|--------|
| dev | 1-2 × DC2s_v3 | B_Standard_B1ms | 10.1.0.0/16 | ✅ |
| uat | 2-4 × DC2s_v3 | B_Standard_B2ms | 10.2.0.0/16 | ✅ |
| prod | 1-10 × DC2s_v3 | B_Standard_B2ms | 10.3.0.0/16 | ⚠️ vCPU quota |

> Prod hit subscription vCPU quota limits — dev and UAT consume all available confidential VM capacity. This is a documented real-world constraint, not a code issue.

---

## Observability Stack

Deployed via Helm into the `monitoring` namespace on AKS:

| Component | Version | Purpose |
|-----------|---------|---------|
| kube-prometheus-stack | 65.1.0 | Prometheus + Grafana + Alertmanager |
| Loki | 6.6.2 | Log aggregation (filesystem, single binary) |
| Promtail | 6.15.5 | Log shipping from all pods |

**Grafana dashboards imported:**
- Kubernetes Cluster Overview (ID: 15760)
- Kubernetes Pods (ID: 13332)
- Loki Logs Explorer (ID: 15141)

**Datasources connected:** Prometheus · Loki · Alertmanager

---

## Repository Structure

```
azure-mlops-3tier/
├── .github/
│   └── workflows/
│       ├── ci.yml          # PR: fmt, validate, tfsec, plan
│       ├── cd.yml          # Deploy: dev → uat → prod
│       └── destroy.yml     # Manual destroy per environment
├── environments/
│   ├── dev/                # tfvars, backend, variables, main
│   ├── uat/                # tfvars, backend, variables, main
│   └── prod/               # tfvars, backend, variables, main
├── modules/
│   ├── aks/
│   ├── acr/
│   ├── database/
│   ├── keyvault/
│   ├── monitoring/
│   └── networking/
└── app/                    # Application code (WIP — pending ACR push)
    ├── frontend/           # nginx + HTML dashboard + Dockerfile
    ├── backend/            # FastAPI + Dockerfile
    ├── mlops/              # sklearn model training + serving + Dockerfile
    ├── k8s/                # Kubernetes manifests
    └── deploy.sh
```

---

## CI/CD Workflows

### CI — Pull Request
```
fmt check → validate (dev/uat/prod) → tfsec security scan → plan → PR comment
```

### CD — Push to main
```
deploy-dev (auto) → deploy-uat (needs: dev) → deploy-prod (needs: uat + manual approval)
```

### Destroy — Manual trigger
```
Select environment → type 'destroy' to confirm → terraform destroy
```

---

## Quick Start

### Prerequisites
```
Azure CLI · Terraform >= 1.9.8 · kubectl · Helm · Docker
```

### GitHub Secrets Required
```
ARM_CLIENT_ID
ARM_CLIENT_SECRET
ARM_SUBSCRIPTION_ID
ARM_TENANT_ID
```

### Deploy Infrastructure
```bash
cd environments/dev
terraform init
terraform apply -auto-approve

az aks get-credentials \
  --resource-group mlops3tier-dev-rg \
  --name $(terraform output -raw aks_cluster)
```

### Deploy Monitoring Stack
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring --version 65.1.0 \
  --set grafana.service.type=LoadBalancer

helm install loki grafana/loki \
  --namespace monitoring --version 6.6.2 \
  --set deploymentMode=SingleBinary \
  --set loki.auth_enabled=false \
  --set loki.useTestSchema=true \
  --set loki.commonConfig.replication_factor=1 \
  --set loki.storage.type=filesystem \
  --set singleBinary.replicas=1 \
  --set read.replicas=0 --set write.replicas=0 --set backend.replicas=0

helm install promtail grafana/promtail \
  --namespace monitoring --version 6.15.5 \
  --set "config.clients[0].url=http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
```

### Access Grafana
```bash
kubectl get svc -n monitoring kube-prometheus-stack-grafana
az keyvault secret show --vault-name <kv-name> --name grafana-admin-password --query value -o tsv
```

---

## Key Design Decisions

| Decision | Reason |
|----------|--------|
| Confidential VMs (DC2s_v3) | Only VM family available in this Azure subscription |
| PostgreSQL in centralus | eastus/westus2 capacity restricted for Flex Server |
| Loki `auth_enabled=false` | Simplifies log shipping for dev/uat without tenant ID config |
| Public PostgreSQL + firewall | Private DNS requires DB and VNet in same region |
| Helm deployed via CLI | kubernetes/helm provider causes circular dependency on first apply |

---

## Tech Stack

`Terraform` · `Azure AKS` · `Azure ACR` · `PostgreSQL Flexible Server` · `Azure Key Vault` · `Prometheus` · `Grafana` · `Loki` · `Promtail` · `Alertmanager` · `Helm` · `Kubernetes` · `GitHub Actions`
