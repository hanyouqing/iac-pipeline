resource "aws_security_group" "gitlab" {
  name        = "${local.name}-sg"
  description = "Security group for GitLab instance"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "HTTP from allowed CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS from allowed CIDR blocks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "SSH from allowed CIDR blocks"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr_blocks
  }

  egress {
    description     = "HTTPS to internet (for GitLab updates, API calls)"
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

  egress {
    description     = "SMTP for email notifications"
    from_port       = 587
    to_port         = 587
    protocol        = "tcp"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  # PostgreSQL egress rule (only if database_subnet_cidrs is provided)
  dynamic "egress" {
    for_each = length(var.database_subnet_cidrs) > 0 ? [1] : []
    content {
      description     = "PostgreSQL to database subnets"
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      cidr_blocks     = var.database_subnet_cidrs
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

resource "aws_ebs_volume" "gitlab_data" {
  availability_zone = data.aws_subnet.public[tolist(data.aws_subnets.public.ids)[0]].availability_zone
  size              = var.gitlab_data_volume_size
  type              = var.gitlab_data_volume_type
  encrypted         = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-data"
    }
  )
}

module "gitlab" {
  source = "github.com/hanyouqing/terraform-aws-modules//ec2?ref=main"

  name = local.name

  ami_ssm_parameter = var.ami_ssm_parameter
  instance_type     = var.instance_type
  key_name          = var.key_name != "" ? var.key_name : null

  subnet_id              = tolist(data.aws_subnets.public.ids)[0]
  vpc_security_group_ids = [aws_security_group.gitlab.id]

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

resource "aws_volume_attachment" "gitlab_data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.gitlab_data.id
  instance_id = module.gitlab.id
}
