#!/usr/bin/env bash
# Affiche le mot de passe admin initial généré par ArgoCD.
set -euo pipefail

NAMESPACE="${ARGOCD_NAMESPACE:-argocd}"

kubectl -n "${NAMESPACE}" get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo
