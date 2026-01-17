#!/bin/bash

# Ansible Management Script
# Usage: ./scripts/make-ansible.sh <command> [options]

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

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Function to show help
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}= Ansible Management Script           =${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  check        - Check Ansible syntax"
    echo "  play         - Run Ansible playbook"
    echo "  ping         - Test Ansible connectivity"
    echo "  list-hosts   - List inventory hosts"
    echo "  dry-run      - Run playbook in check mode"
    echo "  verbose      - Run playbook with verbose output"
    echo ""
    echo "Environment variables:"
    echo "  SITE        - Site to deploy (default: $SITE)"
    echo "  ENVIRONMENT - Environment to deploy (default: $ENVIRONMENT)"
    echo ""
    echo "Examples:"
    echo "  $0 check"
    echo "  $0 play"
    echo "  SITE=my-site ENVIRONMENT=prod $0 play"
    echo ""
}

# Function to validate site exists
validate_site() {
    if [ ! -d "ansible/playbooks/$SITE" ]; then
        echo -e "${RED}✗ Ansible playbook for site $SITE not found${NC}"
        echo -e "${BLUE}Available sites:${NC}"
        ls -d ansible/playbooks/*/ 2>/dev/null | sed 's|ansible/playbooks/|  |' | sed 's|/||' || echo "  No sites found"
        exit 1
    fi
    
    if [ ! -f "ansible/inventories/$SITE-$ENVIRONMENT" ]; then
        echo -e "${RED}✗ Ansible inventory for $SITE-$ENVIRONMENT not found${NC}"
        echo -e "${BLUE}Available inventories:${NC}"
        ls -1 ansible/inventories/$SITE-* 2>/dev/null | sed 's|ansible/inventories/||' | sed 's|^|  |' || echo "  No inventories found"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Site $SITE and inventory $SITE-$ENVIRONMENT found${NC}"
}

# Function to check if ansible is installed
check_ansible() {
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        echo -e "${RED}✗ Ansible not installed${NC}"
        echo -e "${BLUE}Install with: pip install ansible${NC}"
        exit 1
    fi
}

# Parse command line arguments using getopts
while getopts "e:s:h-:" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        s)
            SITE="$OPTARG"
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
    "check")
        validate_site
        check_ansible
        echo -e "${BLUE}Checking Ansible syntax...${NC}"
        ansible-playbook "ansible/playbooks/$SITE/site.yml" \
            --inventory "ansible/inventories/$SITE-$ENVIRONMENT" \
            --syntax-check
        echo -e "${GREEN}✓ Ansible syntax check passed${NC}"
        ;;
    "play")
        validate_site
        check_ansible
        echo -e "${BLUE}Running Ansible playbook...${NC}"
        ansible-playbook "ansible/playbooks/$SITE/site.yml" \
            --inventory "ansible/inventories/$SITE-$ENVIRONMENT" \
            --extra-vars "environment=$ENVIRONMENT" \
            --extra-vars "site=$SITE"
        echo -e "${GREEN}✓ Ansible playbook completed${NC}"
        ;;
    "ping")
        validate_site
        check_ansible
        echo -e "${BLUE}Testing Ansible connectivity...${NC}"
        ansible all -i "ansible/inventories/$SITE-$ENVIRONMENT" -m ping
        ;;
    "list-hosts")
        validate_site
        check_ansible
        echo -e "${BLUE}Listing Ansible inventory hosts...${NC}"
        if command -v ansible-inventory >/dev/null 2>&1; then
            ansible-inventory -i "ansible/inventories/$SITE-$ENVIRONMENT" --list
        else
            ansible all -i "ansible/inventories/$SITE-$ENVIRONMENT" --list-hosts
        fi
        ;;
    "dry-run")
        validate_site
        check_ansible
        echo -e "${BLUE}Running Ansible playbook in check mode...${NC}"
        ansible-playbook "ansible/playbooks/$SITE/site.yml" \
            --inventory "ansible/inventories/$SITE-$ENVIRONMENT" \
            --extra-vars "environment=$ENVIRONMENT" \
            --extra-vars "site=$SITE" \
            --check
        echo -e "${GREEN}✓ Ansible dry run completed${NC}"
        ;;
    "verbose")
        validate_site
        check_ansible
        echo -e "${BLUE}Running Ansible playbook with verbose output...${NC}"
        ansible-playbook "ansible/playbooks/$SITE/site.yml" \
            --inventory "ansible/inventories/$SITE-$ENVIRONMENT" \
            --extra-vars "environment=$ENVIRONMENT" \
            --extra-vars "site=$SITE" \
            -vvv
        echo -e "${GREEN}✓ Ansible playbook completed${NC}"
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
