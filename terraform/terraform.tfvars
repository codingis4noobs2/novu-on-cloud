aws_region   = "us-east-1"
project_name = "novu-on-cloud"
environment  = "production"

vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

enable_nat_gateway = true
single_nat_gateway = true # set false for per-AZ NAT (more $, more resilient)

control_instance_type    = "t3.medium"
worker_instance_type     = "t3.medium"
control_root_volume_size = 20
worker_root_volume_size  = 20

worker_count = 4
worker_roles = ["app", "app", "data", "data"]

k3s_api_port             = 6443
k3s_flannel_vxlan_port   = 8472
k3s_kubelet_port         = 10250
k3s_nodeport_range_start = 30000
k3s_nodeport_range_end   = 32767

# allowed_ssh_cidr = "34.63.110.49/32"

tags = {
  Project   = "novu-on-cloud"
  ManagedBy = "terraform"
}

albc_policy = "./policies/awsloadbalancercontroller.json"
