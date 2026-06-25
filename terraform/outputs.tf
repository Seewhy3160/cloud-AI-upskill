output "primary_vpc_id" {
  value = module.region_primary.vpc_id
}

output "primary_eks_cluster" {
  value = module.region_primary.eks_cluster_name
}

output "primary_aurora_endpoint" {
  value = module.region_primary.aurora_endpoint
}

output "secondary_vpc_id" {
  value = module.region_secondary.vpc_id
}

output "secondary_eks_cluster" {
  value = module.region_secondary.eks_cluster_name
}
