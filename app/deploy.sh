#!/bin/bash
# =============================================================================
# Deploy 3-tier app + MLOps to AKS
# Usage: ./deploy.sh
# =============================================================================
set -e

ACR="acrdevpset49.azurecr.io"

echo "🔐 Logging into ACR..."
az acr login --name acrdevpset49

echo "🏗️  Building and pushing images..."

# Backend
docker build -t $ACR/backend:latest ./backend
docker push $ACR/backend:latest

# Frontend  
docker build -t $ACR/frontend:latest ./frontend
docker push $ACR/frontend:latest

# MLOps
docker build -t $ACR/mlops:latest ./mlops
docker push $ACR/mlops:latest

echo "☸️  Deploying to AKS..."
az aks get-credentials --resource-group mlops3tier-dev-rg --name mlops3tier-dev-pset49-aks --overwrite-existing

# Replace ACR placeholder and apply
sed "s|ACRSERVER|$ACR|g" k8s/manifests.yaml | kubectl apply -f -

echo "⏳ Waiting for deployments..."
kubectl rollout status deployment/backend
kubectl rollout status deployment/frontend
kubectl rollout status deployment/mlops-server

echo ""
echo "✅ Deployment complete!"
echo ""
kubectl get pods
echo ""
echo "🌐 Getting external IPs (may take 2-3 mins)..."
kubectl get svc frontend-svc mlops-svc
