#!/bin/bash

# One-command deployment script for Vault + Kubernetes integration
# Usage: ./deploy.sh <namespace> [policy] [ttl]
# Example: ./deploy.sh my-app
# Note: Script will use .env file in the same directory

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Parameters
NAMESPACE=${1}
POLICY=${2:-"k8s-namespaces"}
TTL=${3:-"24h"}
SERVICE_ACCOUNT="vault-access-sa"
AUTH_MOUNT="kubernetes"
ROLE_NAME="k8s-namespace-${NAMESPACE}"
SECRET_PATH="k8s/${NAMESPACE}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

# Validate inputs
if [ -z "$NAMESPACE" ]; then
    echo -e "${RED}❌ Error: Namespace is required${NC}"
    echo ""
    echo "Usage: $0 <namespace> [policy] [ttl]"
    echo ""
    echo "Examples:"
    echo "  $0 my-app"
    echo "  $0 data-ingestion k8s-namespaces 48h"
    echo ""
    echo "Note: Edit .env file with your secrets before running"
    echo ""
    exit 1
fi

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🚀 Vault + Kubernetes Automated Deployment            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}Configuration:${NC}"
echo -e "  📦 Namespace:          ${GREEN}${NAMESPACE}${NC}"
echo -e "  🔐 Vault Role:         ${GREEN}${ROLE_NAME}${NC}"
echo -e "  📋 Policy:             ${GREEN}${POLICY}${NC}"
echo -e "  ⏱️  TTL:                ${GREEN}${TTL}${NC}"
echo -e "  👤 Service Account:    ${GREEN}${SERVICE_ACCOUNT}${NC}"
echo -e "  📁 Secret Path:        ${GREEN}secret/${SECRET_PATH}${NC}"
echo -e "  📄 Env File:           ${GREEN}.env${NC}"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ kubectl${NC}"

if ! command -v vault &> /dev/null; then
    echo -e "${RED}❌ vault CLI not found${NC}"
    exit 1
fi
echo -e "${GREEN}  ✓ vault CLI${NC}"

if ! vault token lookup &> /dev/null; then
    echo -e "${RED}❌ Not authenticated to Vault${NC}"
    echo "Please login: vault login"
    exit 1
fi
echo -e "${GREEN}  ✓ Vault authenticated${NC}"
echo ""

# Step 1: Create Kubernetes namespace
echo -e "${CYAN}📦 Step 1/5: Kubernetes Namespace${NC}"
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}  ✓ Namespace '${NAMESPACE}' already exists${NC}"
else
    kubectl create namespace ${NAMESPACE}
    echo -e "${GREEN}  ✓ Created namespace '${NAMESPACE}'${NC}"
fi
echo ""

# Step 2: Create ServiceAccount
echo -e "${CYAN}👤 Step 2/5: ServiceAccount${NC}"
kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: ${NAMESPACE}
  name: ${SERVICE_ACCOUNT}
EOF
echo -e "${GREEN}  ✓ ServiceAccount '${SERVICE_ACCOUNT}' created/updated${NC}"
echo ""

# Step 3: Create Vault Role
echo -e "${CYAN}🔐 Step 3/5: Vault Kubernetes Auth Role${NC}"
vault write auth/${AUTH_MOUNT}/role/${ROLE_NAME} \
    bound_service_account_names="${SERVICE_ACCOUNT}" \
    bound_service_account_namespaces="${NAMESPACE}" \
    policies="${POLICY}" \
    audience=vault \
    ttl="${TTL}" > /dev/null

echo -e "${GREEN}  ✓ Vault role '${ROLE_NAME}' created${NC}"
echo ""

# Step 4: Create VaultAuth
echo -e "${CYAN}🔗 Step 4/5: VaultAuth Resource${NC}"
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: static-auth
  namespace: ${NAMESPACE}
spec:
  method: kubernetes
  mount: ${AUTH_MOUNT}
  kubernetes:
    role: ${ROLE_NAME}
    serviceAccount: ${SERVICE_ACCOUNT}
    audiences:
      - vault
EOF
echo -e "${GREEN}  ✓ VaultAuth 'static-auth' created${NC}"
echo ""

# Step 5: Create VaultStaticSecret
echo -e "${CYAN}🔑 Step 5/5: VaultStaticSecret Resource${NC}"
kubectl apply -f - <<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: vault-kv-main
  namespace: ${NAMESPACE}
spec:
  type: kv-v2
  mount: secret
  path: ${SECRET_PATH}
  destination:
    name: vault-kv-main
    create: true
  refreshAfter: 10s
  vaultAuthRef: static-auth
EOF
echo -e "${GREEN}  ✓ VaultStaticSecret 'vault-kv-main' created${NC}"
echo ""

# Create secrets in Vault from .env file (with empty values)
echo -e "${CYAN}💾 Creating secrets in Vault from .env file...${NC}"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}  ❌ .env file not found: ${ENV_FILE}${NC}"
    echo -e "${YELLOW}  Please create a .env file with your secret keys${NC}"
    echo ""
    exit 1
fi

# Check if secret already exists
if vault kv get secret/${SECRET_PATH} &> /dev/null; then
    echo -e "${YELLOW}  ⚠️  Secret already exists at secret/${SECRET_PATH}${NC}"
    read -p "  Do you want to overwrite? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}  ⏭️  Skipping secret creation${NC}"
        echo ""
        SKIP_SECRET=true
    fi
fi

if [ -z "$SKIP_SECRET" ]; then
    # Read .env file and extract keys only (ignore values)
    echo -e "${GREEN}  📄 Reading secret keys from .env file${NC}"
    
    # Build vault kv put command from .env file
    VAULT_CMD="vault kv put secret/${SECRET_PATH}"
    SECRET_COUNT=0
    
    # Read .env file line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # Remove leading/trailing whitespace
        line=$(echo "$line" | xargs)
        
        # Parse KEY=VALUE format and extract only KEY
        if [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
            KEY=$(echo "$line" | cut -d'=' -f1 | xargs)
            
            # Create secret with EMPTY value in Vault
            VAULT_CMD="${VAULT_CMD} ${KEY}=\"\""
            echo -e "${CYAN}    + ${KEY}=${YELLOW}\"\" ${CYAN}(empty in Vault)${NC}"
            ((SECRET_COUNT++))
        fi
    done < "$ENV_FILE"
    
    if [ $SECRET_COUNT -eq 0 ]; then
        echo -e "${RED}  ❌ No valid secret keys found in .env file${NC}"
        echo -e "${YELLOW}  Make sure your .env file has KEY=VALUE format${NC}"
        echo ""
        exit 1
    fi
    
    # Execute vault command
    eval "$VAULT_CMD" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}  ✓ ${SECRET_COUNT} secrets created in Vault with EMPTY values${NC}"
        echo -e "${YELLOW}  💡 Update values in Vault UI or using:${NC}"
        echo -e "${YELLOW}     vault kv put secret/${SECRET_PATH} KEY=value${NC}"
    else
        echo -e "${RED}  ❌ Failed to create secrets in Vault${NC}"
        exit 1
    fi
fi
echo ""

# Wait for resources to sync
echo -e "${CYAN}⏳ Waiting for secret synchronization (5s)...${NC}"
sleep 5
echo ""

# Verification
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ✅ Deployment Complete!                                 ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}📊 Resource Status:${NC}"
echo ""
echo -e "${YELLOW}VaultAuth:${NC}"
kubectl get vaultauth -n ${NAMESPACE} 2>/dev/null || echo "  Not found"
echo ""
echo -e "${YELLOW}VaultStaticSecret:${NC}"
kubectl get vaultstaticsecret -n ${NAMESPACE} 2>/dev/null || echo "  Not found"
echo ""
echo -e "${YELLOW}Kubernetes Secret (synced from Vault):${NC}"
kubectl get secret vault-kv-main -n ${NAMESPACE} 2>/dev/null || echo "  Not synced yet (wait a few seconds)"
echo ""

# Useful commands
echo -e "${CYAN}📖 Useful Commands:${NC}"
echo ""
echo -e "${GREEN}# Check VaultAuth status${NC}"
echo "  kubectl describe vaultauth static-auth -n ${NAMESPACE}"
echo ""
echo -e "${GREEN}# Check VaultStaticSecret status${NC}"
echo "  kubectl describe vaultstaticsecret vault-kv-main -n ${NAMESPACE}"
echo ""
echo -e "${GREEN}# View synced secret${NC}"
echo "  kubectl get secret vault-kv-main -n ${NAMESPACE} -o yaml"
echo ""
echo -e "${GREEN}# Decode secret values${NC}"
echo "  kubectl get secret vault-kv-main -n ${NAMESPACE} -o jsonpath='{.data.username}' | base64 -d"
echo ""
echo -e "${GREEN}# Update secret in Vault${NC}"
echo "  vault kv put secret/${SECRET_PATH} username=newuser password=newpass"
echo ""
echo -e "${GREEN}# View Vault role${NC}"
echo "  vault read auth/${AUTH_MOUNT}/role/${ROLE_NAME}"
echo ""
echo -e "${GREEN}# Delete everything${NC}"
echo "  kubectl delete vaultstaticsecret,vaultauth,serviceaccount -n ${NAMESPACE} --all"
echo "  vault delete auth/${AUTH_MOUNT}/role/${ROLE_NAME}"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
