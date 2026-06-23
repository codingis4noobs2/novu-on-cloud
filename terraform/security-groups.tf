resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP/HTTPS from the internet to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "k3s_control" {
  name        = "${var.project_name}-k3s-control-sg"
  description = "Security group for k3s control plane node"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kubernetes API server"
    from_port   = var.k3s_api_port
    to_port     = var.k3s_api_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "Kubelet API from workers"
    from_port       = var.k3s_kubelet_port
    to_port         = var.k3s_kubelet_port
    protocol        = "tcp"
    security_groups = [aws_security_group.k3s_worker.id]
  }

  # intially planned bastion host architecture but later removed as i am using ssm
  # ingress {
  #   description = "SSH access"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.allowed_ssh_cidr]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name                            = "${var.project_name}-k3s-control-sg"
    "kubernetes.io/cluster/default" = "shared"
  })
}

resource "aws_security_group" "k3s_worker" {
  name        = "${var.project_name}-k3s-worker-sg"
  description = "Security group for k3s worker nodes"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Kubelet API"
    from_port   = var.k3s_kubelet_port
    to_port     = var.k3s_kubelet_port
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description     = "NodePort range for ALB to ingress controller"
    from_port       = var.k3s_nodeport_range_start
    to_port         = var.k3s_nodeport_range_end
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # ingress {
  #   description = "SSH access"
  #   from_port   = 22
  #   to_port     = 22
  #   protocol    = "tcp"
  #   cidr_blocks = [var.allowed_ssh_cidr]
  # }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name                            = "${var.project_name}-k3s-worker-sg"
    "kubernetes.io/cluster/default" = "shared"
  })
}

# Separate rule set (not inline) to avoid circular dependency issues
# between control and worker SGs, and to allow flannel VXLAN +
# all-ports-between-nodes traffic cleanly.

resource "aws_security_group" "k3s_internal" {
  name        = "${var.project_name}-k3s-internal-sg"
  description = "Allow all internal traffic between k3s nodes (flannel, etcd, etc)"
  vpc_id      = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-k3s-internal-sg"
  })
}

resource "aws_security_group_rule" "internal_all_tcp" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.k3s_internal.id
  description       = "All TCP between nodes sharing this SG"
}

resource "aws_security_group_rule" "internal_flannel_vxlan" {
  type              = "ingress"
  from_port         = var.k3s_flannel_vxlan_port
  to_port           = var.k3s_flannel_vxlan_port
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.k3s_internal.id
  description       = "Flannel VXLAN overlay network"
}

resource "aws_security_group_rule" "internal_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k3s_internal.id
}
