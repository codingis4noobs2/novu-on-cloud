variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

variable "project_name" {
  description = "Project name used as a prefix for resource naming/tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g. production, staging)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT Gateway for private subnet egress"
  type        = bool
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cheaper, less resilient) vs one per AZ"
  type        = bool
}

variable "k3s_api_port" {
  description = "Port used by the k3s/Kubernetes API server"
  type        = number
}

variable "k3s_flannel_vxlan_port" {
  description = "Port used by flannel VXLAN backend for pod networking"
  type        = number
}

variable "k3s_kubelet_port" {
  description = "Port used by kubelet API"
  type        = number
}

variable "k3s_nodeport_range_start" {
  description = "Start of the NodePort range"
  type        = number
}

variable "k3s_nodeport_range_end" {
  description = "End of the NodePort range"
  type        = number
}

# variable "allowed_ssh_cidr" {
#   description = "CIDR block allowed to reach instances via SSH"
#   type        = string
# }

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "control_instance_type" {
  description = "Instance type for the k3s control plane node"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for k3s worker nodes"
  type        = string
}

variable "control_root_volume_size" {
  description = "Root EBS volume size (GB) for the control plane node"
  type        = number
}

variable "worker_root_volume_size" {
  description = "Root EBS volume size (GB) for worker nodes"
  type        = number
}

variable "worker_count" {
  description = "Number of k3s worker nodes to provision"
  type        = number
}

variable "worker_roles" {
  description = "Logical role tag for each worker, indexed to match worker_count (e.g. app/data separation for Ansible grouping)"
  type        = list(string)
}

variable "albc_policy" {
  description = "AWS Load Balancer Controller policy"
  type        = string
}
