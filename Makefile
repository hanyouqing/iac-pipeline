
# Terraform CI/CD Makefile
# Mimics GitHub Actions workflows for local development

# Configuration
TERRAFORM_VERSION := 1.12.2
# PROJECT_NAME is now derived from site - see site variable below

# OCI Configuration
OCI_REGION := ap-seoul-1
OCI_PROFILE := DEFAULT

# 阿里云配置
ALICLOUD_REGION := cn-hangzhou

# Parameter configuration (lowercase only for simplicity)
site ?= oci-labs
environment ?= dev
workspace ?= default

# NEW: Tool parameter for unified interface
tool ?= terraform

# OCI command with conditional profile
ifeq ($(OCI_PROFILE),)
OCI_CMD := oci
else
OCI_CMD := OCI_PROFILE=$(OCI_PROFILE) oci
endif

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[1;34m
PURPLE := \033[0;35m
ORANGE := \033[0;33m
CYAN := \033[0;36m
NC := \033[0m # No Color

# Parameter validation function (empty since we only support lowercase)
define validate-parameters
endef

# =============================================================================
# MAIN COMMAND DISPATCHER
# =============================================================================

# Default target when no arguments provided
.DEFAULT_GOAL := help

# Main command dispatchers - delegate to scripts
.PHONY: github terraform ansible setup packer
github: ## GitHub Actions simulation commands
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" = "" ]; then \
		./scripts/make-github.sh help; \
	else \
		./scripts/make-github.sh $(filter-out $@,$(MAKECMDGOALS)); \
	fi

terraform: ## Terraform commands
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" = "" ]; then \
		./scripts/make-terraform.sh help; \
	else \
		./scripts/make-terraform.sh $(filter-out $@,$(MAKECMDGOALS)); \
	fi


ansible: ## Ansible commands
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" = "" ]; then \
		./scripts/make-ansible.sh help; \
	else \
		./scripts/make-ansible.sh $(filter-out $@,$(MAKECMDGOALS)); \
	fi

setup: ## Setup and environment commands
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" = "" ]; then \
		./scripts/make-setup.sh help; \
	else \
		./scripts/make-setup.sh $(filter-out $@,$(MAKECMDGOALS)); \
	fi

packer: ## Packer commands
	@if [ "$(filter-out $@,$(MAKECMDGOALS))" = "" ]; then \
		./scripts/make-packer.sh help; \
	else \
		./scripts/make-packer.sh $(filter-out $@,$(MAKECMDGOALS)); \
	fi

# Subcommand dispatchers - delegate to scripts
.PHONY: github-% terraform-% ansible-% setup-% packer-%
github-%: ## GitHub Actions subcommands
	@./scripts/make-github.sh $(patsubst github-%,%,$@)

terraform-%: ## Terraform subcommands
	@./scripts/make-terraform.sh $(patsubst terraform-%,%,$@) $(filter-out terraform-%,$(MAKECMDGOALS))

ansible-%: ## Ansible subcommands
	@./scripts/make-ansible.sh $(patsubst ansible-%,%,$@)

setup-%: ## Setup subcommands
	@./scripts/make-setup.sh $(patsubst setup-%,%,$@)

packer-%: ## Packer subcommands
	@./scripts/make-packer.sh $(patsubst packer-%,%,$@)

# =============================================================================
# TOOL VALIDATION (新增)
# =============================================================================

.PHONY: validate-tool
validate-tool: ## Validate tool parameter
	@if [ "$(tool)" != "terraform" ] && [ "$(tool)" != "ansible" ] && [ "$(tool)" != "packer" ]; then \
		echo "$(RED)Error: Invalid tool '$(tool)'. Must be one of: terraform, ansible, packer$(NC)"; \
		exit 1; \
	fi

.PHONY: validate-environment
validate-environment: ## Validate environment parameter
	@if [ "$(tool)" = "terraform" ] && [ ! -f "terraform/sites/$(site)/workspaces/$(environment).tfvars" ]; then \
		echo "$(RED)Error: Terraform vars file not found: terraform/sites/$(site)/workspaces/$(environment).tfvars$(NC)"; \
		exit 1; \
	fi
	@if [ "$(tool)" = "ansible" ] && [ ! -f "ansible/inventories/$(site)-$(environment)" ]; then \
		echo "$(RED)Error: Ansible inventory not found: ansible/inventories/$(site)-$(environment)$(NC)"; \
		exit 1; \
	fi
	@if [ "$(tool)" = "packer" ] && [ ! -f "packer/$(site)/$(environment).pkr.hcl" ]; then \
		echo "$(RED)Error: Packer template not found: packer/$(site)/$(environment).pkr.hcl$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# ANSIBLE COMMANDS
# =============================================================================

.PHONY: ansible-help
ansible-help: ## Show Ansible commands
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)= Ansible Commands                     =$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Usage: make ansible-<command>"
	@echo ""
	@echo "Available commands:"
	@echo "  make ansible-check        - Check Ansible syntax"
	@echo "  make ansible-play         - Run Ansible playbook"
	@echo "  make ansible-ping         - Test Ansible connectivity"
	@echo "  make ansible-list-hosts   - List inventory hosts"
	@echo "  make ansible-dry-run      - Run playbook in check mode"
	@echo "  make ansible-verbose      - Run playbook with verbose output"
	@echo ""

.PHONY: ansible-check
ansible-check: ## Check Ansible syntax
	@echo "$(BLUE)Checking Ansible syntax...$(NC)"
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		ansible-playbook ansible/playbooks/$(site)/site.yml \
			--inventory ansible/inventories/$(site)-$(environment) \
			--syntax-check; \
		echo "$(GREEN)✓ Ansible syntax check passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Ansible not installed, skipping syntax check$(NC)"; \
	fi

.PHONY: ansible-play
ansible-play: ## Run Ansible playbook
	@echo "$(BLUE)Running Ansible playbook...$(NC)"
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		ansible-playbook ansible/playbooks/$(site)/site.yml \
			--inventory ansible/inventories/$(site)-$(environment) \
			--extra-vars "environment=$(environment)" \
			--extra-vars "site=$(site)"; \
		echo "$(GREEN)✓ Ansible playbook completed$(NC)"; \
	else \
		echo "$(RED)✗ Ansible not installed$(NC)"; \
		exit 1; \
	fi

.PHONY: ansible-ping
ansible-ping: ## Test Ansible connectivity
	@echo "$(BLUE)Testing Ansible connectivity...$(NC)"
	@if command -v ansible >/dev/null 2>&1; then \
		ansible all -i ansible/inventories/$(site)-$(environment) -m ping; \
	else \
		echo "$(RED)✗ Ansible not installed$(NC)"; \
		exit 1; \
	fi

.PHONY: ansible-list-hosts
ansible-list-hosts: ## List inventory hosts
	@echo "$(BLUE)Listing Ansible inventory hosts...$(NC)"
	@if command -v ansible-inventory >/dev/null 2>&1; then \
		ansible-inventory -i ansible/inventories/$(site)-$(environment) --list; \
	elif command -v ansible >/dev/null 2>&1; then \
		ansible all -i ansible/inventories/$(site)-$(environment) --list-hosts; \
	else \
		echo "$(RED)✗ Ansible not installed$(NC)"; \
		exit 1; \
	fi

.PHONY: ansible-dry-run
ansible-dry-run: ## Run playbook in check mode
	@echo "$(BLUE)Running Ansible playbook in check mode...$(NC)"
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		ansible-playbook ansible/playbooks/$(site)/site.yml \
			--inventory ansible/inventories/$(site)-$(environment) \
			--extra-vars "environment=$(environment)" \
			--extra-vars "site=$(site)" \
			--check; \
		echo "$(GREEN)✓ Ansible dry run completed$(NC)"; \
	else \
		echo "$(RED)✗ Ansible not installed$(NC)"; \
		exit 1; \
	fi

.PHONY: ansible-verbose
ansible-verbose: ## Run playbook with verbose output
	@echo "$(BLUE)Running Ansible playbook with verbose output...$(NC)"
	@if command -v ansible-playbook >/dev/null 2>&1; then \
		ansible-playbook ansible/playbooks/$(site)/site.yml \
			--inventory ansible/inventories/$(site)-$(environment) \
			--extra-vars "environment=$(environment)" \
			--extra-vars "site=$(site)" \
			-vvv; \
		echo "$(GREEN)✓ Ansible playbook completed$(NC)"; \
	else \
		echo "$(RED)✗ Ansible not installed$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# PACKER TARGETS (新增)
# =============================================================================

.PHONY: packer-validate
packer-validate: ## Validate Packer template
	@echo "$(BLUE)Validating Packer template...$(NC)"
	@if command -v packer >/dev/null 2>&1; then \
		cd packer/$(site) && packer validate $(environment).pkr.hcl; \
		echo "$(GREEN)✓ Packer template validation passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Packer not installed, skipping validation$(NC)"; \
	fi

.PHONY: packer-build
packer-build: ## Build Packer image
	@echo "$(BLUE)Building Packer image...$(NC)"
	@if command -v packer >/dev/null 2>&1; then \
		cd packer/$(site) && packer build \
			-var "environment=$(environment)" \
			-var "site=$(site)" \
			$(environment).pkr.hcl; \
		echo "$(GREEN)✓ Packer build completed$(NC)"; \
	else \
		echo "$(RED)✗ Packer not installed$(NC)"; \
		exit 1; \
	fi

# =============================================================================
# TERRAFORM TARGETS (新增统一接口)
# =============================================================================

.PHONY: terraform-init
terraform-init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@cd terraform/sites/$(site) && terraform init
	@cd terraform/sites/$(site) && terraform workspace select $(workspace) || terraform workspace new $(workspace)

.PHONY: terraform-plan
terraform-plan: ## Generate Terraform plan
	@echo "$(BLUE)Generating Terraform plan...$(NC)"
	@cd terraform/sites/$(site) && terraform plan \
		-var-file=terraform.tfvars \
		-var-file=workspaces/$(environment).tfvars \
		-out=$(environment).$(workspace).tfplan

.PHONY: terraform-apply
terraform-apply: ## Apply Terraform plan
	@echo "$(BLUE)Applying Terraform plan...$(NC)"
	@cd terraform/sites/$(site) && terraform apply $(environment).$(workspace).tfplan

.PHONY: terraform-destroy
terraform-destroy: ## Destroy Terraform resources
	@echo "$(RED)Destroying Terraform resources...$(NC)"
	@cd terraform/sites/$(site) && terraform destroy \
		-var-file=terraform.tfvars \
		-var-file=workspaces/$(environment).tfvars

# =============================================================================
# EXISTING TERRAFORM TARGETS (保持现有功能)
# =============================================================================

# Default target
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)= Unified Infrastructure Management =$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Main Command Groups:"
	@echo "  make github     - GitHub Actions simulation commands"
	@echo "  make terraform  - Terraform commands"
	@echo "  make ansible    - Ansible commands"
	@echo "  make setup      - Setup and environment commands"
	@echo "  make packer     - Packer commands"
	@echo ""
	@echo "Usage (Project/Resource Structure):"
	@echo "  make terraform -- plan -p demo/vpc -e development      # Generate Terraform plan"
	@echo "  make terraform -- apply -p demo/vpc -e production      # Apply Terraform changes"
	@echo "  make terraform -- plan -p demo/gitlab -e testing        # Plan GitLab resource"
	@echo "  make terraform -- plan -p demo/jump -e staging          # Plan jump host"
	@echo "  make terraform -- plan -p demo/vpc -e dev               # Short form (dev = development)"
	@echo ""
	@echo "Other Commands:"
	@echo "  make ansible check       # Check Ansible syntax"
	@echo "  make ansible play        # Run Ansible playbook"
	@echo "  make setup install-tools # Install required tools"
	@echo "  make setup check-tools   # Check if tools are installed"
	@echo "  make github pre-commit   # Run all pre-commit checks"
	@echo "  make packer build        # Build Packer image"
	@echo ""
	@echo "Direct Script Usage:"
	@echo "  ./scripts/make-terraform.sh plan -p demo/vpc -e development"
	@echo "  ./scripts/make-terraform.sh plan -p demo/vpc -e dev      # Short form"
	@echo "  ./scripts/make-ansible.sh play"
	@echo "  ./scripts/make-setup.sh install-tools"
	@echo "  ./scripts/make-github.sh pre-commit"
	@echo "  ./scripts/make-packer.sh build"
	@echo ""
	@echo "Environment variables:"
	@echo "  PROJECT_RESOURCE  Project/resource (e.g., demo/vpc, default: demo/vpc)"
	@echo "  ENVIRONMENT       Environment (default: development)"
	@echo "                    Valid: development, testing, staging, production"
	@echo "                    Short: dev, test, stage, prod"
	@echo "  WORKSPACE         Terraform workspace (default: default)"
	@echo "  OCI_REGION        OCI region (default: $(OCI_REGION))"
	@echo "  OCI_PROFILE       OCI profile (default: $(OCI_PROFILE))"
	@echo ""
	@echo "Documentation:"
	@echo "  docs/README.md                    - Complete documentation index"
	@echo "  docs/UNIFIED-INTERFACE-EXAMPLES.md - Usage examples for unified interface"
	@echo "  docs/TAGS.md                      - OCI tags management guide"
	@echo "  docs/REQUIRED-TAGS.md             - Required tags policy guide"

# =============================================================================
# GITHUB ACTIONS SIMULATION COMMANDS
# =============================================================================

.PHONY: github-help
github-help: ## Show GitHub Actions simulation commands
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)= GitHub Actions Simulation Commands =$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Usage: make github-<command>"
	@echo ""
	@echo "Available commands:"
	@echo "  make github-pre-commit    - Run all pre-commit checks"
	@echo "  make github-format-check  - Check Terraform formatting"
	@echo "  make github-format        - Format Terraform code"
	@echo "  make github-validate      - Validate Terraform configuration"
	@echo "  make github-plan          - Generate Terraform plan"
	@echo "  make github-apply         - Apply Terraform changes"
	@echo "  make github-docs          - Generate documentation"
	@echo "  make github-lint          - Run TFLint"
	@echo "  make github-security      - Run security scans"
	@echo "  make github-test          - Run comprehensive tests"
	@echo "  make github-ci            - Full CI/CD simulation"
	@echo ""

.PHONY: github-pre-commit
github-pre-commit: ## Run all pre-commit checks (mimics terraform-pre-commit.yml)
	@echo "$(BLUE)Running pre-commit checks...$(NC)"
	@$(MAKE) github-format-check
	@$(MAKE) github-validate
	@$(MAKE) github-plan
	@$(MAKE) github-docs
	@$(MAKE) github-lint
	@$(MAKE) github-security
	@echo "$(GREEN)✓ All pre-commit checks passed!$(NC)"

.PHONY: github-format-check
github-format-check: ## Check Terraform formatting
	@echo "$(BLUE)Checking Terraform format...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		terraform fmt -check -recursive || (echo "$(RED)✗ Terraform format check failed$(NC)" && exit 1); \
		echo "$(GREEN)✓ Terraform format check passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Terraform not installed, skipping format check$(NC)"; \
	fi

.PHONY: github-format
github-format: ## Format Terraform code
	@echo "$(BLUE)Formatting Terraform code...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		echo "$(BLUE)Formatting root directory...$(NC)"; \
		echo "  Command: terraform fmt -recursive ."; \
		terraform fmt -recursive .; \
		echo "$(BLUE)Formatting OCI modules...$(NC)"; \
		for module in terraform/modules/oci/*/; do \
			if [ -d "$$module" ]; then \
				echo "  Command: terraform fmt -recursive $$module"; \
				terraform fmt -recursive "$$module"; \
			fi; \
		done; \
		echo "$(BLUE)Formatting Alibaba Cloud modules...$(NC)"; \
		for module in terraform/modules/alicloud/*/; do \
			if [ -d "$$module" ]; then \
				echo "  Command: terraform fmt -recursive $$module"; \
				terraform fmt -recursive "$$module"; \
			fi; \
		done; \
		echo "$(BLUE)Formatting sites...$(NC)"; \
		for site in terraform/sites/*/; do \
			if [ -d "$$site" ]; then \
				echo "  Command: terraform fmt -recursive $$site"; \
				terraform fmt -recursive "$$site"; \
			fi; \
		done; \
		echo "$(GREEN)✓ Terraform code formatted$(NC)"; \
		echo "$(BLUE)Formatted directories:$(NC)"; \
		echo "  . (root)"; \
		echo "  terraform/modules/oci/* (OCI modules)"; \
		echo "  terraform/modules/alicloud/* (Alibaba Cloud modules)"; \
		echo "  terraform/sites/* (sites)"; \
		echo "$(BLUE)Changed files:$(NC)"; \
		git diff --name-only --diff-filter=M 2>/dev/null | grep '\.tf$$' | sed 's|^|  |' || echo "  No .tf files changed (or not in git repository)"; \
	else \
		echo "$(YELLOW)⚠ Terraform not installed, skipping format$(NC)"; \
	fi

.PHONY: github-validate
github-validate: ## Validate Terraform configuration
	@$(MAKE) validate-site
	@echo "$(BLUE)Validating Terraform configuration for workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		terraform -chdir=terraform/sites/$(site) init -backend=false; \
		terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace); \
		if [ -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
			terraform -chdir=terraform/sites/$(site) validate || (echo "$(RED)✗ Site validation failed for workspace $(workspace)$(NC)" && exit 1); \
		else \
			terraform -chdir=terraform/sites/$(site) validate || (echo "$(RED)✗ Site validation failed for workspace $(workspace)$(NC)" && exit 1); \
		fi && \
		echo "$(GREEN)✓ Site validation passed for workspace $(workspace)$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Terraform not installed, skipping validation$(NC)"; \
	fi

.PHONY: github-plan
github-plan: ## Generate Terraform plan for current environment
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Generating Terraform plan for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(site) init && \
	terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace) && \
	terraform -chdir=terraform/sites/$(site) plan -var-file=terraform.tfvars -var-file=workspaces/$(workspace).tfvars -out=$$(mktemp).$(site).$(environment).$(workspace).tfplan 2>&1 | sed 's|terraform apply|terraform -chdir=terraform/sites/$(site) apply|g'

.PHONY: github-apply
github-apply: ## Apply Terraform changes for current environment
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Applying Terraform changes for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(site) init && \
	terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace) && \
	terraform -chdir=terraform/sites/$(site) apply -var-file=terraform.tfvars -var-file=workspaces/$(workspace).tfvars -auto-approve

.PHONY: github-docs
github-docs: ## Generate Terraform documentation for all modules and sites
	@echo "$(BLUE)Generating Terraform documentation...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		echo "$(BLUE)Processing OCI modules...$(NC)"; \
		for module in terraform/modules/oci/*/; do \
			if [ -d "$$module" ]; then \
				echo "  Generating docs for $$module"; \
				terraform-docs -c .terraform-docs.yml "$$module" 2>/dev/null || true; \
			fi; \
		done; \
		echo "$(BLUE)Processing Alibaba Cloud modules...$(NC)"; \
		for module in terraform/modules/alicloud/*/; do \
			if [ -d "$$module" ]; then \
				echo "  Generating docs for $$module"; \
				terraform-docs -c .terraform-docs.yml "$$module" 2>/dev/null || true; \
			fi; \
		done; \
		echo "$(BLUE)Processing sites...$(NC)"; \
		for site in terraform/sites/*/; do \
			if [ -d "$$site" ]; then \
				echo "  Generating docs for $$site"; \
				terraform-docs -c .terraform-docs.yml "$$site" 2>/dev/null || true; \
			fi; \
		done; \
		echo "$(GREEN)✓ Documentation generated for all modules and sites$(NC)"; \
		echo "$(BLUE)Updated documentation files:$(NC)"; \
		find . -name "README.md" -exec grep -l "<!-- BEGIN_TF_DOCS -->" {} \; 2>/dev/null | sed 's|^|  |' || echo "  No generated documentation files found"; \
	else \
		echo "$(YELLOW)⚠ terraform-docs not installed, skipping documentation$(NC)"; \
		echo "$(BLUE)Install with: go install github.com/terraform-docs/terraform-docs@latest$(NC)"; \
	fi

.PHONY: github-lint
github-lint: ## Run TFLint
	@echo "$(BLUE)Running TFLint...$(NC)"
	@if command -v tflint >/dev/null 2>&1; then \
		tflint --init || true; \
		tflint || (echo "$(RED)✗ TFLint failed$(NC)" && exit 1); \
		echo "$(GREEN)✓ TFLint passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ TFLint not installed, skipping linting$(NC)"; \
		echo "$(BLUE)Install with: brew install tflint$(NC)"; \
	fi

.PHONY: github-security
github-security: ## Run security scans (TFsec and Checkov)
	@echo "$(BLUE)Running security scans...$(NC)"
	@$(MAKE) github-tfsec
	@$(MAKE) github-checkov
	@echo "$(GREEN)✓ Security scans completed$(NC)"

.PHONY: github-tfsec
github-tfsec: ## Run TFsec security scan
	@echo "$(BLUE)Running TFsec...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec || (echo "$(RED)✗ TFsec found security issues$(NC)" && exit 1); \
		echo "$(GREEN)✓ TFsec passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ TFsec not installed, skipping security scan$(NC)"; \
		echo "$(BLUE)Install with: brew install tfsec$(NC)"; \
	fi

.PHONY: github-checkov
github-checkov: ## Run Checkov security scan
	@echo "$(BLUE)Running Checkov...$(NC)"
	@if command -v checkov >/dev/null 2>&1; then \
		checkov -d . --compact || (echo "$(RED)✗ Checkov found security issues$(NC)" && exit 1); \
		echo "$(GREEN)✓ Checkov passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Checkov not installed, skipping security scan$(NC)"; \
		echo "$(BLUE)Install with: pip install checkov$(NC)"; \
	fi

.PHONY: github-test
github-test: ## Run comprehensive tests
	@echo "$(BLUE)Running comprehensive tests...$(NC)"
	@$(MAKE) validate-sites
	@$(MAKE) validate-modules
	@$(MAKE) github-security
	@echo "$(GREEN)✓ All tests passed$(NC)"

.PHONY: github-ci
github-ci: ## Full CI/CD simulation
	@echo "$(BLUE)Running full CI/CD simulation...$(NC)"
	@$(MAKE) github-pre-commit
	@$(MAKE) github-test
	@echo "$(GREEN)✓ CI/CD simulation completed successfully$(NC)"


# =============================================================================
# TERRAFORM COMMANDS
# =============================================================================

.PHONY: terraform-help
terraform-help: ## Show Terraform commands
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)= Terraform Commands                   =$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Usage: make terraform-<command>"
	@echo ""
	@echo "Available commands:"
	@echo "  make terraform-init        - Initialize Terraform"
	@echo "  make terraform-plan        - Generate Terraform plan"
	@echo "  make terraform-apply       - Apply Terraform changes"
	@echo "  make terraform-destroy     - Destroy Terraform resources"
	@echo "  make terraform-output      - Show Terraform outputs"
	@echo "  make terraform-output-json - Show outputs in JSON format"
	@echo "  make terraform-output-raw  - Show outputs in raw format"
	@echo "  make terraform-workspace   - Manage workspaces"
	@echo "  make terraform-validate    - Validate configuration"
	@echo "  make terraform-clean       - Clean up generated files"
	@echo "  make terraform-status      - Show current status"
	@echo ""

# Terraform targets now handled by scripts - see main dispatcher above

.PHONY: terraform-output
terraform-output: ## Show Terraform outputs for current environment
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Showing Terraform outputs for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(site) init && \
	terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace) && \
	terraform -chdir=terraform/sites/$(site) output

.PHONY: terraform-output-json
terraform-output-json: ## Show Terraform outputs in JSON format
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Showing Terraform outputs in JSON format for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(site) init && \
	terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace) && \
	terraform -chdir=terraform/sites/$(site) output -json

.PHONY: terraform-output-raw
terraform-output-raw: ## Show Terraform outputs in raw format
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Showing Terraform outputs in raw format for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(site) init && \
	terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace) && \
	terraform -chdir=terraform/sites/$(site) output -raw

.PHONY: terraform-workspace
terraform-workspace: ## Manage Terraform workspaces
	@echo "$(BLUE)Terraform workspace management:$(NC)"
	@echo "  make terraform workspace list   - List workspaces"
	@echo "  make terraform workspace new    - Create new workspace"
	@echo "  make terraform workspace select - Select workspace"
	@echo "  make terraform workspace delete - Delete workspace"

.PHONY: terraform-workspace-list
terraform-workspace-list: ## List available Terraform workspaces
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Available Terraform workspaces:$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace list
	@echo "$(BLUE)Available workspace configurations:$(NC)"
	@ls -1 terraform/sites/$(site)/workspaces/*.tfvars 2>/dev/null | sed 's|.*/||' | sed 's|\.tfvars||' || echo "  No workspace configurations found"

.PHONY: terraform-workspace-new
terraform-workspace-new: ## Create a new Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Creating new workspace: $(ORANGE)$(workspace)$(BLUE)$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace new $(workspace)
	@if [ ! -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
		echo "$(BLUE)Creating workspace configuration file...$(NC)"; \
		cp terraform/sites/$(site)/workspaces/default.tfvars terraform/sites/$(site)/workspaces/$(workspace).tfvars; \
		echo "$(GREEN)✓ Workspace configuration file created$(NC)"; \
	fi
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(GREEN) created$(NC)"

.PHONY: terraform-workspace-select
terraform-workspace-select: ## Select a Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Selecting workspace: $(ORANGE)$(workspace)$(BLUE)$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace select $(workspace)
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(GREEN) selected$(NC)"

.PHONY: terraform-workspace-delete
terraform-workspace-delete: ## Delete a Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(RED)WARNING: This will delete workspace $(ORANGE)$(workspace)$(RED)!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@terraform -chdir=terraform/sites/$(site) workspace delete $(workspace)
	@if [ -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
		echo "$(BLUE)Removing workspace configuration file...$(NC)"; \
		rm terraform/sites/$(site)/workspaces/$(workspace).tfvars; \
		echo "$(GREEN)✓ Workspace configuration file removed$(NC)"; \
	fi
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(BLUE) deleted$(NC)"

.PHONY: terraform-validate
terraform-validate: ## Validate Terraform configuration
	@$(MAKE) validate-site
	@echo "$(BLUE)Validating Terraform configuration for workspace $(ORANGE)$(workspace)$(BLUE)...$(NC)"
	@if command -v terraform >/dev/null 2>&1; then \
		terraform -chdir=terraform/sites/$(site) init -backend=false; \
		terraform -chdir=terraform/sites/$(site) workspace select $(workspace) || terraform -chdir=terraform/sites/$(site) workspace new $(workspace); \
		if [ -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
			terraform -chdir=terraform/sites/$(site) validate || (echo "$(RED)✗ Site validation failed for workspace $(workspace)$(NC)" && exit 1); \
		else \
			terraform -chdir=terraform/sites/$(site) validate || (echo "$(RED)✗ Site validation failed for workspace $(workspace)$(NC)" && exit 1); \
		fi && \
		echo "$(GREEN)✓ Site validation passed for workspace $(workspace)$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Terraform not installed, skipping validation$(NC)"; \
	fi

.PHONY: terraform-clean
terraform-clean: ## Clean up generated files
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfstate" -delete 2>/dev/null || true
	@find . -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -name "tfplan" -delete 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "tmp.*.tfplan" -delete 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

# terraform-status now handled by script - see main dispatcher above

# =============================================================================
# SETUP COMMANDS
# =============================================================================

.PHONY: setup-help
setup-help: ## Show setup commands
	@echo "$(BLUE)========================================$(NC)"
	@echo "$(BLUE)= Setup Commands                       =$(NC)"
	@echo "$(BLUE)========================================$(NC)"
	@echo ""
	@echo "Usage: make setup-<command>"
	@echo ""
	@echo "Available commands:"
	@echo "  make setup-install-tools   - Install required tools"
	@echo "  make setup-check-tools     - Check if tools are installed"
	@echo "  make setup-dev-setup       - Setup development environment"
	@echo "  make setup-list-sites      - List available sites"
	@echo "  make setup-list-envs       - List available environments"
	@echo "  make setup-validate-site   - Validate current site"
	@echo "  make setup-clean           - Clean up generated files"
	@echo "  make setup-status          - Show current status"
	@echo ""

.PHONY: setup-install-tools
setup-install-tools: ## Install required tools
	@echo "$(BLUE)Installing required tools...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "$(BLUE)Detected macOS with Homebrew$(NC)"; \
		brew install terraform tflint tfsec; \
		pip3 install checkov; \
		brew install terraform-docs; \
		echo "$(GREEN)✓ Tools installed via Homebrew$(NC)"; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "$(BLUE)Detected Ubuntu/Debian with apt$(NC)"; \
		sudo apt-get update; \
		sudo apt-get install -y curl wget unzip software-properties-common; \
		wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg; \
		echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $$(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list; \
		sudo apt-get update && sudo apt-get install -y terraform; \
		curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash; \
		curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash; \
		pip3 install checkov; \
		go install github.com/terraform-docs/terraform-docs@latest; \
		echo "$(GREEN)✓ Tools installed via apt$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Neither Homebrew (macOS) nor apt (Ubuntu/Debian) found$(NC)"; \
		echo "$(BLUE)Please install tools manually$(NC)"; \
	fi

.PHONY: setup-check-tools
setup-check-tools: ## Check if all required tools are installed
	@echo "$(BLUE)Checking prerequisites...$(NC)"
	@tools=("terraform" "tflint" "tfsec" "checkov" "terraform-docs"); \
	missing=(); \
	for tool in "$${tools[@]}"; do \
		if ! command -v "$$tool" >/dev/null 2>&1; then \
			missing+=("$$tool"); \
		fi; \
	done; \
	if [ "$${#missing[@]}" -eq 0 ]; then \
		echo "$(GREEN)✓ All tools are installed$(NC)"; \
		echo "$(BLUE)Terraform version:$$(terraform version | head -n1)$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Missing tools: $${missing[*]}$(NC)"; \
		echo "$(BLUE)Run 'make setup install-tools' to install missing tools$(NC)"; \
		exit 1; \
	fi

.PHONY: setup-dev-setup
setup-dev-setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@$(MAKE) setup-install-tools
	@$(MAKE) setup-check-tools
	@$(MAKE) github-format
	@$(MAKE) github-docs
	@echo "$(GREEN)✓ Development environment ready$(NC)"

.PHONY: setup-list-sites
setup-list-sites: ## List available sites
	@echo "$(BLUE)Available sites:$(NC)"
	@echo "Terraform sites:"
	@ls -d terraform/sites/*/ 2>/dev/null | sed 's|terraform/sites/|  |' | sed 's|/||' || echo "  No terraform sites found"
	@echo "Ansible playbooks:"
	@ls -d ansible/playbooks/*/ 2>/dev/null | sed 's|ansible/playbooks/|  |' | sed 's|/||' || echo "  No ansible playbooks found"
	@echo "Packer templates:"
	@ls -d packer/*/ 2>/dev/null | sed 's|packer/|  |' | sed 's|/||' || echo "  No packer templates found"

.PHONY: setup-list-envs
setup-list-envs: ## List available environments for current site
	@echo "$(BLUE)Available environments for site '$(site)':$(NC)"
	@echo "Terraform environments:"
	@ls -1 terraform/sites/$(site)/workspaces/*.tfvars 2>/dev/null | sed 's/.*\///' | sed 's/\.tfvars$$//' | sed 's/^/  /' || echo "  No terraform environments found"
	@echo "Ansible inventories:"
	@ls -1 ansible/inventories/$(site)-* 2>/dev/null | sed 's/.*-//' | sed 's/^/  /' || echo "  No ansible inventories found"
	@echo "Packer templates:"
	@ls -1 packer/$(site)/*.pkr.hcl 2>/dev/null | sed 's/.*\///' | sed 's/\.pkr\.hcl$$//' | sed 's/^/  /' || echo "  No packer templates found"

.PHONY: setup-validate-site
setup-validate-site: ## Validate that the current site exists
	$(call validate-parameters)
	@echo "$(BLUE)Validating site: $(site)$(NC)"
	@if [ ! -d "terraform/sites/$(site)" ]; then \
		echo "$(RED)✗ Site $(site) not found$(NC)"; \
		echo "$(BLUE)Available sites:$(NC)"; \
		$(MAKE) setup-list-sites; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Site $(site) found$(NC)"; \
	fi

.PHONY: setup-clean
setup-clean: ## Clean up generated files
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfstate" -delete 2>/dev/null || true
	@find . -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -name "tfplan" -delete 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "tmp.*.tfplan" -delete 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

.PHONY: setup-status
setup-status: ## Show current status
	@echo "$(BLUE)Current Status:$(NC)"
	@echo "  Site: $(site)"
	@echo "  Environment: $(PURPLE)$(environment)$(NC)"
	@echo "  Workspace: $(ORANGE)$(workspace)$(NC)"
	@echo "  OCI Region: $(OCI_REGION)"
	@echo "  OCI Profile: $(OCI_PROFILE)"
	@echo "  Terraform Version: $(TERRAFORM_VERSION)"
	@echo ""
	@echo "$(BLUE)Available modules:$(NC)"
	@ls -d terraform/modules/*/ 2>/dev/null | sed 's|terraform/modules/|  |' | sed 's|/||' || echo "  No modules found"
	@echo ""
	@echo "$(BLUE)Available sites:$(NC)"
	@ls -d terraform/sites/*/ 2>/dev/null | sed 's|terraform/sites/|  |' | sed 's|/||' || echo "  No sites found"
	@echo "$(BLUE)Current site: $(site)$(NC)"
	@echo "$(BLUE)Current environment: $(PURPLE)$(environment)$(BLUE)$(NC)"
	@echo "$(BLUE)Current workspace: $(ORANGE)$(workspace)$(BLUE)$(NC)"

# =============================================================================
# SITE MANAGEMENT (保持现有功能)
# =============================================================================

.PHONY: discover-options
discover-options: ## Discover available sites and workspaces
	@./scripts/discover-options.sh
	@echo ""
	@echo "$(BLUE)For more specific discovery, use:$(NC)"
	@echo "  make discover-workspaces SITE=<site-name>"
	@echo "  make validate-options SITE=<site-name> WORKSPACE=<workspace-name>"

.PHONY: discover-workspaces
discover-workspaces: ## Discover available workspaces for current site
	$(call validate-parameters)
	@if [ -z "$(SITE)" ]; then \
		echo "$(RED)Error: SITE parameter is required$(NC)"; \
		echo "$(BLUE)Usage: make discover-workspaces SITE=<site-name>$(NC)"; \
		echo "$(BLUE)Example: make discover-workspaces SITE=oci-labs$(NC)"; \
		echo ""; \
		echo "$(BLUE)Available sites:$(NC)"; \
		./scripts/discover-options.sh | grep -A 10 "Available sites:"; \
		exit 1; \
	fi
	@./scripts/discover-options.sh $(SITE)

.PHONY: validate-options
validate-options: ## Validate current site and workspace
	$(call validate-parameters)
	@if [ -z "$(SITE)" ] || [ -z "$(WORKSPACE)" ]; then \
		echo "$(RED)Error: Both SITE and WORKSPACE parameters are required$(NC)"; \
		echo "$(BLUE)Usage: make validate-options SITE=<site-name> WORKSPACE=<workspace-name>$(NC)"; \
		echo "$(BLUE)Example: make validate-options SITE=oci-labs WORKSPACE=default$(NC)"; \
		exit 1; \
	fi
	@./scripts/discover-options.sh $(SITE) $(WORKSPACE)

.PHONY: validate-site
validate-site: ## Validate that the current site exists
	$(call validate-parameters)
	@echo "$(BLUE)Validating site: $(site)$(NC)"
	@if [ ! -d "terraform/sites/$(site)" ]; then \
		echo "$(RED)✗ Site $(site) not found$(NC)"; \
		echo "$(BLUE)Available sites:$(NC)"; \
		$(MAKE) list-sites; \
		exit 1; \
	else \
		echo "$(GREEN)✓ Site $(site) found$(NC)"; \
	fi

# =============================================================================
# SITE VALIDATION
# =============================================================================

.PHONY: validate-sites
validate-sites: ## Validate all sites
	@echo "$(BLUE)Validating all sites...$(NC)"
	@for site in terraform/sites/*/; do \
		if [ -d "$$site" ]; then \
			site_name=$$(basename "$$site"); \
			echo "$(BLUE)Validating site $$site_name...$(NC)"; \
			if command -v terraform >/dev/null 2>&1; then \
				terraform -chdir="$$site" init -backend=false && \
				terraform -chdir="$$site" validate || (echo "$(RED)✗ Validation failed for site $$site_name$(NC)" && exit 1); \
				echo "$(GREEN)✓ Site $$site_name validated$(NC)"; \
			else \
				echo "$(YELLOW)⚠ Terraform not installed, skipping site $$site_name$(NC)"; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✓ All sites validated$(NC)"

# =============================================================================
# MODULE VALIDATION (mimics terraform-modules.yml)
# =============================================================================

.PHONY: validate-modules
validate-modules: ## Validate all modules
	@echo "$(BLUE)Validating modules...$(NC)"
	@for module in terraform/modules/*/; do \
		if [ -d "$$module" ]; then \
			echo "$(BLUE)Validating $$module...$(NC)"; \
			if command -v terraform >/dev/null 2>&1; then \
				terraform -chdir="$$module" init -backend=false && \
				terraform -chdir="$$module" validate || (echo "$(RED)✗ Validation failed for $$module$(NC)" && exit 1); \
				echo "$(GREEN)✓ $$module validated$(NC)"; \
			else \
				echo "$(YELLOW)⚠ Terraform not installed, skipping $$module$(NC)"; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✓ All modules validated$(NC)"

.PHONY: validate-alicloud-modules
validate-alicloud-modules: ## Validate all Alibaba Cloud modules
	@echo "$(BLUE)Validating Alibaba Cloud modules...$(NC)"
	@for module in terraform/modules/alicloud/*/; do \
		if [ -d "$$module" ]; then \
			echo "$(BLUE)Validating $$module...$(NC)"; \
			if command -v terraform >/dev/null 2>&1; then \
				terraform -chdir="$$module" init -backend=false && \
				terraform -chdir="$$module" validate || (echo "$(RED)✗ Validation failed for $$module$(NC)" && exit 1); \
				echo "$(GREEN)✓ $$module validated$(NC)"; \
			else \
				echo "$(YELLOW)⚠ Terraform not installed, skipping $$module$(NC)"; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✓ All Alibaba Cloud modules validated$(NC)"

# =============================================================================
# COMPREHENSIVE TESTS (mimics terraform-test.yml)
# =============================================================================

.PHONY: test
test: ## Run comprehensive tests
	@echo "$(BLUE)Running comprehensive tests...$(NC)"
	@$(MAKE) validate-sites
	@$(MAKE) validate-modules
	@$(MAKE) security-scan
	@echo "$(GREEN)✓ All tests passed$(NC)"

# =============================================================================
# UTILITY TARGETS
# =============================================================================

.PHONY: clean
clean: ## Clean up generated files
	@echo "$(BLUE)Cleaning up...$(NC)"
	@find . -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfstate" -delete 2>/dev/null || true
	@find . -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -name "tfplan" -delete 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@find . -name "tmp.*.tfplan" -delete 2>/dev/null || true
	@find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

.PHONY: list-plans
list-plans: ## List generated Terraform plan files
	@echo "$(BLUE)Generated Terraform plan files:$(NC)"
	@find . -name "*.tfplan" -type f 2>/dev/null | sort || echo "  No plan files found"

.PHONY: show-plan
show-plan: ## Show the most recent plan file for current site and workspace
	@$(MAKE) validate-site
	@echo "$(BLUE)Most recent plan file for $(PURPLE)$(ENVIRONMENT)$(BLUE) environment in workspace $(ORANGE)$(WORKSPACE)$(BLUE):$(NC)"
	@latest_plan=$$(find terraform/sites/$(SITE) -name "*$(SITE).$(ENVIRONMENT).$(WORKSPACE).tfplan" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -f2- -d" ") && \
	if [ -n "$$latest_plan" ]; then \
		echo "  $$latest_plan"; \
		echo "$(BLUE)Plan file size:$$(ls -lh "$$latest_plan" | awk '{print $$5}')$(NC)"; \
		echo "$(BLUE)Created:$$(ls -la "$$latest_plan" | awk '{print $$6, $$7, $$8}')$(NC)"; \
		echo ""; \
		echo "$(BLUE)To apply this plan, run:$(NC)"; \
		echo "  terraform -chdir=terraform/sites/$(SITE) apply \"$$latest_plan\""; \
	else \
		echo "  No plan file found for current configuration"; \
		echo "$(BLUE)Run 'make plan' to generate a new plan$(NC)"; \
	fi

.PHONY: show-apply-command
show-apply-command: ## Show the manual apply command for current configuration
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Manual apply command for $(PURPLE)$(environment)$(BLUE) environment in workspace $(ORANGE)$(workspace)$(BLUE):$(NC)"
	@echo "  terraform -chdir=terraform/sites/$(site) apply -var-file=terraform.tfvars -var-file=workspaces/$(workspace).tfvars -auto-approve"
	@echo ""
	@echo "$(BLUE)Or if you have a plan file:$(NC)"
	@latest_plan=$$(find terraform/sites/$(site) -name "*$(site).$(environment).$(workspace).tfplan" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -f2- -d" ") && \
	if [ -n "$$latest_plan" ]; then \
		echo "  terraform -chdir=terraform/sites/$(site) apply \"$$latest_plan\""; \
	else \
		echo "  # No plan file found. Run 'make plan' first."; \
	fi



# Status target moved to setup-status for consistency

# =============================================================================
# DEVELOPMENT TARGETS
# =============================================================================

.PHONY: dev-setup
dev-setup: ## Setup development environment
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@$(MAKE) install-tools
	@$(MAKE) check-prerequisites
	@$(MAKE) format
	@$(MAKE) docs
	@echo "$(GREEN)✓ Development environment ready$(NC)"

.PHONY: watch
watch: ## Watch for changes and run tests
	@echo "$(BLUE)Watching for changes...$(NC)"
	@if command -v fswatch >/dev/null 2>&1; then \
		echo "$(BLUE)Using fswatch (macOS)...$(NC)"; \
		fswatch -o . | while read f; do \
			echo "$(BLUE)Change detected, running tests...$(NC)"; \
			$(MAKE) pre-commit; \
		done; \
	elif command -v inotifywait >/dev/null 2>&1; then \
		echo "$(BLUE)Using inotifywait (Linux)...$(NC)"; \
		while inotifywait -r -e modify,create,delete .; do \
			echo "$(BLUE)Change detected, running tests...$(NC)"; \
			$(MAKE) pre-commit; \
		done; \
	else \
		echo "$(YELLOW)⚠ File watcher not found$(NC)"; \
		if command -v brew >/dev/null 2>&1; then \
			echo "$(BLUE)Install fswatch with: brew install fswatch$(NC)"; \
		elif command -v apt-get >/dev/null 2>&1; then \
			echo "$(BLUE)Install inotify-tools with: sudo apt-get install inotify-tools$(NC)"; \
		fi; \
		echo "$(BLUE)Alternatively, run 'make pre-commit' manually$(NC)"; \
	fi

# =============================================================================
# DOCUMENTATION TARGETS
# =============================================================================

.PHONY: docs-serve
docs-serve: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation on localhost:8000...$(NC)"
	@if command -v python3 >/dev/null 2>&1; then \
		python3 -m http.server 8000 --bind 127.0.0.1; \
	elif command -v python >/dev/null 2>&1; then \
		python -m SimpleHTTPServer 8000; \
		echo "$(YELLOW)⚠ Python 2 detected - binding to localhost not supported$(NC)"; \
		echo "$(BLUE)Access at: http://localhost:8000$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Python not found, cannot serve documentation$(NC)"; \
	fi

.PHONY: docs-build
docs-build: ## Build all documentation
	@echo "$(BLUE)Building documentation...$(NC)"
	@$(MAKE) docs
	@echo "$(BLUE)Building module documentation...$(NC)"
	@for module in terraform/modules/oci/*/; do \
		if [ -d "$$module" ]; then \
			echo "$(BLUE)Building docs for $$module...$(NC)"; \
			if command -v terraform-docs >/dev/null 2>&1; then \
				terraform-docs -c .terraform-docs.yml "$$module" 2>/dev/null || true; \
				echo "$(GREEN)✓ $$module documentation built$(NC)"; \
				echo "  $$module/README.md"; \
			else \
				echo "$(YELLOW)⚠ terraform-docs not available for $$module$(NC)"; \
			fi; \
		fi; \
	done
	@echo "$(BLUE)Building site documentation...$(NC)"
	@for site in terraform/sites/*/; do \
		if [ -d "$$site" ]; then \
			echo "$(BLUE)Building docs for $$site...$(NC)"; \
			if command -v terraform-docs >/dev/null 2>&1; then \
				terraform-docs -c .terraform-docs.yml "$$site" 2>/dev/null || true; \
				echo "$(GREEN)✓ $$site documentation built$(NC)"; \
				echo "  $$site/README.md"; \
			else \
				echo "$(YELLOW)⚠ terraform-docs not available for $$site$(NC)"; \
			fi; \
		fi; \
	done
	@echo "$(GREEN)✓ All documentation built$(NC)"

.PHONY: docs-clean
docs-clean: ## Clean generated documentation
	@echo "$(BLUE)Cleaning generated documentation...$(NC)"
	@echo "$(BLUE)Files to be cleaned:$(NC)"
	@find . -name "README.md" -exec grep -l "<!-- BEGIN_TF_DOCS -->" {} \; 2>/dev/null | sed 's|^|  |' || echo "  No generated documentation files found"
	@find . -name "README.md" -exec grep -l "<!-- BEGIN_TF_DOCS -->" {} \; | xargs rm -f 2>/dev/null || true
	@echo "$(GREEN)✓ Generated documentation cleaned$(NC)"

.PHONY: docs-check
docs-check: ## Check if documentation is up to date for all modules and sites
	@echo "$(BLUE)Checking documentation status...$(NC)"
	@if command -v terraform-docs >/dev/null 2>&1; then \
		echo "$(BLUE)Checking OCI modules...$(NC)"; \
		for module in terraform/modules/oci/*/; do \
			if [ -d "$$module" ]; then \
				echo "  Checking $$module"; \
				terraform-docs -c .terraform-docs.yml "$$module" --output-file README.md.tmp 2>/dev/null || true; \
				if [ -f "$$module/README.md" ] && [ -f "README.md.tmp" ]; then \
					if diff -q "$$module/README.md" "README.md.tmp" >/dev/null 2>&1; then \
						echo "    ✓ Up to date"; \
					else \
						echo "    ✗ Out of date"; \
						rm -f README.md.tmp; \
						exit 1; \
					fi; \
				fi; \
				rm -f README.md.tmp; \
			fi; \
		done; \
		echo "$(BLUE)Checking sites...$(NC)"; \
		for site in terraform/sites/*/; do \
			if [ -d "$$site" ]; then \
				echo "  Checking $$site"; \
				terraform-docs -c .terraform-docs.yml "$$site" --output-file README.md.tmp 2>/dev/null || true; \
				if [ -f "$$site/README.md" ] && [ -f "README.md.tmp" ]; then \
					if diff -q "$$site/README.md" "README.md.tmp" >/dev/null 2>&1; then \
						echo "    ✓ Up to date"; \
					else \
						echo "    ✗ Out of date"; \
						rm -f README.md.tmp; \
						exit 1; \
					fi; \
				fi; \
				rm -f README.md.tmp; \
			fi; \
		done; \
		echo "$(GREEN)✓ All documentation is up to date$(NC)"; \
	else \
		echo "$(YELLOW)⚠ terraform-docs not installed, skipping check$(NC)"; \
	fi

# =============================================================================
# TROUBLESHOOTING
# =============================================================================

.PHONY: debug
debug: ## Debug Terraform configuration
	@echo "$(BLUE)Debugging Terraform configuration...$(NC)"
	@terraform -chdir=terraform/sites/$(site) version && \
	terraform -chdir=terraform/sites/$(site) providers && \
	terraform -chdir=terraform/sites/$(site) graph

.PHONY: doctor
doctor: ## Run diagnostics
	@echo "$(BLUE)Running diagnostics...$(NC)"
	@$(MAKE) check-prerequisites
	@echo "$(BLUE)Checking OCI credentials...$(NC)"
	@if command -v oci >/dev/null 2>&1; then \
		oci iam user get || echo "$(RED)✗ OCI credentials not configured$(NC)"; \
	else \
		echo "$(YELLOW)⚠ OCI CLI not installed$(NC)"; \
	fi
	@echo "$(BLUE)Checking Terraform configuration...$(NC)"
	@$(MAKE) validate
	@echo "$(GREEN)✓ Diagnostics completed$(NC)"

# =============================================================================
# WORKSPACE MANAGEMENT
# =============================================================================

.PHONY: workspace-list
workspace-list: ## List available Terraform workspaces
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Available Terraform workspaces:$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace list
	@echo "$(BLUE)Available workspace configurations:$(NC)"
	@ls -1 terraform/sites/$(site)/workspaces/*.tfvars 2>/dev/null | sed 's|.*/||' | sed 's|\.tfvars||' || echo "  No workspace configurations found"

.PHONY: workspace-new
workspace-new: ## Create a new Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Creating new workspace: $(ORANGE)$(workspace)$(BLUE)$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace new $(workspace)
	@if [ ! -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
		echo "$(BLUE)Creating workspace configuration file...$(NC)"; \
		cp terraform/sites/$(site)/workspaces/default.tfvars terraform/sites/$(site)/workspaces/$(workspace).tfvars; \
		echo "$(GREEN)✓ Workspace configuration file created$(NC)"; \
	fi
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(GREEN) created$(NC)"

.PHONY: workspace-select
workspace-select: ## Select a Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Selecting workspace: $(ORANGE)$(workspace)$(BLUE)$(NC)"
	@terraform -chdir=terraform/sites/$(site) workspace select $(workspace)
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(GREEN) selected$(NC)"

.PHONY: workspace-delete
workspace-delete: ## Delete a Terraform workspace
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(RED)WARNING: This will delete workspace $(ORANGE)$(workspace)$(RED)!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@terraform -chdir=terraform/sites/$(site) workspace delete $(workspace)
	@if [ -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
		echo "$(BLUE)Removing workspace configuration file...$(NC)"; \
		rm terraform/sites/$(site)/workspaces/$(workspace).tfvars; \
		echo "$(GREEN)✓ Workspace configuration file removed$(NC)"; \
	fi
	@echo "$(GREEN)✓ Workspace $(ORANGE)$(workspace)$(BLUE) deleted$(NC)"

.PHONY: workspace-edit
workspace-edit: ## Edit workspace configuration file
	$(call validate-parameters)
	@$(MAKE) validate-site
	@echo "$(BLUE)Opening workspace configuration for editing: $(ORANGE)$(workspace)$(BLUE)$(NC)"
	@if [ -f "terraform/sites/$(site)/workspaces/$(workspace).tfvars" ]; then \
		$${EDITOR:-vim} terraform/sites/$(site)/workspaces/$(workspace).tfvars; \
	else \
		echo "$(RED)✗ Workspace configuration file not found$(NC)"; \
		echo "$(BLUE)Run 'make workspace-new' to create the workspace first$(NC)"; \
		exit 1; \
	fi

.PHONY: workspace-create-prefixed
workspace-create-prefixed: ## Create a new workspace with ihanyouqing prefix
	@$(MAKE) validate-site
	@if [ -z "$(ENV_NAME)" ]; then \
		echo "$(RED)✗ ENV_NAME is required$(NC)"; \
		echo "$(BLUE)Usage: make workspace-create-prefixed ENV_NAME=staging$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Creating new workspace: $(CYAN)ihanyouqing-$(ENV_NAME)$(BLUE)$(NC)"
	@terraform -chdir=terraform/sites/$(SITE) workspace new ihanyouqing-$(ENV_NAME)
	@if [ ! -f "terraform/sites/$(SITE)/workspaces/ihanyouqing-$(ENV_NAME).tfvars" ]; then \
		echo "$(BLUE)Creating workspace configuration file...$(NC)"; \
		cp terraform/sites/$(SITE)/workspaces/default.tfvars terraform/sites/$(SITE)/workspaces/ihanyouqing-$(ENV_NAME).tfvars; \
		sed -i.bak 's/workspace   = "default"/workspace   = "ihanyouqing-$(ENV_NAME)"/' terraform/sites/$(SITE)/workspaces/ihanyouqing-$(ENV_NAME).tfvars; \
		rm terraform/sites/$(SITE)/workspaces/ihanyouqing-$(ENV_NAME).tfvars.bak; \
		echo "$(GREEN)✓ Workspace configuration file created$(NC)"; \
	fi
	@echo "$(GREEN)✓ Workspace $(CYAN)ihanyouqing-$(ENV_NAME)$(GREEN) created$(NC)"

# =============================================================================
# DEPLOYMENT TARGETS
# =============================================================================

.PHONY: deploy
deploy: ## Deploy to current environment
	@echo "$(BLUE)Deploying to $(PURPLE)$(ENVIRONMENT)$(BLUE) environment in workspace $(ORANGE)$(WORKSPACE)$(BLUE)...$(NC)"
	@$(MAKE) pre-commit
	@$(MAKE) apply

.PHONY: destroy
destroy: ## Destroy current environment
	@$(MAKE) validate-site
	@echo "$(RED)WARNING: This will destroy all resources in the $(PURPLE)$(ENVIRONMENT)$(RED) environment in workspace $(ORANGE)$(WORKSPACE)$(RED)!$(NC)"
	@read -p "Are you sure? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@terraform -chdir=terraform/sites/$(SITE) init && \
	terraform -chdir=terraform/sites/$(SITE) workspace select $(WORKSPACE) || terraform -chdir=terraform/sites/$(SITE) workspace new $(WORKSPACE) && \
	terraform -chdir=terraform/sites/$(SITE) destroy -var-file=workspaces/$(WORKSPACE).tfvars -auto-approve
	@echo "$(GREEN)✓ Environment destroyed$(NC)"

# =============================================================================
# MONITORING TARGETS
# =============================================================================

.PHONY: monitor
monitor: ## Monitor deployed resources
	@$(MAKE) validate-site
	@echo "$(BLUE)Monitoring deployed resources in workspace $(ORANGE)$(WORKSPACE)$(BLUE)...$(NC)"
	@terraform -chdir=terraform/sites/$(SITE) workspace select $(WORKSPACE) || terraform -chdir=terraform/sites/$(SITE) workspace new $(WORKSPACE) && \
	terraform -chdir=terraform/sites/$(SITE) output -json 2>/dev/null || echo "$(YELLOW)No outputs available$(NC)"

.PHONY: logs
logs: ## Show recent logs
	@echo "$(BLUE)Showing recent logs...$(NC)"
	@echo "$(YELLOW)Log monitoring not implemented yet$(NC)"
	@echo "$(BLUE)Use OCI CLI or console to view logs$(NC)"

# =============================================================================
# BACKUP AND RECOVERY
# =============================================================================

.PHONY: backup
backup: ## Backup Terraform state
	@echo "$(BLUE)Backing up Terraform state...$(NC)"
	@mkdir -p backups
	@BACKUP_DIR="backups/$(SITE)-$(ENVIRONMENT)-$(WORKSPACE)-$$(date +%Y%m%d-%H%M%S)" && \
	mkdir -p "$$BACKUP_DIR" && \
	echo "$(BLUE)Creating backup in $$BACKUP_DIR$(NC)" && \
	cp -r terraform/sites/$(SITE)/.terraform* "$$BACKUP_DIR"/ 2>/dev/null || true && \
	cp terraform/sites/$(SITE)/*.tfstate* "$$BACKUP_DIR"/ 2>/dev/null || true && \
	echo "$(GREEN)✓ State backed up to $$BACKUP_DIR$(NC)"

.PHONY: list-backups
list-backups: ## List available backups
	@echo "$(BLUE)Available backups:$(NC)"
	@if [ -d "backups" ]; then \
		ls -la backups/ 2>/dev/null || echo "  No backups found"; \
	else \
		echo "  No backup directory found"; \
	fi

.PHONY: restore-from
restore-from: ## Restore from specific backup (use BACKUP_DIR=path)
	@echo "$(BLUE)Restoring Terraform state...$(NC)"
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "$(RED)✗ BACKUP_DIR is required$(NC)"; \
		echo "$(BLUE)Usage: make restore-from BACKUP_DIR=backups/project-env-timestamp$(NC)"; \
		$(MAKE) list-backups; \
		exit 1; \
	fi
	@if [ -d "$(BACKUP_DIR)" ]; then \
		echo "$(BLUE)Restoring from $(BACKUP_DIR)...$(NC)" && \
		cp -r "$(BACKUP_DIR)/.terraform*" terraform/sites/$(SITE)/ 2>/dev/null || true && \
		cp "$(BACKUP_DIR)/*.tfstate*" terraform/sites/$(SITE)/ 2>/dev/null || true && \
		echo "$(GREEN)✓ State restored from $(BACKUP_DIR)$(NC)"; \
	else \
		echo "$(RED)✗ Backup directory $(BACKUP_DIR) not found$(NC)"; \
		$(MAKE) list-backups; \
		exit 1; \
	fi

# =============================================================================
# RELEASE MANAGEMENT
# =============================================================================

.PHONY: release
release: ## Create a new release
	@echo "$(BLUE)Creating release...$(NC)"
	@if [ -z "$(VERSION)" ]; then \
		echo "$(RED)✗ VERSION variable is required$(NC)"; \
		echo "Usage: make release VERSION=1.0.0"; \
		exit 1; \
	fi
	@$(MAKE) pre-commit
	@$(MAKE) test
	@echo "$(GREEN)✓ Release $(VERSION) is ready$(NC)"
	@echo "$(BLUE)Next steps:$(NC)"
	@echo "  1. Create a git tag: git tag v$(VERSION)"
	@echo "  2. Push the tag: git push origin v$(VERSION)"
	@echo "  3. Create a GitHub release"

# =============================================================================
# DEVELOPMENT HELPER COMMANDS
# =============================================================================

.PHONY: dev-validate
dev-validate: ## Quick validation for development
	@$(MAKE) lint validate
	@echo "$(GREEN)✓ Development validation completed$(NC)"

.PHONY: ci-simulation
ci-simulation: ## Full CI/CD simulation
	@$(MAKE) pre-commit
	@echo "$(GREEN)✓ CI/CD simulation completed successfully$(NC)"

# =============================================================================
# ARGUMENT HANDLING
# =============================================================================

# Prevent Make from trying to process arguments as targets
%:
	@:
