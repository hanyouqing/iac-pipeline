# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated Terraform operations.

## Workflows

### 1. Terraform Validate (`terraform-validate.yml`)

**Trigger:** 
- On PR open/sync/reopen (automatic)
- Manual trigger via GitHub Actions UI

**Purpose:** Validates Terraform configuration syntax and format

**Actions:**
- Detects changed resources in `terraform/demo/<resource>`
- Runs `terraform fmt -check` for formatting validation
- Runs `terraform validate` for syntax validation

**Manual Trigger Options:**
- `project`: Project name (e.g., demo, apiadmin, openauth) - optional, detects from changes if empty
- `resource`: Resource name (e.g., vpc, jump, gitlab) - optional, validates all changed if empty

### 2. Terraform Plan on PR (`terraform-pr.yml`)

**Trigger:**
- On PR open/sync/reopen (automatic)
- Manual trigger via GitHub Actions UI

**Purpose:** Generates Terraform plan and comments on PR

**Actions:**
- Detects changed resources in `terraform/demo/<resource>`
- Runs `terraform plan` for each changed resource
- Posts plan output as PR comment (for PR) or commit comment (for manual trigger)
- Updates comment if PR is updated

**Output:**
- Plan results posted as collapsible comments
- Plan artifacts uploaded for download

**Manual Trigger Options:**
- `project`: Project name (e.g., demo, apiadmin, openauth) - optional, detects from changes if empty
- `resource`: Resource name (e.g., vpc, jump, gitlab) - optional, plans all changed if empty
- `environment`: Environment name (dev, testing, staging, production)

**Use Case:** Check if current code differs from deployed infrastructure

**Examples:**
- Plan specific resource: `project=demo`, `resource=vpc`
- Plan all changed resources: Leave both empty (auto-detects)
- Plan all resources in a project: `project=demo`, leave `resource` empty

### 3. Terraform Apply on Approval (`terraform-apply.yml`)

**Trigger:**
- When PR is approved (automatic)
- Manual trigger via GitHub Actions UI

**Purpose:** Applies Terraform changes after PR approval

**Actions:**
- Detects changed resources in `terraform/demo/<resource>`
- Runs `terraform plan` to verify changes
- Runs `terraform apply` to deploy infrastructure
- Posts apply status as PR comment (for PR) or commit comment (for manual trigger)

**Security:**
- Only runs when PR is approved (for PR trigger)
- Requires AWS credentials configured in repository secrets

**Manual Trigger Options:**
- `project`: Project name (e.g., demo, apiadmin, openauth) - required
- `resource`: Resource name (e.g., vpc, jump, gitlab) - required
- `environment`: Environment name (dev, testing, staging, production)
- `auto_approve`: Auto-approve apply (use with caution, default: false)

**Use Case:** Manually apply changes or sync infrastructure

**Examples:**
- Apply specific resource: `project=demo`, `resource=vpc`, `auto_approve=true`
- Apply with environment: `project=apiadmin`, `resource=api`, `environment=staging`

## Required Secrets

Configure the following secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID` - AWS access key ID
- `AWS_SECRET_ACCESS_KEY` - AWS secret access key

## Workflow Behavior

### Change Detection

Workflows automatically detect which resources have changed by:
1. Comparing PR base and head commits
2. Finding files changed in `terraform/<project>/<resource>/` directories
3. Extracting unique project/resource pairs (e.g., `demo/vpc`, `apiadmin/api`, `openauth/auth`)

**Supported Structure:**
```
terraform/
├── demo/          # Project: demo
│   ├── vpc/       # Resource: vpc
│   ├── jump/      # Resource: jump
│   └── gitlab/    # Resource: gitlab
├── apiadmin/      # Project: apiadmin
│   └── api/       # Resource: api
└── openauth/      # Project: openauth
    └── auth/      # Resource: auth
```

### Parallel Execution

Each changed project/resource pair is processed in parallel using GitHub Actions matrix strategy. The matrix contains both project and resource information.

### PR Comments

- **Plan comments:** Posted automatically when PR is created/updated
- **Apply comments:** Posted after apply completes (success or failure)
- Comments are updated if PR is updated (for plan) or new comments added (for apply)

## Example Workflow

### Automatic Workflow (PR-based)

1. **Developer creates PR** with changes to `terraform/demo/vpc/`
2. **Validate workflow** runs and checks syntax
3. **Plan workflow** runs and posts plan output to PR
4. **Reviewer reviews** plan output in PR comments
5. **Reviewer approves** PR
6. **Apply workflow** runs and deploys infrastructure
7. **Apply status** is posted to PR

### Manual Workflow

#### Check Current State vs Code

1. Go to **Actions** tab in GitHub
2. Select **Terraform Plan on PR** workflow
3. Click **Run workflow**
4. Optionally specify:
   - `project`: e.g., `demo` (leave empty to auto-detect from changes)
   - `resource`: e.g., `vpc` (leave empty to check all changed resources)
   - `environment`: e.g., `dev`
5. Click **Run workflow**
6. View plan results in commit comments or workflow logs

**Examples:**
- Check all changed resources: Leave `project` and `resource` empty
- Check specific resource: `project=demo`, `resource=vpc`
- Check all resources in a project: `project=demo`, leave `resource` empty

#### Manually Apply Changes

1. Go to **Actions** tab in GitHub
2. Select **Terraform Apply on Approval** workflow
3. Click **Run workflow**
4. Specify:
   - `project`: e.g., `demo` (required)
   - `resource`: e.g., `vpc` (required)
   - `environment`: e.g., `dev`
   - `auto_approve`: `true` (to auto-approve, use with caution)
5. Click **Run workflow**
6. View apply status in commit comments or workflow logs

**Examples:**
- Apply demo/vpc: `project=demo`, `resource=vpc`, `auto_approve=true`
- Apply apiadmin/api: `project=apiadmin`, `resource=api`, `environment=staging`

## Customization

### Environment Variables

Edit workflow files to customize:
- `AWS_REGION` - Default AWS region
- `TF_VERSION` - Terraform version to use

### Backend Configuration

If using remote state backend:
1. Create `backend.hcl` file in each resource directory
2. Add backend configuration to `.gitignore`
3. Workflows will automatically use `backend.hcl` if present

### Resource Detection

The change detection logic can be customized in the `detect-changes` job:
- Modify the `grep` pattern to match your directory structure
- Adjust the `sed` command to extract resource names differently

## Troubleshooting

### Plan/Apply Fails

1. Check AWS credentials are configured correctly
2. Verify backend configuration (if using remote state)
3. Review workflow logs for detailed error messages

### No Resources Detected

1. Ensure changes are in `terraform/demo/<resource>/` directories
2. Check that `.tf` or `.tfvars` files are modified
3. Verify PR includes the changes

### Comments Not Posted

1. Ensure `GITHUB_TOKEN` has write permissions
2. Check that PR is not from a fork (may have permission issues)
3. Review workflow logs for API errors
