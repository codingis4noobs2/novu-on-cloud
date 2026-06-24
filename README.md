# Hosting Novu on AWS Cloud

<a href="https://go.novu.co/github?utm_campaign=readme-logo" target="_blank" rel="noopener noreferrer">
  <img alt="Novu Logo" src=".github/assets/novu-logo.svg" width="100%"/>
</a>

This project provisions a highly available self-hosted Novu deployment on AWS using Terraform, Ansible, K3s, and Helm. The infrastructure is designed to automate the complete deployment lifecycle, from network provisioning and Kubernetes cluster creation to application installation, ingress configuration, TLS with AWS Certificate Manager, and persistent storage.

> **Important**
>
> This project creates real AWS resources and will incur charges on your AWS account. Before deploying, ensure that you understand the infrastructure being created and the associated costs.
>
> If you are using this repository for learning or experimentation, i strongly recommended to destroy all provisioned resources when you are finished:
>
> ```bash
> terraform destroy
> ```
>
> Failure to clean up resources such as EC2 instances, EBS volumes, NAT Gateways, Load Balancers, and Route 53 hosted zones will definitely result in unexpected AWS charges.

## Architecture Diagram
Will upload soon!

## Prerequisites

Before deploying the infrastructure, install the following tools on your local(or remote) machine:

1. AWS CLI
   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

2. Terraform
   https://developer.hashicorp.com/terraform/install

3. Ansible
   https://docs.ansible.com/projects/ansible/latest/installation_guide/index.html

> **Note**
>
> This option is risky if your remote environment is shared, then i would suggest using the aws console terminal instead. Use CloudShell which provides temporary credentials. This avoids the need to create and manage long-lived IAM access keys. Install terraform and ansible on it too. Use `aws login` for temporary credentials.

## Deploying the Infrastructure

### 1. Create an S3 Bucket

Create an S3 bucket using either the AWS Management Console or AWS CLI. This bucket will be used to store the Terraform state file and lock file.

### 2. Configure the Terraform Backend

Navigate to the `terraform/` directory and open `backend.tf`.

Update the bucket name to match the S3 bucket you created in the previous step.

The backend stores:

* Terraform state (`terraform.tfstate`)
* Terraform lock file (used to prevent concurrent `apply` or `destroy` operations)

### 3. Review Infrastructure Configuration

Open `terraform.tfvars` and review the default values.

You may customize the infrastructure configuration, including instance types, networking, cluster sizing, and other deployment settings according to your requirements.

Once done run `terraform init` from the `terraform/` directory.

### 4. Generate an Execution Plan

From the `terraform/` directory, run:

```bash
terraform plan
```

Review the proposed infrastructure carefully to understand which AWS resources will be created.

### 5. Provision the Infrastructure

If the plan looks correct, deploy the infrastructure:

```bash
terraform apply
```

Terraform will provision all required AWS resources, including networking, compute instances, security groups, IAM resources, and supporting infrastructure required for the Kubernetes cluster.

> **Note**
> Incase you get Error: waiting for EC2 NAT Gateway (nat-xxxxxxxxxxxxxxx) create: unexpected state 'failed', wanted target 'available'. last error: InvalidAllocationID.NotFound: Elastic IP address [eipalloc-xxxxxxxxxxxxxxx] could not be associated with this NAT gateway

Then run `terraform apply --replace="aws_nat_gateway.main[0]"`

### 6. Install the AWS Session Manager Plugin

Install the AWS Session Manager Plugin for your operating system:

https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-debian-and-ubuntu.html

This plugin enables interactive shell access to EC2 instances through AWS Systems Manager (SSM).

### 7. Verify SSM Connectivity

After the infrastructure has been provisioned, open the AWS Management Console and navigate to:

**EC2 → Instance → Connect -> SSM Session Manager**

Verify that all cluster nodes appear as **Online**.

If a node does not register with SSM(usually an error like: SSM Agent unable to acquire credentials: <error>unexpected error getting instance profile role credentials or calling UpdateInstanceInformation. Skipping default host management fallback: retrieved credentials failed to report to ssm. Error: RequestError: send request failed</error>
), a simple instance reboot is usually sufficient:

```bash
aws ec2 reboot-instances --instance-ids <instance-id>
```

or use the EC2 Console.

> **Why i used SSM instead of a Bastion Host?**
>
> A common approach when i was learning aws i saw was to deploy a bastion host and SSH into private instances through it. While this works, it introduces additional infrastructure and cost.
>
> Even when a bastion host is stopped, you may still incur charges for resources such as EBS volumes and Elastic IP addresses(if configured).
>
> AWS Systems Manager provides secure shell access to private instances without exposing SSH ports to the internet, managing SSH keys, or maintaining a dedicated bastion host.

### 8. Configure the Kubernetes Cluster

Once all nodes are available through AWS Systems Manager, navigate to the `ansible/` directory and execute:

```bash
ansible-playbook playbooks/site.yaml
```

This playbook is responsible for configuring the cluster and installing the required dependencies on the provisioned instances.

> **Note**
>
> The playbooks have been written with idempotency in mind wherever practical. However, certain operations may not be fully idempotent and can fail or behave unexpectedly when re-executed on an already configured environment.
> ArgoCD installation is optional; you can remove or comment out the task if you don't want ArgoCD.

### 9. Install Kubernetes Add-ons

At this point, a few Kubernetes add-ons must be installed manually from the control plane node.

Start an SSM session to the control node. Throughout this guide, I will use `bash` for examples, but feel free to use your preferred shell.

Add the required Helm repositories:

```bash
helm repo add eks https://aws.github.io/eks-charts
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
```

Install the AWS EBS CSI Driver:

```bash
helm upgrade --install aws-ebs-csi-driver \
  aws-ebs-csi-driver/aws-ebs-csi-driver \
  -n kube-system
```

> **Note**
>
> The IAM roles and policies required by the AWS EBS CSI Driver and AWS Load Balancer Controller are provisioned automatically by Terraform. No additional IAM configuration is required.

### 10. Clone the Repository

Clone this repository (or your own fork) onto the control node and navigate into novu-helm-chart

The remaining cluster components and application resources will be deployed from this repository.


### 11. Deploy Novu

Before deploying Novu, ensure that you own a domain name and have access to its DNS settings.

You must be able to modify the domain's nameserver (NS) records or DNS records through your domain registrar or DNS provider. This will be required later when configuring Route 53, custom domains, and TLS certificates.

Update the following values in `values.yaml` to match your domain:

```yaml
API_ROOT_URL
FRONT_BASE_URL
VITE_API_HOSTNAME
VITE_WEBSOCKET_HOSTNAME
```

Example:

```yaml
API_ROOT_URL: "https://api.example.com"
FRONT_BASE_URL: "https://example.com"
VITE_API_HOSTNAME: "https://api.example.com"
VITE_WEBSOCKET_HOSTNAME: "wss://ws.example.com"
```

If you do not plan to use HTTPS, use `http://` and `ws://` instead.

> **HTTPS Configuration**
>
> If you do not intend to use HTTPS, remove the following annotations from the `novu-alb` Ingress manifest:
>
> ```yaml
> alb.ingress.kubernetes.io/certificate-arn
> alb.ingress.kubernetes.io/ssl-redirect
> ```
>
> These annotations are only required when using AWS Certificate Manager (ACM) for TLS termination on the Application Load Balancer.

Deploy Novu:

```bash
helm upgrade --install novu . \
  --namespace novu \
  --create-namespace
```

Wait for all pods to become healthy before proceeding.

### 12. Install AWS Load Balancer Controller

Install the AWS Load Balancer Controller:

```bash
helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --create-namespace \
  --set clusterName=default \
  --set region=<aws_region> \
  --set vpcId=<vpc_id> \
  --set serviceAccount.create=true
```

You can obtain the VPC ID from the AWS Console or Terraform outputs.

> **Important**
>
> Ensure that `aws_region` matches the AWS region used by your Terraform deployment.
>
> For example, if Terraform provisioned the infrastructure in `us-east-1`, the controller must also be configured with `us-east-1`.
>
> A mismatched region can cause the controller to fail to discover AWS resources correctly, leading to ingress reconciliation failures and a surprisingly long debugging session. Ask me how I know. 😄

After installation, verify that the controller is running:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

Once the controller is healthy, Kubernetes Ingress resources can automatically provision and manage AWS Application Load Balancers.

### 13. Configure DNS

Create a public hosted zone in Route 53 using the same domain configured in `values.yaml`.

After the hosted zone is created, Route 53 will provide four nameserver (NS) records. Copy these values and update the nameserver settings at your domain registrar or DNS provider.

DNS propagation may take some time depending on your provider.

Once the hosted zone is active, create the following DNS records:

| Record Name     | Type |
| --------------- | ---- |
| example.com     | A    |
| api.example.com | A    |
| ws.example.com  | A    |

For each record:

1. Enable **Alias**
2. Select **Application and Classic Load Balancer**
3. Choose the AWS region where the infrastructure was deployed
4. Select the Application Load Balancer created by the AWS Load Balancer Controller

All three records should point to the same ALB.

After DNS propagation completes, the application should be accessible from the configured domain names.

> **HTTPS (Optional)**
>
> If you plan to use HTTPS, request a certificate from AWS Certificate Manager (ACM) for your domain and subdomains before enabling the TLS-related annotations in the `novu-alb` Ingress resource.
>
> Example:
>
> * `example.com`
> * `*.example.com`
>
> Once the certificate is issued, uncomment & update the `alb.ingress.kubernetes.io/certificate-arn` annotation with the ACM certificate ARN and redeploy the chart.

## ArgoCD
If you have choose to keep ArgoCD, you can access the web UI via 
```
aws ssm start-session \
  --target <control instance id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<argocd-server-svc-ip>"],"portNumber":["443"],"localPortNumber":["8080"]}'
```
Username will be admin & password will be the output of `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
