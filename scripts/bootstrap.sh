#!/bin/bash
# =============================================================================
# One-time Azure setup: Login + Service Principal + State Backend
# =============================================================================
set -euo pipefail

echo "╔═══════════════════════════════════════════╗"
echo "║   Azure MLOps 3-Tier — Bootstrap Setup    ║"
echo "╚═══════════════════════════════════════════╝"

# 1. Login
echo -e "\n[1/4] Logging into Azure..."
az login
SUB_ID=$(az account show --query id -o tsv)
echo "  Subscription: $SUB_ID"

# 2. Service Principal
echo -e "\n[2/4] Creating Service Principal..."
SP=$(az ad sp create-for-rbac --name "terraform-mlops-sp" --role Contributor --scopes "/subscriptions/$SUB_ID" -o json)
echo "$SP" | tee .sp-credentials.json
echo -e "\n  ⚠️  SAVE THESE CREDENTIALS — you won't see them again!"

CLIENT_ID=$(echo $SP | jq -r .appId)
CLIENT_SECRET=$(echo $SP | jq -r .password)
TENANT_ID=$(echo $SP | jq -r .tenant)

# 3. Export env vars
echo -e "\n[3/4] Setting environment variables..."
cat << EOF > .env
export ARM_CLIENT_ID="$CLIENT_ID"
export ARM_CLIENT_SECRET="$CLIENT_SECRET"
export ARM_TENANT_ID="$TENANT_ID"
export ARM_SUBSCRIPTION_ID="$SUB_ID"
EOF
echo "  Created .env file. Run: source .env"

# 4. Remote state backend (optional)
echo -e "\n[4/4] Creating remote state backend..."
az group create --name terraform-state-rg --location eastus -o none
az storage account create --name tfstatemlops3tier --resource-group terraform-state-rg \
  --location eastus --sku Standard_LRS --kind StorageV2 \
  --min-tls-version TLS1_2 --allow-blob-public-access false -o none
az storage container create --name tfstate --account-name tfstatemlops3tier --auth-mode login -o none

echo -e "\n╔═══════════════════════════════════════════╗"
echo "║   Bootstrap Complete!                     ║"
echo "╠═══════════════════════════════════════════╣"
echo "║   Next steps:                             ║"
echo "║   1. source .env                          ║"
echo "║   2. cd environments/dev                  ║"
echo "║   3. terraform init                       ║"
echo "║   4. terraform plan                       ║"
echo "║   5. terraform apply                      ║"
echo "╚═══════════════════════════════════════════╝"
echo -e "\nFor GitHub Actions, add these secrets:"
echo "  ARM_CLIENT_ID=$CLIENT_ID"
echo "  ARM_CLIENT_SECRET=$CLIENT_SECRET"
echo "  ARM_TENANT_ID=$TENANT_ID"
echo "  ARM_SUBSCRIPTION_ID=$SUB_ID"
