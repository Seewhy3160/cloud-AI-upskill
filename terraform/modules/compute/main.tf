# ---------------------------------------------------------------------------
# COMPUTE: EKS (Kubernetes) cluster + a managed worker node group that
# auto-scales between min and max size.
# ---------------------------------------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = var.subnet_ids
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-eks" })
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.name_prefix}-ng"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-ng" })
}
