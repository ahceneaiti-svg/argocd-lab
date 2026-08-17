#!/usr/bin/env bash
# Démarre (ou réutilise) le cluster minikube du lab.
set -euo pipefail

CPUS="${MINIKUBE_CPUS:-4}"
MEMORY="${MINIKUBE_MEMORY:-6g}"
DRIVER="${MINIKUBE_DRIVER:-docker}"

minikube start --cpus="${CPUS}" --memory="${MEMORY}" --driver="${DRIVER}"
kubectl config use-context minikube
kubectl cluster-info
