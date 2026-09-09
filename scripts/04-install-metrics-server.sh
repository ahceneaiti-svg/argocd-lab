#!/usr/bin/env bash
# Installe metrics-server, requis par les HorizontalPodAutoscaler à métriques CPU
# (ex. l'app "autoscaling"). kind ne le fournit pas : sans lui l'API
# metrics.k8s.io est absente et le HPA reste en "<unknown>/50%".
#
# Le manifeste upstream est patché avec --kubelet-insecure-tls : le certificat
# servant du kubelet de kind n'est pas signé par la CA du cluster, donc la
# collecte échoue en TLS strict.
set -euo pipefail

NAMESPACE="${METRICS_SERVER_NAMESPACE:-kube-system}"
MANIFEST_URL="${METRICS_SERVER_MANIFEST:-https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml}"

kubectl apply -f "${MANIFEST_URL}"

# Idempotent : n'ajoute le flag que s'il n'est pas déjà présent.
if ! kubectl -n "${NAMESPACE}" get deployment metrics-server \
  -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q -- '--kubelet-insecure-tls'; then
  kubectl -n "${NAMESPACE}" patch deployment metrics-server --type=json \
    -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'
fi

kubectl -n "${NAMESPACE}" rollout status deployment/metrics-server --timeout=120s
kubectl top nodes
