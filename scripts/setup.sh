#!/bin/bash

# Setup script for Cloudflare Terraform GitHub Actions workflow
# This script helps with initial configuration and setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_VERSION="1.7.0"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo ""
    echo "=============================================="
    echo "  Cloudflare Terraform GitHub Actions Setup"
    echo "=============================================="
    echo ""
}

check_system() {
    log_info "Checking system requirements..."

    # Check OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    log_info "Operating system: $OS"

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_error "Git is not installed. Please install Git first."
        exit 1
    fi

    log_success "System requirements check passed"
}

install_terraform() {
    log_info "Checking Terraform installation..."

    if command -v terraform &> /dev/null; then
        CURRENT_VERSION=$(terraform version -json 2>/dev/null | jq -r '.terraform_version' 2>/dev/null || terraform version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        log_info "Terraform is already installed (version: $CURRENT_VERSION)"

        # Check if version is recent enough
        if [[ "$CURRENT_VERSION" < "$TERRAFORM_VERSION" ]]; then
            log_warning "Terraform version $CURRENT_VERSION is older than recommended $TERRAFORM_VERSION"
            read -p "Would you like to update Terraform? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_terraform_binary
            fi
        else
            log_success "Terraform version is up to date"
        fi
    else
        log_info "Terraform not found. Installing..."
        install_terraform_binary
    fi
}

install_terraform_binary() {
    log_info "Installing Terraform..."

    case $OS in
        linux)
            TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
            ;;
        macos)
            TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_darwin_amd64.zip"
            ;;
        windows)
            TERRAFORM_URL="https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_windows_amd64.zip"
            ;;
    esac

    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    # Download and install
    curl -LO "$TERRAFORM_URL"
    unzip "terraform_${TERRAFORM_VERSION}_*.zip"

    # Install to /usr/local/bin or ask for sudo
    if [[ -w /usr/local/bin ]]; then
        mv terraform /usr/local/bin/
    else
        log_info "Installing to /usr/local/bin (requires sudo)..."
        sudo mv terraform /usr/local/bin/
    fi

    # Cleanup
    cd "$PROJECT_ROOT"
    rm -rf "$TEMP_DIR"

    log_success "Terraform $TERRAFORM_VERSION installed successfully"
}

setup_environment() {
    log_info "Setting up environment configuration..."

    # Create .env file from template if it doesn't exist
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        log_success "Created .env file from template"
    else
        log_info ".env file already exists"
    fi

    # Prompt for Cloudflare API token
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
    fi

    if [ -z "$CLOUDFLARE_API_TOKEN" ] || [ "$CLOUDFLARE_API_TOKEN" = "your_cloudflare_api_token_here" ]; then
        echo ""
        log_info "Cloudflare API Token Configuration"
        echo "You need to create a Cloudflare API token with the following permissions:"
        echo "  - Zone: Zone:Edit, DNS:Edit"
        echo "  - Account: Account:Read (optional)"
        echo ""
        echo "Get your token at: https://dash.cloudflare.com/profile/api-tokens"
        echo ""

        read -p "Enter your Cloudflare API token: " -s CLOUDFLARE_API_TOKEN
        echo ""

        if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
            # Update .env file
            if grep -q "CLOUDFLARE_API_TOKEN=" "$PROJECT_ROOT/.env"; then
                sed -i.bak "s/CLOUDFLARE_API_TOKEN=.*/CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN/" "$PROJECT_ROOT/.env"
            else
                echo "CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN" >> "$PROJECT_ROOT/.env"
            fi
            log_success "Cloudflare API token configured"
        else
            log_warning "No API token provided. You'll need to set it manually in .env file"
        fi
    else
        log_success "Cloudflare API token already configured"
    fi
}

setup_git_hooks() {
    log_info "Setting up Git hooks..."

    # Create pre-commit hook
    HOOK_DIR="$PROJECT_ROOT/.git/hooks"
    PRE_COMMIT_HOOK="$HOOK_DIR/pre-commit"

    if [ ! -d "$HOOK_DIR" ]; then
        log_warning "Not in a Git repository. Skipping Git hooks setup."
        return
    fi

    cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash

# Pre-commit hook for Terraform
echo "Running pre-commit checks..."

# Check if Terraform files are formatted
if ! terraform fmt -check -recursive; then
    echo "❌ Terraform files are not formatted. Run 'terraform fmt -recursive' to fix."
    exit 1
fi

# Run validation
cd tf-cloudflare-gspc 2>/dev/null || cd .
if ! terraform validate; then
    echo "❌ Terraform validation failed."
    exit 1
fi

echo "✅ Pre-commit checks passed"
EOF

    chmod +x "$PRE_COMMIT_HOOK"
    log_success "Git pre-commit hook installed"
}

verify_terraform_config() {
    log_info "Verifying Terraform configuration..."

    cd "$PROJECT_ROOT"

    # Load environment variables
    if [ -f ".env" ]; then
        source ".env"
    fi

    # Export for Terraform
    export CLOUDFLARE_API_TOKEN
    export TF_VAR_cloudflare_api_token="$CLOUDFLARE_API_TOKEN"

    # Initialize Terraform
    if terraform init; then
        log_success "Terraform initialization successful"
    else
        log_error "Terraform initialization failed"
        return 1
    fi

    # Validate configuration
    if terraform validate; then
        log_success "Terraform validation successful"
    else
        log_error "Terraform validation failed"
        return 1
    fi

    # Check formatting
    if terraform fmt -check; then
        log_success "Terraform formatting is correct"
    else
        log_warning "Terraform files need formatting. Run 'terraform fmt' to fix."
        terraform fmt
        log_success "Terraform files formatted"
    fi

    # Run plan to verify API connectivity
    if [ -n "$CLOUDFLARE_API_TOKEN" ] && [ "$CLOUDFLARE_API_TOKEN" != "your_cloudflare_api_token_here" ]; then
        log_info "Testing Cloudflare API connectivity..."
        if terraform plan -no-color > /dev/null 2>&1; then
            log_success "Cloudflare API connectivity verified"
        else
            log_error "Cloudflare API connectivity failed. Check your API token."
            return 1
        fi
    else
        log_warning "Skipping API connectivity test (no token configured)"
    fi
}

install_optional_tools() {
    log_info "Installing optional tools..."

    # Install checkov for security scanning
    if ! command -v checkov &> /dev/null; then
        log_info "Installing checkov for security scanning..."
        if command -v pip3 &> /dev/null; then
            pip3 install checkov
            log_success "Checkov installed"
        elif command -v pip &> /dev/null; then
            pip install checkov
            log_success "Checkov installed"
        else
            log_warning "pip not found. Skipping checkov installation."
            log_info "Install checkov manually: pip install checkov"
        fi
    else
        log_success "Checkov already installed"
    fi

    # Install act for local GitHub Actions testing
    if ! command -v act &> /dev/null; then
        log_info "Installing act for local GitHub Actions testing..."
        case $OS in
            linux)
                curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
                ;;
            macos)
                if command -v brew &> /dev/null; then
                    brew install act
                else
                    log_warning "Homebrew not found. Install act manually: https://github.com/nektos/act"
                fi
                ;;
            windows)
                log_warning "Please install act manually: https://github.com/nektos/act"
                ;;
        esac
    else
        log_success "act already installed"
    fi
}

setup_github_repository() {
    log_info "GitHub repository setup guidance..."

    echo ""
    echo "To complete the setup, you need to configure your GitHub repository:"
    echo ""
    echo "1. Repository Secrets:"
    echo "   Go to Settings > Secrets and variables > Actions"
    echo "   Add secret: CLOUDFLARE_API_TOKEN"
    echo ""
    echo "2. Environment Protection:"
    echo "   Go to Settings > Environments"
    echo "   Create environment: production"
    echo "   Add protection rules (required reviewers recommended)"
    echo ""
    echo "3. Branch Protection:"
    echo "   Go to Settings > Branches"
    echo "   Add rule for main branch"
    echo "   Enable: Require pull request reviews"
    echo "   Enable: Require status checks to pass"
    echo ""
    echo "4. Enable GitHub Advanced Security (if available):"
    echo "   Go to Settings > Code security and analysis"
    echo "   Enable: Dependency graph"
    echo "   Enable: Dependabot alerts"
    echo "   Enable: Code scanning"
    echo ""
}

print_next_steps() {
    echo ""
    echo "=============================================="
    echo "  Setup Complete! Next Steps:"
    echo "=============================================="
    echo ""
    echo "1. Review and edit .env file if needed"
    echo "2. Test the setup: ./scripts/test-workflow.sh"
    echo "3. Configure GitHub repository (see guidance above)"
    echo "4. Create a feature branch and test the workflow"
    echo "5. Create a pull request to test the complete GitOps flow"
    echo ""
    echo "Useful commands:"
    echo "  ./scripts/test-workflow.sh     # Test workflow locally"
    echo "  terraform plan                 # Preview changes"
    echo "  terraform apply                # Apply changes"
    echo "  checkov -d .                   # Security scan"
    echo ""
    echo "Documentation:"
    echo "  .github/README.md              # Workflow documentation"
    echo "  .env.example                   # Environment variables"
    echo "  .checkov.yml                   # Security scan configuration"
    echo ""
    log_success "Setup completed successfully! 🎉"
}

# Main setup process
main() {
    print_header

    check_system
    install_terraform
    setup_environment
    setup_git_hooks
    verify_terraform_config
    install_optional_tools
    setup_github_repository
    print_next_steps
}

# Run main function
main "$@"
