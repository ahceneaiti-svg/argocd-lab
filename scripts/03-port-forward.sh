#!/usr/bin/env bash
# Expose l'UI ArgoCD en local sur https://localhost:8080
set -euo pipefail

NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"
LOCAL_PORT="${ARGOCD_LOCAL_PORT:-8080}"

echo "UI disponible sur https://localhost:${LOCAL_PORT} (Ctrl+C pour arrêter)"
kubectl port-forward service/argocd-server -n "${NAMESPACE}" "${LOCAL_PORT}:443"
