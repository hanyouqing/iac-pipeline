# AWS GitLab EC2 Demo

This directory contains a Terraform configuration for creating an AWS EC2 instance running GitLab using the `hanyouqing/terraform-aws-modules/ec2` module.

## Overview

This configuration creates a GitLab server that:
- Deploys in a public subnet of the specified VPC
- Provides HTTP/HTTPS access for GitLab web UI
- Includes separate EBS volume for GitLab data storage
- Uses Amazon Linux 2023 AMI
- Includes security group with HTTP/HTTPS/SSH access control

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
   instance_type = "t3.medium"  # Minimum recommended for GitLab
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

8. Access GitLab:
   ```bash
   # Get the public IP from outputs
   terraform output gitlab_public_ip
   
   # Open in browser
   open http://<public-ip>
   ```

## GitLab Installation

After the instance is created, you need to install GitLab. You can:

1. **Use user_data script** (recommended):
   Add a GitLab installation script to `user_data` variable in `terraform.tfvars`

2. **Manual installation**:
   ```bash
   # SSH to instance
   ssh -i ~/.ssh/your-key.pem ec2-user@<public-ip>
   
   # Install GitLab (example for Amazon Linux 2023)
   sudo yum update -y
   # Follow GitLab installation guide: https://about.gitlab.com/install/
   ```

3. **Mount data volume**:
   ```bash
   # After SSH to instance
   sudo mkfs -t xfs /dev/nvme1n1  # Format the data volume
   sudo mkdir /var/opt/gitlab
   sudo mount /dev/nvme1n1 /var/opt/gitlab
   # Add to /etc/fstab for persistence
   ```

## Configuration

### Required Variables

- `vpc_name`: Name of the VPC (must match VPC created by vpc module)
- `key_name`: EC2 Key Pair name for SSH access

### Optional Variables

- `aws_region`: AWS region (default: `us-east-1`)
- `environment`: Environment name (default: `dev`)
- `project_name`: Project name (default: `demo`)
- `instance_type`: EC2 instance type (default: `t3.medium`, minimum recommended)
- `allowed_cidr_blocks`: CIDR blocks allowed HTTP/HTTPS access (default: `["0.0.0.0/0"]`)
- `allowed_ssh_cidr_blocks`: CIDR blocks allowed SSH access (default: `["0.0.0.0/0"]`)
- `root_volume_size`: Root volume size in GB (default: `20`)
- `gitlab_data_volume_size`: GitLab data volume size in GB (default: `50`)

See `variables.tf` for complete variable documentation.

## Security Best Practices

1. **Access Control:**
   - Restrict `allowed_cidr_blocks` to your office IPs or VPN CIDR ranges
   - Restrict `allowed_ssh_cidr_blocks` to administrative IPs only
   - Avoid using `0.0.0.0/0` in production environments
   - Use SSH key pairs instead of passwords

2. **Network Security:**
   - GitLab is deployed in public subnet
   - Security group allows HTTP (80), HTTPS (443), and SSH (22)
   - Consider using Application Load Balancer with SSL certificate for HTTPS

3. **Instance Security:**
   - Root volume is encrypted by default
   - Data volume is encrypted by default
   - Use IAM instance profiles for AWS API access (if needed)
   - Enable detailed monitoring for production environments
   - Regularly update the AMI and apply security patches

4. **GitLab Security:**
   - Change default root password immediately
   - Enable 2FA for all users
   - Configure SSL/TLS certificates
   - Set up regular backups
   - Use GitLab's built-in security features

## Cost Considerations

### Monthly Cost Estimation

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| EC2 Instance | t3.medium | ~$30-35 |
| EBS Root Volume | 20 GB gp3 | ~$1.60 |
| EBS Data Volume | 50 GB gp3 | ~$4.00 |
| Data Transfer | 10 GB/month | ~$0.90 |
| **Total** | | **~$36-41/month** |

### Cost Optimization Strategies

1. **Non-Production Environments:**
   - Use `t3.small` instance type (may be slow)
   - Use smaller data volume (20 GB)
   - Disable detailed monitoring

2. **Production Environments:**
   - Use `t3.large` or `t3.xlarge` for better performance
   - Use larger data volume (100+ GB) for repositories
   - Enable detailed monitoring if needed
   - Consider Reserved Instances for predictable workloads

3. **Cost Scaling:**
   - Small (dev/test): ~$36-41/month
   - Medium (staging): ~$60-80/month
   - Large (production): ~$120-200/month

## Architecture

```
VPC (Public Subnet)
└── GitLab EC2 Instance
    ├── Root Volume (20 GB, encrypted)
    ├── Data Volume (50 GB, encrypted, /dev/sdf)
    ├── Public IP (for web access)
    ├── Security Group (HTTP/HTTPS/SSH)
    └── GitLab Application
```

## Storage

The configuration creates two EBS volumes:

1. **Root Volume** (`/dev/xvda`):
   - Size: 20 GB (configurable)
   - Type: gp3 (configurable)
   - Encrypted: Yes
   - Contains: OS and GitLab application

2. **Data Volume** (`/dev/sdf`):
   - Size: 50 GB (configurable)
   - Type: gp3 (configurable)
   - Encrypted: Yes
   - Contains: GitLab repositories and data (needs manual mounting)

### Mounting Data Volume

After instance creation, mount the data volume:

```bash
# SSH to instance
ssh ec2-user@<public-ip>

# Check if volume is attached
lsblk

# Format volume (first time only)
sudo mkfs -t xfs /dev/nvme1n1

# Create mount point
sudo mkdir -p /var/opt/gitlab

# Mount volume
sudo mount /dev/nvme1n1 /var/opt/gitlab

# Add to /etc/fstab for persistence
echo '/dev/nvme1n1 /var/opt/gitlab xfs defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

## Outputs

The configuration provides the following outputs:

- `gitlab_instance_id`: EC2 instance ID
- `gitlab_public_ip`: Public IP address
- `gitlab_private_ip`: Private IP address
- `gitlab_public_dns`: Public DNS name
- `gitlab_url`: GitLab HTTP URL
- `gitlab_url_https`: GitLab HTTPS URL
- `gitlab_security_group_id`: Security group ID
- `gitlab_data_volume_id`: Data EBS volume ID
- `vpc_id`: VPC ID
- `subnet_id`: Subnet ID

See `outputs.tf` for complete output documentation.

## Troubleshooting

### Cannot Access GitLab Web UI

1. Check security group allows your IP:
   ```bash
   aws ec2 describe-security-groups --group-ids <sg-id>
   ```

2. Verify instance is running:
   ```bash
   aws ec2 describe-instances --instance-ids <instance-id>
   ```

3. Check GitLab service status (after SSH):
   ```bash
   sudo gitlab-ctl status
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

### Data Volume Not Mounted

1. Check volume attachment:
   ```bash
   aws ec2 describe-volumes --volume-ids <volume-id>
   ```

2. SSH to instance and check:
   ```bash
   lsblk
   sudo file -s /dev/nvme1n1
   ```

## References

- [Terraform AWS EC2 Module](https://github.com/hanyouqing/terraform-aws-modules/tree/main/ec2)
- [GitLab Installation Guide](https://about.gitlab.com/install/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [AWS EBS Documentation](https://docs.aws.amazon.com/ebs/)
- [GitLab Documentation](https://docs.gitlab.com/)
