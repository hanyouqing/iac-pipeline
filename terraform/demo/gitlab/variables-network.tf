# Network-related variables for GitLab

variable "database_subnet_cidrs" {
  description = "CIDR blocks of database subnets for PostgreSQL access"
  type        = list(string)
  default     = []
}
