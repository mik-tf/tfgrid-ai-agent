#!/bin/bash
# Test connectivity to AI agent VM
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
    echo "Please run: make infrastructure"
    exit 1
fi

# Get IP based on connectivity network
if [ "$CONNECTIVITY_NETWORK" = "mycelium" ]; then
    VM_IP=$($TF_CMD output -raw ai_agent_mycelium_ip)
else
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip)
fi

cd ..

echo "🏓 Testing connectivity to AI agent VM"
echo "===================================="
echo ""
echo "Network: $CONNECTIVITY_NETWORK"
echo "IP: $VM_IP"
echo ""

if ping -c 3 -W 2 $VM_IP; then
    echo ""
    echo "✅ AI agent VM is reachable via $CONNECTIVITY_NETWORK"
else
    echo ""
    echo "❌ Cannot reach AI agent VM"
    echo ""
    echo "Troubleshooting:"
    if [ "$CONNECTIVITY_NETWORK" = "wireguard" ]; then
        echo "  1. Check WireGuard: make wireguard"
        echo "  2. Verify deployment: make verify"
    else
        echo "  1. Check Mycelium connectivity"
        echo "  2. Verify deployment: make verify"
        echo "  3. Try WireGuard: Set CONNECTIVITY_NETWORK=wireguard in .env"
    fi
    exit 1
fi
