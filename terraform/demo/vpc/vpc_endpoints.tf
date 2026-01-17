# VPC Endpoints Configuration
# All endpoints are disabled by default
# Set enable_vpc_endpoints = true or enable specific endpoints to enable them

# Get all route tables for the VPC
# Only create data source if at least one endpoint is enabled
data "aws_route_tables" "vpc_route_tables" {
  count  = (var.enable_vpc_endpoints && var.enable_s3_endpoint) || (var.enable_vpc_endpoints && var.enable_dynamodb_endpoint) ? 1 : 0
  vpc_id = module.vpc.vpc_id
}

# S3 Gateway Endpoint
resource "aws_vpc_endpoint" "s3" {
  count = var.enable_vpc_endpoints && var.enable_s3_endpoint ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.vpc_route_tables[0].ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-s3-endpoint"
    }
  )
}

# DynamoDB Gateway Endpoint
resource "aws_vpc_endpoint" "dynamodb" {
  count = var.enable_vpc_endpoints && var.enable_dynamodb_endpoint ? 1 : 0

  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = data.aws_route_tables.vpc_route_tables[0].ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-dynamodb-endpoint"
    }
  )
}
