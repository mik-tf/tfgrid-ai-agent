.PHONY: help deploy infrastructure ansible wireguard wg inventory address connect ping clean verify login-qwen create-project run-project monitor-project stop-project list-projects git-setup git-show-key

# Default target
all: deploy

# Help target
help:
	@echo "ThreeFold Grid AI-Agent - AI Coding on TFGrid"
	@echo "==========================================="
	@echo ""
	@echo "🚀 Quick Start:"
	@echo "  make deploy              - Complete deployment (infrastructure + ansible)"
	@echo "  make login-qwen          - Login to Qwen on VM (interactive)"
	@echo "  make create-project project=my-app  - Create new agent project"
	@echo "  make run-project project=my-app     - Start agent loop"
	@echo ""
	@echo "📋 Infrastructure Commands:"
	@echo "  make infrastructure      - Deploy VM on ThreeFold Grid"
	@echo "  make wireguard (or wg)   - Setup WireGuard connection"
	@echo "  make inventory           - Generate Ansible inventory"
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
	@echo "  make login-qwen                     - Login to Qwen (interactive)"
	@echo "  make create-project project=<name>  - Create new project"
	@echo "  make run-project project=<name>     - Start agent loop"
	@echo "  make monitor-project project=<name> - Monitor progress"
	@echo "  make stop-project project=<name>    - Stop agent loop"
	@echo "  make list-projects                  - List all projects"
	@echo ""
	@echo "🔧 Git Configuration:"
	@echo "  make git-setup project=<name> provider=github  - Setup GitHub remote"
	@echo "  make git-setup project=<name> provider=gitea   - Setup Gitea remote"
	@echo "  make git-setup project=<name> provider=<url>   - Setup custom remote"
	@echo "  make git-show-key                              - Show git SSH key"
	@echo ""
	@echo "📖 Configuration:"
	@echo "  1. Copy .env.example to .env and edit"
	@echo "  2. Set mnemonic: set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)"
	@echo "  3. Run: make deploy"
	@echo ""
	@echo "🔗 Documentation:"
	@echo "  README.md           - Main documentation"
	@echo "  docs/QUICKSTART.md  - Quick start guide"
	@echo "  docs/ARCHITECTURE.md - System architecture"

# Complete deployment
deploy: infrastructure wireguard inventory ansible
	@echo ""
	@echo "✅ Deployment complete!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Login to Qwen: make login-qwen"
	@echo "  2. Create project: make create-project project=my-app"
	@echo "  3. Run Agent: make run-project project=my-app"

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

# Configure VM with Ansible
ansible:
	@echo "🔧 Configuring AI agent VM with Ansible..."
	@cd platform && ansible-playbook -i inventory.ini site.yml

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
login-qwen:
	@./scripts/qwen-login.sh

# Create AI agent project
create-project:
	@./scripts/agent-create-project.sh $(project)

# Run AI agent project
run-project:
	@./scripts/agent-run-project.sh $(project)

# Monitor AI agent project
monitor-project:
	@./scripts/agent-monitor-project.sh $(project)

# Stop agent project
stop-project:
	@./scripts/agent-stop-project.sh $(project)

# List all projects
list-projects:
	@./scripts/agent-list-projects.sh

# Setup git remote
git-setup:
	@./scripts/agent-git-setup.sh $(project) $(provider) $(user)

# Show git SSH key
git-show-key:
	@./scripts/address.sh | grep -A 1 "Git SSH Key"
