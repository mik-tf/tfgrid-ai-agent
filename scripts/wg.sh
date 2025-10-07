#!/bin/bash
# Setup WireGuard connection to AI agent VM
set -e

echo "🔐 Setting up WireGuard connection"
echo "==================================="

# Check if tofu/terraform is available
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
else
    echo "❌ Error: Neither OpenTofu nor Terraform found"
    exit 1
fi

# Check if WireGuard is installed
if ! command -v wg &> /dev/null; then
    echo "❌ Error: WireGuard not installed"
    echo "Please install WireGuard:"
    echo "  Ubuntu/Debian: sudo apt install wireguard"
    echo "  macOS: brew install wireguard-tools"
    exit 1
fi

cd infrastructure

# Get WireGuard configuration
echo "📝 Extracting WireGuard configuration..."
terraform_output=$($TF_CMD show -json)
echo "$terraform_output" | jq -r '.values.outputs.wg_config.value' > ../wg-ai-agent.conf

cd ..

# Setup WireGuard
echo "🔧 Configuring WireGuard interface..."
sudo cp wg-ai-agent.conf /etc/wireguard/wg-ai-agent.conf
sudo chmod 600 /etc/wireguard/wg-ai-agent.conf

echo "🚀 Starting WireGuard..."
sudo wg-quick down wg-ai-agent 2>/dev/null || true
sudo wg-quick up wg-ai-agent

echo ""
echo "✅ WireGuard connection established!"
echo ""
echo "Test connectivity: make ping"
