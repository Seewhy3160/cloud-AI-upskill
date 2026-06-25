variable "name_prefix" {
  description = "Prefix for naming/tagging."
  type        = string
}

variable "cluster_role_arn" {
  description = "IAM role ARN for the EKS control plane (from security module)."
  type        = string
}

variable "node_role_arn" {
  description = "IAM role ARN for the EKS worker nodes (from security module)."
  type        = string
}

variable "subnet_ids" {
  description = "Private compute subnet IDs the cluster runs in."
  type        = list(string)
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version."
  type        = string
  default     = "1.30"
}

variable "node_instance_types" {
  description = "EC2 instance types for the managed node group."
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes (auto-scaling ceiling)."
  type        = number
  default     = 6
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
