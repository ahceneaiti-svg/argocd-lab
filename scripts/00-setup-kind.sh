#!/usr/bin/env bash
# Crée (ou réutilise) le cluster kind du lab.
set -euo pipefail

CLUSTER_NAME="${KIND_CLUSTER_NAME:-argocd-lab}"
NODE_IMAGE="${KIND_NODE_IMAGE:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIND_CONFIG="${KIND_CONFIG:-${SCRIPT_DIR}/../kind/cluster.yaml}"

if kind get clusters 2>/dev/null | grep -qx "${CLUSTER_NAME}"; then
  echo "Cluster kind '${CLUSTER_NAME}' déjà présent, réutilisation."
else
  create_args=(--name "${CLUSTER_NAME}")
  [ -f "${KIND_CONFIG}" ] && create_args+=(--config "${KIND_CONFIG}")
  [ -n "${NODE_IMAGE}" ] && create_args+=(--image "${NODE_IMAGE}")
  kind create cluster "${create_args[@]}"
fi

kubectl config use-context "kind-${CLUSTER_NAME}"
kubectl cluster-info
