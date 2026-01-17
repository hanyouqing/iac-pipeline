#!/bin/bash

# Setup Management Script
# Usage: ./scripts/make-setup.sh <command> [options]

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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Function to show help
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}= Setup Management Script             =${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  install-tools   - Install required tools"
    echo "  check-tools     - Check if tools are installed"
    echo "  dev-setup       - Setup development environment"
    echo "  list-sites      - List available sites"
    echo "  list-envs       - List available environments"
    echo "  validate-site   - Validate current site"
    echo "  clean           - Clean up generated files"
    echo "  status          - Show current status"
    echo ""
    echo "Environment variables:"
    echo "  SITE        - Site to validate (default: $SITE)"
    echo ""
    echo "Examples:"
    echo "  $0 install-tools"
    echo "  $0 check-tools"
    echo "  SITE=my-site $0 validate-site"
    echo ""
}

# Function to install tools
install_tools() {
    echo -e "${BLUE}Installing required tools...${NC}"
    if command -v brew >/dev/null 2>&1; then
        echo -e "${BLUE}Detected macOS with Homebrew${NC}"
        brew install terraform tflint tfsec
        pip3 install checkov
        brew install terraform-docs
        echo -e "${GREEN}✓ Tools installed via Homebrew${NC}"
    elif command -v apt-get >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Ubuntu/Debian with apt${NC}"
        sudo apt-get update
        sudo apt-get install -y curl wget unzip software-properties-common
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt-get update && sudo apt-get install -y terraform
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
        curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash
        pip3 install checkov
        go install github.com/terraform-docs/terraform-docs@latest
        echo -e "${GREEN}✓ Tools installed via apt${NC}"
    else
        echo -e "${YELLOW}⚠ Neither Homebrew (macOS) nor apt (Ubuntu/Debian) found${NC}"
        echo -e "${BLUE}Please install tools manually${NC}"
    fi
}

# Function to check tools
check_tools() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    tools=("terraform" "tflint" "tfsec" "checkov" "terraform-docs")
    missing=()
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done
    if [ ${#missing[@]} -eq 0 ]; then
        echo -e "${GREEN}✓ All tools are installed${NC}"
        echo -e "${BLUE}Terraform version:$(terraform version | head -n1)${NC}"
    else
        echo -e "${YELLOW}⚠ Missing tools: ${missing[*]}${NC}"
        echo -e "${BLUE}Run '$0 install-tools' to install missing tools${NC}"
        exit 1
    fi
}

# Function to setup development environment
dev_setup() {
    echo -e "${BLUE}Setting up development environment...${NC}"
    install_tools
    check_tools
    echo -e "${BLUE}Formatting Terraform code...${NC}"
    terraform fmt -recursive . || true
    echo -e "${BLUE}Generating documentation...${NC}"
    if command -v terraform-docs >/dev/null 2>&1; then
        for module in terraform/modules/oci/*/; do
            if [ -d "$module" ]; then
                terraform-docs -c .terraform-docs.yml "$module" 2>/dev/null || true
            fi
        done
    fi
    echo -e "${GREEN}✓ Development environment ready${NC}"
}

# Function to list sites
list_sites() {
    echo -e "${BLUE}Available sites:${NC}"
    echo "Terraform sites:"
    ls -d terraform/sites/*/ 2>/dev/null | sed 's|terraform/sites/|  |' | sed 's|/||' || echo "  No terraform sites found"
    echo "Ansible playbooks:"
    ls -d ansible/playbooks/*/ 2>/dev/null | sed 's|ansible/playbooks/|  |' | sed 's|/||' || echo "  No ansible playbooks found"
    echo "Packer templates:"
    ls -d packer/*/ 2>/dev/null | sed 's|packer/|  |' | sed 's|/||' || echo "  No packer templates found"
}

# Function to list environments
list_envs() {
    echo -e "${BLUE}Available environments for site '$SITE':${NC}"
    echo "Terraform environments:"
    ls -1 terraform/sites/$SITE/workspaces/*.tfvars 2>/dev/null | sed 's/.*\///' | sed 's/\.tfvars$//' | sed 's/^/  /' || echo "  No terraform environments found"
    echo "Ansible inventories:"
    ls -1 ansible/inventories/$SITE-* 2>/dev/null | sed 's/.*-//' | sed 's/^/  /' || echo "  No ansible inventories found"
    echo "Packer templates:"
    ls -1 packer/$SITE/*.pkr.hcl 2>/dev/null | sed 's/.*\///' | sed 's/\.pkr\.hcl$//' | sed 's/^/  /' || echo "  No packer templates found"
}

# Function to validate site
validate_site() {
    echo -e "${BLUE}Validating site: $SITE${NC}"
    if [ ! -d "terraform/sites/$SITE" ]; then
        echo -e "${RED}✗ Site $SITE not found${NC}"
        echo -e "${BLUE}Available sites:${NC}"
        list_sites
        exit 1
    else
        echo -e "${GREEN}✓ Site $SITE found${NC}"
    fi
}

# Function to clean up
clean() {
    echo -e "${BLUE}Cleaning up...${NC}"
    find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.tfstate" -delete 2>/dev/null || true
    find . -name "*.tfstate.backup" -delete 2>/dev/null || true
    find . -name "tfplan" -delete 2>/dev/null || true
    find . -name "*.tfplan" -delete 2>/dev/null || true
    find . -name "tmp.*.tfplan" -delete 2>/dev/null || true
    find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
    find . -name "packer_cache" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name "*.log" -delete 2>/dev/null || true
    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Function to show status
status() {
    echo -e "${BLUE}Current Status:${NC}"
    echo "  Site: $SITE"
    echo ""
    echo -e "${BLUE}Available modules:${NC}"
    ls -d terraform/modules/*/ 2>/dev/null | sed 's|terraform/modules/|  |' | sed 's|/||' || echo "  No modules found"
    echo ""
    echo -e "${BLUE}Available sites:${NC}"
    ls -d terraform/sites/*/ 2>/dev/null | sed 's|terraform/sites/|  |' | sed 's|/||' || echo "  No sites found"
    echo -e "${BLUE}Current site: $SITE${NC}"
}

# Parse command line arguments using getopts
while getopts "s:h-:" opt; do
    case $opt in
        s)
            SITE="$OPTARG"
            ;;
        h)
            show_help
            exit 0
            ;;
        -)
            case "${OPTARG}" in
                site)
                    SITE="${!OPTIND}"
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
    "install-tools")
        install_tools
        ;;
    "check-tools")
        check_tools
        ;;
    "dev-setup")
        dev_setup
        ;;
    "list-sites")
        list_sites
        ;;
    "list-envs")
        list_envs
        ;;
    "validate-site")
        validate_site
        ;;
    "clean")
        clean
        ;;
    "status")
        status
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
