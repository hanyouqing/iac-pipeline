module "vpc" {
  source = "github.com/hanyouqing/terraform-aws-modules//vpc?ref=main"

  # Required variables
  environment = var.environment
  project     = var.project_name
  region      = var.aws_region

  # VPC configuration
  vpc_cidr = var.vpc_cidr
  # Use provided AZs or default to match subnet count
  availability_zones = var.azs != null ? var.azs : (
    length(var.public_subnets) >= 2 ? ["us-east-1a", "us-east-1b"] : ["us-east-1a", "us-east-1b", "us-east-1c"]
  )

  # Subnet configuration
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  # NAT Gateway configuration
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  # VPN Gateway configuration
  enable_vpn_gateway = var.enable_vpn_gateway

  # DNS configuration
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # Flow Logs configuration
  enable_flow_log           = var.enable_flow_log
  flow_log_destination_type = var.flow_log_destination_type
  flow_log_destination_arn  = var.flow_log_destination_arn

  # Tags
  tags = local.common_tags
}
