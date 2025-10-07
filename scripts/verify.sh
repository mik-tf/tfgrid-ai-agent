#!/bin/bash
# Verify deployment status
set -e

echo "✅ Verifying tfgrid-ai-agent deployment"
echo "====================================="

# Check if tofu/terraform is available
if command -v tofu &> /dev/null; then
    TF_CMD="tofu"
elif command -v terraform &> /dev/null; then
    TF_CMD="terraform"
else
    echo "❌ OpenTofu/Terraform: Not found"
    exit 1
fi

echo "✅ OpenTofu/Terraform: $TF_CMD"

# Check deployment
cd infrastructure
if $TF_CMD output ai_agent_wg_ip &>/dev/null; then
    echo "✅ Infrastructure: Deployed"
    AI_AGENT_WG_IP=$($TF_CMD output -raw ai_agent_wg_ip)
else
    echo "❌ Infrastructure: Not deployed"
    cd ..
    exit 1
fi
cd ..

# Check WireGuard
if sudo wg show wg-ai-agent &>/dev/null; then
    echo "✅ WireGuard: Connected"
else
    echo "❌ WireGuard: Not connected"
fi

# Check connectivity
if ping -c 1 -W 2 $AI_AGENT_WG_IP &>/dev/null; then
    echo "✅ VM Connectivity: Reachable"
else
    echo "❌ VM Connectivity: Not reachable"
fi

# Check inventory
if [ -f platform/inventory.ini ]; then
    echo "✅ Ansible Inventory: Generated"
else
    echo "❌ Ansible Inventory: Not generated"
fi

# Check SSH access
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@$AI_AGENT_WG_IP "echo ok" &>/dev/null; then
    echo "✅ SSH Access: Working"
    
    # Check if ai-agent is installed
    if ssh -o StrictHostKeyChecking=no root@$AI_AGENT_WG_IP "test -d /opt/ai-agent" 2>/dev/null; then
        echo "✅ AI-Agent: Installed"
    else
        echo "❌ AI-Agent: Not installed (run: make ansible)"
    fi
    
    # Check if Qwen CLI is installed
    if ssh -o StrictHostKeyChecking=no root@$AI_AGENT_WG_IP "command -v qwen" &>/dev/null; then
        echo "✅ Qwen CLI: Installed"
    else
        echo "❌ Qwen CLI: Not installed (run: make ansible)"
    fi
else
    echo "❌ SSH Access: Not working"
fi

echo ""
echo "Verification complete!"
