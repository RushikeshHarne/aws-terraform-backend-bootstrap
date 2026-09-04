# 🚀 Multi-Repo GitOps State Engine & Discovery Foundation

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


📑 How To Use This Foundation in Your Infrastructure
⚙️ Phase 1: Prerequisites & AWS Configuration
1. Set Up GitHub Actions Secrets
In your GitHub Repository, navigate to Settings $\rightarrow$ Secrets and variables $\rightarrow$ Actions and add:
AWS_ACCESS_KEY_ID: IAM user/role access key.
AWS_SECRET_ACCESS_KEY: IAM user/role secret key.

2. Configure Local Variables (Optional)
In variables.tf, customize your base bucket prefix and target region:

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket_name" {
  type    = string
  default = "rush" # Evaluates to: rush-<YOUR_AWS_ACCOUNT_ID>
}

