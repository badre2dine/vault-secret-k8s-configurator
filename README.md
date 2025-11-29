# Vault Kubernetes Deployer# Vault Kubernetes Deployer# Documentation: Kubernetes Authentication Configuration for Vault (Vault outside cluster)



Automated deployment script for integrating HashiCorp Vault with Kubernetes namespaces using the Vault Secrets Operator.



## FeaturesAutomated deployment script for integrating HashiCorp Vault with Kubernetes namespaces using the Vault Secrets Operator.## 1. Objective



- 🚀 Automated Kubernetes namespace creation with Vault integrationConfigure the **Kubernetes** auth method in HashiCorp Vault when **Vault runs outside the Kubernetes cluster**, using a **dedicated ServiceAccount** with a "long-lived" token.

- 🔐 Reads environment variables from `.env` files and creates empty secrets in Vault

- 🎯 Creates VaultAuth and VaultStaticSecret CRDs automatically## Features

- ⚙️ Configurable TTL and Vault policies

- 🔒 Security-first: only key names are read from `.env`, values stay empty in Vault---



## Prerequisites- 🚀 Automated Kubernetes namespace creation with Vault integration



- Kubernetes cluster with Vault Secrets Operator installed- 🔐 Reads environment variables from `.env` files and creates empty secrets in Vault## 2. Prerequisites

- HashiCorp Vault server (can be outside the cluster)

- `kubectl` configured with cluster access- 🎯 Creates VaultAuth and VaultStaticSecret CRDs automatically- A functional Kubernetes cluster

- `vault` CLI installed and authenticated

- Vault KV v2 secrets engine enabled at `/secret`- ⚙️ Configurable TTL and Vault policies- `kubectl` configured

- Vault Kubernetes auth method configured (see Manual Setup section below)

- 🔒 Security-first: only key names are read from `.env`, values stay empty in Vault- `vault` CLI configured to access your Vault instance

## Quick Start

- Administrator access to the cluster

### 1. Clone this repository

## Prerequisites

```bash

git clone https://github.com/YOUR_USERNAME/vault-k8s-deployer.git .vault---

cd .vault

```- Kubernetes cluster with Vault Secrets Operator installed



Or add as a git submodule:- HashiCorp Vault server (can be outside the cluster)## 3. Creating the Vault ServiceAccount



```bash- `kubectl` configured with cluster access```bash

git submodule add https://github.com/YOUR_USERNAME/vault-k8s-deployer.git .vault

```- `vault` CLI installed and authenticatedkubectl create sa vault-auth -n kube-system



### 2. Create your environment file- Vault KV v2 secrets engine enabled at `/secret````



Copy the example and add your environment variable keys:- Vault Kubernetes auth method configured (see [Manual Setup](#manual-vault-setup) below)



```bash---

cp env.example .env

```## Quick Start



Edit `.env` with your actual keys and values for local development:## 4. Creating a Secret to Obtain a Long-Lived Token



```env### 1. Clone this repositoryCreate a file `vault-auth-secret.yaml`:

DATABASE_URL=postgresql://localhost:5432/mydb

API_KEY=your-api-key-here

AWS_ACCESS_KEY_ID=your-aws-key

``````bash```yaml



**Important**: The script only reads the KEY names from `.env` and creates **empty** secrets in Vault. You must manually fill in the real values in Vault for security.git clone https://github.com/YOUR_USERNAME/vault-k8s-deployer.git .vaultapiVersion: v1



### 3. Run the deployment scriptcd .vaultkind: Secret



Basic usage (creates namespace with default policy and TTL):```metadata:



```bash  name: vault-auth-token

./deploy.sh my-namespace

```Or add as a git submodule:  namespace: kube-system



With custom policy:  annotations:



```bash```bash    kubernetes.io/service-account.name: "vault-auth"

./deploy.sh my-namespace my-custom-policy

```git submodule add https://github.com/YOUR_USERNAME/vault-k8s-deployer.git .vaulttype: kubernetes.io/service-account-token



With custom policy and TTL:``````



```bash

./deploy.sh my-namespace my-custom-policy 48h

```### 2. Create your environment fileApply:



### 4. Fill secrets in Vault```bash



After deployment, fill the empty secrets with real values in Vault:Copy the example and add your environment variable keys:kubectl apply -f vault-auth-secret.yaml



```bash```

vault kv put secret/my-namespace/app \

  DATABASE_URL="postgresql://prod-db:5432/mydb" \```bash

  API_KEY="real-api-key-here" \

  AWS_ACCESS_KEY_ID="real-aws-key"cp env.example .env---

```

```

## What the Script Does

## 5. Grant TokenReview Permissions (RBAC)

1. ✅ Creates Kubernetes namespace

2. ✅ Creates ServiceAccount (`vault-access-sa`)Edit `.env` with your actual keys and values for local development:```bash

3. ✅ Creates Vault role (`k8s-namespace-{namespace}`)

4. ✅ Deploys VaultAuth CRD for authenticationkubectl create clusterrolebinding vault-auth-review \

5. ✅ Reads `.env` file and extracts KEY names

6. ✅ Creates VaultStaticSecret CRD```env    --clusterrole=system:auth-delegator \

7. ✅ Creates empty secrets in Vault at `secret/{namespace}/app`

DATABASE_URL=postgresql://localhost:5432/mydb    --serviceaccount=kube-system:vault-auth

## Project Structure

API_KEY=your-api-key-here```

```

.vault/AWS_ACCESS_KEY_ID=your-aws-key

├── deploy.sh          # Main deployment script

├── env.example        # Template for .env file```---

├── policy.hcl         # Vault policy configuration

├── README.md          # This file

└── .gitignore         # Git ignore patterns

```**Important**: The script only reads the KEY names from `.env` and creates **empty** secrets in Vault. You must manually fill in the real values in Vault for security.## 6. Verify that the SA has TokenReview Permission



## Configuration```bash



### Default Values### 3. Run the deployment scriptkubectl auth can-i create tokenreviews \



- **Policy**: `k8s-namespaces` (Vault policy to attach to the role)  --as=system:serviceaccount:kube-system:vault-auth

- **TTL**: `24h` (Time-to-live for Vault tokens)

- **Secrets Path**: `secret/{namespace}/app`Basic usage (creates namespace with default policy and TTL):```



### Customizing Vault PolicyExpected result:



Edit `policy.hcl` and apply it to Vault:```bash```



```bash./deploy.sh my-namespaceyes

vault policy write k8s-namespaces policy.hcl

`````````



## Security Notes



⚠️ **Important Security Considerations**:With custom policy:---



1. **Never commit `.env` files** with real values to git (they're in `.gitignore`)

2. **Secrets are created empty** in Vault - you must fill them manually

3. **Use strong Vault policies** to limit access per namespace```bash## 7. Retrieve the Secret Token

4. **Rotate secrets regularly** using Vault's TTL features

5. **Audit access** to Vault secrets regularly./deploy.sh my-namespace my-custom-policy```bash



## Troubleshooting```kubectl get secret vault-auth-token -n kube-system -o jsonpath='{.data.token}' | base64 -d



### Script fails with "Vault not authenticated"```



```bashWith custom policy and TTL:Keep this token: it will be used as `token_reviewer_jwt`.

vault login

```



### Secrets not appearing in pods```bash---



Check VaultStaticSecret status:./deploy.sh my-namespace my-custom-policy 48h



```bash```## 8. Retrieve the Cluster CA

kubectl get vaultstaticsecret -n my-namespace

kubectl describe vaultstaticsecret vault-secret -n my-namespace```bash

```

### 4. Fill secrets in Vaultkubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

### VaultAuth connection issues

```

Verify Vault address and ServiceAccount:

After deployment, fill the empty secrets with real values in Vault:

```bash

kubectl get vaultauth -n my-namespace---

kubectl get serviceaccount vault-access-sa -n my-namespace

``````bash



---vault kv put secret/my-namespace/app \## 9. Retrieve the API Server



## Manual Vault Setup  DATABASE_URL="postgresql://prod-db:5432/mydb" \```bash



If you need to configure Vault Kubernetes authentication manually (required before using this tool), follow these steps:  API_KEY="real-api-key-here" \kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'



### Objective  AWS_ACCESS_KEY_ID="real-aws-key"```



Configure the **Kubernetes** auth method in HashiCorp Vault when **Vault runs outside the Kubernetes cluster**, using a **dedicated ServiceAccount** with a long-lived token.```Example:



### Step 1: Create the Vault ServiceAccount```



```bash## What the Script Doeshttps://192.168.1.181:6443

kubectl create sa vault-auth -n kube-system

``````



### Step 2: Create a Secret for Long-Lived Token1. ✅ Creates Kubernetes namespace



Create a file `vault-auth-secret.yaml`:2. ✅ Creates ServiceAccount (`vault-access-sa`)---



```yaml3. ✅ Creates Vault role (`k8s-namespace-{namespace}`)

apiVersion: v1

kind: Secret4. ✅ Deploys VaultAuth CRD for authentication## 10. Configure the Auth Method on Vault

metadata:

  name: vault-auth-token5. ✅ Reads `.env` file and extracts KEY names```bash

  namespace: kube-system

  annotations:6. ✅ Creates VaultStaticSecret CRDvault write auth/kubernetes/config \

    kubernetes.io/service-account.name: "vault-auth"

type: kubernetes.io/service-account-token7. ✅ Creates empty secrets in Vault at `secret/{namespace}/app`  token_reviewer_jwt="<TOKEN_LONG_LIVED>" \

```

  kubernetes_host="https://192.168.1.181:6443" \

Apply:

## Project Structure  kubernetes_ca_cert=@ca.crt

```bash

kubectl apply -f vault-auth-secret.yaml```

```

```Expected result:

### Step 3: Grant TokenReview Permissions

.vault/```

```bash

kubectl create clusterrolebinding vault-auth-review \├── deploy.sh          # Main deployment scriptSuccess! Data written to: auth/kubernetes/config

    --clusterrole=system:auth-delegator \

    --serviceaccount=kube-system:vault-auth├── env.example        # Template for .env file```

```

├── policy.hcl         # Vault policy configuration

### Step 4: Verify TokenReview Permission

├── README.md          # This file---

```bash

kubectl auth can-i create tokenreviews \└── .gitignore         # Git ignore patterns

  --as=system:serviceaccount:kube-system:vault-auth

``````## 11. Verify the Configuration on Vault



Expected result: `yes````bash



### Step 5: Retrieve the Secret Token## Configurationvault read auth/kubernetes/config



```bash```

kubectl get secret vault-auth-token -n kube-system -o jsonpath='{.data.token}' | base64 -d

```### Default Values



Keep this token - it will be used as `token_reviewer_jwt`.---



### Step 6: Retrieve the Cluster CA- **Policy**: `k8s-namespaces` (Vault policy to attach to the role)## 12. Create policy



```bash- **TTL**: `24h` (Time-to-live for Vault tokens)```bash

kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt

```- **Secrets Path**: `secret/{namespace}/app`vault policy write k8s-namespaces policy.json



### Step 7: Retrieve the API Server Address```



```bash### Customizing Vault Policy## 12. Create a Vault Role

kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'

``````bash



Example: `https://192.168.1.181:6443`Edit `policy.hcl` and apply it to Vault:vault write auth/kubernetes/role/k8s-namespace-data-ingestion \



### Step 8: Configure the Auth Method on Vault    bound_service_account_names="vault-access-sa" \



```bash```bash    bound_service_account_namespaces="data-ingestion" \

vault write auth/kubernetes/config \

  token_reviewer_jwt="<TOKEN_LONG_LIVED>" \vault policy write k8s-namespaces policy.hcl    policies="k8s-namespaces" \

  kubernetes_host="https://192.168.1.181:6443" \

  kubernetes_ca_cert=@ca.crt```    audience=vault \

```

    ttl=24h

Expected result: `Success! Data written to: auth/kubernetes/config`

## Security Notes```

### Step 9: Verify the Configuration



```bash

vault read auth/kubernetes/config⚠️ **Important Security Considerations**:Adjust with your actual namespace and ServiceAccount.

```



### Step 10: Create the Vault Policy

1. **Never commit `.env` files** with real values to git (they're in `.gitignore`)---

```bash

vault policy write k8s-namespaces policy.hcl2. **Secrets are created empty** in Vault - you must fill them manually## 13. 

```

3. **Use strong Vault policies** to limit access per namespace## 13. Verification from a Pod (Login Test)

### Step 11: Test from a Pod

4. **Rotate secrets regularly** using Vault's TTL featuresFrom any pod:

From any pod:

5. **Audit access** to Vault secrets regularly```bash

```bash

kubectl exec -it <pod> -n <namespace> -- shkubectl exec -it <pod> -n <namespace> -- sh

```

## Troubleshooting```

Inside the pod:



```bash

vault write auth/kubernetes/login \### Script fails with "Vault not authenticated"Inside the pod:

  role="k8s-namespace-<namespace>" \

  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)```bash

```

```bashvault write auth/kubernetes/login \

Expected result:

vault login  role="demo-role" \

```

Key                Value```  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

---                -----

token              <vault-client-token>```

token_policies     ["default", "k8s-namespaces"]

```### Secrets not appearing in pods



### Final ValidationRésultat attendu :



The integration is successful if:Check VaultStaticSecret status:```



- ✅ `kubectl auth can-i create tokenreviews` returns **yes**Key                Value

- ✅ `vault write auth/kubernetes/config` succeeded

- ✅ Login from a pod returns a Vault token```bash---                -----

- ✅ The Vault role corresponds to the ServiceAccount and namespace

kubectl get vaultstaticsecret -n my-namespacetoken              <vault-client-token>

---

kubectl describe vaultstaticsecret vault-secret -n my-namespacetoken_policies     ["default" ...]

## Contributing

```metadata           map[...]

Contributions are welcome! Please open an issue or submit a pull request.

```

## License

### VaultAuth connection issues

MIT License

---

## Support

Verify Vault address and ServiceAccount:

For issues and questions:

- Open an issue on GitHub## 14. Validation finale

- Check the [Vault documentation](https://developer.hashicorp.com/vault/docs)

- Review [Vault Secrets Operator documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)```bashL’intégration est réussie si :


kubectl get vaultauth -n my-namespace- `kubectl auth can-i create tokenreviews` retourne **yes**

kubectl get serviceaccount vault-access-sa -n my-namespace- `vault write auth/.../config` a réussi

```- le login depuis un pod retourne un token Vault

- la Role Vault correspond bien au SA + namespace

---

---

## Manual Vault Setup

## 15. Fin

If you need to configure Vault Kubernetes authentication manually (required before using this tool), follow these steps:Cette documentation couvre l’ensemble du processus recommandé par HashiCorp pour l’authentification Kubernetes lorsque Vault tourne en dehors du cluster.



### 1. Objective

Configure the **Kubernetes** auth method in HashiCorp Vault when **Vault runs outside the Kubernetes cluster**, using a **dedicated ServiceAccount** with a long-lived token.

### 2. Prerequisites

- A functional Kubernetes cluster
- `kubectl` configured with administrator access
- `vault` CLI configured to access your Vault instance

### 3. Create the Vault ServiceAccount

```bash
kubectl create sa vault-auth -n kube-system
```

### 4. Create a Secret to Obtain a Long-Lived Token

Create a file `vault-auth-secret.yaml`:

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

### 5. Grant TokenReview Permissions (RBAC)

```bash
kubectl create clusterrolebinding vault-auth-review \
    --clusterrole=system:auth-delegator \
    --serviceaccount=kube-system:vault-auth
```

### 6. Verify TokenReview Permission

```bash
kubectl auth can-i create tokenreviews \
  --as=system:serviceaccount:kube-system:vault-auth
```

Expected result: `yes`

### 7. Retrieve the Secret Token

```bash
kubectl get secret vault-auth-token -n kube-system -o jsonpath='{.data.token}' | base64 -d
```

Keep this token - it will be used as `token_reviewer_jwt`.

### 8. Retrieve the Cluster CA

```bash
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
```

### 9. Retrieve the API Server Address

```bash
kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}'
```

Example: `https://192.168.1.181:6443`

### 10. Configure the Auth Method on Vault

```bash
vault write auth/kubernetes/config \
  token_reviewer_jwt="<TOKEN_LONG_LIVED>" \
  kubernetes_host="https://192.168.1.181:6443" \
  kubernetes_ca_cert=@ca.crt
```

Expected result: `Success! Data written to: auth/kubernetes/config`

### 11. Verify the Configuration

```bash
vault read auth/kubernetes/config
```

### 12. Create the Vault Policy

```bash
vault policy write k8s-namespaces policy.hcl
```

### 13. Verification from a Pod (Login Test)

From any pod:

```bash
kubectl exec -it <pod> -n <namespace> -- sh
```

Inside the pod:

```bash
vault write auth/kubernetes/login \
  role="k8s-namespace-<namespace>" \
  jwt=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

Expected result:

```
Key                Value
---                -----
token              <vault-client-token>
token_policies     ["default", "k8s-namespaces"]
metadata           map[...]
```

### 14. Final Validation

The integration is successful if:

- ✅ `kubectl auth can-i create tokenreviews` returns **yes**
- ✅ `vault write auth/kubernetes/config` succeeded
- ✅ Login from a pod returns a Vault token
- ✅ The Vault role corresponds to the ServiceAccount and namespace

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

MIT License

## Support

For issues and questions:
- Open an issue on GitHub
- Check the [Vault documentation](https://developer.hashicorp.com/vault/docs)
- Review [Vault Secrets Operator documentation](https://developer.hashicorp.com/vault/docs/platform/k8s/vso)
