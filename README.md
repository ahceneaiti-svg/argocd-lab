# Lab ArgoCD sur kind

Lab local pour apprendre ArgoCD : cluster [kind](https://kind.sigs.k8s.io/) + ArgoCD installé via Helm + une Application d'exemple (GitOps).

## Prérequis

- `kind`
- `docker` (runtime des noeuds kind)
- `kubectl`
- `helm`
- `argocd` CLI (optionnel, pour login en ligne de commande)

## Structure

```
.
├── scripts/
│   ├── 00-setup-kind.sh          # crée (ou réutilise) le cluster kind
│   ├── 01-install-argocd.sh      # installe ArgoCD via Helm dans le namespace argocd
│   ├── 02-get-admin-password.sh  # récupère le mot de passe admin initial
│   └── 03-port-forward.sh        # expose l'UI ArgoCD sur https://localhost:8080
├── kind/
│   └── cluster.yaml              # config kind mono-noeud du lab
├── helm/
│   └── values.yaml               # valeurs Helm adaptées à un lab kind
└── apps/
    └── example-apps-of-apps.yaml  # app-of-apps : déploie tous les exemples de argocd-example-apps
```

## Démarrage rapide

```bash
./scripts/00-setup-kind.sh
./scripts/01-install-argocd.sh
./scripts/02-get-admin-password.sh
./scripts/03-port-forward.sh
```

Puis ouvrir https://localhost:8080 (accepter le certificat auto-signé), login `admin` / mot de passe affiché.

Overrides via variables d'environnement : `KIND_CLUSTER_NAME` (défaut `argocd-lab`),
`KIND_NODE_IMAGE` (image des noeuds, ex. `kindest/node:v1.31.0`), `KIND_CONFIG` (chemin du
fichier de config kind), `ARGOCD_NAMESPACE`, `ARGOCD_RELEASE`, `ARGOCD_LOCAL_PORT`.

Le contexte kubectl créé par kind s'appelle `kind-<KIND_CLUSTER_NAME>` (ex. `kind-argocd-lab`).

## Déployer toutes les applications d'exemple

```bash
kubectl apply -f apps/example-apps-of-apps.yaml
```

Ceci déploie une Application "app-of-apps" (`example-apps`) qui utilise le chart Helm `apps/` du dépôt
[`argoproj/argocd-example-apps`](https://github.com/argoproj/argocd-example-apps) pour créer une Application
enfant par exemple : `guestbook`, `helm-guestbook`, `kustomize-guestbook`, `jsonnet-guestbook`,
`jsonnet-guestbook-tla`, `helm-dependency`, `helm-hooks`, `pre-post-sync`, `sync-waves`, `sock-shop`,
`blue-green`, `applicationset` — chacune dans son propre namespace, sync automatique + self-heal.

Le `values.yaml` par défaut du chart amont a un bug (`nil pointer` sur `.destination.namespace` pour les
apps sans clé `destination`) : le manifeste le corrige en réécrivant la liste `applications` en valeurs
Helm inline. Sont volontairement omis :

- `plugin-*` : nécessitent un sidecar config-management-plugin non configuré dans `helm/values.yaml`
- `app-any-ns*` (`lightweight/*`) : nécessitent des AppProjects dédiés (`team-frontend`/`team-backend`/`team-platform`)

Limitations connues sur ce lab single-cluster :

- `example.blue-green` reste `OutOfSync`/`Missing` : nécessite le CRD `Rollout.argoproj.io` (Argo Rollouts),
  non installé ici.
- `example.applicationset` déploie lui-même d'autres Applications/ApplicationSets (`appset-*`) ; les variantes
  `appset-progressive-*` restent `Missing` car elles ciblent des environnements multi-cluster qui n'existent
  pas dans ce lab.
- `example.helm-hooks` / `example.sync-waves` peuvent rester `Missing` un moment : leurs Jobs de hook tirent
  `alpine:latest` / `nginx:latest`, ce qui peut être lent au premier pull sur kind.

## Accès à l'UI sans port-forward (optionnel)

`kind/cluster.yaml` mappe le `hostPort` 8080 vers le `nodePort` 30080. Pour l'utiliser, basculer
`server.service.type` sur `NodePort` (avec `nodePort: 30080`) dans `helm/values.yaml`, réinstaller,
puis accéder à https://localhost:8080 directement. Par défaut le lab passe par `03-port-forward.sh`.

## Nettoyage

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
kind delete cluster --name argocd-lab   # ou la valeur de KIND_CLUSTER_NAME
```
