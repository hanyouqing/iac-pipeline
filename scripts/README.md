# Scripts Directory

This directory contains simplified management scripts for different tools in the infrastructure pipeline.

## Available Scripts

### 1. `make-terraform.sh` - Terraform Management

**Directory Structure**: `terraform/<project>/<resource>/`

```bash
# Show help
./scripts/make-terraform.sh help

# Basic operations (New Structure)
./scripts/make-terraform.sh init -p demo/vpc -e development
./scripts/make-terraform.sh plan -p demo/vpc -e development
./scripts/make-terraform.sh apply -p demo/vpc -e production
./scripts/make-terraform.sh destroy -p demo/vpc -e staging

# Short environment names
./scripts/make-terraform.sh plan -p demo/vpc -e dev      # dev = development
./scripts/make-terraform.sh plan -p demo/vpc -e test     # test = testing
./scripts/make-terraform.sh plan -p demo/vpc -e stage    # stage = staging
./scripts/make-terraform.sh plan -p demo/vpc -e prod     # prod = production

# Output operations
./scripts/make-terraform.sh output -p demo/vpc -e development
./scripts/make-terraform.sh output-json -p demo/vpc -e development
./scripts/make-terraform.sh output-raw -p demo/vpc -e development

# Workspace management
./scripts/make-terraform.sh workspace-list -p demo/vpc
./scripts/make-terraform.sh workspace-new -p demo/vpc -w staging
./scripts/make-terraform.sh workspace-select -p demo/vpc -w staging

# Utilities
./scripts/make-terraform.sh validate -p demo/vpc -e development
./scripts/make-terraform.sh clean -p demo/vpc
./scripts/make-terraform.sh status -p demo/vpc -e development

# Using environment variables
export PROJECT_RESOURCE=demo/vpc ENVIRONMENT=development
./scripts/make-terraform.sh plan
./scripts/make-terraform.sh apply
```

**Features**:
- Supports structure: `terraform/<project>/<resource>/`
- Automatic `backend.hcl` detection for init
- Plan files saved as `plan.<environment>.<workspace>.tfplan`
- Environment variable passed via `-var=environment=<env>`
- Enhanced status command shows workspace and plan files

**Parameters**:
- `-p, --project`: Project and resource in format `<project>/<resource>` (e.g., `demo/vpc`, `apiadmin/api`, `openauth/auth`)
- `-e, --environment`: Environment (default: `development`)
  - Valid values: `development`, `testing`, `staging`, `production`
  - Short forms: `dev`, `test`, `stage`, `prod`
- `-w, --workspace`: Terraform workspace (default: default)

**Environment Variables**:
- `PROJECT_RESOURCE`: Project and resource in format `<project>/<resource>` (e.g., `demo/vpc`, default: `demo/vpc`)
- `ENVIRONMENT`: Environment (default: `development`)
- `WORKSPACE`: Terraform workspace (default: `default`)
- `OCI_REGION`: OCI region (default: `ap-seoul-1`)
- `OCI_PROFILE`: OCI profile (default: `DEFAULT`)

### 2. `make-ansible.sh` - Ansible Management
```bash
# Show help
./scripts/make-ansible.sh help

# Basic operations
./scripts/make-ansible.sh check
./scripts/make-ansible.sh play
./scripts/make-ansible.sh ping

# Advanced operations
./scripts/make-ansible.sh list-hosts
./scripts/make-ansible.sh dry-run
./scripts/make-ansible.sh verbose
```

### 3. `make-packer.sh` - Packer Management
```bash
# Show help
./scripts/make-packer.sh help

# Basic operations
./scripts/make-packer.sh validate
./scripts/make-packer.sh build
./scripts/make-packer.sh inspect
```

### 4. `make-github.sh` - GitHub Actions Simulation
```bash
# Show help
./scripts/make-github.sh help

# Simulate GitHub Actions workflows
./scripts/make-github.sh validate
./scripts/make-github.sh plan
./scripts/make-github.sh apply
```

### 5. `make-setup.sh` - Environment Setup
```bash
# Show help
./scripts/make-setup.sh help

# Setup operations
./scripts/make-setup.sh install-tools
./scripts/make-setup.sh check-prerequisites
./scripts/make-setup.sh configure
```

## Directory Structure

```
terraform/
├── demo/              # Project: demo
│   ├── vpc/          # Resource: vpc
│   ├── jump/         # Resource: jump
│   └── gitlab/       # Resource: gitlab
├── apiadmin/         # Project: apiadmin
│   └── api/          # Resource: api
└── openauth/         # Project: openauth
    └── auth/         # Resource: auth
```

## Usage Examples

### Example 1: Initialize and Plan VPC
```bash
# Initialize Terraform
./scripts/make-terraform.sh init -p demo/vpc -e development

# Generate plan
./scripts/make-terraform.sh plan -p demo/vpc -e development

# Apply changes
./scripts/make-terraform.sh apply -p demo/vpc -e production
```

### Example 2: Using Environment Variables
```bash
export PROJECT_RESOURCE=demo/jump
export ENVIRONMENT=development

./scripts/make-terraform.sh init
./scripts/make-terraform.sh plan
./scripts/make-terraform.sh apply
```

### Example 3: Multiple Environments
```bash
# Development environment
./scripts/make-terraform.sh plan -p demo/vpc -e development
# Or short form:
./scripts/make-terraform.sh plan -p demo/vpc -e dev

# Testing environment
./scripts/make-terraform.sh plan -p demo/vpc -e testing
# Or short form:
./scripts/make-terraform.sh plan -p demo/vpc -e test

# Staging environment
./scripts/make-terraform.sh plan -p demo/vpc -e staging
# Or short form:
./scripts/make-terraform.sh plan -p demo/vpc -e stage

# Production environment
./scripts/make-terraform.sh plan -p demo/vpc -e production
# Or short form:
./scripts/make-terraform.sh plan -p demo/vpc -e prod
```

### Example 4: Workspace Management
```bash
# List workspaces
./scripts/make-terraform.sh workspace-list -p demo/vpc

# Create new workspace
./scripts/make-terraform.sh workspace-new -p demo/vpc -w staging

# Select workspace
./scripts/make-terraform.sh workspace-select -p demo/vpc -w staging

# Plan with specific workspace
./scripts/make-terraform.sh plan -p demo/vpc -e development -w staging
```

### Example 5: Status and Cleanup
```bash
# Check current status
./scripts/make-terraform.sh status -p demo/vpc -e development

# Clean up generated files
./scripts/make-terraform.sh clean -p demo/vpc
```

## Backend Configuration

The script automatically detects and uses `backend.hcl` if present in the Terraform directory:

```bash
# If backend.hcl exists, it will be used automatically
./scripts/make-terraform.sh init -p demo -r vpc -e dev

# Otherwise, uses default backend configuration from backend.tf
```

## Plan File Management

Plan files are saved in the Terraform directory with the format:
```
plan.<environment>.<workspace>.tfplan
```

Example:
- `plan.dev.default.tfplan`
- `plan.staging.staging.tfplan`
- `plan.production.prod.tfplan`

The `apply` command automatically finds and uses the appropriate plan file.

## Error Handling

The script provides clear error messages:
- Missing parameters
- Invalid project/resource paths
- Workspace issues
- Plan file not found

## Tips

1. **Use environment variables** for repeated operations:
   ```bash
   export PROJECT=demo RESOURCE=vpc ENVIRONMENT=dev
   ```

2. **Check status** before operations:
   ```bash
   ./scripts/make-terraform.sh status -p demo -r vpc -e dev
   ```

3. **Validate** before planning:
   ```bash
   ./scripts/make-terraform.sh validate -p demo -r vpc -e dev
   ```

4. **Clean up** plan files regularly:
   ```bash
   ./scripts/make-terraform.sh clean -p demo -r vpc
   ```

## See Also

- [Main README](../README.md)
- [Terraform Documentation](../terraform/demo/vpc/README.md)
- [GitHub Actions Workflows](../.github/workflows/README.md)
