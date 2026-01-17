#!/bin/bash

# Terraform Management Script
# Usage: ./scripts/make-terraform.sh <command> [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[1;34m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default values
PROJECT_RESOURCE=${PROJECT_RESOURCE:-demo/vpc}
ENVIRONMENT=${ENVIRONMENT:-development}
WORKSPACE=${WORKSPACE:-default}

# Function to parse PROJECT_RESOURCE into PROJECT and RESOURCE
parse_project_resource() {
    if [[ "$PROJECT_RESOURCE" == *"/"* ]]; then
        PROJECT="${PROJECT_RESOURCE%%/*}"
        RESOURCE="${PROJECT_RESOURCE#*/}"
    else
        # Fallback: if no slash, treat as project only
        PROJECT="$PROJECT_RESOURCE"
        RESOURCE=""
    fi
}

# Initial parse from environment variable
parse_project_resource

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root
cd "$PROJECT_ROOT"

# Function to validate environment
validate_environment() {
    local valid_environments=("development" "testing" "staging" "production" "dev" "test" "stage" "prod")
    local env_lower=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')
    
    # Map short names to full names
    case "$env_lower" in
        dev) ENVIRONMENT="development" ;;
        test) ENVIRONMENT="testing" ;;
        stage) ENVIRONMENT="staging" ;;
        prod) ENVIRONMENT="production" ;;
    esac
    
    # Validate environment
    local is_valid=false
    for valid_env in "${valid_environments[@]}"; do
        if [ "$ENVIRONMENT" = "$valid_env" ] || [ "$env_lower" = "$valid_env" ]; then
            is_valid=true
            break
        fi
    done
    
    if [ "$is_valid" = false ]; then
        echo -e "${RED}✗ Invalid environment: $ENVIRONMENT${NC}"
        echo -e "${BLUE}Valid environments: development, testing, staging, production${NC}"
        echo -e "${BLUE}Short names also supported: dev, test, stage, prod${NC}"
        exit 1
    fi
}

# Function to validate required parameters
validate_required_params() {
    local missing_params=()
    
    if [ -z "$PROJECT_RESOURCE" ]; then
        missing_params+=("project/resource (-p)")
    fi
    
    if [ -n "$PROJECT_RESOURCE" ] && [[ "$PROJECT_RESOURCE" != *"/"* ]]; then
        echo -e "${RED}✗ Invalid project/resource format: $PROJECT_RESOURCE${NC}"
        echo -e "${BLUE}Expected format: <project>/<resource> (e.g., demo/vpc)${NC}"
        exit 1
    fi
    
    if [ -n "$PROJECT_RESOURCE" ] && [ -z "$PROJECT" ]; then
        missing_params+=("project in -p <project>/<resource>")
    fi
    
    if [ -n "$PROJECT_RESOURCE" ] && [ -z "$RESOURCE" ]; then
        missing_params+=("resource in -p <project>/<resource>")
    fi
    
    if [ ${#missing_params[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing required parameters: ${missing_params[*]}${NC}"
        echo -e "${BLUE}Usage: $0 <command> -p <project>/<resource> -e <environment> [options]${NC}"
        echo -e "${BLUE}Example: $0 plan -p demo/vpc -e development${NC}"
        exit 1
    fi
    
    # Validate environment
    validate_environment
}

# Function to show help
show_help() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}= Terraform Management Script        =${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "Usage: $0 <command> -p <project>/<resource> -e <environment> [options]"
    echo ""
    echo "Required Options:"
    echo "  -p, --project PROJECT/RESOURCE   Set project and resource (e.g., demo/vpc)"
    echo "  -e, --environment ENV            Set environment (default: development)"
    echo "                                    Valid: development, testing, staging, production"
    echo "                                    Short: dev, test, stage, prod"
    echo ""
    echo "Optional Options:"
    echo "  -w, --workspace WS               Set workspace (default: $WORKSPACE)"
    echo ""
    echo "Available commands:"
    echo "  init         - Initialize Terraform (supports backend.hcl if present)"
    echo "  plan         - Generate Terraform plan (saves to plan.<env>.<workspace>.tfplan)"
    echo "  apply        - Apply Terraform changes (uses plan file if available)"
    echo "  destroy      - Destroy Terraform resources"
    echo "  output       - Show Terraform outputs"
    echo "  output-json  - Show outputs in JSON format"
    echo "  output-raw   - Show outputs in raw format"
    echo "  workspace    - Manage workspaces"
    echo "  fmt          - Format Terraform configuration files"
    echo "  validate     - Validate configuration (includes format check)"
    echo "  force-unlock - Force unlock Terraform state (requires lock ID)"
    echo "  clean        - Clean up generated files in current directory"
    echo "  status       - Show current status (workspace, plan files, etc.)"
    echo ""
    echo "  <terraform-command> - Any other Terraform command will be passed through"
    echo "                        (e.g., show, state, import, taint, etc.)"
    echo ""
    echo "Environment variables:"
    echo "  PROJECT_RESOURCE - Project/resource (e.g., demo/vpc, default: demo/vpc)"
    echo "  ENVIRONMENT      - Environment (default: development)"
    echo "  WORKSPACE        - Terraform workspace (default: $WORKSPACE)"
    echo "  OCI_REGION       - OCI region (default: ap-seoul-1)"
    echo "  OCI_PROFILE      - OCI profile (default: DEFAULT)"
    echo ""
    echo "Examples:"
    echo "  $0 plan -p demo/vpc -e development"
    echo "  $0 apply -p demo/gitlab -e production"
    echo "  $0 fmt -p demo/vpc -e development"
    echo "  $0 force-unlock -p demo/vpc -e development <lock-id>"
    echo "  $0 show -p demo/vpc -e development"
    echo "  $0 plan -p demo/jump -e testing -w staging"
    echo "  $0 plan -p demo/vpc -e dev        # Short form"
    echo ""
    echo "Environment Variables:"
    echo "  PROJECT_RESOURCE - Project/resource (default: demo/vpc)"
    echo "  ENVIRONMENT      - Environment (default: development)"
    echo "  WORKSPACE        - Terraform workspace (default: $WORKSPACE)"
    echo "  OCI_REGION       - OCI region (default: ap-seoul-1)"
    echo "  OCI_PROFILE      - OCI profile (default: DEFAULT)"
    echo ""
}

# Function to validate project/resource exists
validate_project_resource() {
    TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
    if [ ! -d "$TERRAFORM_DIR" ]; then
        echo -e "${RED}✗ Resource $RESOURCE not found in project $PROJECT${NC}"
        echo -e "${BLUE}Available projects:${NC}"
        ls -d terraform/*/ 2>/dev/null | sed 's|terraform/|  |' | sed 's|/||' || echo "  No projects found"
        if [ -d "terraform/$PROJECT" ]; then
            echo -e "${BLUE}Available resources in project $PROJECT:${NC}"
            ls -d terraform/$PROJECT/*/ 2>/dev/null | sed 's|terraform/$PROJECT/|  |' | sed 's|/||' || echo "  No resources found"
        fi
        exit 1
    fi
    echo -e "${GREEN}✓ Resource $RESOURCE found in project $PROJECT${NC}"
}

# Function to run terraform command
run_terraform() {
    local cmd="$1"
    shift
    
    TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
    
    echo -e "${BLUE}Running: terraform -chdir=$TERRAFORM_DIR $cmd $*${NC}"
    terraform -chdir="$TERRAFORM_DIR" "$cmd" "$@"
}

# Parse command line arguments
COMMAND="${1:-help}"

# If command is help, show help and exit
if [ "$COMMAND" = "help" ] || [ "$COMMAND" = "-h" ] || [ "$COMMAND" = "--help" ]; then
    show_help
    exit 0
fi

# Shift to get the options
shift

# Parse options using getopts
while getopts "e:p:w:h-:" opt; do
    case $opt in
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        p)
            PROJECT_RESOURCE="$OPTARG"
            # Parse project/resource
            parse_project_resource
            if [ -z "$PROJECT" ] || [ -z "$RESOURCE" ]; then
                echo -e "${RED}Error: Invalid format for -p. Expected <project>/<resource>${NC}"
                echo -e "${BLUE}Example: -p demo/vpc${NC}"
                exit 1
            fi
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
                project)
                    PROJECT_RESOURCE="${!OPTIND}"
                    OPTIND=$((OPTIND + 1))
                    # Parse project/resource
                    parse_project_resource
                    if [ -z "$PROJECT" ] || [ -z "$RESOURCE" ]; then
                        echo -e "${RED}Error: Invalid format for --project. Expected <project>/<resource>${NC}"
                        echo -e "${BLUE}Example: --project demo/vpc${NC}"
                        exit 1
                    fi
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

# Re-parse PROJECT_RESOURCE after all options are processed (in case it was updated)
parse_project_resource

# Main command handling
case "$COMMAND" in
    "help"|"-h"|"--help")
        show_help
        ;;
    "init")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Initializing Terraform...${NC}"
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Check for backend.hcl file
        if [ -f "$TERRAFORM_DIR/backend.hcl" ]; then
            echo -e "${BLUE}Using backend configuration from backend.hcl${NC}"
            run_terraform init -backend-config=backend.hcl
        else
            echo -e "${BLUE}Initializing with default backend configuration${NC}"
            run_terraform init
        fi
        
        run_terraform workspace select "$WORKSPACE" || run_terraform workspace new "$WORKSPACE"
        ;;
    "plan")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Generating Terraform plan...${NC}"
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Create temporary plan file in /tmp with fixed name (no random suffix)
        # Use fixed filename based on project/resource/environment/workspace
        # Format: terraform-plan.<project-resource-environment>.<workspace>.tfplan
        PLAN_BASENAME="terraform-plan.${PROJECT}-${RESOURCE}-${ENVIRONMENT}.${WORKSPACE}.tfplan"
        
        # Try to use system temp directory (works on macOS and Linux)
        # Remove trailing slash if present
        TMP_DIR="${TMPDIR:-/tmp}"
        TMP_DIR="${TMP_DIR%/}"
        PLAN_FILE="${TMP_DIR}/${PLAN_BASENAME}"
        
        # If file already exists, append process ID to avoid conflicts
        if [ -f "$PLAN_FILE" ]; then
            PLAN_FILE="${PLAN_FILE%.tfplan}.$$.tfplan"
        fi
        
        # Save plan file path to metadata file for apply command
        PLAN_METADATA_FILE="$TERRAFORM_DIR/.plan.$ENVIRONMENT.$WORKSPACE.path"
        echo "$PLAN_FILE" > "$PLAN_METADATA_FILE"
        
        # Extract just the filename for terraform -out parameter (relative to TERRAFORM_DIR)
        PLAN_FILENAME=$(basename "$PLAN_FILE")
        
        # Run terraform plan with absolute path
        run_terraform plan \
            -var-file=terraform.tfvars \
            -var="environment=$ENVIRONMENT" \
            -out="$PLAN_FILE"
        
        echo -e "${GREEN}✓ Plan file created: $PLAN_FILE${NC}"
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${GREEN}To apply this plan, run:${NC}"
        echo -e "${BOLD}${CYAN}  make terraform -- apply -p $PROJECT_RESOURCE -e $ENVIRONMENT${NC}"
        echo -e "${BOLD}${CYAN}  or${NC}"
        echo -e "${BOLD}${CYAN}  terraform -chdir=$TERRAFORM_DIR apply \"$PLAN_FILE\"${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        ;;
    "apply")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Applying Terraform plan...${NC}"
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Try to read plan file path from metadata file
        PLAN_METADATA_FILE="$TERRAFORM_DIR/.plan.$ENVIRONMENT.$WORKSPACE.path"
        if [ -f "$PLAN_METADATA_FILE" ]; then
            PLAN_FILE=$(cat "$PLAN_METADATA_FILE")
            if [ -f "$PLAN_FILE" ]; then
                echo -e "${BLUE}Using plan file: $PLAN_FILE${NC}"
                if run_terraform apply "$PLAN_FILE"; then
                    # Clean up metadata file and plan file after successful apply
                    rm -f "$PLAN_METADATA_FILE"
                    rm -f "$PLAN_FILE"
                    echo -e "${GREEN}✓ Plan file cleaned up${NC}"
                else
                    echo -e "${YELLOW}⚠ Apply failed, plan file kept: $PLAN_FILE${NC}"
                    exit 1
                fi
            else
                echo -e "${YELLOW}⚠ Plan file not found: $PLAN_FILE${NC}"
                rm -f "$PLAN_METADATA_FILE"
                echo -e "${YELLOW}⚠ Applying without plan file...${NC}"
                echo -e "${YELLOW}⚠ This will prompt for confirmation unless -auto-approve is used${NC}"
                run_terraform apply \
                    -var-file=terraform.tfvars \
                    -var="environment=$ENVIRONMENT" \
                    -auto-approve
            fi
        else
            # Fallback to old location for backward compatibility
            OLD_PLAN_FILE="$TERRAFORM_DIR/plan.$ENVIRONMENT.$WORKSPACE.tfplan"
            if [ -f "$OLD_PLAN_FILE" ]; then
                echo -e "${BLUE}Using plan file: $OLD_PLAN_FILE${NC}"
                run_terraform apply "plan.$ENVIRONMENT.$WORKSPACE.tfplan"
            else
                echo -e "${YELLOW}⚠ No plan file found, applying without plan...${NC}"
                echo -e "${YELLOW}⚠ This will prompt for confirmation unless -auto-approve is used${NC}"
                run_terraform apply \
                    -var-file=terraform.tfvars \
                    -var="environment=$ENVIRONMENT" \
                    -auto-approve
            fi
        fi
        ;;
    "destroy")
        validate_required_params
        validate_project_resource
        echo -e "${RED}Destroying Terraform resources...${NC}"
        echo -e "${RED}Project/Resource: $PROJECT_RESOURCE${NC}"
        echo -e "${RED}Environment: $ENVIRONMENT | Workspace: $WORKSPACE${NC}"
        read -p "Are you sure you want to destroy? Type 'yes' to confirm: " confirm
        if [ "$confirm" != "yes" ]; then
            echo -e "${YELLOW}Destroy cancelled${NC}"
            exit 0
        fi
        run_terraform destroy \
            -var-file=terraform.tfvars \
            -var="environment=$ENVIRONMENT" \
            -auto-approve
        ;;
    "output")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Showing Terraform outputs...${NC}"
        run_terraform output
        ;;
    "output-json")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Showing Terraform outputs in JSON format...${NC}"
        run_terraform output -json
        ;;
    "output-raw")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Showing Terraform outputs in raw format...${NC}"
        run_terraform output -raw
        ;;
    "workspace")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Terraform workspace management:${NC}"
        echo "  $0 workspace list   - List workspaces"
        echo "  $0 workspace new    - Create new workspace"
        echo "  $0 workspace select - Select workspace"
        echo "  $0 workspace delete - Delete workspace"
        ;;
    "workspace-list")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Available Terraform workspaces:${NC}"
        run_terraform workspace list
        ;;
    "workspace-new")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Creating new workspace: $WORKSPACE${NC}"
        run_terraform workspace new "$WORKSPACE"
        ;;
    "workspace-select")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Selecting workspace: $WORKSPACE${NC}"
        run_terraform workspace select "$WORKSPACE"
        ;;
    "workspace-delete")
        validate_required_params
        validate_project_resource
        echo -e "${RED}WARNING: This will delete workspace $WORKSPACE!${NC}"
        read -p "Are you sure? (yes/no): " confirm && [ "$confirm" = "yes" ] || exit 1
        run_terraform workspace delete "$WORKSPACE"
        ;;
    "fmt")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Formatting Terraform configuration files...${NC}"
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Format Terraform files
        if terraform -chdir="$TERRAFORM_DIR" fmt -recursive; then
            echo -e "${GREEN}✓ Terraform files formatted successfully${NC}"
        else
            echo -e "${RED}✗ Failed to format Terraform files${NC}"
            exit 1
        fi
        ;;
    "validate")
        validate_required_params
        validate_project_resource
        echo -e "${BLUE}Validating Terraform configuration...${NC}"
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Format check
        echo -e "${BLUE}Checking Terraform format...${NC}"
        if terraform -chdir="$TERRAFORM_DIR" fmt -check -recursive > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Format check passed${NC}"
        else
            echo -e "${YELLOW}⚠ Format check failed. Run 'terraform fmt' to fix${NC}"
        fi
        
        # Initialize and validate
        run_terraform init -backend=false
        run_terraform workspace select "$WORKSPACE" || run_terraform workspace new "$WORKSPACE"
        run_terraform validate
        echo -e "${GREEN}✓ Validation passed${NC}"
        ;;
    "force-unlock")
        validate_required_params
        validate_project_resource
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Get remaining arguments after options for the lock ID
        # OPTIND points to the first non-option argument
        shift $((OPTIND - 1))
        
        # Filter out the command name if it appears in arguments (user may have repeated it)
        # Also filter out our script options that might have been passed incorrectly
        LOCK_ID=""
        for arg in "$@"; do
            # Skip if it's the command name or our script options
            case "$arg" in
                force-unlock|-p|--project|-e|--environment|-w|--workspace|-h|--help)
                    continue
                    ;;
                *)
                    # This should be the lock ID (UUID format, typically the longest argument)
                    if [ -z "$LOCK_ID" ] || [ ${#arg} -gt ${#LOCK_ID} ]; then
                        LOCK_ID="$arg"
                    fi
                    ;;
            esac
        done
        
        # If still no lock ID, try the last argument (most likely to be the lock ID)
        if [ -z "$LOCK_ID" ] && [ $# -gt 0 ]; then
            # Get the last argument
            for arg in "$@"; do
                LOCK_ID="$arg"
            done
        fi
        
        if [ -z "$LOCK_ID" ]; then
            echo -e "${RED}Error: Lock ID is required for force-unlock${NC}"
            echo -e "${BLUE}Usage: $0 force-unlock -p <project>/<resource> -e <environment> <lock-id>${NC}"
            echo -e "${BLUE}Example: $0 force-unlock -p demo/vpc -e development a2e47270-0342-0995-4d98-64cb3c1084f1${NC}"
            echo ""
            echo -e "${YELLOW}To find the lock ID, check the error message from terraform commands${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}⚠ WARNING: Force unlocking Terraform state lock${NC}"
        echo -e "${YELLOW}Lock ID: $LOCK_ID${NC}"
        echo -e "${YELLOW}Project/Resource: $PROJECT_RESOURCE${NC}"
        echo -e "${YELLOW}Environment: $ENVIRONMENT | Workspace: $WORKSPACE${NC}"
        read -p "Are you sure you want to force unlock? Type 'yes' to confirm: " confirm
        if [ "$confirm" != "yes" ]; then
            echo -e "${YELLOW}Force unlock cancelled${NC}"
            exit 0
        fi
        
        run_terraform force-unlock -force "$LOCK_ID"
        ;;
    "clean")
        validate_required_params
        validate_project_resource
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        echo -e "${BLUE}Cleaning up Terraform files in $TERRAFORM_DIR...${NC}"
        
        # Clean specific directory
        if [ -d "$TERRAFORM_DIR/.terraform" ]; then
            rm -rf "$TERRAFORM_DIR/.terraform"
            echo -e "${GREEN}✓ Removed .terraform directory${NC}"
        fi
        
        if [ -f "$TERRAFORM_DIR/.terraform.lock.hcl" ]; then
            rm -f "$TERRAFORM_DIR/.terraform.lock.hcl"
            echo -e "${GREEN}✓ Removed .terraform.lock.hcl${NC}"
        fi
        
        # Remove plan files
        PLAN_COUNT=$(find "$TERRAFORM_DIR" -name "plan.*.tfplan" -type f 2>/dev/null | wc -l)
        if [ "$PLAN_COUNT" -gt 0 ]; then
            find "$TERRAFORM_DIR" -name "plan.*.tfplan" -type f -delete
            echo -e "${GREEN}✓ Removed $PLAN_COUNT plan file(s)${NC}"
        fi
        
        # Remove state files (local only, not remote)
        STATE_COUNT=$(find "$TERRAFORM_DIR" -name "terraform.tfstate" -o -name "terraform.tfstate.backup" 2>/dev/null | wc -l)
        if [ "$STATE_COUNT" -gt 0 ]; then
            find "$TERRAFORM_DIR" -name "terraform.tfstate" -o -name "terraform.tfstate.backup" | xargs rm -f
            echo -e "${GREEN}✓ Removed $STATE_COUNT state file(s)${NC}"
        fi
        
        echo -e "${GREEN}✓ Cleanup completed${NC}"
        ;;
    "status")
        echo -e "${BLUE}Current Status:${NC}"
        echo "  Project/Resource: $PROJECT_RESOURCE"
        echo "  Project: $PROJECT"
        echo "  Resource: $RESOURCE"
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        echo "  Environment: $ENVIRONMENT"
        echo "  Workspace: $WORKSPACE"
        echo "  Directory: $TERRAFORM_DIR"
        echo ""
        
        # Show workspace status if directory exists
        if [ -d "$TERRAFORM_DIR" ]; then
            echo -e "${BLUE}Workspace Status:${NC}"
            if [ -d "$TERRAFORM_DIR/.terraform" ]; then
                CURRENT_WS=$(terraform -chdir="$TERRAFORM_DIR" workspace show 2>/dev/null || echo "unknown")
                echo "  Current workspace: $CURRENT_WS"
                echo ""
                echo -e "${BLUE}Available workspaces:${NC}"
                terraform -chdir="$TERRAFORM_DIR" workspace list 2>/dev/null || echo "  Not initialized"
            else
                echo "  Not initialized (run 'init' first)"
            fi
            echo ""
            
            # Show plan files
            PLAN_FILES=$(find "$TERRAFORM_DIR" -name "plan.*.tfplan" -type f 2>/dev/null)
            if [ -n "$PLAN_FILES" ]; then
                echo -e "${BLUE}Available plan files:${NC}"
                echo "$PLAN_FILES" | sed 's|.*/|  |' | while read -r plan; do
                    echo "  $plan"
                done
            else
                echo -e "${BLUE}Plan files:${NC} None"
            fi
        fi
        echo ""
        
        echo -e "${BLUE}Available projects:${NC}"
        ls -d terraform/*/ 2>/dev/null | sed 's|terraform/|  |' | sed 's|/||' || echo "  No projects found"
        if [ -d "terraform/$PROJECT" ]; then
            echo -e "${BLUE}Available resources in project $PROJECT:${NC}"
            ls -d terraform/$PROJECT/*/ 2>/dev/null | sed 's|terraform/$PROJECT/|  |' | sed 's|/||' || echo "  No resources found"
        fi
        ;;
    *)
        # Generic fallback: pass through to terraform command
        # This allows support for all terraform subcommands (show, state, import, taint, etc.)
        validate_required_params
        validate_project_resource
        
        TERRAFORM_DIR="terraform/$PROJECT/$RESOURCE"
        
        # Get remaining arguments after options for the terraform command
        # After getopts, OPTIND points to the first unprocessed argument
        # But getopts doesn't remove processed options from $@, so we need to filter them
        # Build array of remaining args, skipping our script options
        TERRAFORM_ARGS=()
        # Start from OPTIND-1 (getopts uses 1-based indexing, arrays are 0-based)
        i=$((OPTIND - 1))
        while [ $i -lt $# ]; do
            eval "arg=\${$((i + 1))}"
            # Skip our script options and their values
            case "$arg" in
                -p|--project|-e|--environment|-w|--workspace|-h|--help)
                    # Skip this option, and if it takes a value, skip the value too
                    i=$((i + 1))
                    if [ $i -lt $# ]; then
                        i=$((i + 1))
                    fi
                    continue
                    ;;
            esac
            # This is a terraform argument
            TERRAFORM_ARGS+=("$arg")
            i=$((i + 1))
        done
        
        echo -e "${BLUE}Running Terraform command: $COMMAND${NC}"
        if [ ${#TERRAFORM_ARGS[@]} -gt 0 ]; then
            echo -e "${BLUE}Passing arguments to terraform: ${TERRAFORM_ARGS[*]}${NC}"
        fi
        
        # Run the terraform command with terraform-specific arguments only
        run_terraform "$COMMAND" "${TERRAFORM_ARGS[@]}"
        ;;
esac
