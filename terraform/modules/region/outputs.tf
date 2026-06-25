output "vpc_id" {
  value = module.networking.vpc_id
}

output "eks_cluster_name" {
  value = module.compute.cluster_name
}

output "aurora_endpoint" {
  value = module.data.aurora_endpoint
}

output "content_bucket" {
  value = module.storage.bucket_id
}
