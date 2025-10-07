#!/bin/bash
# Show AI agent VM addresses
set -e

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
    echo "Please run: make infrastructure"
    exit 1
fi

# Get outputs
AI_AGENT_WG_IP=$($TF_CMD output -raw ai_agent_wg_ip)
AI_AGENT_MYCELIUM_IP=$($TF_CMD output -raw ai_agent_mycelium_ip)
AI_AGENT_NODE_ID=$($TF_CMD output -raw ai_agent_node_id)

cd ..

echo "ThreeFold Grid AI agent VM Addresses"
echo "=================================="
echo ""
echo "🔐 WireGuard Network:"
echo "  AI agent VM: $AI_AGENT_WG_IP"
echo ""
echo "🌍 Mycelium IPv6 Overlay:"
echo "  AI agent VM: $AI_AGENT_MYCELIUM_IP"
echo ""
echo "📍 Node Information:"
echo "  Node ID: $AI_AGENT_NODE_ID"
echo ""
echo "🔑 Git SSH Key (add to GitHub/Gitea):"
if [ -f platform/inventory.ini ]; then
    VM_IP=$AI_AGENT_WG_IP
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$VM_IP "test -f /root/.ssh/id_ed25519_git.pub" 2>/dev/null; then
        ssh -o StrictHostKeyChecking=no root@$VM_IP "cat /root/.ssh/id_ed25519_git.pub" 2>/dev/null || echo "  (Run 'make ansible' first to generate key)"
    else
        echo "  (Run 'make ansible' first to generate key)"
    fi
else
    echo "  (Run 'make ansible' first to generate key)"
fi
echo ""
echo "Commands:"
echo "  Connect: make connect"
echo "  Ping:    make ping"
