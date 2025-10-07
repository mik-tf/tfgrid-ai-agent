#!/bin/bash
# Run agent loop for a project on the VM
set -e

# Load .env to get network preference
if [ -f .env ]; then
    source .env
fi
CONNECTIVITY_NETWORK="${CONNECTIVITY_NETWORK:-wireguard}"

PROJECT_NAME="$1"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name>"
    echo "Example: $0 my-app"
    echo ""
    echo "Or use: make run-project project=my-app"
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
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip)
fi

cd ..

echo "🚀 Starting agent loop for: $PROJECT_NAME"
echo "=========================================="

# Check if project exists
if ! ssh -o StrictHostKeyChecking=no root@$VM_IP "test -d /opt/ai-agent-projects/$PROJECT_NAME" 2>/dev/null; then
    echo "❌ Error: Project '$PROJECT_NAME' not found on VM"
    echo ""
    echo "Available projects:"
    ssh -o StrictHostKeyChecking=no root@$VM_IP "ls -1 /opt/ai-agent-projects/ 2>/dev/null || echo '  (none)'"
    echo ""
    echo "Create project: make create-project project=$PROJECT_NAME"
    exit 1
fi

# Check if Qwen is authenticated
if ! ssh -o StrictHostKeyChecking=no root@$VM_IP "qwen auth status" &>/dev/null; then
    echo "❌ Error: Qwen not authenticated on VM"
    echo ""
    echo "Please run: make login-qwen"
    exit 1
fi

# Start agent loop on VM
echo "📝 Starting agent loop on VM..."
ssh -o StrictHostKeyChecking=no root@$VM_IP \
    "cd /opt/ai-agent && make run PROJECT_NAME=$PROJECT_NAME"

echo ""
echo "✅ agent loop started for '$PROJECT_NAME'!"
echo ""
echo "Monitor progress:"
echo "  make monitor-project project=$PROJECT_NAME"
echo ""
echo "Stop Agent:"
echo "  make stop-project project=$PROJECT_NAME"
