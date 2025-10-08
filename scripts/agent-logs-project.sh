#!/bin/bash
# View logs for an agent project on the VM
set -e

echo "📋 Viewing project logs"
echo "========================================="

# Load .env to get network preference
if [ -f .env ]; then
    source .env
fi
CONNECTIVITY_NETWORK="${CONNECTIVITY_NETWORK:-wireguard}"

# Get project name from argument or prompt interactively
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo ""
    echo "Available projects (run 'make list' for details):"
    ./scripts/agent-list-projects.sh 2>/dev/null | grep "📁" || echo "  (none)"
    echo ""
    read -p "Enter project name: " PROJECT_NAME
    echo ""
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Project name is required"
    exit 1
fi

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
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip | sed 's|/.*||')
fi

cd ..

# Delegate to ai-agent (it handles all logs display logic)
ssh -t -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
    "cd /opt/ai-agent && make logs PROJECT_NAME=$PROJECT_NAME"
