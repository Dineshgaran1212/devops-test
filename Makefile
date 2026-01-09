# Makefile for Target Application
# Provides convenient commands for building, testing, and deploying

.PHONY: help build push deploy clean test lint helm-lint docker-build docker-push

# Variables
APP_NAME := target-web-app
DOCKER_REGISTRY ?= docker.io/your-registry
IMAGE_TAG ?= latest
IMAGE := $(DOCKER_REGISTRY)/$(APP_NAME):$(IMAGE_TAG)
HELM_CHART := ./helm/target-app
NAMESPACE ?= production
RELEASE_NAME ?= target-app

# Colors for output
COLOR_RESET := \033[0m
COLOR_INFO := \033[36m
COLOR_SUCCESS := \033[32m
COLOR_WARNING := \033[33m

help: ## Display this help message
	@echo "$(COLOR_INFO)Available targets:$(COLOR_RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(COLOR_SUCCESS)%-20s$(COLOR_RESET) %s\n", $$1, $$2}'

build: docker-build ## Build Docker image

docker-build: ## Build Docker image
	@echo "$(COLOR_INFO)Building Docker image: $(IMAGE)$(COLOR_RESET)"
	docker build -t $(IMAGE) -t $(DOCKER_REGISTRY)/$(APP_NAME):latest .
	@echo "$(COLOR_SUCCESS)✓ Docker image built successfully$(COLOR_RESET)"

docker-push: ## Push Docker image to registry
	@echo "$(COLOR_INFO)Pushing Docker image: $(IMAGE)$(COLOR_RESET)"
	docker push $(IMAGE)
	docker push $(DOCKER_REGISTRY)/$(APP_NAME):latest
	@echo "$(COLOR_SUCCESS)✓ Docker image pushed successfully$(COLOR_RESET)"

push: docker-push ## Push Docker image (alias)

test: ## Run tests
	@echo "$(COLOR_INFO)Running tests...$(COLOR_RESET)"
	docker run --rm $(IMAGE) pytest || true
	@echo "$(COLOR_SUCCESS)✓ Tests completed$(COLOR_RESET)"

lint: ## Lint Python code
	@echo "$(COLOR_INFO)Linting Python code...$(COLOR_RESET)"
	cd code && python -m flake8 . || true
	cd code && python -m pylint *.py || true
	@echo "$(COLOR_SUCCESS)✓ Linting completed$(COLOR_RESET)"

helm-lint: ## Lint Helm chart
	@echo "$(COLOR_INFO)Linting Helm chart...$(COLOR_RESET)"
	helm lint $(HELM_CHART)
	@echo "$(COLOR_SUCCESS)✓ Helm chart is valid$(COLOR_RESET)"

helm-template: ## Render Helm templates
	@echo "$(COLOR_INFO)Rendering Helm templates...$(COLOR_RESET)"
	helm template $(RELEASE_NAME) $(HELM_CHART) \
		--set web.image.repository=$(DOCKER_REGISTRY)/$(APP_NAME) \
		--set web.image.tag=$(IMAGE_TAG)

helm-install: ## Install application using Helm
	@echo "$(COLOR_INFO)Installing application with Helm...$(COLOR_RESET)"
	kubectl create namespace $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -
	helm upgrade --install $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--set web.image.repository=$(DOCKER_REGISTRY)/$(APP_NAME) \
		--set web.image.tag=$(IMAGE_TAG) \
		--wait \
		--timeout 5m
	@echo "$(COLOR_SUCCESS)✓ Application installed successfully$(COLOR_RESET)"

deploy: helm-install ## Deploy application (alias)

helm-upgrade: ## Upgrade existing Helm release
	@echo "$(COLOR_INFO)Upgrading Helm release...$(COLOR_RESET)"
	helm upgrade $(RELEASE_NAME) $(HELM_CHART) \
		--namespace $(NAMESPACE) \
		--set web.image.repository=$(DOCKER_REGISTRY)/$(APP_NAME) \
		--set web.image.tag=$(IMAGE_TAG) \
		--wait
	@echo "$(COLOR_SUCCESS)✓ Application upgraded successfully$(COLOR_RESET)"

helm-uninstall: ## Uninstall Helm release
	@echo "$(COLOR_WARNING)Uninstalling Helm release...$(COLOR_RESET)"
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo "$(COLOR_SUCCESS)✓ Application uninstalled$(COLOR_RESET)"

helm-rollback: ## Rollback Helm release
	@echo "$(COLOR_WARNING)Rolling back Helm release...$(COLOR_RESET)"
	helm rollback $(RELEASE_NAME) --namespace $(NAMESPACE)
	@echo "$(COLOR_SUCCESS)✓ Rollback completed$(COLOR_RESET)"

status: ## Check deployment status
	@echo "$(COLOR_INFO)Deployment status:$(COLOR_RESET)"
	kubectl get all -n $(NAMESPACE)
	@echo ""
	@echo "$(COLOR_INFO)Helm status:$(COLOR_RESET)"
	helm status $(RELEASE_NAME) -n $(NAMESPACE)

logs: ## View application logs
	@echo "$(COLOR_INFO)Viewing application logs...$(COLOR_RESET)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/component=web -f

logs-db: ## View database logs
	@echo "$(COLOR_INFO)Viewing database logs...$(COLOR_RESET)"
	kubectl logs -n $(NAMESPACE) -l app.kubernetes.io/component=database -f

port-forward: ## Port forward to application
	@echo "$(COLOR_INFO)Port forwarding to application on localhost:8080$(COLOR_RESET)"
	kubectl port-forward -n $(NAMESPACE) svc/$(RELEASE_NAME)-web 8080:80

shell: ## Get shell in application pod
	@echo "$(COLOR_INFO)Opening shell in application pod...$(COLOR_RESET)"
	kubectl exec -it -n $(NAMESPACE) $$(kubectl get pod -n $(NAMESPACE) -l app.kubernetes.io/component=web -o jsonpath='{.items[0].metadata.name}') -- /bin/bash

clean: ## Clean up local Docker images
	@echo "$(COLOR_WARNING)Cleaning up Docker images...$(COLOR_RESET)"
	docker rmi $(IMAGE) || true
	docker rmi $(DOCKER_REGISTRY)/$(APP_NAME):latest || true
	@echo "$(COLOR_SUCCESS)✓ Cleanup completed$(COLOR_RESET)"

all: build push deploy ## Build, push, and deploy

scan: ## Scan Docker image for vulnerabilities
	@echo "$(COLOR_INFO)Scanning Docker image for vulnerabilities...$(COLOR_RESET)"
	docker scan $(IMAGE) || trivy image $(IMAGE) || echo "Install Docker scan or Trivy for vulnerability scanning"

minikube-setup: ## Setup Minikube for local testing
	@echo "$(COLOR_INFO)Setting up Minikube...$(COLOR_RESET)"
	minikube start
	minikube addons enable ingress
	@echo "$(COLOR_SUCCESS)✓ Minikube setup completed$(COLOR_RESET)"
	@echo "$(COLOR_WARNING)Add to /etc/hosts:$(COLOR_RESET)"
	@echo "$$(minikube ip) target.example.com"
