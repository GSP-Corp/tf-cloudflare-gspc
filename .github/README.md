# GitHub Actions Terraform Workflow for Cloudflare

This repository contains a GitHub Actions workflow for managing Cloudflare resources using Terraform in a GitOps pattern.

## Workflow Overview

The workflow (`terraform-cloudflare.yml`) provides automated Terraform operations with the following features:

### Triggers
- **Pull Requests**: Validates and plans changes
- **Push to main**: Applies changes automatically
- **Manual Dispatch**: Allows manual plan/apply/destroy operations

### Jobs

#### 1. Terraform Validate
- Runs on all triggers
- Performs format checking, initialization, and validation
- Outputs results for other jobs

#### 2. Terraform Plan
- Runs on pull requests and manual dispatch
- Creates execution plan
- Posts plan results as PR comments
- Uploads plan artifact for later use

#### 3. Terraform Apply
- Runs on push to main or manual apply
- Requires production environment approval
- Uses saved plan from PR when available
- Creates deployment summary

#### 4. Terraform Destroy
- Only runs on manual dispatch with destroy action
- Requires production environment approval
- Creates destruction summary

#### 5. Security Scan
- Runs Checkov security scanning
- Uploads results to GitHub Advanced Security

## Setup Instructions

### 1. Required Secrets

Add these secrets to your GitHub repository:

```bash
# Repository Settings > Secrets and variables > Actions
CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
```

### 2. Environment Protection

Set up a `production` environment in your repository:

1. Go to Settings > Environments
2. Create a new environment called `production`
3. Configure protection rules:
   - Required reviewers (recommended)
   - Deployment branches (main only)
   - Environment secrets (if needed)

### 3. Branch Protection

Configure branch protection for `main`:

1. Go to Settings > Branches
2. Add rule for `main` branch
3. Enable:
   - Require pull request reviews
   - Require status checks to pass
   - Require branches to be up to date
   - Include administrators

## Usage

### Development Workflow

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-changes
   ```

2. **Make Terraform Changes**
   - Edit `.tf` files
   - Test locally if needed

3. **Create Pull Request**
   - Workflow runs validation and planning
   - Plan results are posted as PR comment
   - Security scan runs automatically

4. **Review and Merge**
   - Review the plan in PR comments
   - Merge to main when approved

5. **Automatic Deployment**
   - Push to main triggers automatic apply
   - Requires production environment approval

### Manual Operations

#### Manual Plan
```bash
# Go to Actions tab > Terraform Cloudflare GitOps > Run workflow
# Select "plan" action
```

#### Manual Apply
```bash
# Go to Actions tab > Terraform Cloudflare GitOps > Run workflow
# Select "apply" action
```

#### Manual Destroy
```bash
# Go to Actions tab > Terraform Cloudflare GitOps > Run workflow
# Select "destroy" action
```

## Cloudflare Authentication

The workflow uses the Cloudflare API token for authentication. The token is configured in multiple ways:

1. **Environment Variable**: `CLOUDFLARE_API_TOKEN`
2. **Terraform Variable**: `TF_VAR_cloudflare_api_token`

### Creating a Cloudflare API Token

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Custom Token" template
4. Configure permissions:
   - Account: `Cloudflare Tunnel:Edit`
   - Zone: `Zone:Edit`, `DNS:Edit`
   - Include: All accounts or specific account
5. Copy the token and add to GitHub secrets

## Security Features

### Checkov Integration
- Scans Terraform code for security misconfigurations
- Results uploaded to GitHub Advanced Security
- Soft fail mode (won't block deployment)

### Environment Protection
- Production environment requires approval
- Limits who can deploy to production
- Audit trail of all deployments

### Least Privilege
- Workflow only has necessary permissions
- API tokens scoped to required resources

## Monitoring and Troubleshooting

### Workflow Logs
- View detailed logs in Actions tab
- Each step provides specific output
- Terraform plans and applies show full output

### Common Issues

1. **Authentication Errors**
   - Verify `CLOUDFLARE_API_TOKEN` secret is set
   - Check token permissions and expiration

2. **Terraform State Issues**
   - Ensure state file is properly configured
   - Check for state locking conflicts

3. **Plan/Apply Mismatches**
   - May occur if changes happen between plan and apply
   - Manual apply will create new plan

### Best Practices

1. **Small Changes**: Make incremental changes for easier review
2. **Test Locally**: Use `terraform plan` locally before pushing
3. **Review Plans**: Always review plan output in PR comments
4. **Monitor Deployments**: Watch deployment logs for issues
5. **Regular Updates**: Keep Terraform and providers updated

## Customization

### Terraform Version
Update the `TF_VERSION` environment variable in the workflow file.

### Working Directory
Modify `TF_WORKING_DIR` if your Terraform files are in a different location.

### Triggers
Adjust the `on` section to change when the workflow runs.

### Security Scanning
Configure Checkov rules by adding a `.checkov.yml` file to your repository.

## Support

For issues with this workflow:
1. Check the Actions logs for specific error messages
2. Verify all secrets and environment settings
3. Review Terraform and Cloudflare documentation
4. Check GitHub Actions documentation for workflow syntax