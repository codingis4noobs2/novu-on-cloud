resource "aws_iam_role" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name
}

locals {
  common_userdata = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y python3 python3-pip curl

    # confirm python3 is reachable at a predictable path for Ansible
    ln -sf /usr/bin/python3 /usr/bin/python || true
  EOF

  control_userdata = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y python3 python3-pip curl software-properties-common

    ln -sf /usr/bin/python3 /usr/bin/python || true

    apt-add-repository --yes --update ppa:ansible/ansible
    apt-get install -y ansible

    ansible --version > /var/log/ansible-install.log 2>&1 || true
  EOF
}

resource "aws_instance" "k3s_control" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.control_instance_type
  subnet_id              = aws_subnet.private[0].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  vpc_security_group_ids = [aws_security_group.k3s_control.id, aws_security_group.k3s_internal.id]
  user_data              = local.control_userdata

  root_block_device {
    volume_size = var.control_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-k3s-control"
    Role = "control-plane"
  })
}

resource "aws_instance" "k3s_worker" {
  count                  = var.worker_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.worker_instance_type
  subnet_id              = aws_subnet.private[count.index % length(aws_subnet.private)].id
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name
  vpc_security_group_ids = [aws_security_group.k3s_worker.id, aws_security_group.k3s_internal.id]
  user_data              = local.common_userdata
  credit_specification {
    cpu_credits = "standard"
  }

  root_block_device {
    volume_size = var.worker_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-k3s-worker-${count.index + 1}"
    Role = var.worker_roles[count.index]
  })
}

# https://docs.aws.amazon.com/eks/latest/userguide/lbc-helm.html
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "aws-load-balancer-controller"
  description = "AWS Load Balancer Controller IAM policy"
  policy      = file(var.albc_policy)
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
}
