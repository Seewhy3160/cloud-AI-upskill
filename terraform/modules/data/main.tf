# ---------------------------------------------------------------------------
# DATA: Aurora PostgreSQL, ElastiCache Redis, MSK (Kafka), and OpenSearch.
# All live in the private data subnets and are reachable only from the data
# security group. Encryption at rest uses the shared KMS key where supported.
# ---------------------------------------------------------------------------

# ===== Aurora PostgreSQL =====
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.name_prefix}-aurora-subnets"
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier          = "${var.name_prefix}-aurora"
  engine                      = "aurora-postgresql"
  database_name               = "streamflix"
  master_username             = "streamflix_admin"
  manage_master_user_password = true # password stored in Secrets Manager automatically
  db_subnet_group_name        = aws_db_subnet_group.aurora.name
  vpc_security_group_ids      = [var.security_group_id]
  storage_encrypted           = true
  kms_key_id                  = var.kms_key_arn
  skip_final_snapshot         = true
  tags                        = var.tags
}

resource "aws_rds_cluster_instance" "aurora" {
  count              = 1
  identifier         = "${var.name_prefix}-aurora-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.aurora.engine
  tags               = var.tags
}

# ===== ElastiCache Redis =====
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.name_prefix}-redis-subnets"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "${var.name_prefix} Redis cache"
  engine                     = "redis"
  node_type                  = var.redis_node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  subnet_group_name          = aws_elasticache_subnet_group.redis.name
  security_group_ids         = [var.security_group_id]
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  tags                       = var.tags
}

# ===== MSK (Apache Kafka) =====
resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${var.name_prefix}-kafka"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = length(var.subnet_ids)

  broker_node_group_info {
    instance_type   = var.msk_instance_type
    client_subnets  = var.subnet_ids
    security_groups = [var.security_group_id]
    storage_info {
      ebs_storage_info {
        volume_size = 50
      }
    }
  }

  encryption_info {
    encryption_at_rest_kms_key_arn = var.kms_key_arn
  }

  tags = var.tags
}

# ===== OpenSearch =====
resource "aws_opensearch_domain" "search" {
  domain_name    = "${var.name_prefix}-search"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type          = var.opensearch_instance_type
    instance_count         = length(var.subnet_ids)
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = length(var.subnet_ids)
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 20
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = var.kms_key_arn
  }

  node_to_node_encryption {
    enabled = true
  }

  vpc_options {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.security_group_id]
  }

  tags = var.tags
}
