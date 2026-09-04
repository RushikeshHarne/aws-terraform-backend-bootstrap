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
