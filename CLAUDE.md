# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Local ArgoCD lab: a Minikube cluster with ArgoCD installed via the official Helm chart (`argo/argo-cd` from `https://argoproj.github.io/argo-helm`), plus an app-of-apps deployment of the `argoproj/argocd-example-apps` examples. Not an application codebase — no build/lint/test tooling exists here.

## Commands

Run in order from repo root:

```bash
./scripts/00-setup-minikube.sh      # start/reuse the minikube cluster (driver: docker)
./scripts/01-install-argocd.sh      # helm repo add/update + helm upgrade --install into namespace argocd
./scripts/02-get-admin-password.sh  # print the initial admin password
./scripts/03-port-forward.sh        # kubectl port-forward argocd-server -> https://localhost:8080
```

Deploy all example applications (app-of-apps: creates one child `Application` per example in `argoproj/argocd-example-apps`, e.g. `guestbook`, `helm-guestbook`, `kustomize-guestbook`, `sock-shop`, `blue-green`, `applicationset`, ...):

```bash
kubectl apply -f apps/example-apps-of-apps.yaml
```

Cleanup:

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
minikube stop        # or: minikube delete
```

All scripts are idempotent (`helm upgrade --install`, `kubectl create ns --dry-run=client | kubectl apply`) — safe to re-run against an already-provisioned cluster. Scripts read overrides from env vars (`MINIKUBE_CPUS`, `MINIKUBE_MEMORY`, `MINIKUBE_DRIVER`, `ARGOCD_NAMESPACE`, `ARGOCD_RELEASE`, `ARGOCD_LOCAL_PORT`) rather than hardcoded flags.

## Structure

- `scripts/` — numbered setup steps (00 cluster, 01 install, 02 credentials, 03 UI access), meant to run in sequence.
- `helm/values.yaml` — Helm overrides for the `argo-cd` chart, tuned for minikube: HA disabled, single replica per component, reduced CPU/memory requests/limits, `server.insecure: false`.
- `apps/` — ArgoCD `Application` manifests (GitOps definitions), applied directly with `kubectl apply` after ArgoCD is up. `example-apps-of-apps.yaml` is the sole entry point; it overrides the upstream chart's `applications` values list inline (via `source.helm.values`) to work around a bug in that chart's default `values.yaml` (missing `destination` key causes a Helm template nil-pointer) and to omit examples that need infra this lab doesn't set up (config-management-plugin sidecars, multi-tenant `AppProject`s).

## Known limitations of the deployed example apps

- `example.blue-green` stays `OutOfSync`/`Missing`: needs the `Rollout.argoproj.io` CRD (Argo Rollouts), not installed here.
- `example.applicationset`'s generated `appset-progressive-*` children stay `Missing`: they target multi-cluster environments that don't exist in this single-cluster lab.
- `example.helm-hooks` / `example.sync-waves` can stay `Missing` for a while: their hook Jobs pull `alpine:latest`/`nginx:latest`, slow on first pull under minikube.

## Conventions when extending this lab

- New Helm overrides go in `helm/values.yaml`, not as extra `--set` flags in the install script.
- New example apps are added to the `applications:` list inside `apps/example-apps-of-apps.yaml`'s inline Helm values (name + explicit `destination.namespace`, matching the upstream chart's schema), not as standalone `Application` manifests.
- New setup steps get a new numbered script in `scripts/`, sourcing the same env-var override convention as the existing ones.
