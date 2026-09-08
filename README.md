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
│   └── 03-port-forward.sh        # fallback : port-forward de l'UI si le NodePort n'est pas utilisable
├── kind/
│   └── cluster.yaml              # config kind mono-noeud : mappe hostPort 8080 -> nodePort 30080
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
```

Puis ouvrir https://localhost:8080 (accepter le certificat auto-signé), login `admin` / mot de passe affiché.

L'UI est exposée directement : `helm/values.yaml` met `server.service` en `NodePort`
(https sur `30080`), et `kind/cluster.yaml` mappe le `hostPort` 8080 du noeud vers ce
`nodePort`. Aucun `port-forward` nécessaire. Si ce mapping n'est pas exploitable (port
8080 déjà pris, config kind modifiée), utiliser le fallback :

```bash
./scripts/03-port-forward.sh
```

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

## Accès à l'UI

| Chemin | Détail |
| --- | --- |
| NodePort (défaut) | `server.service.type: NodePort`, https sur `nodePort` 30080 ; `kind/cluster.yaml` mappe le `hostPort` 8080 dessus. `https://localhost:8080` directement après `01-install-argocd.sh`. |
| port-forward (fallback) | `./scripts/03-port-forward.sh` fait `kubectl port-forward service/argocd-server 8080:443`. À utiliser si le `hostPort` 8080 est déjà occupé ou si `kind/cluster.yaml` a été modifié. |

Le chart applique `nodePortHttp` au port http **et** `nodePortHttps` au port https ; `helm/values.yaml`
fixe donc deux valeurs distinctes (`30081` / `30080`) pour éviter un `duplicate nodePort` au déploiement.

## Nettoyage

```bash
helm uninstall argocd -n argocd
kubectl delete namespace argocd
kind delete cluster --name argocd-lab   # ou la valeur de KIND_CLUSTER_NAME
```
