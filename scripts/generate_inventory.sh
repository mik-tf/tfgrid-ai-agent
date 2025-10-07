#!/bin/bash
# Generate Ansible inventory from Terraform/OpenTofu outputs
set -e

echo "📝 Generating Ansible inventory"
echo "================================"

# Load .env if it exists
if [ -f .env ]; then
    source .env
fi

# Default to wireguard if not set
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

# Get outputs
AI_AGENT_WG_IP=$($TF_CMD output -raw ai_agent_wg_ip)
AI_AGENT_MYCELIUM_IP=$($TF_CMD output -raw ai_agent_mycelium_ip)
AI_AGENT_NODE_ID=$($TF_CMD output -raw ai_agent_node_id)

cd ..

# Determine which IP to use for ansible_host
if [ "$CONNECTIVITY_NETWORK" = "mycelium" ]; then
    ANSIBLE_HOST="$AI_AGENT_MYCELIUM_IP"
    echo "Using Mycelium IPv6 for connectivity"
else
    ANSIBLE_HOST="$AI_AGENT_WG_IP"
    echo "Using WireGuard for connectivity"
fi

# Generate inventory
cat > platform/inventory.ini <<EOF
# Ansible inventory for tfgrid-ai-agent
# Generated automatically - do not edit manually
# Connectivity network: $CONNECTIVITY_NETWORK

[ai_agent]
ai_agent_vm ansible_host=$ANSIBLE_HOST

[ai_agent:vars]
ai_agent_wg_ip=$AI_AGENT_WG_IP
ai_agent_mycelium_ip=$AI_AGENT_MYCELIUM_IP
ai_agent_node_id=$AI_AGENT_NODE_ID
connectivity_network=$CONNECTIVITY_NETWORK

[all:vars]
ansible_user=root
ansible_ssh_common_args=-o StrictHostKeyChecking=no
EOF

echo "✅ Inventory generated: platform/inventory.ini"
echo ""
echo "AI agent VM:"
echo "  WireGuard IP:  $AI_AGENT_WG_IP"
echo "  Mycelium IP:   $AI_AGENT_MYCELIUM_IP"
echo "  Node ID:       $AI_AGENT_NODE_ID"
echo "  Connectivity:  $CONNECTIVITY_NETWORK ($ANSIBLE_HOST)"
