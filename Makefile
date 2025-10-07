.PHONY: help init deploy quick infrastructure ansible wireguard wg inventory wait-ssh address connect ping clean verify \
        login create run stop monitor list git-setup git-key \
        login-qwen create-project run-project monitor-project stop-project list-projects git-show-key

# Default target
all: deploy

# Help target
help:
	@echo "ThreeFold Grid AI-Agent - AI Coding on TFGrid"
	@echo "==========================================="
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make init                - Initialize .env with smart defaults"
	@echo "  make deploy              - Complete deployment (infrastructure + ansible)"
	@echo "  make login               - Login to Qwen on VM (interactive)"
	@echo "  make create project=my-app  - Create new agent project"
	@echo "  make run project=my-app     - Start agent loop"
	@echo ""
	@echo "📋 Infrastructure Commands:"
	@echo "  make infrastructure      - Deploy VM on ThreeFold Grid"
	@echo "  make quick               - Retry config (wireguard + inventory + ansible)"
	@echo "  make wireguard (or wg)   - Setup WireGuard connection"
	@echo "  make inventory           - Generate Ansible inventory"
	@echo "  make wait-ssh            - Wait for SSH to become ready"
	@echo "  make ansible             - Configure VM with Ansible"
	@echo "  make clean               - Destroy all infrastructure"
	@echo "  make verify              - Verify deployment status"
	@echo ""
	@echo "🌐 Network & Connectivity:"
	@echo "  make address             - Show all VM addresses"
	@echo "  make connect             - SSH to AI agent VM"
	@echo "  make ping                - Test VM connectivity"
	@echo ""
	@echo "🤖 AI Agent Operations:"
	@echo "  make login                - Login to Qwen (interactive)"
	@echo "  make create project=name  - Create new project"
	@echo "  make run project=name     - Start agent loop"
	@echo "  make monitor project=name - Monitor progress"
	@echo "  make stop project=name    - Stop agent loop"
	@echo "  make list                 - List all projects"
	@echo ""
	@echo "🔧 Git Configuration:"
	@echo "  make git-setup project=<name> provider=github  - Setup GitHub remote"
	@echo "  make git-setup project=<name> provider=gitea   - Setup Gitea remote"
	@echo "  make git-setup project=<name> provider=<url>   - Setup custom remote"
	@echo "  make git-show-key                              - Show git SSH key"
	@echo ""
	@echo "See docs/ for more information"

# Initialize .env with smart defaults
init:
	@bash scripts/init-env.sh

# Complete deployment
deploy: infrastructure wireguard inventory wait-ssh ansible
	@echo "✅ Deployment complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Login to Qwen: make login"
	@echo "  2. Create project: make create project=my-app"
	@echo "  3. Run Agent: make run project=my-app"

# Deploy infrastructure
infrastructure:
	@./scripts/infrastructure.sh

# Setup WireGuard
wireguard:
	@./scripts/wg.sh

# Alias for wireguard
wg: wireguard

# Generate Ansible inventory
inventory:
	@./scripts/generate_inventory.sh

# Wait for SSH to be ready
wait-ssh:
	@./scripts/wait-for-ssh.sh

# Configure VM with Ansible
ansible:
	@echo "🔧 Configuring AI agent VM with Ansible..."
	@cd platform && ansible-playbook -i inventory.ini site.yml

# Quick retry (skip infrastructure deployment)
quick: wireguard inventory wait-ssh ansible
	@echo "✅ Configuration complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Login to Qwen: make login"
	@echo "  2. Create project: make create project=my-app"
	@echo "  3. Run Agent: make run project=my-app"

# Show all addresses
address:
	@./scripts/address.sh

# SSH to VM
connect:
	@./scripts/connect.sh

# Test connectivity
ping:
	@./scripts/ping.sh

# Clean up deployment
clean:
	@./scripts/clean.sh

# Verify deployment
verify:
	@./scripts/verify.sh

# Login to Qwen
login:
	@./scripts/qwen-login.sh

# Create AI agent project
create:
	@./scripts/agent-create-project.sh $(project)

# Run AI agent project
run:
	@./scripts/agent-run-project.sh $(project)

# Monitor AI agent project
monitor:
	@./scripts/agent-monitor-project.sh $(project)

# Stop agent project
stop:
	@./scripts/agent-stop-project.sh $(project)

# List all projects
list:
	@./scripts/agent-list-projects.sh

# Setup git remote
git-setup:
	@./scripts/agent-git-setup.sh $(project) $(provider) $(user)

# Show git SSH key
git-key:
	@./scripts/address.sh | grep -A 1 "Git SSH Key"

# Legacy aliases for backwards compatibility
login-qwen: login
create-project: create
run-project: run
monitor-project: monitor
stop-project: stop
list-projects: list
git-show-key: git-key
