#!/bin/bash
# Deploy ThreeFold Grid infrastructure with OpenTofu/Terraform
set -e

echo "🚀 Deploying AI agent VM on ThreeFold Grid"
echo "========================================"

# Check if mnemonic is set
if [ -z "$TF_VAR_mnemonic" ]; then
    echo "❌ Error: TF_VAR_mnemonic not set"
    echo ""
    echo "Please set your mnemonic:"
    echo "  Bash: export TF_VAR_mnemonic=\$(cat ~/.config/threefold/mnemonic)"
    echo "  Fish: set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)"
    exit 1
fi

# Load environment variables from .env if it exists
if [ -f .env ]; then
    echo "📝 Loading configuration from .env..."
    set -a
    source .env
    set +a
fi

# Check if tofu or terraform is available
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
else
    echo "❌ Error: Neither OpenTofu nor Terraform found"
    echo "Please install OpenTofu: https://opentofu.org/docs/intro/install/"
    exit 1
fi

echo "Using: $TF_CMD"

# Navigate to infrastructure directory
cd infrastructure

# Initialize
echo ""
echo "📦 Initializing $TF_CMD..."
$TF_CMD init

# Plan
echo ""
echo "📋 Planning deployment..."
$TF_CMD plan

# Apply
echo ""
echo "🚀 Applying deployment..."
$TF_CMD apply -auto-approve

# Show outputs
echo ""
echo "✅ Deployment complete!"
echo ""
echo "📊 VM Information:"
$TF_CMD output

cd ..

echo ""
echo "Next steps:"
echo "  1. Setup WireGuard: make wireguard (or make wg)"
echo "  2. Generate inventory: make inventory"
echo "  3. Configure VM: make ansible"
