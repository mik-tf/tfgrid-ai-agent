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

echo "🔐 Qwen Authentication Setup"
echo "============================="
echo ""
echo "First, let's check if Qwen is already authenticated..."
echo ""

# Check if Qwen is already authenticated by testing a simple command
if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "timeout 5 qwen --version" &>/dev/null; then
    echo "✅ Qwen is already authenticated!"
    echo ""
    echo "Next steps:"
    echo "  1. Create project: make create project=my-app"
    echo "  2. Run AI agent: make run project=my-app"
    exit 0
fi

echo "⚠️  Qwen needs to be authenticated on the VM."
echo ""
echo "This requires OAuth authentication through a web browser."
echo "The process involves:"
echo "  1. Qwen will display a URL and QR code"
echo "  2. You visit the URL in your browser (or scan QR code)"
echo "  3. Complete the OAuth authorization"
echo "  4. Once done, press ESC to return"
echo ""
echo "IMPORTANT: This will open an interactive session."
echo "If you see an authentication screen, complete it in your browser,"
echo "then press ESC to exit once it shows 'Authorization successful'."
echo ""
read -p "Press Enter to continue (or Ctrl+C to cancel)..."
echo ""

echo "🔓 Starting Qwen authentication session..."
echo "==========================================="
echo ""

# Use -t to allocate TTY for interactive session
# Disable host key checking to avoid warnings on redeployment
ssh -t \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "bash -c '
        echo \"Testing Qwen CLI...\"
        echo \"If you see an OAuth screen, follow the instructions and press ESC when done.\"
        echo \"\"
        timeout 300 qwen --version 2>&1 || true
        echo \"\"
        echo \"Authentication attempt completed.\"
        echo \"Testing if Qwen is now working...\"
        if timeout 5 qwen --version &>/dev/null; then
            echo \"\"
            echo \"✅ SUCCESS: Qwen is authenticated!\"
        else
            echo \"\"
            echo \"⚠️  Authentication may not be complete.\"
            echo \"You may need to run '\''make login'\'' again.\"
        fi
    '"

echo ""
echo "Authentication session ended."
echo ""
echo "Verifying authentication status..."

if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "timeout 5 qwen --version" &>/dev/null; then
    echo "✅ Qwen is now authenticated!"
    echo ""
    echo "Next steps:"
    echo "  1. Create project: make create project=my-app"
    echo "  2. Run AI agent: make run project=my-app"
else
    echo "⚠️  Authentication verification failed."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Try running 'make login' again"
    echo "  2. Ensure you completed the OAuth flow in your browser"
    echo "  3. Check VM internet connectivity: make connect, then ping 8.8.8.8"
    echo "  4. Manual setup: make connect, then run 'qwen --version' and follow prompts"
fi
