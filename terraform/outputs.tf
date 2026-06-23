output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateway(s)"
  value       = aws_nat_gateway.main[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "alb_security_group_id" {
  description = "Security group ID for the ALB"
  value       = aws_security_group.alb.id
}

output "k3s_control_security_group_id" {
  description = "Security group ID for the k3s control plane"
  value       = aws_security_group.k3s_control.id
}

output "k3s_worker_security_group_id" {
  description = "Security group ID for k3s worker nodes"
  value       = aws_security_group.k3s_worker.id
}

output "k3s_internal_security_group_id" {
  description = "Security group ID for internal k3s node-to-node traffic"
  value       = aws_security_group.k3s_internal.id
}

output "availability_zones_used" {
  description = "Availability zones used for subnets"
  value       = var.availability_zones
}

output "k3s_control_instance_id" {
  description = "Instance ID of the k3s control plane node"
  value       = aws_instance.k3s_control.id
}

output "k3s_control_private_ip" {
  description = "Private IP of the k3s control plane node"
  value       = aws_instance.k3s_control.private_ip
}

output "k3s_worker_instance_ids" {
  description = "Instance IDs of the k3s worker nodes"
  value       = aws_instance.k3s_worker[*].id
}

output "k3s_worker_private_ips" {
  description = "Private IPs of the k3s worker nodes"
  value       = aws_instance.k3s_worker[*].private_ip
}

output "k3s_worker_roles" {
  description = "Role tag assigned to each worker, in the same order as the private IPs"
  value       = var.worker_roles
}
