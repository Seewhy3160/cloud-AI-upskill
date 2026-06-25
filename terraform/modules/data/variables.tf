variable "name_prefix" {
  description = "Prefix for naming/tagging."
  type        = string
}

variable "subnet_ids" {
  description = "Private data subnet IDs for all data services."
  type        = list(string)
}

variable "security_group_id" {
  description = "Data-tier security group ID (from security module)."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption at rest."
  type        = string
}

variable "db_instance_class" {
  description = "Aurora PostgreSQL instance class."
  type        = string
  default     = "db.t3.medium"
}

variable "redis_node_type" {
  description = "ElastiCache Redis node type."
  type        = string
  default     = "cache.t3.micro"
}

variable "msk_instance_type" {
  description = "MSK (Kafka) broker instance type."
  type        = string
  default     = "kafka.t3.small"
}

variable "opensearch_instance_type" {
  description = "OpenSearch data node instance type."
  type        = string
  default     = "t3.small.search"
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
