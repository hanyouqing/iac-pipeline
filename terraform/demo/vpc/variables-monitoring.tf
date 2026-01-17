# Monitoring and Alerting Variables

variable "enable_monitoring" {
  description = "Enable CloudWatch monitoring and alarms"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "ARN of SNS topic for alerts (optional, will create one if not provided and monitoring is enabled)"
  type        = string
  default     = null
}

variable "alarm_threshold_nat_errors" {
  description = "Threshold for NAT Gateway error port allocation alarm"
  type        = number
  default     = 1
}

variable "alarm_threshold_nat_bandwidth_gb" {
  description = "Threshold for NAT Gateway bandwidth alarm in GB"
  type        = number
  default     = 1
}

variable "alarm_threshold_flow_log_rejects" {
  description = "Threshold for VPC Flow Log reject alarm"
  type        = number
  default     = 100
}
