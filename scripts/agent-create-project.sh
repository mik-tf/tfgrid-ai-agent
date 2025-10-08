#!/bin/bash
# Create a new agent project on the VM
set -e

echo "🚀 Creating agent project"
echo "========================================="

# Get project name from argument or prompt interactively
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    read -p "Enter project name: " PROJECT_NAME
    echo ""
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Project name is required"
    exit 1
fi

# Load .env to get network preference
if [ -f .env ]; then
    source .env
fi
CONNECTIVITY_NETWORK="${CONNECTIVITY_NETWORK:-wireguard}"

# Check if tofu/terraform is available
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
else
    echo "❌ Error: Neither OpenTofu nor Terraform found"
    exit 1
fi

cd infrastructure

# Check if infrastructure is deployed
if ! $TF_CMD output ai_agent_wg_ip &>/dev/null; then
    echo "❌ Error: Infrastructure not deployed"
    echo "Please run: make deploy"
    exit 1
fi

# Get IP based on connectivity network
if [ "$CONNECTIVITY_NETWORK" = "mycelium" ]; then
    VM_IP=$($TF_CMD output -raw ai_agent_mycelium_ip)
else
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip)
fi

cd ..

echo "🚀 Creating agent project: $PROJECT_NAME"
echo "========================================="

# Check if Qwen is authenticated by checking for settings file
echo "Checking Qwen authentication..."
if ! ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "test -f ~/.qwen/settings.json" 2>/dev/null; then
    echo "❌ Error: Qwen not authenticated on VM"
    echo ""
    echo "Please run: make login"
    exit 1
fi
echo "✅ Qwen is authenticated"

# Check if project already exists
if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP "test -d /opt/$PROJECT_NAME" 2>/dev/null; then
    echo "❌ Error: Project '$PROJECT_NAME' already exists on VM"
    echo ""
    echo "Available projects:"
    ./scripts/agent-list-projects.sh 2>/dev/null | grep "📁" || echo "  (none)"
    exit 1
fi

# Delegate to ai-agent (it handles all project creation logic)
ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
    "cd /opt/ai-agent && make create PROJECT_NAME=$PROJECT_NAME"
