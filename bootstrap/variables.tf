variable "state_region" {
  description = "AWS region where the remote-state S3 bucket and lock table live."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally-unique name for the S3 bucket that stores Terraform state. Must be unique across ALL of AWS, so add your own suffix."
  type        = string
}

variable "lock_table_name" {
  description = "Name for the DynamoDB table used for state locking."
  type        = string
  default     = "streamflix-tf-locks"
}
