# AWS VPC Demo

This directory contains a Terraform configuration for creating an AWS VPC using the `terraform-aws-modules/vpc/aws` module.

## Overview

This configuration creates a VPC with:
- Public and private subnets across multiple availability zones
- Internet Gateway for public subnet internet access
- NAT Gateway(s) for private subnet internet access (configurable)
- VPC Flow Logs for network monitoring (configurable)
- DNS hostnames and DNS support enabled

## Prerequisites

- Terraform >= 1.14
- AWS CLI configured with appropriate credentials
- AWS Provider ~> 6.28
- S3 bucket for Terraform state storage
- DynamoDB table for state locking (optional but recommended)

## Quick Start

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars terraform.tfvars
   ```

2. Configure backend (if using remote state):
   ```bash
   cp backend.hcl.example backend.hcl
   ```
   Edit `backend.hcl` with your S3 bucket and DynamoDB table details.

3. Edit `terraform.tfvars` with your specific values:
   ```hcl
   aws_region   = "us-east-1"
   environment  = "development"
   project_name = "demo"
   ```

4. Initialize Terraform:
   ```bash
   # With backend configuration file
   terraform init -backend-config="backend.hcl"
   
   # Or without backend (local state)
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

- `aws_region`: AWS region to deploy resources
- `environment`: Environment name (dev, testing, staging, production)
- `project_name`: Project name for resource naming

### Optional Variables

- `vpc_cidr`: VPC CIDR block (default: `10.0.0.0/16`)
- `azs`: List of availability zones (auto-selected if null)
- `public_subnets`: List of public subnet CIDRs
- `private_subnets`: List of private subnet CIDRs
- `database_subnets`: List of database subnet CIDRs (default: `["10.0.201.0/24", "10.0.202.0/24"]`)
- `create_database_subnet_group`: Create database subnet group (default: `true`)
- `create_database_subnet_route_table`: Create separate route table for database subnets (default: `true`)
- `enable_nat_gateway`: Enable NAT Gateway (default: `true`)
- `single_nat_gateway`: Use single NAT Gateway for cost optimization (default: `false`)
- `enable_flow_log`: Enable VPC Flow Logs (default: `true`)

See `variables.tf` for complete variable documentation.

## Cost Considerations

### Monthly Cost Estimation (Production Configuration)

| Resource | Configuration | Monthly Cost |
|----------|--------------|--------------|
| VPC | Standard VPC | $0 |
| Internet Gateway | Standard | $0 |
| NAT Gateway | 2 NAT Gateways (multi-AZ) | ~$64 |
| NAT Gateway Data Transfer | 1 TB/month | ~$45 |
| VPC Flow Logs | CloudWatch Logs | ~$5-10 |
| **Total** | | **~$114-119/month** |

### Cost Optimization Strategies

1. **Non-Production Environments:**
   - Set `enable_nat_gateway = false` if private subnets don't need internet access
   - Set `single_nat_gateway = true` to use one NAT Gateway instead of multiple
   - Disable Flow Logs: `enable_flow_log = false`

2. **Production Environments:**
   - Use multiple NAT Gateways for high availability
   - Consider VPC endpoints for AWS services to reduce NAT Gateway data transfer costs
   - Use S3 destination for Flow Logs instead of CloudWatch Logs for cost savings

3. **Cost Scaling:**
   - Small (dev/test): ~$0-5/month (no NAT Gateway, no Flow Logs)
   - Medium (staging): ~$35-40/month (single NAT Gateway, Flow Logs)
   - Large (production): ~$114-119/month (multi-AZ NAT Gateways, Flow Logs)
   - Enterprise: ~$200+/month (multiple VPCs, enhanced monitoring)

## Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets
│   ├── 10.0.1.0/24 (AZ-1)
│   └── 10.0.2.0/24 (AZ-2)
│       └── Internet Gateway
│
├── Private Subnets
│   ├── 10.0.101.0/24 (AZ-1)
│   └── 10.0.102.0/24 (AZ-2)
│       └── NAT Gateway(s)
│
└── Database Subnets (Isolated)
    ├── 10.0.201.0/24 (AZ-1)
    └── 10.0.202.0/24 (AZ-2)
        └── No Internet/NAT Gateway access
            └── Database Subnet Group
```

### Subnet Tier Explanation

- **Public Subnets**: For internet-facing resources (Load Balancers, Bastion Hosts)
- **Private Subnets**: For application servers with outbound internet access via NAT Gateway
- **Database Subnets**: Isolated subnets for databases (RDS, ElastiCache) with no internet access

## Outputs

The configuration provides the following outputs:

- `vpc_id`: VPC ID
- `vpc_name`: VPC name
- `public_subnets`: List of public subnet IDs
- `private_subnets`: List of private subnet IDs
- `database_subnets`: List of database subnet IDs
- `database_subnet_group_id`: Database subnet group ID (if created)
- `database_subnet_group_name`: Database subnet group name (if created)
- `nat_gateway_ids`: List of NAT Gateway IDs
- `internet_gateway_id`: Internet Gateway ID
- `flow_log_id`: VPC Flow Log ID (if enabled)

See `outputs.tf` for complete output documentation.

## Security Best Practices

1. **Network Segmentation:**
   - Use private subnets for application servers
   - Use database subnets for RDS, ElastiCache, and other database services
   - Use public subnets only for load balancers and bastion hosts
   - Database subnets are completely isolated with no internet access

2. **Security Groups:**
   - Create security groups with least privilege rules
   - Database security groups should only allow inbound from application security groups
   - Reference subnet IDs from outputs when creating security groups

3. **Database Subnets:**
   - Database subnets have no route to internet gateway or NAT gateway
   - Use database subnet groups for RDS and ElastiCache
   - Configure security groups to restrict database access to application tier only
   - Enable encryption at rest for all database resources

4. **Flow Logs:**
   - Enable Flow Logs for network monitoring and troubleshooting
   - Review Flow Logs regularly for security incidents

5. **NAT Gateway:**
   - Use NAT Gateway for private subnet internet access
   - Database subnets don't need NAT Gateway (cost savings)
   - Consider VPC endpoints to reduce NAT Gateway costs

## Next Steps

After creating the VPC:

1. Create security groups for your resources
2. Deploy EC2 instances or other resources in the subnets
3. Configure route tables if custom routing is needed
4. Set up VPC endpoints for AWS services
5. Configure Network ACLs if additional network-level security is required

## References

- [Terraform AWS VPC Module](https://github.com/terraform-aws-modules/terraform-aws-vpc)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [VPC Flow Logs](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)
