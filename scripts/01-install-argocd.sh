#!/usr/bin/env bash
# Installe ArgoCD dans le namespace "argocd" via le chart Helm officiel.
set -euo pipefail

NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
RELEASE="${ARGOCD_RELEASE:-argocd}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update argo

kubectl create namespace "${NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install "${RELEASE}" argo/argo-cd \
  -n "${NAMESPACE}" \
  -f "${SCRIPT_DIR}/../helm/values.yaml"

kubectl -n "${NAMESPACE}" wait --for=condition=Available deployment --all --timeout=180s
kubectl -n "${NAMESPACE}" get pods
