# vso-policy.hcl
path "secret/data/k8s/data-ingestion" {
  capabilities = ["read", "list"]
}