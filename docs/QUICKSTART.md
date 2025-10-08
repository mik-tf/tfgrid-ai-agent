# Quick Start Guide

Get up and running with TFGrid AI-Agent in 5 minutes.

## Prerequisites Check

```bash
# Check if required tools are installed
command -v tofu || command -v terraform   # ✅ OpenTofu or Terraform
command -v ansible                        # ✅ Ansible
command -v wg                             # ✅ WireGuard
command -v ssh-keygen                     # ✅ SSH
```

If any are missing, see [Installation](#installation).

## 5-Minute Setup

### Step 1: Clone and Configure (1 minute)

```bash
# Clone repository
git clone https://github.com/yourusername/tfgrid-ai-agent
cd tfgrid-ai-agent

# Copy and edit configuration
cp .env.example .env
nano .env
```

**Minimum required in `.env`:**
```bash
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=1234  # Your node ID from Grid Explorer

export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"
```

### Step 2: Set Mnemonic (30 seconds)

```bash
# Bash
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)

# Fish
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)
```

### Step 3: Deploy (2-3 minutes)

```bash
make deploy
```

This deploys VM, sets up WireGuard, and configures everything.

### Step 4: Login to Qwen (30 seconds)

```bash
make login
```

Follow prompts to authenticate with your Qwen account (OAuth authentication).

### Step 5: Create and Run Project (1 minute)

```bash
# Create project
make create project=my-first-app

# Start AI agent
make run project=my-first-app
```

**Done!** The agent is now coding on your TFGrid VM. 🎉

## Next Steps

### Monitor Progress

```bash
# In another terminal
make monitor project=my-first-app
```

### Setup Git Remote (Optional)

```bash
# Show git SSH key
make git-key

# Add to GitHub: https://github.com/settings/keys

# Setup remote
make git-setup project=my-first-app provider=github
```

### Connect to VM

```bash
# SSH to VM
make connect

# Inside VM
cd /opt/ai-agent-projects/my-first-app
git log
tail -f agent-output.log
```

### Stop AI agent

```bash
make stop project=my-first-app
```

## Installation

### Ubuntu/Debian

```bash
# OpenTofu
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash

# Ansible
sudo apt update
sudo apt install ansible

# WireGuard
sudo apt install wireguard

# jq (recommended)
sudo apt install jq
```

### macOS

```bash
brew install opentofu ansible wireguard-tools jq
```

### ThreeFold Setup

1. **Get mnemonic**: Install [ThreeFold Connect](https://manual.grid.tf/documentation/threefold_token/buy_sell_tft/threefold_connect.html)
2. **Get TFT**: Purchase tokens
3. **Save mnemonic**: `mkdir -p ~/.config/threefold && echo "your mnemonic" > ~/.config/threefold/mnemonic`
4. **Find node**: Visit [Grid Explorer](https://dashboard.grid.tf/)

## Common Commands Reference

```bash
# Deployment
make deploy          # Complete deployment
make infrastructure  # Deploy VM only
make ansible         # Configure VM only
make clean           # Destroy everything

# Network
make address         # Show addresses
make connect         # SSH to VM
make ping            # Test connectivity
make wg              # Setup WireGuard

# Agent Operations
make login                      # Login to Qwen
make create project=<name>      # Create project
make run project=<name>         # Start AI agent
make monitor project=<name>     # Monitor progress
make stop project=<name>        # Stop AI agent
make list                       # List projects

# Git
make git-key                              # Show SSH key
make git-setup project=<name> provider=<github|gitea|gitlab>
```

## Troubleshooting

**Can't connect to VM?**
```bash
make wireguard
make ping
```

**Qwen not authenticated?**
```bash
make login
```

**Project not found?**
```bash
make list
make create project=my-app
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.

## What's Next?

- Read [USAGE.md](USAGE.md) for detailed examples
- Check [ARCHITECTURE.md](ARCHITECTURE.md) to understand the system
- Learn [GIT_INTEGRATION.md](GIT_INTEGRATION.md) for git workflows
- Review [SECURITY.md](SECURITY.md) for best practices

---

**Need help?** Open an issue or check the full [README.md](../README.md).
