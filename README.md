# ⚡ Enterprise GitOps Bootstrap: Zero-Lock S3 State Engine

This repository provides a production-grade **GitOps Bootstrap Foundation** that automates central remote state storage and dynamic configuration discovery across multi-repository Terraform environments.

---

## 🎯 What This Project Solves For Users

When managing infrastructure across multiple repositories (e.g., Bootstrap, Network, Applications), managing state files and resource identifiers manually leads to drift and state collisions.

* 🔐 **Centralized State Security:** Consolidates state storage into a single, permanent S3 bucket isolated by key paths (`bootstrap/`, `network/`, `app/`).
* 🔗 **Zero-Hardcoding Cross-Repo Discovery:** Uses AWS Systems Manager (SSM) Parameter Store to automatically publish state parameters for downstream pipelines.
* 🔒 **DynamoDB-Free Locking:** Native S3 state locking (`use_lockfile = true`) removes legacy DynamoDB locking overhead.
* 🛡️ **Safety from Accidental Deletion:** The core S3 bucket is decoupled from standard `terraform destroy` cycles, preventing state wipeouts during infrastructure teardowns.

---
## 🏗️ Architecture Overview

```text
                           ┌───────────────────────────┐
                           │   CENTRAL S3 BUCKET       │
                           │   rush-<ACCOUNT_ID>       │
                           │   (Persistent Storage)    │
                           └─────────────┬─────────────┘
                                         │
         ┌───────────────────────────────┼───────────────────────────────┐
         ▼                               ▼                               ▼
  ┌──────────────┐                ┌──────────────┐                ┌──────────────┐
  │  Repo 1      │                │  Repo 2      │                │  Repo 3      │
  │  (Bootstrap) │                │  (Network)   │                │  (App Stack) │
  │  key:        │                │  key:        │                │  key:        │
  │  bootstrap/  │                │  network/    │                │  app/        │
  │  tfstate     │                │  tfstate     │                │  tfstate     │
  └──────────────┘                └──────────────┘                └──────────────┘
```
---
# 📑 How To Use This Foundation in Your Infrastructure
## ⚙️ Phase 1: Prerequisites & AWS Configuration

1. Set Up GitHub Actions Secrets
     
  In your GitHub Repository, navigate to Settings -> Secrets and variables -> Actions and add:

    AWS_ACCESS_KEY_ID: IAM user/role access key.
    
    AWS_SECRET_ACCESS_KEY: IAM user/role secret key.

---
2. Configure Local Variables (Optional)
   
  In variables.tf, customize your base bucket prefix and target region:

```text
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type    = string
  default = "rush" # Evaluates to: rush-<YOUR_AWS_ACCOUNT_ID>
}
```

---
## 🚀 Phase 2: Deploying the Bootstrap Engine
1. Push to Main: Push your changes to the main branch to trigger the automated deployment workflow .github/workflows/deploy.yml.

2. Automated Pipeline Execution:

  Account Identity Resolution: Retrieves your 12-digit AWS Account ID dynamically via data "aws_caller_identity" "current" {}.
  
  S3 Bucket Creation: Provisions the bucket rush-<ACCOUNT_ID>.
  
  SSM Parameter Registration: Publishes the bucket name to /terraform/remote_state_bucket in AWS Systems Manager.


```text
# Optional: Deploy locally via CLI
terraform init
terraform plan
terraform apply -auto-approve
```

---

## 🔗 Phase 3: Integrating Downstream Repositories (Repo 2 / Repo 3)
Once Repo 1 completes execution, use the provisioned bucket in your downstream repositories (such as Network or Application repos).

### Step 1: Update backend.tf in Repo 2 / Repo 3
Configure the backend block using the generated central bucket name and a unique key path:

```text
terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "rush-123456789012"          # Generated S3 Bucket Name
    key          = "network/terraform.tfstate" # Unique path for this repo
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                        # Native S3 state locking (No DynamoDB required)
  }
}
```
---

### Step 2: Fetch Configuration via SSM Parameter (Optional)
Query the central SSM parameter in your downstream Terraform code to reference cross-repo outputs dynamically:

```text
data "aws_ssm_parameter" "state_bucket" {
  name = "/terraform/remote_state_bucket"
}

output "remote_bucket_in_use" {
  value = data.aws_ssm_parameter.state_bucket.value
}
```
---

### Step 3: Apply Infrastructure
Run terraform init and terraform apply in your downstream repository. Your .tfstate file is now safely stored centrally with native S3 locking enabled!


#📂 Repository Structure

```text
.
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 deploy.yml            # Automated CI/CD deployment pipeline
├── 📁 Modules/
│   └── 📁 remote_backend/           # Module defining S3 bucket specs
├── 📄 main.tf                       # Core logic & SSM Parameter definition
├── 📄 variables.tf                  # Input variables & region defaults
└── 📄 outputs.tf                    # Bucket ID & SSM Parameter path outputs
```
---

## 🛡️ Teardown & Maintenance Lifecycle
### 🧼 terraform destroy Safety: Running a teardown in Repo 1 removes ephemeral resources (SSM Parameter) while leaving the backend S3 bucket intact to protect state files from other repositories.

### 🗑️ Full Bucket Decommissioning: To remove the backend storage bucket during lab/sandbox teardowns, execute:

```text
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="rush-${ACCOUNT_ID}"

# Wipe object versions & delete markers
aws s3api delete-objects --bucket "$BUCKET_NAME" \
  --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

aws s3api delete-objects --bucket "$BUCKET_NAME" \
  --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

# Force remove empty bucket
aws s3 rb "s3://${BUCKET_NAME}" --force
```


## 🔗 Related Repositories
If you'd like to test this setup end-to-end, try combining it with the network layer configuration:

* 🌐 **Network Infrastructure:** [network-tier](https://github.com/RushikeshHarne/aws-terraform-network-tier.git) — Infrastructure provisioner for core network resources (VPC, Subnets, IGW).
