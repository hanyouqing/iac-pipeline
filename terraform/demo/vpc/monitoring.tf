# CloudWatch Alarms for VPC Monitoring

resource "aws_cloudwatch_metric_alarm" "nat_gateway_errors" {
  count = var.enable_nat_gateway ? 1 : 0

  alarm_name          = "${local.name}-nat-gateway-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "This metric monitors NAT Gateway error port allocation"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = length(module.vpc.nat_gateway_ids) > 0 ? module.vpc.nat_gateway_ids[0] : ""
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-nat-gateway-errors"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "nat_gateway_bandwidth" {
  count = var.enable_nat_gateway ? 1 : 0

  alarm_name          = "${local.name}-nat-gateway-bandwidth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "BytesOutToDestination"
  namespace           = "AWS/NATGateway"
  period              = 300
  statistic           = "Average"
  threshold           = 1000000000 # 1 GB
  alarm_description   = "This metric monitors NAT Gateway bandwidth usage"
  treat_missing_data  = "notBreaching"

  dimensions = {
    NatGatewayId = length(module.vpc.nat_gateway_ids) > 0 ? module.vpc.nat_gateway_ids[0] : ""
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-nat-gateway-bandwidth"
    }
  )
}

# SNS Topic for VPC Alerts (optional)
resource "aws_sns_topic" "vpc_alerts" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "${local.name}-vpc-alerts"
  display_name      = "${local.name} VPC Alerts"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-vpc-alerts"
    }
  )
}

# CloudWatch Log Group for VPC Flow Logs (if using CloudWatch Logs)
resource "aws_cloudwatch_log_metric_filter" "vpc_flow_log_errors" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name           = "${local.name}-flow-log-errors"
  log_group_name = module.vpc.vpc_flow_log_cloudwatch_log_group_name
  pattern        = "[version, account_id, interface_id, srcaddr, dstaddr, srcport, dstport, protocol, packets, bytes, window_start, window_end, action=REJECT, flow_direction]"

  metric_transformation {
    name      = "VPCFlowLogRejects"
    namespace = "VPC/FlowLogs"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "vpc_flow_log_rejects" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  alarm_name          = "${local.name}-flow-log-rejects"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "VPCFlowLogRejects"
  namespace           = "VPC/FlowLogs"
  period              = 300
  statistic           = "Sum"
  threshold           = 100
  alarm_description   = "This metric monitors rejected VPC flow log entries"
  treat_missing_data  = "notBreaching"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-flow-log-rejects"
    }
  )
}
