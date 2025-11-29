# Vault Kubernetes Deployer

Automated deployment script for integrating HashiCorp Vault with Kubernetes namespaces using the Vault Secrets Operator.

## Features

- 🚀 Automated Kubernetes namespace creation with Vault integration
- 🔐 Reads environment variables from .env files and creates empty secrets in Vault
- 🎯 Creates VaultAuth and VaultStaticSecret CRDs automatically
- ⚙️ Configurable TTL and Vault policies
- 🔒 Security-first: only key names are read from .env, values stay empty in Vault

## Prerequisites

- Kubernetes cluster with Vault Secrets Operator installed
- HashiCorp Vault server (can be outside the cluster)
- kubectl configured with cluster access
- vault CLI installed and authenticated
- Vault KV v2 secrets engine enabled at /secret
- Vault Kubernetes auth method configured (see Manual Setup section)

## Quick Start

### 1. Clone this repository

```bash
git clone https://github.com/badre2dine/vault-secret-k8s-configurator.git .vault
cd .vault
```

Or add as a git submodule:

```bash
git submodule add https://github.com/badre2dine/vault-secret-k8s-configurator.git .vault
```

### 2. Create your environment file

```bash
cp env.example .env
```

Edit .env with your keys and values:

```env
DATABASE_URL=postgresql://localhost:5432/mydb
API_KEY=your-api-key-here
AWS_ACCESS_KEY_ID=your-aws-key
```

**Important**: The script only reads KEY names from .env and creates empty secrets in Vault. Fill real values manually in Vault.

### 3. Run the deployment script

Basic usage (uses .env in current directory):

```bash
./deploy.sh my-namespace
```

With custom policy:

```bash
./deploy.sh my-namespace my-custom-policy
```

With custom TTL:

```bash
./deploy.sh my-namespace my-custom-policy 48h
```

With custom .env file path:

```bash
./deploy.sh my-namespace --env-file /path/to/.env
./deploy.sh my-namespace my-custom-policy 48h -e ../config/.env
```

Show help:

```bash
./deploy.sh --help
```

### 4. Fill secrets in Vault

```bash
vault kv put secret/my-namespace/app \
  DATABASE_URL="postgresql://prod:5432/db" \
  API_KEY="real-key" \
  AWS_ACCESS_KEY_ID="real-aws-key"
```

## What the Script Does

1. ✅ Creates Kubernetes namespace
2. ✅ Creates ServiceAccount (vault-access-sa)
3. ✅ Creates Vault role (k8s-namespace-{namespace})
4. ✅ Deploys VaultAuth CRD
5. ✅ Reads .env file and extracts KEY names
6. ✅ Creates VaultStaticSecret CRD
7. ✅ Creates empty secrets in Vault at secret/{namespace}/app

## Project Structure

```
.vault/
├── deploy.sh                   # Main deployment script
├── env.example                 # Template for .env file
├── policy.hcl                  # Vault policy configuration
├── vault-operator-values.yaml  # Vault Operator config example
├── README.md                   # This file
└── .gitignore                  # Git ignore patterns
```

## Configuration

### Script Options

```bash
./deploy.sh <namespace> [policy] [ttl] [options]
```

**Arguments:**
- `namespace` - Kubernetes namespace (required)
- `policy` - Vault policy name (default: k8s-namespaces)
- `ttl` - Token TTL (default: 24h)

**Options:**
- `-e, --env-file <path>` - Path to .env file (default: ./.env)
- `-h, --help` - Show help message

**Examples:**
```bash
./deploy.sh my-app
./deploy.sh data-ingestion k8s-namespaces 48h
./deploy.sh my-app --env-file /path/to/.env
./deploy.sh my-app k8s-namespaces 24h -e ../config/.env
```

### Default Values

- **Policy**: k8s-namespaces
- **TTL**: 24h
- **Secrets Path**: secret/{namespace}/app
- **Env File**: ./.env

### Customizing Vault Policy

```bash
vault policy write k8s-namespaces policy.hcl
```

## Security Notes

⚠️ **Important**:

1. Never commit .env files with real values
2. Secrets are created empty in Vault - fill manually
3. Use strong Vault policies per namespace
4. Rotate secrets regularly
5. Audit access to Vault secrets

## Troubleshooting

### Script fails with "Vault not authenticated"

```bash
vault login
```

### Secrets not appearing in pods

```bash
kubectl get vaultstaticsecret -n my-namespace
kubectl describe vaultstaticsecret vault-secret -n my-namespace
```

### VaultAuth connection issues

```bash
kubectl get vaultauth -n my-namespace
kubectl get serviceaccount vault-access-sa -n my-namespace
```

---

## Manual Vault Setup

Configure Vault Kubernetes authentication when Vault runs outside the cluster.

### Step 1: Create ServiceAccount

```bash
kubectl create sa vault-auth -n kube-system
```

### Step 2: Create Secret for Long-Lived Token

Create vault-auth-secret.yaml:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: "vault-auth"
type: kubernetes.io/service-account-token
```

Apply:

```bash
kubectl apply -f vault-auth-secret.yaml
```

### Step 3: Grant TokenReview Permissions

```bash
kubectl create clusterrolebinding vault-auth-review \
    --clusterrole=system:auth-delegator \
    --serviceaccount=kube-system:vault-auth
```

### Step 4: Verify Permission

```bash
kubectl auth can-i create tokenreviews \
  --as=system:serviceaccount:kube-system:vault-auth
```

Expected: yes

### Step 5: Retrieve Token

```bash
kubectl get secret vault-auth-token -n kube-system \
  -o jsonpath='{.data.token}' | base64 -d
```

### Step 6: Retrieve Cluster CA

```bash
kubectl config view --raw --minify \
  -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
```

### Step 7: Get API Server Address

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

Example: https://192.168.1.181:6443

### Step 8: Configure Vault Auth

```bash
vault write auth/kubernetes/config \
  token_reviewer_jwt="<TOKEN>" \
  kubernetes_host="https://192.168.1.181:6443" \
  kubernetes_ca_cert=@ca.crt
```

### Step 9: Verify Configuration

```bash
vault read auth/kubernetes/config
```

### Step 10: Create Vault Policy

```bash
vault policy write k8s-namespaces policy.hcl
```

### Step 11: Test from Pod

```bash
kubectl exec -it <pod> -n <namespace> -- sh
```

Inside pod:

```bash
vault write auth/kubernetes/login \
  role="k8s-namespace-<namespace>" \
  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

Expected output shows token and policies.

### Final Validation

✅ kubectl auth can-i create tokenreviews returns yes
✅ vault write auth/kubernetes/config succeeded
✅ Login from pod returns Vault token
✅ Vault role matches ServiceAccount and namespace

---

## Contributing

Contributions welcome! Open an issue or submit a pull request.

## License

MIT License

## Support

- GitHub Issues: https://github.com/badre2dine/vault-secret-k8s-configurator/issues
- Vault Docs: https://developer.hashicorp.com/vault/docs
- VSO Docs: https://developer.hashicorp.com/vault/docs/platform/k8s/vso
