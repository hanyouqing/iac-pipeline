output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.vpc.vpc_name
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "List of CIDR blocks of public subnets"
  value       = module.vpc.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "List of CIDR blocks of private subnets"
  value       = module.vpc.private_subnet_cidrs
}

output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = length(var.database_subnets) > 0 ? module.vpc.database_subnet_ids : []
}

output "database_subnet_cidrs" {
  description = "List of CIDR blocks of database subnets"
  value       = length(var.database_subnets) > 0 ? module.vpc.database_subnet_cidrs : []
}

output "database_subnet_group_id" {
  description = "ID of the database subnet group"
  value       = var.create_database_subnet_group && length(var.database_subnets) > 0 ? module.vpc.database_subnet_group_id : null
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group (same as ID)"
  value       = var.create_database_subnet_group && length(var.database_subnets) > 0 ? module.vpc.database_subnet_group_id : null
}

output "nat_gateway_ids" {
  description = "List of IDs of NAT Gateways"
  value       = var.enable_nat_gateway ? module.vpc.nat_gateway_ids : []
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = module.vpc.vpc_arn
}

output "azs" {
  description = "List of availability zones used"
  value       = var.azs != null ? var.azs : ["us-east-1a", "us-east-1b"]
}

output "flow_log_id" {
  description = "ID of the VPC Flow Log"
  value       = var.enable_flow_log ? module.vpc.vpc_flow_log_id : null
}

output "zzz_reminder_access_commands" {
  description = "⚠️  REMINDER: Access Commands"
  value       = <<-EOT
    ⚠️  REMINDER: Access Commands
    
    aws ec2 describe-vpcs --vpc-ids ${module.vpc.vpc_id} --region ${var.aws_region}
    aws ec2 describe-subnets --filters "Name=vpc-id,Values=${module.vpc.vpc_id}" --region ${var.aws_region}
    ${var.enable_nat_gateway ? "aws ec2 describe-nat-gateways --filter \"Name=vpc-id,Values=${module.vpc.vpc_id}\" --region ${var.aws_region}" : ""}
  EOT
}

output "zzz_reminder_important_notes" {
  description = "⚠️  REMINDER: Important Notes"
  value       = <<-EOT
    ⚠️  REMINDER: Important Notes
    
    Network: VPC ${var.vpc_cidr} | Public: ${join(", ", var.public_subnets)} | Private: ${join(", ", var.private_subnets)}${length(var.database_subnets) > 0 ? " | Database: ${join(", ", var.database_subnets)}" : ""}
    Cost: NAT Gateway ${var.enable_nat_gateway ? (var.single_nat_gateway ? "~$32/month" : "~$64/month") : "disabled"} | Flow Logs ${var.enable_flow_log ? "enabled" : "disabled"}
    Security: Create security groups separately | Database subnets isolated (no internet access)${length(var.database_subnets) > 0 && var.create_database_subnet_group && module.vpc.database_subnet_group_id != null ? " | Use database subnet group: ${module.vpc.database_subnet_group_id}" : ""}
    Next: Create security groups → Deploy resources → Configure VPC endpoints (optional)
  EOT
}