# Cloudflare Terraform with GitHub Actions GitOps

This repository contains Terraform configuration for managing Cloudflare resources with a complete GitOps workflow using GitHub Actions.

## 🚀 Features

- **Automated Terraform Operations**: Plan, apply, and destroy operations via GitHub Actions
- **GitOps Workflow**: Infrastructure changes managed through pull requests
- **Security Scanning**: Automated security checks with Checkov
- **Environment Protection**: Production deployments require approval
- **PR Comments**: Terraform plan results automatically posted to pull requests
- **Manual Operations**: Support for manual plan/apply/destroy operations
- **Local Testing**: Scripts for testing workflow components locally

## 📋 Prerequisites

- GitHub repository with Actions enabled
- Cloudflare account with API token
- Terraform >= 1.7.0 (for local development)

## 🔧 Quick Setup

### 1. Automated Setup

Run the setup script to configure your environment:

```bash
./scripts/setup.sh
```

This script will:
- Install Terraform (if needed)
- Create environment configuration
- Set up Git hooks
- Install optional tools (checkov, act)
- Guide you through GitHub repository setup

### 2. Manual Setup

If you prefer manual setup:

1. **Copy environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file with your Cloudflare API token:**
   ```bash
   CLOUDFLARE_API_TOKEN=your_cloudflare_api_token_here
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Validate configuration:**
   ```bash
   terraform validate
   ```

### 3. GitHub Repository Configuration

#### Required Secrets
Add these secrets in GitHub repository settings:

- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token

#### Environment Protection
1. Go to Settings > Environments
2. Create environment: `production`
3. Add protection rules (required reviewers recommended)

#### Branch Protection
1. Go to Settings > Branches
2. Add rule for `main` branch
3. Enable required status checks

## 🔑 Cloudflare API Token

Create a Cloudflare API token with these permissions:

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Click "Create Token"
3. Use "Custom Token" template
4. Configure permissions:
   - **Zone**: `Zone:Edit`, `DNS:Edit`
   - **Account**: `Account:Read` (optional)
5. Include all accounts or specific account
6. Copy token and add to GitHub secrets

## 🏗️ Project Structure

```
tf-cloudflare-gspc/
├── .github/
│   ├── workflows/
│   │   └── terraform-cloudflare.yml  # Main workflow
│   └── README.md                     # Workflow documentation
├── scripts/
│   ├── setup.sh                      # Setup script
│   └── test-workflow.sh              # Local testing
├── main.tf                           # Main Terraform configuration
├── variables.tf                      # Variable definitions
├── versions.tf                       # Provider versions
├── zone.tf                           # Zone configuration
├── zt.tf                             # Zero Trust configuration
├── .env.example                      # Environment template
├── .checkov.yml                      # Security scan config
├── .gitignore                        # Git ignore rules
└── README.md                         # This file
```

## 🔄 GitOps Workflow

### Development Process

1. **Create feature branch:**
   ```bash
   git checkout -b feature/my-changes
   ```

2. **Make Terraform changes:**
   ```bash
   # Edit .tf files
   terraform fmt
   terraform validate
   ```

3. **Create pull request:**
   - GitHub Actions runs validation and planning
   - Plan results posted as PR comment
   - Security scan runs automatically

4. **Review and merge:**
   - Review plan output in PR comments
   - Address any security findings
   - Merge when approved

5. **Automatic deployment:**
   - Push to `main` triggers apply
   - Requires production environment approval

### Manual Operations

#### Run Manual Plan
```bash
# Via GitHub Actions
# Go to Actions > Run workflow > Select "plan"
```

#### Run Manual Apply
```bash
# Via GitHub Actions
# Go to Actions > Run workflow > Select "apply"
```

#### Run Manual Destroy
```bash
# Via GitHub Actions
# Go to Actions > Run workflow > Select "destroy"
```

## 🧪 Local Testing

### Test All Components
```bash
./scripts/test-workflow.sh
```

### Test Specific Components
```bash
./scripts/test-workflow.sh fmt      # Format check
./scripts/test-workflow.sh plan     # Terraform plan
./scripts/test-workflow.sh security # Security scan
```

### Test with act (GitHub Actions locally)
```bash
# Install act: https://github.com/nektos/act
act pull_request
```

## 🔒 Security Features

### Checkov Integration
- Automated security scanning
- Results uploaded to GitHub Advanced Security
- Configurable via `.checkov.yml`

### Environment Protection
- Production deployments require approval
- Audit trail of all changes
- Reviewer requirements

### Secret Management
- API tokens stored as GitHub secrets
- No secrets in code or logs
- Least privilege access

## 🛠️ Current Resources

This configuration manages:

- **Cloudflare Zone**: `gspc.digital`
- **DNS Records**: Various DNS configurations
- **Zero Trust**: Network security settings
- **Zone Settings**: Security and performance settings

## 📊 Monitoring

### Workflow Status
- View workflow runs in GitHub Actions tab
- Detailed logs for each step
- Email notifications on failures

### Security Alerts
- Checkov scan results in Security tab
- Dependabot alerts for dependencies
- Code scanning results

## 🔧 Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify `CLOUDFLARE_API_TOKEN` secret
   - Check token permissions and expiration

2. **Terraform State Issues**
   - Ensure state file is accessible
   - Check for state locking conflicts

3. **Plan/Apply Mismatches**
   - May occur if changes happen between plan and apply
   - Manual apply will create new plan

4. **Security Scan Failures**
   - Review Checkov results
   - Update configuration or add suppressions

### Debug Commands

```bash
# Local debugging
terraform plan -var-file=terraform.tfvars
terraform validate
checkov -d . --framework terraform

# Check API connectivity
curl -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
```

## 🚀 Best Practices

1. **Small Changes**: Make incremental changes for easier review
2. **Test Locally**: Run `./scripts/test-workflow.sh` before pushing
3. **Review Plans**: Always review plan output in PR comments
4. **Monitor Deployments**: Watch workflow runs for issues
5. **Keep Updated**: Regularly update Terraform and providers
6. **Document Changes**: Use clear commit messages and PR descriptions

## 📚 Resources

- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Checkov Documentation](https://www.checkov.io/)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests locally
5. Submit a pull request
6. Address review feedback

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check workflow logs in GitHub Actions
2. Review troubleshooting section
3. Check Terraform and Cloudflare documentation
4. Create an issue in this repository

---

**Note**: This is a production-ready GitOps setup. Always review changes carefully before merging to main branch.