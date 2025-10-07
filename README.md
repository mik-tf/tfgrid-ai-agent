# TFGrid AI-Agent - AI Coding on ThreeFold Grid

Run AI-powered continuous coding automation safely on isolated ThreeFold Grid VMs. Deploy a dedicated VM with the [ai-agent framework](https://github.com/mik-tf/ai-agent) pre-installed, execute AI coding loops remotely, and keep your local machine safe from code changes.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Overview

**TFGrid AI-Agent** combines two powerful technologies:

1. **tfgrid-gateway**: Infrastructure deployment on ThreeFold Grid using OpenTofu/Terraform
2. **ai-agent**: AI-powered continuous coding automation with Qwen

The result: **Safe, isolated AI coding in the cloud** with full local control.

### What is AI-Agent?

The **[ai-agent framework](https://github.com/mik-tf/ai-agent)** implements continuous loop automation where an AI coding agent runs continuously to work on codebases. This approach enables:

- Overnight codebase porting (React → Vue, Python → TypeScript)
- Continuous feature implementation
- Automated refactoring and maintenance
- AI-driven project development

**Inspired by**: The framework is inspired by the ["Ralph" coding technique](https://ghuntley.com/ralph/) popularized by [Geoff Huntley](https://github.com/ghuntley), extended into a production-ready automation platform.

### Why ThreeFold Grid?

Running AI agents on TFGrid provides:

- **Safety**: VM isolation protects your local machine
- **Scalability**: Deploy multiple VMs for different projects
- **Cost-effective**: Pay only for resources used
- **Decentralized**: Run on distributed infrastructure
- **Control**: Destroy and recreate VMs easily

## Features

### Infrastructure Management
- ✅ One-command VM deployment on ThreeFold Grid
- ✅ OpenTofu/Terraform infrastructure as code
- ✅ WireGuard VPN for secure connectivity
- ✅ Mycelium IPv6 overlay network
- ✅ Automated Ansible configuration

### Agent Operations
- ✅ Remote project creation
- ✅ Remote agent loop execution
- ✅ Real-time progress monitoring
- ✅ Graceful loop termination
- ✅ Multi-project support

### AI Provider
- ✅ **FREE tier available** - 2,000 tokens/day with Google login
- ✅ No API key or credit card required
- ✅ Qwen (Alibaba Cloud) - current default
- ✅ Extensible to support multiple providers (Claude, GPT-4, DeepSeek, etc.)

### Git Integration
- ✅ Automatic git configuration
- ✅ Smart GitHub/Gitea/GitLab integration
- ✅ SSH key management
- ✅ Auto-commit and push support

### Network & Connectivity
- ✅ Address discovery (`make address`)
- ✅ SSH access (`make connect`)
- ✅ Connectivity testing (`make ping`)
- ✅ WireGuard setup (`make wg`)

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/mik-tf/tfgrid-ai-agent
cd tfgrid-ai-agent
```

### 2. Configure Environment

**Option A: Automatic (Recommended)**
```bash
make init
# → Interactive setup that auto-detects your git config
# → Just answer a few questions (node ID, resources)
```

The `make init` command will:
- ✅ Auto-detect your local git name/email
- ✅ Auto-detect GitHub username (if using `gh` CLI)
- ✅ Prompt for TFGrid node ID and VM resources
- ✅ Create `.env` with sensible defaults

**Option B: Manual**
```bash
cp .env.example .env
nano .env
# → Edit all values manually
```

### 3. Set Credentials

**Required: TFGrid Mnemonic**
```bash
# Store mnemonic securely
mkdir -p ~/.config/threefold
echo "your mnemonic words here" > ~/.config/threefold/mnemonic
chmod 600 ~/.config/threefold/mnemonic

# Set environment variable
# Fish
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)
# Bash
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)
```

**Optional: GitHub Token (for automated git push from VM)**
```bash
# Create token: GitHub.com → Settings → Developer settings → Personal access tokens
# Scopes needed: repo, workflow
echo "ghp_your_token_here" > ~/.config/threefold/github_token
chmod 600 ~/.config/threefold/github_token

# Set environment variable
# Fish
set -x GITHUB_TOKEN (cat ~/.config/threefold/github_token)
export GITHUB_TOKEN=$(cat ~/.config/threefold/github_token)

### 4. Deploy
```bash
make deploy
# → Deploys VM, configures with Ansible, sets up WireGuard
# → Takes 5-10 minutes
```
### 5. Login to Qwen (FREE!)

**No API key or credit card needed!**
```bash
make login-qwen
# Login with your Google account
# Get 2,000 FREE tokens daily - perfect for getting started!
```

### 6. Create & Run Project
```bash
# Create project
make create-project project=my-app

# Setup git remote (optional)
make git-setup project=my-app provider=github

# Start agent loop
make run-project project=my-app

# Monitor progress
make monitor-project project=my-app

# Stop when done
make stop-project project=my-app
```

**That's it!** The agent is now running on your TFGrid VM. 🚀

## Architecture

```
┌─────────────────┐         ┌──────────────────────┐
│  Local Machine  │         │   ThreeFold Grid     │
│                 │         │                      │
│  • OpenTofu     │────────▶│  ┌────────────────┐  │
│  • Ansible      │         │  │  AI agent VM   │  │
│  • Makefile     │         │  │                │  │
│  • Scripts      │         │  │  • ai-agent    │  │
│                 │         │  │  • Node.js     │  │
│  WireGuard VPN  │◀───────▶│  │  • Qwen CLI    │  │
│                 │         │  │  • Git repos   │  │
└─────────────────┘         │  └────────────────┘  │
                            │                      │
                            │  Mycelium IPv6       │
                            └──────────────────────┘
```

**Key Components:**

1. **Infrastructure Layer**: OpenTofu deploys VM on TFGrid
2. **Network Layer**: WireGuard + Mycelium for connectivity
3. **Configuration Layer**: Ansible installs ai-agent and dependencies
4. **Execution Layer**: Remote scripts control agent operations
5. **Control Layer**: Makefile provides unified interface

## Prerequisites

### Required
- **Linux or macOS** system
- **OpenTofu** or Terraform ([install](https://opentofu.org/docs/intro/install/))
- **Ansible** ([install](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))
- **WireGuard** ([install](https://www.wireguard.com/install/))
- **ThreeFold account** with TFT balance
- **SSH keys** (`~/.ssh/id_ed25519` or `~/.ssh/id_rsa`)

### Optional
- **jq** for JSON processing
- **tmux** or **screen** for session management

### Check Installation
```bash
# Check if tools are installed
command -v tofu || command -v terraform
command -v ansible
command -v wg
command -v ssh-keygen
```

## Installation

### 1. Install Prerequisites

**Ubuntu/Debian:**
```bash
# OpenTofu
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash

# Ansible
sudo apt install ansible

# WireGuard
sudo apt install wireguard

# jq
sudo apt install jq
```

**macOS:**
```bash
# Homebrew
brew install opentofu ansible wireguard-tools jq
```

### 2. Setup ThreeFold Account

1. Create account: [ThreeFold Connect](https://manual.grid.tf/documentation/threefold_token/buy_sell_tft/threefold_connect.html)
2. Get TFT tokens
3. Save mnemonic to `~/.config/threefold/mnemonic`

### 3. Find Node ID

Visit [ThreeFold Grid Explorer](https://dashboard.grid.tf/) and find a node with:
- Available resources (4 CPU, 8GB RAM minimum)
- Good uptime
- Your preferred location

### 4. Configure TFGrid AI-Agent

```bash
git clone https://github.com/mik-tf/tfgrid-ai-agent
cd tfgrid-ai-agent
cp .env.example .env
nano .env
```

Edit `.env`:
```bash
# ThreeFold Grid
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=1234  # Your node ID
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192
export TF_VAR_ai_agent_disk=100

# Git identity
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"

# Git providers (optional)
export GITHUB_USER="yourusername"
```

### 5. Set Mnemonic

```bash
# Bash
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)

# Fish
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)
```

### 6. Deploy

```bash
make deploy
```

This will:
1. Deploy VM on ThreeFold Grid (2-5 minutes)
2. Setup WireGuard connection
3. Generate Ansible inventory
4. Install Node.js, Qwen CLI, and ai-agent
5. Configure git and SSH keys

## Usage

### Complete Workflow Example

```bash
# 1. Deploy infrastructure
make deploy

# 2. Verify deployment
make verify

# 3. Show VM addresses
make address

# 4. Login to Qwen
make login-qwen

# 5. Create project
make create-project project=my-website

# 6. (Optional) Setup git remote
make git-show-key  # Copy key to GitHub
make git-setup project=my-website provider=github

# 7. Start AI agent
make run-project project=my-website

# 8. Monitor in another terminal
make monitor-project project=my-website

# 9. Connect to VM (optional)
make connect

# 10. Stop AI agent when done
make stop-project project=my-website

# 11. List all projects
make list-projects

# 12. Clean up (when done)
make clean
```

### Common Commands

**Infrastructure:**
```bash
make infrastructure  # Deploy VM only
make wireguard      # Setup WireGuard (alias: make wg)
make inventory      # Generate Ansible inventory
make ansible        # Configure VM
make clean          # Destroy everything
make verify         # Check deployment status
```

**Network:**
```bash
make address        # Show all addresses
make connect        # SSH to VM
make ping           # Test connectivity
```

**Agent:**
```bash
make login-qwen                         # Login to Qwen
make create-project project=my-app      # Create project
make run-project project=my-app         # Start AI agent
make monitor-project project=my-app     # Monitor progress
make stop-project project=my-app        # Stop AI agent
make list-projects                      # List all projects
```

**Git:**
```bash
make git-show-key                                  # Show SSH key
make git-setup project=my-app provider=github      # GitHub
make git-setup project=my-app provider=gitea       # Gitea
make git-setup project=my-app provider=<custom>    # Custom URL
```

## Configuration

### Single Configuration File

TFGrid AI-Agent uses a **single `.env` file** for all configuration:

```bash
# .env - Non-sensitive configuration only

# ThreeFold Grid (TF_VAR_* automatically used by OpenTofu)
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=1234
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192
export TF_VAR_ai_agent_disk=100

# Git Identity
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"

# Git Providers (optional, for convenience)
export GITHUB_USER="myusername"
export GITEA_URL="git.example.com"
export GITEA_USER="myusername"
```

### Sensitive Data (Outside .env)

**Never put sensitive data in `.env`!** Use environment variables:

```bash
# Mnemonic (required)
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)

# API Key (optional, only if using paid tier)
set -x ANTHROPIC_API_KEY (cat ~/.config/anthropic/api_key)
```

### VM Resources

Recommended resources based on workload:

| Workload | CPU | RAM | Disk |
|----------|-----|-----|------|
| **Light** (small projects) | 2 | 4096 | 50 |
| **Medium** (default) | 4 | 8192 | 100 |
| **Heavy** (large codebases) | 8 | 16384 | 200 |

### Network Selection

Choose network in `.env`:
- `main` - Production network (recommended)
- `test` - Test network (for testing)
- `dev` - Development network

## Documentation

Comprehensive documentation in `docs/`:

### Technical Documentation
- **[QUICKSTART.md](docs/QUICKSTART.md)** - 5-minute getting started guide
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - System design and components
- **[CONFIGURATION.md](docs/CONFIGURATION.md)** - Detailed configuration guide
- **[USAGE.md](docs/USAGE.md)** - Complete usage examples
- **[GIT_INTEGRATION.md](docs/GIT_INTEGRATION.md)** - Git setup and workflows
- **[TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[SECURITY.md](docs/SECURITY.md)** - Security best practices

### Business & Advanced
- **[BUSINESS.md](docs/BUSINESS.md)** - Business strategy & monetization guide
- **[AI_PROVIDERS.md](docs/AI_PROVIDERS.md)** - Multi-AI provider support (Claude, GPT-4, Gemini, DeepSeek, etc.)
- **[TFGRID_AI_NODES.md](docs/TFGRID_AI_NODES.md)** - Self-hosted AI on TFGrid GPU nodes (future roadmap)

## Troubleshooting

### Cannot Connect to VM

```bash
# Check WireGuard
sudo wg show wg-ai-agent

# Restart WireGuard
make wireguard

# Test connectivity
make ping
```

### Qwen Not Authenticated

```bash
# Login to Qwen
make login-qwen

# Or connect and login manually
make connect
qwen login
```

### Git Push Fails

```bash
# Show git SSH key
make git-show-key

# Add key to GitHub/Gitea
# Then setup remote again
make git-setup project=my-app provider=github
```

### Project Not Found

```bash
# List projects
make list-projects

# Create project
make create-project project=my-app
```

### Deployment Fails

```bash
# Verify prerequisites
command -v tofu
command -v ansible
command -v wg

# Check mnemonic
echo $TF_VAR_mnemonic

# Check .env
cat .env

# Try again
make clean
make deploy
```

See [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for more solutions.

## Security Best Practices

1. **Never commit `.env`** or sensitive data (already in `.gitignore`)
2. **Use environment variables** for mnemonic and API keys
3. **Rotate keys regularly** and use key restrictions
4. **Use SSH key authentication** for git (not HTTPS tokens)
5. **Set proper file permissions** on credential files (600)
6. **Destroy VMs** when not in use to minimize attack surface
7. **Use WireGuard** for all VM communication (encrypted)

## Contributing

Contributions welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) first.

### Development Setup

```bash
git clone https://github.com/mik-tf/tfgrid-ai-agent
cd tfgrid-ai-agent
# Make changes
# Test thoroughly
git commit -m "Description"
git push
```

### Reporting Issues

Open an issue with:
- Clear description
- Steps to reproduce
- Expected vs actual behavior
- Logs and error messages
- Environment info (OS, versions)

## License

Apache License 2.0 - See [LICENSE](LICENSE) for details.

Copyright 2025 ThreeFold

## Acknowledgments

- **tfgrid-gateway** - Infrastructure template
- **ai-agent** - AI automation framework
- **ThreeFold Grid** - Decentralized cloud infrastructure
- **Anthropic Qwen** - AI coding assistant

## Links

- [ThreeFold Grid](https://threefold.io/)
- [ThreeFold Manual](https://manual.grid.tf/)
- [Grid Explorer](https://dashboard.grid.tf/)
- [AI agent technique](https://github.com/mik-tf/ai-agent)
- [OpenTofu](https://opentofu.org/)
- [Ansible](https://www.ansible.com/)

---

**Happy AI Coding on ThreeFold Grid!** 🚀
