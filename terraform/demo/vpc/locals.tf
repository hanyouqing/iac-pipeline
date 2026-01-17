locals {
  name = "${var.project_name}-${var.environment}"

  common_tags = merge(
    var.default_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Code        = "hanyouqing/iac-pipeline:terraform/demo/vpc"
    },
    var.owner != "" ? { Owner = var.owner } : {},
    var.cost_center != "" ? { CostCenter = var.cost_center } : {},
    var.tags
  )
}
