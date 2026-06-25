output "state_bucket_name" {
  description = "Copy this into terraform/backend.tf -> bucket"
  value       = aws_s3_bucket.state.id
}

output "lock_table_name" {
  description = "Copy this into terraform/backend.tf -> dynamodb_table"
  value       = aws_dynamodb_table.locks.name
}
