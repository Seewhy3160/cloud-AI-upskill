variable "name_prefix" {
  description = "Prefix for naming/tagging all resources (e.g. streamflix-use1)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.0.0.0/16)."
  type        = string
}

variable "az_count" {
  description = "How many Availability Zones to spread subnets across."
  type        = number
  default     = 2
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}
