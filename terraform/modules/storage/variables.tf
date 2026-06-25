variable "name_prefix" {
  description = "Prefix for naming/tagging all resources."
  type        = string
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name for video content."
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt objects at rest."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
