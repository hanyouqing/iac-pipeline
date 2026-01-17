# AWS Jump Host (Bastion) Demo

This directory contains a Terraform configuration for creating an AWS EC2 jump host (bastion server) using the `hanyouqing/terraform-aws-modules/ec2` module.

## Overview

This configuration creates a jump host (bastion server) that:
- Deploys in a public subnet of the specified VPC
- Provides SSH access to private resources
- Uses Amazon Linux 2023 AMI
- Includes security group with SSH access control
- Supports encrypted root volume

## Prerequisites

- Terraform >= 1.14
- AWS CLI configured with appropriate credentials
- AWS Provider ~> 6.28
- Existing VPC with public subnets (created by `terraform/demo/vpc`)
- EC2 Key Pair for SSH access

## Quick Start

1. Ensure VPC is created first:
   ```bash
   cd ../vpc
   terraform apply
   ```

2. Copy the example variables file:
   ```bash
   cp terraform.tfvars terraform.tfvars
   ```

3. Configure backend (if using remote state):
   ```bash
   cp backend.hcl.example backend.hcl
   ```
   Edit `backend.hcl` with your S3 bucket details.

4. Edit `terraform.tfvars` with your specific values:
   ```hcl
   aws_region   = "us-east-1"
   environment  = "dev"
   project_name = "demo"
   vpc_name     = "demo-dev"  # Must match VPC name from vpc module
   key_name     = "your-ec2-key-pair-name"
   ```

5. Initialize Terraform:
   ```bash
   terraform init -backend-config="backend.hcl"
   ```

6. Review the plan:
   ```bash
   terraform plan
   ```

7. Apply the configuration:
   ```bash
   terraform apply
   ```

8. SSH to jump host:
   ```bash
   ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
   ```

## Configuration

### Required Variables

- `vpc_name`: Name of the VPC (must match VPC created by vpc module)
- `key_name`: EC2 Key Pair name for SSH access

### Optional Variables

- `aws_region`: AWS region (default: `us-east-1`)
- `environment`: Environment name (default: `dev`)
- `project_name`: Project name (default: `demo`)
- `instance_type`: EC2 instance type (default: `t3.micro`)
- `allowed_cidr_blocks`: CIDR blocks allowed to SSH (default: `["0.0.0.0/0"]`)
- `root_volume_size`: Root volume size in GB (default: `8`)
- `root_volume_type`: Root volume type (default: `gp3`)

See `variables.tf` for complete variable documentation.

## Security Best Practices

1. **SSH Access Control:**
   - Restrict `allowed_cidr_blocks` to your office IPs or VPN CIDR ranges
   - Avoid using `0.0.0.0/0` in production environments
   - Use SSH key pairs instead of passwords

2. **Network Security:**
   - Jump host is deployed in public subnet
   - Security group only allows SSH (port 22) from specified CIDR blocks
   - All outbound traffic is allowed (for accessing private resources)

3. **Instance Security:**
   - Root volume is encrypted by default
   - Use IAM instance profiles for AWS API access (if needed)
   - Enable detailed monitoring for production environments
   - Regularly update the AMI and apply security patches

4. **Access Management:**
   - Use AWS Systems Manager Session Manager as alternative to SSH
   - Implement MFA for AWS console access
   - Rotate SSH keys regularly
   - Use bastion host to access private resources (never expose private instances directly)

## Cost Considerations

### Monthly Cost Estimation

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| EC2 Instance | t3.micro | ~$7-10 |
| EBS Volume | 8 GB gp3 | ~$0.64 |
| Data Transfer | 1 GB/month | ~$0.09 |
| **Total** | | **~$8-11/month** |

### Cost Optimization Strategies

1. **Non-Production Environments:**
   - Use `t3.micro` instance type (eligible for free tier)
   - Disable detailed monitoring
   - Use smaller root volume (8 GB minimum)

2. **Production Environments:**
   - Use `t3.small` or `t3.medium` for better performance
   - Enable detailed monitoring if needed
   - Consider Reserved Instances for predictable workloads

3. **Cost Scaling:**
   - Small (dev/test): ~$8-11/month
   - Medium (staging): ~$15-20/month
   - Large (production): ~$30-40/month

## Architecture

```
VPC (Public Subnet)
└── Jump Host (EC2)
    ├── Public IP (for SSH access)
    ├── Security Group (SSH from allowed CIDRs)
    └── Private IP (for accessing private resources)
```

## Using Jump Host

### SSH Access

```bash
# Direct SSH
ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>

# SSH Config (~/.ssh/config)
Host jump-demo
    HostName <public-ip>
    User ec2-user
    IdentityFile ~/.ssh/your-key.pem
    ForwardAgent yes

# Then use: ssh jump-demo
```

### Access Private Resources

```bash
# SSH to jump host first
ssh jump-demo

# From jump host, SSH to private instances
ssh ec2-user@<private-instance-ip>
```

### SSH Agent Forwarding

```bash
# Enable agent forwarding
ssh -A jump-demo

# Now you can SSH to private instances without copying keys
ssh ec2-user@<private-instance-ip>
```

## Outputs

The configuration provides the following outputs:

- `jump_instance_id`: EC2 instance ID
- `jump_public_ip`: Public IP address
- `jump_private_ip`: Private IP address
- `jump_public_dns`: Public DNS name
- `jump_security_group_id`: Security group ID
- `vpc_id`: VPC ID
- `subnet_id`: Subnet ID

See `outputs.tf` for complete output documentation.

## Troubleshooting

### Cannot SSH to Jump Host

1. Check security group allows your IP:
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. Verify key pair is correct:
   ```bash
   aws ec2 describe-key-pairs --key-names <key-name>
   ```

3. Check instance status:
   ```bash
   aws ec2 describe-instances --instance-ids <instance-id>
   ```

### VPC Not Found

1. Ensure VPC is created first:
   ```bash
   cd ../vpc && terraform apply
   ```

2. Verify VPC name matches:
   ```bash
   aws ec2 describe-vpcs --filters "Name=tag:Name,Values=demo-dev"
   ```

## References

- [Terraform AWS EC2 Module](https://github.com/hanyouqing/terraform-aws-modules/tree/main/ec2)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/security-groups.html)
- [SSH Config](https://www.ssh.com/academy/ssh/config)
