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
  description = "Environment name (dev, testing, staging, production)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "testing", "staging", "production"], var.environment)
    error_message = "Environment must be one of: dev, testing, staging, production."
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

variable "vpc_name" {
  description = "Name of the VPC to deploy GitLab into (used to lookup VPC)"
  type        = string
  default     = "demo-dev"
}

variable "instance_type" {
  description = "EC2 instance type for GitLab (minimum t3.medium recommended)"
  type        = string
  default     = "t3.medium"

  validation {
    condition     = can(regex("^[a-z0-9.]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

variable "ami_ssm_parameter" {
  description = "SSM parameter name for the AMI ID (Amazon Linux 2023)"
  type        = string
  default     = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

variable "key_name" {
  description = "Key pair name to use for SSH access"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access GitLab (HTTP/HTTPS)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to GitLab instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_public_ip" {
  description = "Enable public IP for GitLab instance"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Size of root volume in GB (minimum 20GB recommended for GitLab)"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 20 and 16384 GB."
  }
}

variable "root_volume_type" {
  description = "Type of root volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be one of: gp3, gp2, io1, io2."
  }
}

variable "gitlab_data_volume_size" {
  description = "Size of additional EBS volume for GitLab data in GB"
  type        = number
  default     = 50

  validation {
    condition     = var.gitlab_data_volume_size >= 20 && var.gitlab_data_volume_size <= 16384
    error_message = "GitLab data volume size must be between 20 and 16384 GB."
  }
}

variable "gitlab_data_volume_type" {
  description = "Type of GitLab data volume (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.gitlab_data_volume_type)
    error_message = "GitLab data volume type must be one of: gp3, gp2, io1, io2."
  }
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "gitlab_external_url" {
  description = "External URL for GitLab (e.g., https://gitlab.example.com)"
  type        = string
  default     = ""
}

variable "gitlab_root_password" {
  description = "Initial root password for GitLab (leave empty to generate random password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "user_data" {
  description = "User data script to run on instance launch (GitLab installation script)"
  type        = string
  default     = ""
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
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
