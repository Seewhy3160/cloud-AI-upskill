output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_compute_subnet_ids" {
  value = aws_subnet.private_compute[*].id
}

output "private_data_subnet_ids" {
  value = aws_subnet.private_data[*].id
}
