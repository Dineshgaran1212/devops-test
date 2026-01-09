#!/bin/bash
#
# CI/CD Deployment Script for Target Application
# This script builds the Docker image, pushes it to a registry, and deploys via Helm
#

set -e  # Exit on any error

# Configuration variables
APP_NAME="target-web-app"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-docker.io/your-registry}"
IMAGE_TAG="${CI_COMMIT_SHORT_SHA:-latest}"
HELM_RELEASE_NAME="${HELM_RELEASE_NAME:-target-app}"
KUBERNETES_NAMESPACE="${KUBERNETES_NAMESPACE:-default}"
HELM_CHART_PATH="./helm/target-app"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Build the Docker image
build_image() {
    log_info "Building Docker image: ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}"
    
    docker build \
        -t ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG} \
        -t ${DOCKER_REGISTRY}/${APP_NAME}:latest \
        -f Dockerfile \
        .
    
    if [ $? -eq 0 ]; then
        log_info "Docker image built successfully"
    else
        log_error "Docker build failed"
        exit 1
    fi
}

# Step 2: Run security scan on the image (optional but recommended)
scan_image() {
    log_info "Scanning Docker image for vulnerabilities..."
    
    # Example using Trivy (if available)
    if command -v trivy &> /dev/null; then
        trivy image --severity HIGH,CRITICAL ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}
    else
        log_warn "Trivy not installed, skipping security scan"
    fi
}

# Step 3: Push the image to Docker registry
push_image() {
    log_info "Pushing image to registry: ${DOCKER_REGISTRY}"
    
    # Login to Docker registry (assumes credentials are configured)
    # docker login ${DOCKER_REGISTRY} -u ${DOCKER_USERNAME} -p ${DOCKER_PASSWORD}
    
    docker push ${DOCKER_REGISTRY}/${APP_NAME}:${IMAGE_TAG}
    docker push ${DOCKER_REGISTRY}/${APP_NAME}:latest
    
    if [ $? -eq 0 ]; then
        log_info "Docker image pushed successfully"
    else
        log_error "Docker push failed"
        exit 1
    fi
}

# Step 4: Deploy using Helm
deploy_helm() {
    log_info "Deploying application using Helm"
    
    # Create namespace if it doesn't exist
    kubectl create namespace ${KUBERNETES_NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Upgrade or install the Helm release
    helm upgrade --install ${HELM_RELEASE_NAME} ${HELM_CHART_PATH} \
        --namespace ${KUBERNETES_NAMESPACE} \
        --set web.image.repository=${DOCKER_REGISTRY}/${APP_NAME} \
        --set web.image.tag=${IMAGE_TAG} \
        --wait \
        --timeout 5m
    
    if [ $? -eq 0 ]; then
        log_info "Helm deployment successful"
    else
        log_error "Helm deployment failed"
        exit 1
    fi
}

# Step 5: Verify deployment
verify_deployment() {
    log_info "Verifying deployment..."
    
    kubectl rollout status deployment/${HELM_RELEASE_NAME}-web -n ${KUBERNETES_NAMESPACE} --timeout=300s
    
    log_info "Deployment verification completed"
    log_info "Application pods:"
    kubectl get pods -n ${KUBERNETES_NAMESPACE} -l app.kubernetes.io/component=web
}

# Main execution
main() {
    log_info "Starting CI/CD pipeline for ${APP_NAME}"
    log_info "Image tag: ${IMAGE_TAG}"
    log_info "Target namespace: ${KUBERNETES_NAMESPACE}"
    
    build_image
    scan_image
    push_image
    deploy_helm
    verify_deployment
    
    log_info "CI/CD pipeline completed successfully!"
    log_info "Access the application at: https://target.example.com"
}

# Run main function
main