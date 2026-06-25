# StreamFlix — Cloud Migration Submission (Group 2)

End-to-end deliverable for the StreamFlix streaming-infrastructure modernization: scope, architecture, and working Infrastructure-as-Code.

## Repository contents

```
.
├── README.md                  # This file — overview + setup instructions
├── sow/
│   ├── SOW.md                 # Statement of Work (source)
│   └── SOW.pdf                # Statement of Work (PDF export)
├── architecture/
│   └── diagram.png            # AWS multi-region architecture diagram
└── terraform/                 # Working Terraform (the main stack lives here)
    ├── main.tf                # Root: defines both regions
    ├── variables.tf           # Input variables
    ├── outputs.tf             # Outputs printed after apply
    ├── backend.tf             # Remote-state config (edit 2 lines)
    ├── versions.tf            # Provider/version constraints
    ├── terraform.tfvars.example
    ├── bootstrap/             # Run FIRST: creates the state bucket + lock table
    └── modules/
        ├── networking/        # VPC, subnets, IGW, NAT, route tables
        ├── security/          # KMS, IAM roles, security groups
        ├── storage/           # S3 content bucket + lifecycle tiering
        ├── compute/           # EKS cluster + node group
        ├── data/              # Aurora, Redis, MSK (Kafka), OpenSearch
        └── region/            # Composes the modules into one regional stack
```

## Documents

- **Statement of Work** — `sow/SOW.md` (and `sow/SOW.pdf`): executive summary, in/out-of-scope, business objectives, technical solution, security and compliance, timeline, risks.
- **Architecture** — `architecture/diagram.png`: two active-active AWS regions, each with edge delivery, EKS compute, streaming, data services, and cross-cutting security/observability.

---

## Setup and deployment (Terraform)

### Prerequisites

1. **Terraform** v1.5+ — https://developer.hashicorp.com/terraform/install
2. **AWS CLI** v2 — https://aws.amazon.com/cli/
3. **An AWS account** with credentials that can create VPC, EKS, RDS, MSK, OpenSearch, S3, IAM, KMS.

Verify the tools:

```powershell
terraform version
aws --version
```

> Commands below are written for **Windows PowerShell**. macOS/Linux equivalents are in parentheses.

### Why there's a bootstrap stack (and why it runs first)

This project has **two** Terraform stacks: a small `bootstrap/` stack and the main stack. You must run `bootstrap/` first, once, before anything else. Here's why.

The main stack keeps its state file (`terraform.tfstate`) in an **S3 bucket**, with a **DynamoDB table** for locking, instead of on your laptop. Remote state is what makes the project safe to share and run as a team:

- **Shared source of truth** — state lives in one place, not on one person's machine.
- **Locking** — the lock table stops two people from running `apply` at the same time and corrupting state.
- **Durability and history** — the bucket is versioned and encrypted, so state is backed up and protected.

But this creates a chicken-and-egg problem: the main stack needs that bucket and table to *already exist* the moment it runs `terraform init` — it can't create the very thing it depends on. So something has to create them first.

That "something" is the **bootstrap stack**. Its only job is to create:

- the **S3 bucket** that will hold the main stack's state, and
- the **DynamoDB lock table**.

It runs with **local state** (a `terraform.tfstate` file on your disk), because at that point there is no remote backend to use yet. Once it finishes, you copy its two outputs into the main stack's `backend.tf` (Step 3), and from then on the main stack stores its state remotely in that bucket.

```
Step 2: bootstrap (local state)  ──creates──>  S3 bucket + DynamoDB lock table
              │
              └── outputs ──> paste into terraform/backend.tf (Step 3)
                                    │
Step 5: main stack (remote state) ──uses──>  that bucket + lock table
```

You run the bootstrap **once, ever**, at the very start, and only return to it at the very end to tear everything down — and in that order: destroy the **main stack first**, then the bootstrap (the state bucket can't be removed while the main stack is still using it).

### Step 1 — Provide AWS credentials

```powershell
$env:AWS_ACCESS_KEY_ID     = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION    = "us-east-1"
aws sts get-caller-identity   # should print your account ID
```

### Step 2 — Create the remote-state backend (run once)

This is the bootstrap stack (see "Why there's a bootstrap stack" above). It creates the S3 bucket and DynamoDB lock table the main stack will use for its state.

```powershell
cd terraform\bootstrap
terraform init
terraform apply -var="state_bucket_name=streamflix-tfstate-CHANGEME1234"
```

- Bucket name must be **globally unique** — replace `CHANGEME1234`.
- Type `yes`. Note the two outputs: `state_bucket_name` and `lock_table_name`.

### Step 3 — Point the main stack at that backend

Edit `terraform/backend.tf`, set the two marked lines to the Step 2 outputs:

```hcl
bucket         = "streamflix-tfstate-CHANGEME1234"
dynamodb_table = "streamflix-tf-locks"
```

### Step 4 — Set your variables

```powershell
cd ..
copy terraform.tfvars.example terraform.tfvars   # (cp on macOS/Linux)
```

Edit `terraform.tfvars` and set globally-unique content bucket names:

```hcl
primary_content_bucket   = "streamflix-content-primary-CHANGEME1234"
secondary_content_bucket = "streamflix-content-secondary-CHANGEME1234"
```

### Step 5 — Deploy

```powershell
terraform init
terraform plan
terraform apply
```

Type `yes`. Full apply takes **20–40 minutes** (EKS, Aurora, MSK, and OpenSearch are slow to provision). Outputs (VPC IDs, EKS cluster names, Aurora endpoint) print on completion.

### Step 6 — Tear down (stops the bill)

Destroy in this order: **main stack first, then the bootstrap.** The bootstrap's state bucket cannot be deleted while the main stack is still using it.

**1. Destroy the main stack** (removes EKS, Aurora, Redis, MSK, OpenSearch, VPCs — everything billable):

```powershell
cd terraform
terraform destroy
```

**2. Empty the versioned state bucket.** The bootstrap bucket has versioning enabled, so Terraform cannot delete it while old object versions remain (you'll get `BucketNotEmpty`). Purge every version and delete-marker first (replace the bucket name with yours):

```powershell
# delete all object versions
aws s3api list-object-versions --bucket YOUR-STATE-BUCKET --region us-east-1 --query "Versions[].{Key:Key,VersionId:VersionId}" --output text | ForEach-Object {
  $p = $_ -split "\s+"; if ($p[0]) { aws s3api delete-object --bucket YOUR-STATE-BUCKET --region us-east-1 --key $p[0] --version-id $p[1] }
}
# delete all delete-markers
aws s3api list-object-versions --bucket YOUR-STATE-BUCKET --region us-east-1 --query "DeleteMarkers[].{Key:Key,VersionId:VersionId}" --output text | ForEach-Object {
  $p = $_ -split "\s+"; if ($p[0]) { aws s3api delete-object --bucket YOUR-STATE-BUCKET --region us-east-1 --key $p[0] --version-id $p[1] }
}
```

**3. Destroy the bootstrap** (removes the now-empty bucket and the lock table):

```powershell
cd bootstrap
terraform destroy -var="state_bucket_name=YOUR-STATE-BUCKET"
```

**4. Confirm the account is clean** (all should return empty `[]`):

```powershell
aws eks list-clusters --region us-east-1
aws eks list-clusters --region eu-west-1
aws rds describe-db-clusters --region us-east-1 --query "DBClusters[].DBClusterIdentifier"
aws rds describe-db-clusters --region eu-west-1 --query "DBClusters[].DBClusterIdentifier"
aws kafka list-clusters --region us-east-1 --query "ClusterInfoList[].ClusterName"
aws kafka list-clusters --region eu-west-1 --query "ClusterInfoList[].ClusterName"
aws opensearch list-domain-names --region us-east-1
aws opensearch list-domain-names --region eu-west-1
```

---

## Standard Terraform commands

| Command | Purpose |
|---|---|
| `terraform fmt -recursive` | Format all `.tf` files |
| `terraform validate` | Check syntax/validity |
| `terraform init` | Download providers, connect backend |
| `terraform plan` | Preview changes |
| `terraform apply` | Build/update infrastructure |
| `terraform output` | Re-print outputs |
| `terraform destroy` | Delete everything |

## Key variables

| Variable | Default | Description |
|---|---|---|
| `primary_content_bucket` | — (required) | Globally-unique S3 content bucket (primary) |
| `secondary_content_bucket` | — (required) | Globally-unique S3 content bucket (secondary) |
| `primary_region` | `us-east-1` | Primary region |
| `secondary_region` | `eu-west-1` | Secondary region |
| `primary_vpc_cidr` | `10.0.0.0/16` | Primary VPC CIDR |
| `secondary_vpc_cidr` | `10.1.0.0/16` | Secondary VPC CIDR |
| `project` / `environment` | `streamflix` / `dev` | Naming + tags |

Module sizing variables (EKS node size, DB/Redis/Kafka/OpenSearch instance types) have sensible small defaults; see each module's `variables.tf`.

## Scope notes

- **Implemented:** VPC/subnets/NAT/routing, KMS, IAM, security groups, S3 with lifecycle tiering, EKS cluster + node group, Aurora PostgreSQL, ElastiCache Redis, MSK (Kafka), OpenSearch — across two active-active regions.
- **On the diagram but not in code (intentional, future modules):** CloudFront/Route 53 edge, WAF/Shield, Elemental MediaLive/MediaConvert, SageMaker, Redshift, Cognito, Transit Gateway cross-region replication, and Kubernetes workloads (deployed *into* EKS separately).
- **Cost warning:** this provisions real, billable infrastructure. Defaults are minimal sizes; run `terraform destroy` when not in use.
- Aurora's master password is auto-generated into AWS Secrets Manager and never stored in plaintext state.
