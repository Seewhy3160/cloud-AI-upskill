variable "name_prefix" {
  description = "Prefix for naming/tagging all resources."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security groups belong to."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
