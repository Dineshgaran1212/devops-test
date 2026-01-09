#!/bin/bash
#
# Validation Script for Target Application Deployment
# This script validates that all requirements are met
#

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
TOTAL=0

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Assessment Validation Script${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

check_passed() {
    ((PASSED++))
    ((TOTAL++))
    echo -e "${GREEN}✓${NC} $1"
}

check_failed() {
    ((FAILED++))
    ((TOTAL++))
    echo -e "${RED}✗${NC} $1"
}

check_warning() {
    ((TOTAL++))
    echo -e "${YELLOW}⚠${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}--- $1 ---${NC}"
}

validate_files() {
    print_section "File Structure Validation"
    
    # Dockerfile
    if [ -f "Dockerfile" ]; then
        check_passed "Dockerfile exists"
        if grep -q "FROM python:3.9" Dockerfile; then
            check_passed "Dockerfile uses production-ready base image"
        else
            check_failed "Dockerfile doesn't use recommended Python version"
        fi
    else
        check_failed "Dockerfile not found"
    fi
    
    # Helm Chart
    if [ -d "helm/target-app" ]; then
        check_passed "Helm chart directory exists"
        
        if [ -f "helm/target-app/Chart.yaml" ]; then
            check_passed "Chart.yaml exists"
        else
            check_failed "Chart.yaml not found"
        fi
        
        if [ -f "helm/target-app/values.yaml" ]; then
            check_passed "values.yaml exists"
        else
            check_failed "values.yaml not found"
        fi
        
        # Check for required templates
        required_templates=(
            "deployment-web.yaml"
            "statefulset-mysql.yaml"
            "service-web.yaml"
            "service-mysql.yaml"
            "ingress.yaml"
            "secrets.yaml"
        )
        
        for template in "${required_templates[@]}"; do
            if [ -f "helm/target-app/templates/$template" ]; then
                check_passed "Template $template exists"
            else
                check_failed "Template $template not found"
            fi
        done
    else
        check_failed "Helm chart directory not found"
    fi
    
    # CI/CD Files
    if [ -f ".gitlab-ci.yml" ]; then
        check_passed ".gitlab-ci.yml exists"
        if grep -q "build:docker" .gitlab-ci.yml; then
            check_passed "CI/CD pipeline has build stage"
        fi
        if grep -q "deploy:production" .gitlab-ci.yml; then
            check_passed "CI/CD pipeline has deploy stage"
        fi
    else
        check_failed ".gitlab-ci.yml not found"
    fi
    
    if [ -f "pipeline/deploy.sh" ]; then
        check_passed "Deployment script exists"
        if [ -x "pipeline/deploy.sh" ]; then
            check_passed "Deployment script is executable"
        else
            check_warning "Deployment script is not executable (run: chmod +x pipeline/deploy.sh)"
        fi
    else
        check_failed "pipeline/deploy.sh not found"
    fi
    
    # Documentation
    docs=("DEPLOYMENT.md" "CI-CD-GUIDE.md" "ARCHITECTURE.md" "README.md")
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            check_passed "Documentation: $doc exists"
        else
            check_warning "Documentation: $doc not found"
        fi
    done
}

validate_helm_chart() {
    print_section "Helm Chart Validation"
    
    if command -v helm &> /dev/null; then
        check_passed "Helm is installed"
        
        # Lint the chart
        if helm lint helm/target-app &> /dev/null; then
            check_passed "Helm chart passes lint check"
        else
            check_failed "Helm chart has lint errors"
            helm lint helm/target-app
        fi
        
        # Test template rendering
        if helm template test helm/target-app &> /dev/null; then
            check_passed "Helm templates render successfully"
        else
            check_failed "Helm templates have errors"
        fi
        
        # Check for Ingress with correct domain
        if helm template test helm/target-app | grep -q "target.example.com"; then
            check_passed "Ingress configured with target.example.com"
        else
            check_failed "Ingress not configured with required domain"
        fi
    else
        check_warning "Helm not installed - skipping Helm validation"
    fi
}

validate_dockerfile() {
    print_section "Dockerfile Validation"
    
    if command -v docker &> /dev/null; then
        check_passed "Docker is installed"
        
        # Try to build the image
        echo "Building Docker image (this may take a while)..."
        if docker build -t target-app-test:validation . &> /dev/null; then
            check_passed "Docker image builds successfully"
            
            # Check image size
            size=$(docker images target-app-test:validation --format "{{.Size}}")
            check_passed "Docker image size: $size"
            
            # Cleanup
            docker rmi target-app-test:validation &> /dev/null || true
        else
            check_failed "Docker build failed"
        fi
    else
        check_warning "Docker not installed - skipping Docker validation"
    fi
}

validate_kubernetes_manifests() {
    print_section "Kubernetes Manifests Validation"
    
    if command -v kubectl &> /dev/null; then
        check_passed "kubectl is installed"
        
        # Render templates and validate
        if helm template test helm/target-app > /tmp/manifests.yaml 2>/dev/null; then
            if kubectl apply --dry-run=client -f /tmp/manifests.yaml &> /dev/null; then
                check_passed "Kubernetes manifests are valid"
            else
                check_failed "Kubernetes manifests have errors"
            fi
            rm -f /tmp/manifests.yaml
        fi
    else
        check_warning "kubectl not installed - skipping K8s validation"
    fi
}

check_requirements() {
    print_section "Requirement Checklist"
    
    # Requirement 1: Containerization
    if [ -f "Dockerfile" ]; then
        check_passed "REQ 1: Application is containerized (Dockerfile exists)"
    else
        check_failed "REQ 1: Application containerization missing"
    fi
    
    # Requirement 2: Kubernetes deployment files
    if [ -d "helm/target-app" ]; then
        check_passed "REQ 2: Kubernetes deployment files exist (Helm chart)"
    else
        check_failed "REQ 2: Kubernetes deployment files missing"
    fi
    
    # Requirement 3: Helm Chart
    if [ -f "helm/target-app/Chart.yaml" ] && [ -f "helm/target-app/values.yaml" ]; then
        check_passed "REQ 3: Helm chart is complete"
    else
        check_failed "REQ 3: Helm chart is incomplete"
    fi
    
    # Requirement 4: Network accessibility
    if [ -f "helm/target-app/templates/ingress.yaml" ]; then
        if grep -q "target.example.com" helm/target-app/templates/ingress.yaml; then
            check_passed "REQ 4: Ingress configured for target.example.com"
        else
            check_failed "REQ 4: Ingress not configured with correct domain"
        fi
    else
        check_failed "REQ 4: Ingress not found"
    fi
    
    # Requirement 5: CI/CD Pipeline
    if [ -f ".gitlab-ci.yml" ] || [ -f "pipeline/deploy.sh" ]; then
        check_passed "REQ 5: CI/CD pipeline exists"
    else
        check_failed "REQ 5: CI/CD pipeline missing"
    fi
}

print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Validation Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total Checks: ${TOTAL}"
    echo -e "${GREEN}Passed: ${PASSED}${NC}"
    echo -e "${RED}Failed: ${FAILED}${NC}"
    echo ""
    
    PASS_RATE=$((PASSED * 100 / TOTAL))
    
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ ALL CHECKS PASSED! (100%)${NC}"
        echo -e "${GREEN}The solution is ready for submission!${NC}"
        return 0
    elif [ $PASS_RATE -ge 80 ]; then
        echo -e "${YELLOW}⚠ MOST CHECKS PASSED (${PASS_RATE}%)${NC}"
        echo -e "${YELLOW}Review failed checks before submission.${NC}"
        return 1
    else
        echo -e "${RED}✗ VALIDATION FAILED (${PASS_RATE}%)${NC}"
        echo -e "${RED}Please fix the issues before submission.${NC}"
        return 1
    fi
}

# Main execution
main() {
    print_header
    validate_files
    validate_helm_chart
    validate_dockerfile
    validate_kubernetes_manifests
    check_requirements
    print_summary
}

main
exit $?
