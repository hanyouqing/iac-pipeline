# Network-related variables for jump host

variable "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets for SSH access"
  type        = list(string)
  default     = []
}
