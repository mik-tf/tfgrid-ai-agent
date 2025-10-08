#!/bin/bash
# Create a new agent project on the VM
set -e

echo "🚀 Creating agent project"
echo "========================================="

# Get project name from argument or prompt interactively
PROJECT_NAME="$1"
if [ -z "$PROJECT_NAME" ]; then
    read -p "Enter project name: " PROJECT_NAME
    echo ""
fi

if [ -z "$PROJECT_NAME" ]; then
    echo "❌ Error: Project name is required"
    exit 1
fi

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

echo "🚀 Creating agent project: $PROJECT_NAME"
echo "========================================="

# Check if Qwen is authenticated by checking for settings file
echo "Checking Qwen authentication..."
if ! ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    root@$VM_IP "test -f ~/.qwen/settings.json" 2>/dev/null; then
    echo "❌ Error: Qwen not authenticated on VM"
    echo ""
    echo "Please run: make login"
    exit 1
fi
echo "✅ Qwen is authenticated"

# Check if project already exists
if ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP "test -d /opt/$PROJECT_NAME" 2>/dev/null; then
    echo "❌ Error: Project '$PROJECT_NAME' already exists on VM"
    echo ""
    echo "Available projects:"
    ./scripts/agent-list-projects.sh 2>/dev/null | grep "📁" || echo "  (none)"
    exit 1
fi

# Collect all inputs LOCALLY (interactive prompts on user's machine)
echo ""
echo "⏱️  How long should the AI agent run?"
echo "Examples: 30m, 1h, 2h30m, indefinite"
echo ""
read -p "Enter duration: " TIME_DURATION
echo ""

echo "📝 Choose prompt type:"
echo "1) Custom prompt (paste your own)"
echo "2) Generic template (select from options)"
echo ""
read -p "Select (1-2) [2]: " PROMPT_TYPE
PROMPT_TYPE=${PROMPT_TYPE:-2}
echo ""

if [ "$PROMPT_TYPE" = "1" ]; then
    echo "📋 Enter your custom prompt (press Ctrl+D when done):"
    echo ""
    CUSTOM_PROMPT=$(cat)
    echo ""
    echo "✅ Custom prompt received"
else
    echo "📋 Select generic project template:"
    echo "1) Codebase Porting (e.g., React to Vue)"
    echo "2) Translation Services"
    echo "3) Editing & Proofreading"
    echo "4) Copywriting"
    echo "5) Website Creation"
    echo "6) Other/General Purpose"
    echo ""
    read -p "Select (1-6) [1]: " PROJECT_TYPE
    PROJECT_TYPE=${PROJECT_TYPE:-1}
    echo ""
fi

echo "🔧 Creating project on VM..."
echo ""

# Call ai-agent in NON-INTERACTIVE mode with all inputs as env vars
if [ "$PROMPT_TYPE" = "1" ]; then
    # Custom prompt mode
    ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
        "cd /opt/ai-agent && \
         NON_INTERACTIVE=1 \
         PROJECT_NAME='$PROJECT_NAME' \
         TIME_DURATION='$TIME_DURATION' \
         PROMPT_TYPE='$PROMPT_TYPE' \
         CUSTOM_PROMPT='$CUSTOM_PROMPT' \
         make create"
else
    # Generic template mode
    ssh -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$VM_IP \
        "cd /opt/ai-agent && \
         NON_INTERACTIVE=1 \
         PROJECT_NAME='$PROJECT_NAME' \
         TIME_DURATION='$TIME_DURATION' \
         PROMPT_TYPE='$PROMPT_TYPE' \
         PROJECT_TYPE='$PROJECT_TYPE' \
         make create"
fi

# Check if creation was successful
if [ $? -ne 0 ]; then
    echo "❌ Error: Project creation failed"
    exit 1
fi

# Ask locally if user wants to start the agent
echo ""
echo "🚀 Do you want to start the AI agent now for the project '$PROJECT_NAME'?"
read -p "Start now? (y/N): " START_NOW
echo ""

if [[ "$START_NOW" =~ ^[Yy]$ ]]; then
    echo "Starting AI agent for project '$PROJECT_NAME'..."
    echo ""
    
    # Use the run script to start the agent (without -t so process persists)
    cd "$(dirname "$0")/.."
    make run PROJECT_NAME="$PROJECT_NAME"
else
    echo "Project created successfully!"
    echo ""
    echo "To start the agent later, run: make run PROJECT_NAME=$PROJECT_NAME"
fi
