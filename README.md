# iac-pipeline

Infrastructure as Code Pipeline.

## Project Structure

This repository uses a project-based structure for Terraform configurations:

```
terraform/
└── <project-name>/          # Project name (e.g., demo)
    ├── <resource-type>/     # Resource type (e.g., vpc, jump, gitlab)
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── providers.tf
    │   ├── versions.tf
    │   ├── backend.tf
    │   ├── terraform.tfvars
    │   └── README.md
    └── ...
```

### Example: Demo Project

The `demo` project contains different resource types:

- `terraform/demo/vpc/` - VPC network infrastructure
- `terraform/demo/jump/` - Jump host (bastion server)
- `terraform/demo/gitlab/` - GitLab server

## Usage

### Using Makefile

```bash
# Plan a resource
make terraform plan -p demo/vpc -e development

# Apply a resource
make terraform apply -p demo/vpc -e production

# Destroy a resource
make terraform destroy -p demo/vpc -e staging

# Short environment names (dev, test, stage, prod)
make terraform plan -p demo/vpc -e dev
```

### Using Scripts Directly

```bash
# Plan a resource
./scripts/make-terraform.sh plan -p demo/vpc -e development

# Apply a resource
./scripts/make-terraform.sh apply -p demo/vpc -e production

# Short environment names
./scripts/make-terraform.sh plan -p demo/vpc -e dev
```

### Direct Terraform Commands

```bash
# Navigate to resource directory
cd terraform/demo/vpc

# Initialize
terraform init -backend-config="backend.hcl"

# Plan
terraform plan

# Apply
terraform apply
```

## Parameters

- `-p, --project`: Project and resource in format `<project>/<resource>` (e.g., `demo/vpc`, default: `demo/vpc`)
- `-e, --environment`: Environment name (default: `development`)
  - Valid values: `development`, `testing`, `staging`, `production`
  - Short forms: `dev`, `test`, `stage`, `prod`
- `-w, --workspace`: Terraform workspace (default: `default`)

## Environment Variables

- `PROJECT_RESOURCE`: Project and resource in format `<project>/<resource>` (e.g., `demo/vpc`, default: `demo/vpc`)
- `ENVIRONMENT`: Environment name (default: `development`)
- `WORKSPACE`: Terraform workspace (default: `default`)
- `OCI_REGION`: OCI region (default: `ap-seoul-1`)
- `OCI_PROFILE`: OCI profile (default: `DEFAULT`)



