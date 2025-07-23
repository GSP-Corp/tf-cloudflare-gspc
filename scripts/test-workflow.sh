#!/bin/bash

# Local testing script for GitHub Actions Terraform workflow
# This script helps test the workflow components locally before pushing to GitHub

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
TF_DIR="$PROJECT_ROOT"
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

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if terraform is installed
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform $TERRAFORM_VERSION"
        exit 1
    fi

    # Check terraform version
    CURRENT_VERSION=$(terraform version -json | jq -r '.terraform_version')
    log_info "Current Terraform version: $CURRENT_VERSION"

    # Check if .env file exists
    if [ ! -f "$PROJECT_ROOT/.env" ]; then
        log_warning ".env file not found. Creating from template..."
        cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
        log_warning "Please edit .env file with your actual values before running tests"
    fi

    # Check if environment variables are set
    if [ -f "$PROJECT_ROOT/.env" ]; then
        source "$PROJECT_ROOT/.env"
    fi

    if [ -z "$CLOUDFLARE_API_TOKEN" ]; then
        log_error "CLOUDFLARE_API_TOKEN is not set. Please set it in .env file"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

terraform_fmt_check() {
    log_info "Running Terraform format check..."
    cd "$TF_DIR"

    if terraform fmt -check -recursive; then
        log_success "Terraform format check passed"
        return 0
    else
        log_error "Terraform format check failed"
        log_info "Run 'terraform fmt -recursive' to fix formatting issues"
        return 1
    fi
}

terraform_init() {
    log_info "Running Terraform init..."
    cd "$TF_DIR"

    if terraform init; then
        log_success "Terraform init completed"
        return 0
    else
        log_error "Terraform init failed"
        return 1
    fi
}

terraform_validate() {
    log_info "Running Terraform validate..."
    cd "$TF_DIR"

    if terraform validate; then
        log_success "Terraform validate passed"
        return 0
    else
        log_error "Terraform validate failed"
        return 1
    fi
}

terraform_plan() {
    log_info "Running Terraform plan..."
    cd "$TF_DIR"

    if terraform plan -out=tfplan; then
        log_success "Terraform plan completed"
        return 0
    else
        log_error "Terraform plan failed"
        return 1
    fi
}

security_scan() {
    log_info "Running security scan with Checkov..."

    # Check if checkov is installed
    if ! command -v checkov &> /dev/null; then
        log_warning "Checkov is not installed. Installing..."
        pip install checkov
    fi

    cd "$TF_DIR"

    if checkov -d . --framework terraform --soft-fail; then
        log_success "Security scan completed"
        return 0
    else
        log_warning "Security scan found issues (soft fail mode)"
        return 0
    fi
}

test_act_workflow() {
    log_info "Testing with act (GitHub Actions local runner)..."

    # Check if act is installed
    if ! command -v act &> /dev/null; then
        log_warning "act is not installed. Please install act to test GitHub Actions locally"
        log_info "Install act: https://github.com/nektos/act"
        return 1
    fi

    cd "$PROJECT_ROOT"

    # Test the workflow
    if act pull_request -n; then
        log_success "act workflow test passed"
        return 0
    else
        log_error "act workflow test failed"
        return 1
    fi
}

cleanup() {
    log_info "Cleaning up..."
    cd "$TF_DIR"

    # Remove plan file
    [ -f "tfplan" ] && rm -f tfplan

    # Remove log files
    [ -f "terraform.log" ] && rm -f terraform.log

    log_success "Cleanup completed"
}

run_all_tests() {
    log_info "Running all tests..."

    local exit_code=0

    check_prerequisites || exit_code=1

    if [ $exit_code -eq 0 ]; then
        terraform_fmt_check || exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        terraform_init || exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        terraform_validate || exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        terraform_plan || exit_code=1
    fi

    if [ $exit_code -eq 0 ]; then
        security_scan || exit_code=1
    fi

    # Optional: Test with act
    # test_act_workflow || exit_code=1

    cleanup

    if [ $exit_code -eq 0 ]; then
        log_success "All tests passed! ✅"
    else
        log_error "Some tests failed! ❌"
    fi

    return $exit_code
}

show_help() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    help        Show this help message
    check       Check prerequisites
    fmt         Run Terraform format check
    init        Run Terraform init
    validate    Run Terraform validate
    plan        Run Terraform plan
    security    Run security scan with Checkov
    act         Test with act (GitHub Actions local runner)
    cleanup     Clean up temporary files
    all         Run all tests (default)

Examples:
    $0 all          # Run all tests
    $0 plan         # Run only Terraform plan
    $0 security     # Run only security scan
    $0 cleanup      # Clean up temporary files

Environment:
    Create a .env file from .env.example and set your Cloudflare API token:
    CLOUDFLARE_API_TOKEN=your_token_here

Prerequisites:
    - Terraform >= $TERRAFORM_VERSION
    - Cloudflare API token
    - checkov (for security scanning)
    - act (optional, for local GitHub Actions testing)

EOF
}

# Main script logic
case "${1:-all}" in
    help|--help|-h)
        show_help
        ;;
    check)
        check_prerequisites
        ;;
    fmt)
        check_prerequisites
        terraform_fmt_check
        ;;
    init)
        check_prerequisites
        terraform_init
        ;;
    validate)
        check_prerequisites
        terraform_init
        terraform_validate
        ;;
    plan)
        check_prerequisites
        terraform_init
        terraform_plan
        ;;
    security)
        check_prerequisites
        security_scan
        ;;
    act)
        test_act_workflow
        ;;
    cleanup)
        cleanup
        ;;
    all)
        run_all_tests
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
