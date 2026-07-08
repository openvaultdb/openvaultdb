# Kubernetes Deployment

> **Status: Draft — pending Fable 5 architecture and security review.**

## Purpose

Specify the Kubernetes deployment model for production OpenVaultDB instances: Helm chart structure, configuration, high-availability considerations, and operational guidance.

## Deployment Model Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                         │
│                                                                 │
│  ┌──────────────┐    ┌─────────────────────────────────────┐   │
│  │   Ingress    │    │         openvaultdb Namespace        │   │
│  │  (TLS term.) │───▶│                                     │   │
│  └──────────────┘    │  ┌─────────────────┐               │   │
│                      │  │  ovdb Deployment│               │   │
│                      │  │  (3 replicas)   │               │   │
│                      │  └────────┬────────┘               │   │
│                      │           │                         │   │
│                      │  ┌────────▼────────┐               │   │
│                      │  │   ConfigMap     │               │   │
│                      │  │   Secrets (ext) │               │   │
│                      │  └────────┬────────┘               │   │
│                      │           │                         │   │
│                      │  ┌────────▼────────┐               │   │
│                      │  │  External DB    │               │   │
│                      │  │  (PostgreSQL or │               │   │
│                      │  │   Firestore)    │               │   │
│                      │  └─────────────────┘               │   │
│                      └─────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Helm Chart Structure (Draft)

```
helm/openvaultdb/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml              # Horizontal Pod Autoscaler
│   └── networkpolicy.yaml
└── README.md
```

## Draft `values.yaml`

```yaml
# values.yaml — draft defaults

replicaCount: 1  # Increase for HA

image:
  repository: ghcr.io/openvaultdb/ovdb
  pullPolicy: IfNotPresent
  tag: ""  # Defaults to chart appVersion

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: false
  className: ""
  annotations: {}
  hosts:
    - host: vault.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: vault-tls
      hosts:
        - vault.example.com

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

autoscaling:
  enabled: false
  minReplicas: 1
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80

config:
  server:
    baseUrl: ""  # Required: external base URL
    port: 8080

  storage:
    provider: sqlite  # sqlite | github | firestore
    sqlite:
      path: /data/vault.db

  identity:
    provider: builtin  # builtin | oidc
    oidc:
      issuer: ""
      clientId: ""
      # clientSecret provided via secret

  billing:
    provider: disabled  # disabled | stripe

  audit:
    provider: local
    local:
      path: /data/audit.log

secrets:
  # Reference to existing secret containing sensitive values
  existingSecret: ""
  # Keys in the secret:
  #   OVDB_IDENTITY_OIDC_CLIENT_SECRET
  #   OVDB_STORAGE_GITHUB_TOKEN
  #   OVDB_BILLING_STRIPE_SECRET_KEY

persistence:
  enabled: true
  storageClass: ""
  accessMode: ReadWriteOnce
  size: 5Gi
```

## High-Availability Configuration

For production HA deployments:
- `replicaCount: 3` minimum
- Requires external database (PostgreSQL recommended; SQLite not suitable for multiple replicas)
- Session affinity or stateless token validation required
- Pod Disruption Budget (PDB) recommended

```yaml
# HA values override
replicaCount: 3
config:
  storage:
    provider: firestore
    # or: PostgreSQL via future plugin
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
```

> **Open question**: PostgreSQL StorageProvider is not in the MVP plugin set. HA deployments need a replicated backend. Is Firestore the only MVP option for HA, or should PostgreSQL be prioritized?

## Secrets Management

Recommended approach: External Secrets Operator with HashiCorp Vault, AWS SSM, or GCP Secret Manager.

```yaml
# ExternalSecret example (draft)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: ovdb-secrets
spec:
  secretStoreRef:
    name: vault-secret-store
    kind: SecretStore
  target:
    name: ovdb-secrets
  data:
    - secretKey: OVDB_IDENTITY_OIDC_CLIENT_SECRET
      remoteRef:
        key: ovdb/oidc-client-secret
```

> **Alternative**: Kubernetes Secrets without External Secrets Operator. Simpler setup; secrets are base64-encoded in etcd (less secure without etcd encryption).

## Network Policies (Draft)

```yaml
# Restrict egress to necessary endpoints only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ovdb-network-policy
spec:
  podSelector:
    matchLabels:
      app: ovdb
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress-nginx
      ports:
        - port: 8080
  egress:
    - to: []  # Allow all egress (storage providers, OIDC, billing)
      ports:
        - port: 443
```

> **Note**: Egress policy depends on storage provider endpoints. GitHub, Firestore, and OIDC providers all require outbound HTTPS.

## Resource Recommendations (Draft)

| Deployment Size | CPU Request | Memory Request | Replicas |
|---|---|---|---|
| Development | 100m | 128Mi | 1 |
| Small production | 200m | 256Mi | 2 |
| Medium production | 500m | 512Mi | 3 |
| Large production | 1000m | 1Gi | 5+ |

> **Note**: These are draft estimates. Actual requirements depend on vault size, request rate, and migration frequency.

## Install Command (Draft)

```bash
helm repo add openvaultdb https://charts.openvaultdb.com
helm repo update
helm install ovdb openvaultdb/openvaultdb \
  --namespace openvaultdb \
  --create-namespace \
  --values my-values.yaml
```

## Upgrade

```bash
helm upgrade ovdb openvaultdb/openvaultdb \
  --namespace openvaultdb \
  --values my-values.yaml
```

> **Risk**: Helm upgrades that include server database schema changes require running `ovdb server migrate` before the new pods start. The Helm chart should include an init container or Job for this.

## Open Questions

1. Should the Helm chart include an init container for database migrations?
2. Is a Kubernetes Operator appropriate for managing OpenVaultDB instances?
3. How should HA be supported before a PostgreSQL plugin exists?
4. What monitoring stack should be bundled (Prometheus ServiceMonitor)?
5. Should a Helm chart test be included for CI validation?

## Risks

- SQLite with persistent volume is not suitable for multiple replicas (split-brain).
- Secret management configuration is complex and error-prone for new operators.
- Resource limits may be too low for large vault migrations.

## Acceptance Criteria

- Helm chart installs successfully with default values on a kind cluster.
- Server starts and passes health check after install.
- Upgrade with `helm upgrade` does not cause data loss.
- Network policy templates restrict unnecessary ingress/egress.

## Related Specifications

- [docker-compose.md](docker-compose.md)
- [../open-source/self-hosting.md](../open-source/self-hosting.md)
- [../architecture/reference-implementation.md](../architecture/reference-implementation.md)
