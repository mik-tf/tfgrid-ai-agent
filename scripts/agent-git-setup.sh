#!/bin/bash
# Setup git remote for a agent project
set -e

PROJECT_NAME="$1"
PROVIDER="${2:-manual}"
USER_OVERRIDE="$3"

if [ -z "$PROJECT_NAME" ]; then
    echo "Usage: $0 <project-name> [provider] [user]"
    echo ""
    echo "Examples:"
    echo "  $0 my-app github"
    echo "  $0 my-app gitea"
    echo "  $0 my-app github different-user"
    echo "  $0 my-app git@custom.com:org/my-app.git"
    echo ""
    echo "Or use Makefile:"
    echo "  make git-setup project=my-app provider=github"
    exit 1
fi

# Load .env for defaults
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

# Check if project exists
if ! ssh -o StrictHostKeyChecking=no root@$VM_IP "test -d /opt/ai-agent-projects/$PROJECT_NAME" 2>/dev/null; then
    echo "❌ Error: Project '$PROJECT_NAME' not found on VM"
    exit 1
fi

# Construct remote URL based on provider
case "$PROVIDER" in
    github)
        GIT_USER="${USER_OVERRIDE:-${GITHUB_USER}}"
        if [ -z "$GIT_USER" ]; then
            echo "❌ Error: Set GITHUB_USER in .env or provide user parameter"
            echo "Example: make git-setup project=$PROJECT_NAME provider=github user=myusername"
            exit 1
        fi
        REMOTE_URL="git@github.com:${GIT_USER}/${PROJECT_NAME}.git"
        ;;
    
    gitea)
        GIT_USER="${USER_OVERRIDE:-${GITEA_USER}}"
        if [ -z "$GIT_USER" ] || [ -z "$GITEA_URL" ]; then
            echo "❌ Error: Set GITEA_USER and GITEA_URL in .env"
            exit 1
        fi
        REMOTE_URL="git@${GITEA_URL}:${GIT_USER}/${PROJECT_NAME}.git"
        ;;
    
    gitlab)
        GIT_USER="${USER_OVERRIDE:-${GITLAB_USER}}"
        if [ -z "$GIT_USER" ]; then
            echo "❌ Error: Set GITLAB_USER in .env or provide user parameter"
            exit 1
        fi
        REMOTE_URL="git@gitlab.com:${GIT_USER}/${PROJECT_NAME}.git"
        ;;
    
    manual)
        echo "📝 Manual git setup for: $PROJECT_NAME"
        echo ""
        echo "Connect to VM: make connect"
        echo "Then run:"
        echo "  cd /opt/ai-agent-projects/$PROJECT_NAME"
        echo "  git remote add origin <your-url>"
        echo "  git push -u origin main"
        exit 0
        ;;
    
    *)
        # Treat as custom URL
        REMOTE_URL="$PROVIDER"
        ;;
esac

echo "📦 Setting up git remote for: $PROJECT_NAME"
echo "Provider: $PROVIDER"
echo "Remote URL: $REMOTE_URL"
echo ""

# Setup remote on VM
ssh -o StrictHostKeyChecking=no root@$VM_IP \
    "cd /opt/ai-agent-projects/$PROJECT_NAME && \
     git remote add origin '$REMOTE_URL' && \
     git push -u origin main"

echo ""
echo "✅ Git remote configured and pushed successfully!"
