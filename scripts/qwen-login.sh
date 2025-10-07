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
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip | sed 's|/.*||')
fi

cd ..

echo "🔐 Launching Qwen CLI on AI agent VM"
echo "===================================="
echo ""
echo "This will open an interactive Qwen session."
echo "Authentication will happen automatically on first use."
echo "Press Ctrl+D or type 'exit' to close the session."
echo ""

# Use -t to allocate TTY for interactive session
# Disable host key checking to avoid warnings on redeployment
ssh -t \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "qwen"

echo ""
echo "✅ Qwen session ended"
echo ""
echo "Next steps:"
echo "  1. Create project: make create project=my-app"
echo "  2. Run AI agent: make run project=my-app"
