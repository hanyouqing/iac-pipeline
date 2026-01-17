#!/bin/bash

# GitHub Actions Simulation Script
# Usage: ./scripts/make-github.sh <command> [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Default values
SITE=${SITE:-oci-labs}
ENVIRONMENT=${ENVIRONMENT:-dev}
WORKSPACE=${WORKSPACE:-default}

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Function to show help
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}= GitHub Actions Simulation Script    =${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  pre-commit    - Run all pre-commit checks"
    echo "  format-check  - Check Terraform formatting"
    echo "  format        - Format Terraform code"
    echo "  validate      - Validate Terraform configuration"
    echo "  plan          - Generate Terraform plan"
    echo "  apply         - Apply Terraform changes"
    echo "  docs          - Generate documentation"
    echo "  lint          - Run TFLint"
    echo "  security      - Run security scans"
    echo "  test          - Run comprehensive tests"
    echo "  ci            - Full CI/CD simulation"
    echo ""
    echo "Environment variables:"
    echo "  SITE        - Site to deploy (default: $SITE)"
    echo "  ENVIRONMENT - Environment to deploy (default: $ENVIRONMENT)"
    echo "  WORKSPACE   - Terraform workspace (default: $WORKSPACE)"
    echo ""
    echo "Examples:"
    echo "  $0 pre-commit"
    echo "  $0 format-check"
    echo "  SITE=my-site ENVIRONMENT=prod $0 plan"
    echo ""
}

# Function to validate site exists
validate_site() {
    if [ ! -d "terraform/sites/$SITE" ]; then
        echo -e "${RED}✗ Site $SITE not found${NC}"
        echo -e "${BLUE}Available sites:${NC}"
        ls -d terraform/sites/*/ 2>/dev/null | sed 's|terraform/sites/|  |' | sed 's|/||' || echo "  No sites found"
        exit 1
    fi
    echo -e "${GREEN}✓ Site $SITE found${NC}"
}

# Function to run terraform command
run_terraform() {
    local cmd="$1"
    shift
    echo -e "${BLUE}Running: terraform $cmd $*${NC}"
    cd "terraform/sites/$SITE"
    terraform "$cmd" "$@"
    cd "$PROJECT_ROOT"
}

# Parse command line arguments using getopts
while getopts "e:s:w:h-:" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        s)
            SITE="$OPTARG"
            ;;
        w)
            WORKSPACE="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                environment)
                    ENVIRONMENT="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    ;;
                site)
                    SITE="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    ;;
                workspace)
                    WORKSPACE="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    ;;
                help)
                    show_help
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Error: Unknown long option --$OPTARG${NC}"
                    show_help
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo -e "${RED}Error: Unknown option -$OPTARG${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Shift to get the command
shift $((OPTIND - 1))
COMMAND="${1:-help}"

# Main command handling
case "$COMMAND" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "pre-commit")
        echo -e "${BLUE}Running pre-commit checks...${NC}"
        $0 format-check
        $0 validate
        $0 plan
        $0 docs
        $0 lint
        $0 security
        echo -e "${GREEN}✓ All pre-commit checks passed!${NC}"
        ;;
    "format-check")
        echo -e "${BLUE}Checking Terraform format...${NC}"
        if command -v terraform >/dev/null 2>&1; then
            terraform fmt -check -recursive || (echo -e "${RED}✗ Terraform format check failed${NC}" && exit 1)
            echo -e "${GREEN}✓ Terraform format check passed${NC}"
        else
            echo -e "${YELLOW}⚠ Terraform not installed, skipping format check${NC}"
        fi
        ;;
    "format")
        echo -e "${BLUE}Formatting Terraform code...${NC}"
        if command -v terraform >/dev/null 2>&1; then
            echo -e "${BLUE}Formatting root directory...${NC}"
            terraform fmt -recursive .
            echo -e "${BLUE}Formatting OCI modules...${NC}"
            for module in terraform/modules/oci/*/; do
                if [ -d "$module" ]; then
                    terraform fmt -recursive "$module"
                fi
            done
            echo -e "${BLUE}Formatting sites...${NC}"
            for site in terraform/sites/*/; do
                if [ -d "$site" ]; then
                    terraform fmt -recursive "$site"
                fi
            done
            echo -e "${GREEN}✓ Terraform code formatted${NC}"
        else
            echo -e "${YELLOW}⚠ Terraform not installed, skipping format${NC}"
        fi
        ;;
    "validate")
        validate_site
        echo -e "${BLUE}Validating Terraform configuration...${NC}"
        if command -v terraform >/dev/null 2>&1; then
            run_terraform init -backend=false
            run_terraform workspace select "$WORKSPACE" || run_terraform workspace new "$WORKSPACE"
            run_terraform validate
            echo -e "${GREEN}✓ Site validation passed${NC}"
        else
            echo -e "${YELLOW}⚠ Terraform not installed, skipping validation${NC}"
        fi
        ;;
    "plan")
        validate_site
        echo -e "${BLUE}Generating Terraform plan...${NC}"
        if command -v terraform >/dev/null 2>&1; then
            run_terraform init
            run_terraform workspace select "$WORKSPACE" || run_terraform workspace new "$WORKSPACE"
            run_terraform plan -var-file=terraform.tfvars -var-file=workspaces/$WORKSPACE.tfvars -out=$(mktemp).$SITE.$ENVIRONMENT.$WORKSPACE.tfplan
        else
            echo -e "${YELLOW}⚠ Terraform not installed, skipping plan${NC}"
        fi
        ;;
    "apply")
        validate_site
        echo -e "${BLUE}Applying Terraform changes...${NC}"
        if command -v terraform >/dev/null 2>&1; then
            run_terraform init
            run_terraform workspace select "$WORKSPACE" || run_terraform workspace new "$WORKSPACE"
            run_terraform apply -var-file=terraform.tfvars -var-file=workspaces/$WORKSPACE.tfvars -auto-approve
        else
            echo -e "${YELLOW}⚠ Terraform not installed, skipping apply${NC}"
        fi
        ;;
    "docs")
        echo -e "${BLUE}Generating Terraform documentation...${NC}"
        if command -v terraform-docs >/dev/null 2>&1; then
            echo -e "${BLUE}Processing OCI modules...${NC}"
            for module in terraform/modules/oci/*/; do
                if [ -d "$module" ]; then
                    terraform-docs -c .terraform-docs.yml "$module" 2>/dev/null || true
                fi
            done
            echo -e "${BLUE}Processing sites...${NC}"
            for site in terraform/sites/*/; do
                if [ -d "$site" ]; then
                    terraform-docs -c .terraform-docs.yml "$site" 2>/dev/null || true
                fi
            done
            echo -e "${GREEN}✓ Documentation generated${NC}"
        else
            echo -e "${YELLOW}⚠ terraform-docs not installed, skipping documentation${NC}"
        fi
        ;;
    "lint")
        echo -e "${BLUE}Running TFLint...${NC}"
        if command -v tflint >/dev/null 2>&1; then
            tflint --init || true
            tflint || (echo -e "${RED}✗ TFLint failed${NC}" && exit 1)
            echo -e "${GREEN}✓ TFLint passed${NC}"
        else
            echo -e "${YELLOW}⚠ TFLint not installed, skipping linting${NC}"
        fi
        ;;
    "security")
        echo -e "${BLUE}Running security scans...${NC}"
        $0 tfsec
        $0 checkov
        echo -e "${GREEN}✓ Security scans completed${NC}"
        ;;
    "tfsec")
        echo -e "${BLUE}Running TFsec...${NC}"
        if command -v tfsec >/dev/null 2>&1; then
            tfsec || (echo -e "${RED}✗ TFsec found security issues${NC}" && exit 1)
            echo -e "${GREEN}✓ TFsec passed${NC}"
        else
            echo -e "${YELLOW}⚠ TFsec not installed, skipping security scan${NC}"
        fi
        ;;
    "checkov")
        echo -e "${BLUE}Running Checkov...${NC}"
        if command -v checkov >/dev/null 2>&1; then
            checkov -d . --compact || (echo -e "${RED}✗ Checkov found security issues${NC}" && exit 1)
            echo -e "${GREEN}✓ Checkov passed${NC}"
        else
            echo -e "${YELLOW}⚠ Checkov not installed, skipping security scan${NC}"
        fi
        ;;
    "test")
        echo -e "${BLUE}Running comprehensive tests...${NC}"
        $0 validate
        $0 lint
        $0 security
        echo -e "${GREEN}✓ All tests passed${NC}"
        ;;
    "ci")
        echo -e "${BLUE}Running full CI/CD simulation...${NC}"
        $0 pre-commit
        $0 test
        echo -e "${GREEN}✓ CI/CD simulation completed successfully${NC}"
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
