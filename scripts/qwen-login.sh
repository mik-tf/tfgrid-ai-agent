#!/bin/bash
# Login to Qwen on AI agent VM
set -e

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

echo "🔐 Logging into Qwen on AI agent VM"
echo "=================================="
echo ""
echo "Follow the prompts to authenticate with Google/Gmail"
echo "This provides 2000 free tokens per day"
echo ""

# Use -t to allocate TTY for interactive session
ssh -t -o StrictHostKeyChecking=no root@$VM_IP "qwen login"

echo ""
echo "✅ Qwen authentication complete!"
echo ""
echo "Next steps:"
echo "  1. Create project: make create-project project=my-app"
echo "  2. Run AI agent: make run-project project=my-app"
