resource "random_id" "bucket" {
  byte_length = 8
}

resource "aws_s3_bucket" "ansible_ssm" {
  bucket = "${var.project_name}-ansible-ssm-${random_id.bucket.hex}"
}

resource "aws_iam_policy" "ansible_s3_access" {
  name = "${var.project_name}-ansible-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.ansible_ssm.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = ["${aws_s3_bucket.ansible_ssm.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ansible_s3_access" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = aws_iam_policy.ansible_s3_access.arn
}

resource "local_file" "inventory" {
  content = templatefile("../ansible/template.tpl", {
    k3s_master_id  = aws_instance.k3s_control.id
    k3s_master_ip  = aws_instance.k3s_control.private_ip
    k3s_worker_ids = aws_instance.k3s_worker[*].id
    worker_roles   = var.worker_roles
    aws_region     = var.aws_region
    bucket_name    = aws_s3_bucket.ansible_ssm.bucket
  })
  filename = "../ansible/inventory/hosts.ini"
}
