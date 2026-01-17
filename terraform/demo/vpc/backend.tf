terraform {
  backend "s3" {
    # Backend configuration should be provided via backend configuration file or command line
    # Example: terraform init -backend-config="backend.hcl"
    #
    # Required backend configuration:
    bucket               = "terraform-aws-modules-example-state"                          # S3 bucket for state storage (must exist)
    key                  = "hanyouqing/iac-pipeline:terraform/demo/vpc/terraform.tfstate" # State file path
    region               = "us-east-1"                                                    # AWS region
    encrypt              = true                                                           # Enable encryption at rest
    use_lockfile         = true                                                           # Use S3 native locking (Terraform 1.10+)
    workspace_key_prefix = "env:"                                                         # Workspace key prefix (required per rules)

    # Optional backend configuration:
    # profile              = "my-aws-profile"            # AWS profile to use
    # role_arn             = "arn:aws:iam::123456789012:role/TerraformBackend"  # IAM role for backend
    # kms_key_id           = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"  # KMS key for encryption
    # endpoint             = "https://s3.us-east-1.amazonaws.com"  # Custom S3 endpoint
    # skip_credentials_validation = false                 # Skip AWS credentials validation
    # skip_metadata_api_check     = false                 # Skip EC2 metadata API check
    # force_path_style            = false                 # Force path style S3 URLs
  }
}
