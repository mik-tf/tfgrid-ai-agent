#!/bin/bash
# Clean up deployment and remove resources
set -e

echo "🧹 Cleaning up tfgrid-ai-agent deployment"
echo "======================================="
echo ""
echo "⚠️  WARNING: This will destroy all resources!"
echo ""
read -p "Are you sure? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "📝 Loading configuration from .env..."
    set -a
    source .env
    set +a
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

# Stop WireGuard
echo ""
echo "🔌 Stopping WireGuard..."
sudo wg-quick down wg-ai-agent 2>/dev/null || true

# Destroy infrastructure
echo ""
echo "💥 Destroying infrastructure..."
cd infrastructure
$TF_CMD destroy -auto-approve
cd ..

# Clean up generated files
echo ""
echo "🗑️  Removing generated files..."
rm -f wg-ai-agent.conf
rm -f platform/inventory.ini

echo ""
echo "✅ Cleanup complete!"
