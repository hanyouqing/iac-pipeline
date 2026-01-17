#!/bin/bash

# Packer Management Script
# Usage: ./scripts/make-packer.sh <command> [options]

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
    echo -e "${BLUE}= Packer Management Script            =${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  validate    - Validate Packer template"
    echo "  build       - Build Packer image"
    echo "  list        - List available templates"
    echo "  clean       - Clean up build artifacts"
    echo ""
    echo "Environment variables:"
    echo "  SITE        - Site to build (default: $SITE)"
    echo "  ENVIRONMENT - Environment to build (default: $ENVIRONMENT)"
    echo ""
    echo "Examples:"
    echo "  $0 validate"
    echo "  $0 build"
    echo "  SITE=my-site ENVIRONMENT=prod $0 build"
    echo ""
}

# Function to validate site exists
validate_site() {
    if [ ! -d "packer/$SITE" ]; then
        echo -e "${RED}✗ Packer templates for site $SITE not found${NC}"
        echo -e "${BLUE}Available sites:${NC}"
        ls -d packer/*/ 2>/dev/null | sed 's|packer/|  |' | sed 's|/||' || echo "  No sites found"
        exit 1
    fi
    
    if [ ! -f "packer/$SITE/$ENVIRONMENT.pkr.hcl" ]; then
        echo -e "${RED}✗ Packer template $ENVIRONMENT.pkr.hcl not found${NC}"
        echo -e "${BLUE}Available templates:${NC}"
        ls -1 packer/$SITE/*.pkr.hcl 2>/dev/null | sed 's|.*/||' | sed 's|\.pkr\.hcl||' | sed 's|^|  |' || echo "  No templates found"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Site $SITE and template $ENVIRONMENT.pkr.hcl found${NC}"
}

# Function to check if packer is installed
check_packer() {
    if ! command -v packer >/dev/null 2>&1; then
        echo -e "${RED}✗ Packer not installed${NC}"
        echo -e "${BLUE}Install with: bbrew tap hashicorp/tap && brew install hashicorp/tap/packer${NC}"
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
    "validate")
        validate_site
        check_packer
        echo -e "${BLUE}Validating Packer template...${NC}"
        cd "packer/$SITE"
        packer validate "$ENVIRONMENT.pkr.hcl"
        echo -e "${GREEN}✓ Packer template validation passed${NC}"
        cd "$PROJECT_ROOT"
        ;;
    "build")
        validate_site
        check_packer
        echo -e "${BLUE}Building Packer image...${NC}"
        cd "packer/$SITE"
        packer build \
            -var "environment=$ENVIRONMENT" \
            -var "site=$SITE" \
            "$ENVIRONMENT.pkr.hcl"
        echo -e "${GREEN}✓ Packer build completed${NC}"
        cd "$PROJECT_ROOT"
        ;;
    "list")
        echo -e "${BLUE}Available Packer sites and templates:${NC}"
        for site in packer/*/; do
            if [ -d "$site" ]; then
                site_name=$(basename "$site")
                echo -e "${GREEN}$site_name:${NC}"
                ls -1 "$site"*.pkr.hcl 2>/dev/null | sed 's|.*/||' | sed 's|\.pkr\.hcl||' | sed 's|^|  |' || echo "  No templates found"
            fi
        done
        ;;
    "clean")
        echo -e "${BLUE}Cleaning up Packer build artifacts...${NC}"
        find . -name "packer_cache" -type d -exec rm -rf {} + 2>/dev/null || true
        find . -name "*.log" -delete 2>/dev/null || true
        echo -e "${GREEN}✓ Packer cleanup completed${NC}"
        ;;
    *)
        echo -e "${RED}Error: Unknown command '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
