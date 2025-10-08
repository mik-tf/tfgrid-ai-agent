#!/bin/bash
# Remove/delete an agent project on the VM
set -e

echo "🗑️  Removing agent project"
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
    read -p "Enter project name to remove: " PROJECT_NAME
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

# Check if project is running
echo "🔍 Checking project status..."
IS_RUNNING=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
    "pgrep -f 'agent-loop.sh /opt/$PROJECT_NAME' || true" 2>/dev/null)

if [ -n "$IS_RUNNING" ]; then
    echo ""
    echo "⚠️  WARNING: Project '$PROJECT_NAME' is currently running!"
    echo ""
    read -p "Stop the project before removing? (yes/no): " STOP_CONFIRM
    echo ""
    
    if [ "$STOP_CONFIRM" = "yes" ]; then
        echo "🛑 Stopping project..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
            "cd /opt/ai-agent && make stop PROJECT_NAME=$PROJECT_NAME" 2>/dev/null || true
        echo "✅ Project stopped"
        echo ""
    else
        echo "❌ Removal cancelled. Stop the project first with: make stop"
        exit 0
    fi
fi

echo "🗑️  Removing project: $PROJECT_NAME"
echo "=========================================="
echo ""
echo "⚠️  WARNING: This will permanently delete the project!"
read -p "Are you sure? (yes/no): " CONFIRM
echo ""

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Removal cancelled"
    exit 0
fi

# Remove project on VM
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
    "cd /opt/ai-agent && make remove PROJECT_NAME=$PROJECT_NAME"

echo ""
echo "✅ Project '$PROJECT_NAME' removed successfully!"
