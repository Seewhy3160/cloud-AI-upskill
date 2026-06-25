output "aurora_endpoint" {
  value = aws_rds_cluster.aurora.endpoint
}

output "redis_primary_endpoint" {
  value = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "kafka_cluster_arn" {
  value = aws_msk_cluster.kafka.arn
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.search.endpoint
}
