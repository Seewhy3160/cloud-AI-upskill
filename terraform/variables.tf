variable "primary_region" {
  description = "AWS region for the primary (Region A) stack."
  type        = string
  default     = "us-east-1"
}

variable "secondary_region" {
  description = "AWS region for the secondary (Region B) stack."
  type        = string
  default     = "eu-west-1"
}

variable "project" {
  description = "Project name, used in tags and resource name prefixes."
  type        = string
  default     = "streamflix"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod). Used in tags."
  type        = string
  default     = "dev"
}

variable "primary_vpc_cidr" {
  description = "VPC CIDR for the primary region."
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "VPC CIDR for the secondary region."
  type        = string
  default     = "10.1.0.0/16"
}

variable "primary_content_bucket" {
  description = "Globally-unique S3 content bucket name for the primary region. ADD YOUR OWN SUFFIX."
  type        = string
}

variable "secondary_content_bucket" {
  description = "Globally-unique S3 content bucket name for the secondary region. ADD YOUR OWN SUFFIX."
  type        = string
}
