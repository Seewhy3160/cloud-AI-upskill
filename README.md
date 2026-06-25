# StreamFlix — Infrastructure as Code (Terraform)

Implements the StreamFlix multi-region AWS architecture as modular, deployable Terraform. Two active-active regions (primary + secondary), each with networking, security, compute (EKS), storage (S3), and data (Aurora PostgreSQL, Redis, MSK/Kafka, OpenSearch).

> Provider note: the architecture targets AWS. Cloud provider selection was an open item; this code is the AWS implementation.

---

## What you need before you start

Install these three things on your machine.

1. **Terraform** (v1.5 or newer). Download from https://developer.hashicorp.com/terraform/install
   - Verify it works. Open PowerShell and run:
     ```powershell
     terraform version
     ```
2. **AWS CLI** (v2). Download from https://aws.amazon.com/cli/
   - Verify:
     ```powershell
     aws --version
     ```
3. **An AWS account** with an IAM user (or SSO) that can create VPCs, EKS, RDS, S3, etc. Have an **Access Key ID** and **Secret Access Key** ready, or use SSO.

---

## Folder layout

```
streamflix-terraform/
├── bootstrap/              # Run FIRST. Creates the S3 bucket + DynamoDB
│                           # table that store the main stack's state.
└── terraform/              # The MAIN stack (the actual architecture).
    ├── backend.tf          # Points at the bootstrap bucket (you edit 2 lines)
    ├── main.tf             # Defines both regions
    ├── variables.tf        # All input variables
    ├── outputs.tf          # Values printed after apply
    ├── terraform.tfvars.example   # Copy this to terraform.tfvars
    └── modules/
        ├── networking/     # VPC, subnets, IGW, NAT, route tables
        ├── security/       # KMS, IAM roles, security groups
        ├── storage/        # S3 content bucket + lifecycle tiering
        ├── compute/        # EKS cluster + node group
        ├── data/           # Aurora, Redis, MSK, OpenSearch
        └── region/         # Glues the above into one regional stack
```

---

## Step-by-step deployment

Do these in order. Commands are written for **Windows PowerShell**; macOS/Linux notes are in parentheses.

### Step 1 — Give Terraform your AWS credentials

Easiest method, run once per PowerShell session:

```powershell
$env:AWS_ACCESS_KEY_ID     = "YOUR_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY = "YOUR_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION    = "us-east-1"
```

(Alternative: run `aws configure` once and it saves credentials permanently to a profile.)

Check it worked:

```powershell
aws sts get-caller-identity
```

You should see your account number. If you get an error, your keys are wrong.

### Step 2 — Create the remote-state backend (bootstrap)

This makes one S3 bucket (to hold state) and one DynamoDB table (to lock state). Run it once, ever.

```powershell
cd streamflix-terraform\bootstrap
terraform init
terraform apply -var="state_bucket_name=streamflix-tfstate-CHANGEME1234"
```

- The bucket name must be **globally unique across all of AWS**. Replace `CHANGEME1234` with your own random characters.
- Type `yes` when prompted.
- When it finishes, it prints two outputs: `state_bucket_name` and `lock_table_name`. **Write these down.**

### Step 3 — Point the main stack at that backend

Open `terraform\backend.tf` in any text editor. Change the two marked lines to the values from Step 2:

```hcl
bucket         = "streamflix-tfstate-CHANGEME1234"   # <- your state_bucket_name
dynamodb_table = "streamflix-tf-locks"               # <- your lock_table_name
```

Leave `key`, `region`, and `encrypt` as they are (unless your state bucket is in a different region).

### Step 4 — Set your variable values

```powershell
cd ..\terraform
copy terraform.tfvars.example terraform.tfvars
```
(macOS/Linux: `cp terraform.tfvars.example terraform.tfvars`)

Open `terraform.tfvars` and change the two S3 content bucket names to something globally unique (add your own random suffix):

```hcl
primary_content_bucket   = "streamflix-content-primary-CHANGEME1234"
secondary_content_bucket = "streamflix-content-secondary-CHANGEME1234"
```

### Step 5 — Initialise the main stack

```powershell
terraform init
```

This downloads the AWS provider and connects to your remote state bucket. You should see "Terraform has been successfully initialized!"

### Step 6 — Preview what will be created

```powershell
terraform plan
```

This shows everything Terraform will build. It changes nothing. Read the summary line at the bottom (e.g. "Plan: 80 to add").

### Step 7 — Build the infrastructure

```powershell
terraform apply
```

Review the plan, type `yes`. This takes **20–40 minutes** because EKS, Aurora, MSK, and OpenSearch are slow to create. When done, Terraform prints the outputs (VPC IDs, EKS cluster names, Aurora endpoint).

### Step 8 — Tear it all down (when finished)

This stops the bill. It deletes everything the main stack created.

```powershell
terraform destroy
```

Type `yes`. To also remove the state bucket and lock table afterwards:

```powershell
cd ..\bootstrap
terraform destroy -var="state_bucket_name=streamflix-tfstate-CHANGEME1234"
```

---

## Standard Terraform commands (quick reference)

| Command | What it does |
|---|---|
| `terraform fmt -recursive` | Auto-formats all `.tf` files |
| `terraform validate` | Checks the code is syntactically valid |
| `terraform init` | Downloads providers, connects backend |
| `terraform plan` | Previews changes (creates nothing) |
| `terraform apply` | Builds/updates infrastructure |
| `terraform output` | Re-prints the output values |
| `terraform destroy` | Deletes everything in the stack |

---

## Variables reference

### Bootstrap stack (`bootstrap/`)

| Variable | Required | Default | Description |
|---|---|---|---|
| `state_bucket_name` | Yes | — | Globally-unique S3 bucket name for Terraform state |
| `state_region` | No | `us-east-1` | Region for the state bucket and lock table |
| `lock_table_name` | No | `streamflix-tf-locks` | DynamoDB table name for state locking |

### Main stack (`terraform/`)

| Variable | Required | Default | Description |
|---|---|---|---|
| `primary_content_bucket` | Yes | — | Globally-unique S3 content bucket (primary region) |
| `secondary_content_bucket` | Yes | — | Globally-unique S3 content bucket (secondary region) |
| `primary_region` | No | `us-east-1` | Primary (Region A) AWS region |
| `secondary_region` | No | `eu-west-1` | Secondary (Region B) AWS region |
| `project` | No | `streamflix` | Name prefix + tag applied to resources |
| `environment` | No | `dev` | Environment tag (dev/staging/prod) |
| `primary_vpc_cidr` | No | `10.0.0.0/16` | VPC CIDR for the primary region |
| `secondary_vpc_cidr` | No | `10.1.0.0/16` | VPC CIDR for the secondary region |

### Module-level variables (tunable, sensible defaults)

These have defaults and only need changing if you want different sizing. Set them inside the `region` module call or expose them upward as needed.

| Module | Variable | Default | Description |
|---|---|---|---|
| networking | `az_count` | `2` | Availability Zones per region |
| compute | `kubernetes_version` | `1.30` | EKS version |
| compute | `node_instance_types` | `["t3.medium"]` | Worker node instance type(s) |
| compute | `node_desired_size` / `min` / `max` | `2 / 2 / 6` | Node group auto-scaling range |
| data | `db_instance_class` | `db.t3.medium` | Aurora instance size |
| data | `redis_node_type` | `cache.t3.micro` | Redis node size |
| data | `msk_instance_type` | `kafka.t3.small` | Kafka broker size |
| data | `opensearch_instance_type` | `t3.small.search` | OpenSearch node size |

---

## Outputs

After `terraform apply`, the main stack prints:

| Output | Description |
|---|---|
| `primary_vpc_id` / `secondary_vpc_id` | The VPC IDs in each region |
| `primary_eks_cluster` / `secondary_eks_cluster` | EKS cluster names |
| `primary_aurora_endpoint` | Aurora PostgreSQL writer endpoint (primary) |

---

## Cost and scope warnings

- **This costs real money.** EKS, NAT Gateways, Aurora, MSK, and OpenSearch all bill hourly. Run `terraform destroy` when you are not using it. Defaults are the smallest sensible sizes for a dev/test deploy.
- **Implemented in this code:** VPC/subnets/NAT/routing, KMS, IAM roles, security groups, S3 with lifecycle tiering, EKS cluster + node group, Aurora PostgreSQL, ElastiCache Redis, MSK (Kafka), OpenSearch.
- **Shown on the architecture diagram but NOT in this code (deliberate scope cut — add as later modules):** CloudFront/Route 53 edge, WAF/Shield, Elemental MediaLive/MediaConvert, SageMaker, Redshift, Cognito, Transit Gateway / cross-region replication, and Kubernetes workloads (these are deployed *into* EKS separately, not by this stack).
- Aurora's master password is auto-generated and stored in AWS Secrets Manager (via `manage_master_user_password`); it is never written to state in plaintext.
