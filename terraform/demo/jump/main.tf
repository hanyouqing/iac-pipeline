resource "aws_security_group" "jump" {
  name        = "${local.name}-sg"
  description = "Security group for jump host"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDR blocks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description     = "HTTPS to internet (for package updates, API calls)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  egress {
    description     = "HTTP to internet (for package updates)"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  egress {
    description     = "DNS"
    from_port       = 53
    to_port         = 53
    protocol        = "udp"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  # SSH to private subnets (if private_subnet_cidrs is provided)
  dynamic "egress" {
    for_each = length(var.private_subnet_cidrs) > 0 ? [1] : []
    content {
      description     = "SSH to private subnets"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = var.private_subnet_cidrs
      prefix_list_ids = []
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-sg"
    }
  )
}

module "jump" {
  source = "github.com/hanyouqing/terraform-aws-modules//ec2?ref=main"

  name = local.name

  ami_ssm_parameter = var.ami_ssm_parameter
  instance_type     = var.instance_type
  key_name          = var.key_name != "" ? var.key_name : null

  subnet_id              = tolist(data.aws_subnets.public.ids)[0]
  vpc_security_group_ids = [aws_security_group.jump.id]

  associate_public_ip_address = var.enable_public_ip

  root_block_device = [
    {
      volume_type = var.root_volume_type
      volume_size = var.root_volume_size
      encrypted   = true
    }
  ]

  monitoring    = var.enable_detailed_monitoring
  user_data     = var.user_data != "" ? var.user_data : null
  instance_tags = local.common_tags
}
