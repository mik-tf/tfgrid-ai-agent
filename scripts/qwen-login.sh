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

echo "⚠️  Qwen needs to be authenticated on the VM."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 OAuth Authentication Steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Qwen will display an authorization URL in the terminal"
echo "2. COPY the URL manually (it's not clickable over SSH)"
echo "3. PASTE and open it in your LOCAL web browser"
echo "4. Sign in with your Google account (or other OAuth provider)"
echo "5. Authorize Qwen Code"
echo "6. Come back to this terminal and press ESC"
echo ""
echo "💡 TIP: The URL looks like:"
echo "   https://chat.qwen.ai/authorize?user_code=XXXXXXXX&client=qwen-code"
echo ""
echo "⚠️  IMPORTANT: Open the URL in your LOCAL browser, not on the VM!"
echo ""
read -p "Press Enter when ready to start (or Ctrl+C to cancel)..."
echo ""

echo "🔓 Starting Qwen authentication session..."
echo "==========================================="
echo ""

# Clear instructions for the OAuth flow
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 What happens next:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1️⃣  An OAuth authorization URL will appear below"
echo "  2️⃣  COPY the URL and open it in your LOCAL browser"
echo "  3️⃣  Complete the Google OAuth login in your browser"
echo "  4️⃣  Press ENTER here after completing OAuth"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run qwen with expect to handle interactive OAuth flow
ssh -t -o LogLevel=ERROR -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    root@$VM_IP 'bash -c '\''
# Clean previous auth
rm -rf ~/.qwen

# Use expect to automate the OAuth device flow
expect <<END_EXPECT
set timeout 120
log_user 1

spawn qwen
expect {
    "How would you like to authenticate" {
        # Select option 1: Qwen OAuth
        send "1\r"
        
        # Now wait for the OAuth URL to appear and keep the session alive
        expect {
            "authorize" {
                # OAuth URL displayed, wait for user to complete in browser
                # Display a clear prompt
                puts "\n"
                puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                puts "✅ OAuth URL displayed above"
                puts "Press ENTER in the OTHER terminal after completing OAuth..."
                puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                # Keep this session alive for 2 minutes
                sleep 120
                send "\x03"
            }
            timeout {
                puts "Timeout waiting for OAuth"
                exit 1
            }
        }
    }
    timeout {
        puts "Timeout waiting for qwen"
        exit 1
    }
}
END_EXPECT
'\'''

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
read -p "Press ENTER here after completing OAuth in your browser..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "Authentication session ended."
echo ""
echo "Verifying authentication status..."

if ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "test -f ~/.qwen/settings.json" &>/dev/null; then
    echo "✅ Qwen is now authenticated!"
    echo ""
    echo "Next steps:"
    echo "  1. Create project: make create"
    echo "  2. Run AI agent: make run"
else
    echo "⚠️  Authentication verification failed."
    echo ""
    echo "Troubleshooting:"
    echo "  1. Try running 'make login' again"
    echo "  2. Ensure you completed the OAuth flow in your browser"
    echo "  3. Check VM internet connectivity: make connect, then ping 8.8.8.8"
    echo "  4. Manual setup: make connect, then run 'qwen --version' and follow prompts"
fi
