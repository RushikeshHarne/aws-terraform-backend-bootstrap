🚀 GitHub Actions Multi-Repo GitOps Foundation 

This repository serves as the core Bootstrap Foundation for a multi-repository Terraform environment. It establishes a centralized, persistent Amazon S3 remote backend and publishes configuration pointers via AWS SSM Parameter Store for downstream infrastructure repositories (e.g., Network, App Stack).🏗️ Architecture OverviewPlaintext 

                           ┌───────────────────────────┐
                           │   CENTRAL S3 BUCKET       │
                           │   rush-123456789012       │
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
  
📦 Centralized Storage, Isolated States: A single S3 bucket hosts isolated .tfstate files using unique key paths for every repository.
🔑 Dynamic Account Resolution: Account IDs are resolved dynamically using aws_caller_identity (data "aws_caller_identity" "current" {}) to avoid hardcoding AWS account details across environments.
🔒 Native S3 State Locking (use_lockfile): Modern Terraform versions (>= 1.10) support native S3 lock files directly in the backend configuration (use_lockfile = true). This relies on AWS S3 Conditional Writes to create temporary .tflock objects during updates, rendering external DynamoDB lock tables obsolete.
🛡️ Key Design Principles & Q&A❓
1. Why is the S3 State Bucket Isolated from terraform destroy?Executing terraform destroy tears down managed resources (such as SSM parameters, VPCs, or EC2 instances).If the backend storage bucket itself were managed inside a standard Terraform lifecycle, running terraform destroy would attempt to remove the state file's host storage. To protect state history and prevent circular lockouts, the central state bucket remains a permanent storage engine.
   
❓ 2. What Happens During a Teardown?
🧼 Repo Teardown: Executing terraform destroy in Repo 1 removes ephemeral resources (like SSM parameters) and resets bootstrap/terraform.tfstate to zero tracked resources.
🛡️ Backend Survival: The central S3 bucket remains intact. Downstream state files (network/terraform.tfstate, app/terraform.tfstate) stay untouched and safe.

❓ 3. How to Decommission the Central Bucket (When Needed)In production, backend buckets are kept permanently. However, for sandbox cleanups or account decommissioning, the S3 bucket can be emptied and deleted manually using the AWS CLI:

Bash# 1. Resolve Account ID and set bucket name
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="rush-${ACCOUNT_ID}"

# 2. Wipe all versioned state objects and delete markers
aws s3api delete-objects --bucket "$BUCKET_NAME" \
  --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

aws s3api delete-objects --bucket "$BUCKET_NAME" \
  --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' --output json)" 2>/dev/null || true

# 3. Force-remove the empty bucket
aws s3 rb "s3://${BUCKET_NAME}" --force
📂 Repository StructurePlaintext.
├── 📁 .github/
│   └── 📁 workflows/
│       └── 📄 deploy.yml            # CI/CD Deployment pipeline
├── 📁 Modules/
│   └── 📁 remote_backend/           # Module defining S3 bucket configuration
├── 📄 main.tf                       # Module call & caller identity resolution
├── 📄 variables.tf                  # Region, env, and base bucket naming
└── 📄 outputs.tf                    # S3 bucket ID and SSM parameter outputs
💻 Configuration Reference📄 main.tfTerraformterraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# 1. Call Reusable Remote Backend Module
module "state_backend" {
  source      = "./Modules/remote_backend"
  bucket_name = "${var.state_bucket_name}-${data.aws_caller_identity.current.account_id}"
}

# 2. Store Bucket Name in SSM Parameter Store for Downstream Repositories
resource "aws_ssm_parameter" "state_bucket_name" {
  name        = "/terraform/remote_state_bucket"
  type        = "String"
  value       = module.state_backend.bucket_id
  description = "Central S3 bucket name used for remote state storage"
}
📄 variables.tfTerraformvariable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region to deploy backend resources"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Target deployment environment"
}

variable "state_bucket_name" {
  type        = string
  default     = "rush"
  description = "Base prefix for globally unique S3 state bucket"
}
📄 outputs.tfTerraformoutput "s3_state_bucket_name" {
  description = "The central S3 bucket created for state storage"
  value       = module.state_backend.bucket_id
}

output "ssm_parameter_name" {
  description = "SSM Parameter path storing the bucket name"
  value       = aws_ssm_parameter.state_bucket_name.name
}
📄 .github/workflows/deploy.ymlYAMLname: "Deploy State Backend Storage"

on:
  push:
    branches:
      - main

jobs:
  deploy-backend:
    name: "Provision S3 Backend & SSM Parameter"
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Init
        run: terraform init

      - name: Terraform Apply
        run: terraform apply -auto-approve
🔗 Consuming Backend in Downstream Repositories (Repo 2 / Repo 3)In downstream repositories, configure backend state storage and native S3 state locking (use_lockfile = true) inside your backend.tf or main.tf:  Terraformterraform {
  backend "s3" {
    bucket       = "rush-123456789012" # Resolved dynamically or injected
    key          = "network/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true                # Native S3 state locking (No DynamoDB required)
  }
}
