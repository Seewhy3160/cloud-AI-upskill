# ---------------------------------------------------------------------------
# ROOT: defines one AWS provider per region (aliased) and builds a full
# regional stack in each via the reusable `region` module.
# ---------------------------------------------------------------------------

provider "aws" {
  alias  = "primary"
  region = var.primary_region
  default_tags {
    tags = local.common_tags
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
  default_tags {
    tags = local.common_tags
  }
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "region_primary" {
  source              = "./modules/region"
  providers           = { aws = aws.primary }
  name_prefix         = "${var.project}-primary"
  vpc_cidr            = var.primary_vpc_cidr
  content_bucket_name = var.primary_content_bucket
  tags                = local.common_tags
}

module "region_secondary" {
  source              = "./modules/region"
  providers           = { aws = aws.secondary }
  name_prefix         = "${var.project}-secondary"
  vpc_cidr            = var.secondary_vpc_cidr
  content_bucket_name = var.secondary_content_bucket
  tags                = local.common_tags
}
