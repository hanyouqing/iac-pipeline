variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.aws_region))
    error_message = "AWS region must be a valid region identifier."
  }
}

variable "environment" {
  description = "Environment name (development, testing, staging, production or short forms: dev, test, stage, prod)"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "testing", "staging", "production", "dev", "test", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: development, testing, staging, production (or short forms: dev, test, stage, prod)."
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "demo"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "azs" {
  description = "List of availability zones. If null, will be automatically selected by the module"
  type        = list(string)
  default     = null
}

variable "public_subnets" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition = alltrue([
      for subnet in var.public_subnets : can(cidrhost(subnet, 0))
    ])
    error_message = "All public subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "private_subnets" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]

  validation {
    condition = alltrue([
      for subnet in var.private_subnets : can(cidrhost(subnet, 0))
    ])
    error_message = "All private subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "database_subnets" {
  description = "List of CIDRs for database subnets (isolated subnets for RDS, ElastiCache, etc.)"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24"]

  validation {
    condition = alltrue([
      for subnet in var.database_subnets : can(cidrhost(subnet, 0))
    ])
    error_message = "All database subnet CIDRs must be valid IPv4 CIDR blocks."
  }
}

variable "create_database_subnet_group" {
  description = "Controls if database subnet group should be created"
  type        = bool
  default     = true
}

variable "create_database_subnet_route_table" {
  description = "Controls if separate route table for database subnets should be created"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Whether to enable NAT Gateways for private subnets. Set to false for non-production environments to reduce costs"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for all private subnets (cost optimization for non-production)"
  type        = bool
  default     = false
}

variable "enable_vpn_gateway" {
  description = "Whether to enable VPN Gateway"
  type        = bool
  default     = false
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "enable_flow_log" {
  description = "Enable VPC Flow Logs for network monitoring"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Type of flow log destination. Can be s3 or cloud-watch-logs"
  type        = string
  default     = "cloud-watch-logs"

  validation {
    condition     = contains(["s3", "cloud-watch-logs"], var.flow_log_destination_type)
    error_message = "Flow log destination type must be either 's3' or 'cloud-watch-logs'."
  }
}

variable "flow_log_destination_arn" {
  description = "ARN of the destination for VPC Flow Logs. Required if flow_log_destination_type is s3"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "tags" {
  description = "Additional tags to apply to VPC resources"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for financial tracking"
  type        = string
  default     = ""
}

# VPC Endpoints Configuration
variable "enable_s3_endpoint" {
  description = "Enable S3 VPC Gateway Endpoint"
  type        = bool
  default     = false
}

variable "enable_dynamodb_endpoint" {
  description = "Enable DynamoDB VPC Gateway Endpoint"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable all VPC endpoints (Gateway and Interface). Set to false to disable all endpoints by default"
  type        = bool
  default     = false
}
