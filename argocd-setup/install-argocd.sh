#!/bin/bash

# Check if namespace argument is provided
if [ -z "$1" ]; then
  ARGOCD_NAMESPACE=""
  echo "No namespace provided, using default: $ARGOCD_NAMESPACE"
else
  ARGOCD_NAMESPACE="$1"
  echo "Using provided namespace: $ARGOCD_NAMESPACE"
fi

# Create namespace if it doesn't exist
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add ArgoCD Helm repo if not already added
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install ArgoCD with LoadBalancer service type
helm install argocd argo/argo-cd \
  --namespace $ARGOCD_NAMESPACE \
  --set server.service.type=LoadBalancer

# Wait for deployment to complete
echo "Waiting for ArgoCD server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE

# Get the service details
echo "ArgoCD server service:"
kubectl get svc argocd-server -n $ARGOCD_NAMESPACE

# Get the initial admin password
echo "Initial admin password:"
kubectl -n $ARGOCD_NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo

echo "ArgoCD has been installed successfully!"
echo "Access the UI using the LoadBalancer external IP"
echo "Username: admin"
echo "Remember to change the admin password and delete the argocd-initial-admin-secret after login"