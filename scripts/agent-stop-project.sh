#!/bin/bash
# Stop agent loop for a project on the VM
set -e

echo "🛑 Stopping agent project"
echo "========================================="

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
    VM_IP=$($TF_CMD output -raw ai_agent_wg_ip)
fi

cd ..

# Get project name from argument or select interactively
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    echo ""
    
    # Get list of projects via SSH
    PROJECTS_LIST=$(ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
        "cd /opt/ai-agent && make list" 2>/dev/null | grep "📁" | sed 's/.*📁 //')
    
    if [ -z "$PROJECTS_LIST" ]; then
        echo "❌ No projects found"
        exit 1
    fi
    
    # Convert to array
    mapfile -t PROJECTS <<< "$PROJECTS_LIST"
    
    # Show numbered list
    echo "Available projects:"
    for i in "${!PROJECTS[@]}"; do
        num=$((i + 1))
        if [ $num -eq 1 ]; then
            echo "  $num. ${PROJECTS[$i]} [default]"
        else
            echo "  $num. ${PROJECTS[$i]}"
        fi
    done
    echo ""
    
    # Prompt for selection
    if [ ${#PROJECTS[@]} -eq 1 ]; then
        read -p "Select project [${PROJECTS[0]}]: " SELECTION
    else
        read -p "Select project (1-${#PROJECTS[@]}) or type name [1]: " SELECTION
    fi
    echo ""
    
    # Handle selection
    if [ -z "$SELECTION" ]; then
        PROJECT_NAME="${PROJECTS[0]}"
    elif [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
        idx=$((SELECTION - 1))
        if [ $idx -ge 0 ] && [ $idx -lt ${#PROJECTS[@]} ]; then
            PROJECT_NAME="${PROJECTS[$idx]}"
        else
            echo "❌ Invalid selection: $SELECTION"
            exit 1
        fi
    else
        PROJECT_NAME="$SELECTION"
    fi
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Project name is required"
    exit 1
fi

echo "🛑 Stopping agent loop for: $PROJECT_NAME"
echo "=========================================="

# Check if project exists
if ! ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP "test -d /opt/$PROJECT_NAME" 2>/dev/null; then
    echo "❌ Error: Project '$PROJECT_NAME' not found on VM"
    exit 1
fi

# Delegate to ai-agent (it handles all stop logic)
ssh -t -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
    "cd /opt/ai-agent && make stop PROJECT_NAME=$PROJECT_NAME"
