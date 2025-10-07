#!/bin/bash
# Wait for SSH to become available on AI agent VM
set -e

echo "⏳ Waiting for SSH to become ready on AI agent VM"
echo "================================================"

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
    NETWORK_TYPE="Mycelium"
else
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip | sed 's|/.*||')
    NETWORK_TYPE="WireGuard"
fi

cd ..

echo "Network: $NETWORK_TYPE"
echo "IP: $VM_IP"
echo ""

# Wait parameters
MAX_ATTEMPTS=30
ATTEMPT=0
SLEEP_TIME=10

echo "Checking SSH connectivity (timeout: ${MAX_ATTEMPTS}0 seconds)..."

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    # Try SSH connection
    if ssh -o ConnectTimeout=5 \
           -o StrictHostKeyChecking=no \
           -o UserKnownHostsFile=/dev/null \
           -o BatchMode=yes \
           root@"$VM_IP" "echo 'SSH Ready'" >/dev/null 2>&1; then
        echo ""
        echo "✅ SSH is ready! (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        exit 0
    fi
    
    # Show progress
    echo -n "."
    
    # Wait before retry
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
        sleep $SLEEP_TIME
    fi
done

echo ""
echo "❌ SSH did not become ready after $MAX_ATTEMPTS attempts"
echo ""
echo "Troubleshooting:"
echo "  1. Check VM is running: make address"
echo "  2. Test network connectivity: make ping"
echo "  3. Try connecting manually: ssh root@$VM_IP"
echo "  4. Or wait a bit longer and run: make quick"
exit 1
