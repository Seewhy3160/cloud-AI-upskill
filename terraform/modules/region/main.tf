# ---------------------------------------------------------------------------
# REGION: composes networking + security + storage + compute + data into one
# complete regional stack. The root module instantiates this twice (once per
# region) using aliased AWS providers.
# ---------------------------------------------------------------------------

module "networking" {
  source      = "../networking"
  name_prefix = var.name_prefix
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
  tags        = var.tags
}

module "security" {
  source      = "../security"
  name_prefix = var.name_prefix
  vpc_id      = module.networking.vpc_id
  tags        = var.tags
}

module "storage" {
  source      = "../storage"
  name_prefix = var.name_prefix
  bucket_name = var.content_bucket_name
  kms_key_arn = module.security.kms_key_arn
  tags        = var.tags
}

module "compute" {
  source           = "../compute"
  name_prefix      = var.name_prefix
  cluster_role_arn = module.security.eks_cluster_role_arn
  node_role_arn    = module.security.eks_node_role_arn
  subnet_ids       = module.networking.private_compute_subnet_ids
  tags             = var.tags
}

module "data" {
  source            = "../data"
  name_prefix       = var.name_prefix
  subnet_ids        = module.networking.private_data_subnet_ids
  security_group_id = module.security.data_sg_id
  kms_key_arn       = module.security.kms_key_arn
  tags              = var.tags
}
