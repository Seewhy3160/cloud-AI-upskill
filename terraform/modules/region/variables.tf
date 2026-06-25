variable "name_prefix" {
  description = "Prefix for this region's resources (e.g. streamflix-use1)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for this region's VPC."
  type        = string
}

variable "content_bucket_name" {
  description = "Globally-unique S3 bucket name for this region's video content."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
