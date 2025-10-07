# Configuration Guide

Complete guide to configuring TFGrid AI-Agent.

## Table of Contents
- [Overview](#overview)
- [Configuration File](#configuration-file)
- [Environment Variables](#environment-variables)
- [ThreeFold Grid Settings](#threefold-grid-settings)
- [VM Resources](#vm-resources)
- [Git Configuration](#git-configuration)
- [Qwen Authentication](#qwen-authentication)
- [Advanced Configuration](#advanced-configuration)

## Overview

TFGrid AI-Agent uses a **single configuration file** (`.env`) for all non-sensitive settings, and **environment variables** for sensitive data like mnemonics and API keys.

### Configuration Philosophy

✅ **DO**: Put configuration in `.env`  
✅ **DO**: Use environment variables for secrets  
❌ **DON'T**: Put sensitive data in `.env`  
❌ **DON'T**: Commit `.env` to git (already in `.gitignore`)

## Configuration File

### Setup

```bash
# Copy template
cp .env.example .env

# Edit configuration
nano .env
```

### Complete .env Example

```bash
# ==============================================================================
# THREEFOLD GRID CONFIGURATION
# ==============================================================================

# Network: main (production), test, or dev
export TF_VAR_tfgrid_network="main"

# Node ID for AI agent VM (from Grid Explorer)
export TF_VAR_ai_agent_node=1234

# VM Resources
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192   # 8GB RAM in MB
export TF_VAR_ai_agent_disk=100   # 100GB storage

# ==============================================================================
# GIT CONFIGURATION
# ==============================================================================

# Git Identity (used for commits made by the AI agent)
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"

# Git Providers (optional, for convenience commands)
export GITHUB_USER="myusername"
export GITEA_URL="git.example.com"
export GITEA_USER="myusername"
export GITLAB_USER="myusername"
```

## Environment Variables

### Sensitive Data (Set Separately)

**Required:**
```bash
# ThreeFold mnemonic
# Bash:
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)

# Fish:
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)
```

**Optional:**
```bash
# Qwen API key (only if using paid tier instead of free Google login)
# Bash:
export ANTHROPIC_API_KEY=$(cat ~/.config/anthropic/api_key)

# Fish:
set -x ANTHROPIC_API_KEY (cat ~/.config/anthropic/api_key)
```

### Why Separate?

- **Security**: Sensitive data never in files
- **Safety**: Can't accidentally commit secrets
- **Flexibility**: Easy to rotate keys
- **Best Practice**: Industry standard pattern

## ThreeFold Grid Settings

### Network Selection

```bash
export TF_VAR_tfgrid_network="main"
```

**Options:**

| Network | Description | Use Case |
|---------|-------------|----------|
| `main` | Production network | Real deployments, stable |
| `test` | Test network | Testing, cheaper TFT |
| `dev` | Development network | Experimental features |

**Recommendation**: Use `main` for production, `test` for testing.

### Node Selection

```bash
export TF_VAR_ai_agent_node=1234
```

**How to find nodes:**

1. Visit [ThreeFold Grid Explorer](https://dashboard.grid.tf/)
2. Filter by:
   - **Location**: Choose nearby for lower latency
   - **Resources**: Ensure sufficient CPU/RAM/disk
   - **Uptime**: Look for high uptime percentage
   - **Price**: Compare pricing

**Example nodes** (as of 2025):
- Node 14: Belgium, high resources
- Node 7: USA, reliable
- Node 121: Germany, good uptime

### Finding Available Nodes

```bash
# Use Grid Explorer filters:
# - Min CPU: 4
# - Min RAM: 8192 MB
# - Min Storage: 100 GB
# - Public IPv4: Not required (we use WireGuard)
```

## VM Resources

### Resource Configuration

```bash
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192
export TF_VAR_ai_agent_disk=100
```

### Resource Recommendations

| Workload | CPU | RAM (MB) | Disk (GB) | Use Case |
|----------|-----|----------|-----------|----------|
| **Light** | 2 | 4096 | 50 | Small projects, testing |
| **Medium** | 4 | 8192 | 100 | Standard projects (default) |
| **Heavy** | 8 | 16384 | 200 | Large codebases, multiple projects |
| **Extra Heavy** | 16 | 32768 | 500 | Enterprise workloads |

### Sizing Guidelines

**CPU**:
- 2 cores: Single small project
- 4 cores: 1-2 medium projects
- 8 cores: Multiple projects or large codebases
- 16+ cores: Parallel agent instances

**RAM**:
- 4GB: Minimum, basic Node.js projects
- 8GB: Recommended, comfortable for most projects
- 16GB: Large projects with many dependencies
- 32GB+: Multiple concurrent agent instances

**Disk**:
- 50GB: Minimal, few dependencies
- 100GB: Standard, room for git history
- 200GB: Multiple projects, extensive history
- 500GB+: Many large projects

### Cost Estimation

Approximate TFT costs (varies by node):
- Light (2/4GB/50GB): ~0.5-1 TFT/month
- Medium (4/8GB/100GB): ~1-2 TFT/month
- Heavy (8/16GB/200GB): ~3-5 TFT/month

**Check current pricing on Grid Explorer.**

## Git Configuration

### Git Identity

```bash
export GIT_USER_NAME="Your Name"
export GIT_USER_EMAIL="you@example.com"
```

**Used for:**
- Git commits made by the AI agent
- Shows up in git history
- GitHub/Gitea commit attribution

**Recommendations:**
- Use your real name and email
- Match your GitHub/Gitea profile
- Helps track the agent's work

### Git Provider Configuration

**GitHub:**
```bash
export GITHUB_USER="myusername"
```

**Gitea:**
```bash
export GITEA_URL="git.example.com"
export GITEA_USER="myusername"
```

**GitLab:**
```bash
export GITLAB_USER="myusername"
```

**Usage:**
```bash
# With configuration
make git-setup project=my-app provider=github

# Constructs: git@github.com:myusername/my-app.git
```

### SSH Key Management

**Two SSH keys are used:**

1. **Local machine key** (`~/.ssh/id_ed25519`):
   - For SSH access to AI agent VM
   - Auto-detected by OpenTofu
   - Your personal key

2. **VM git key** (`/root/.ssh/id_ed25519_git`):
   - Generated during `make ansible`
   - Used by the AI agent for git push/pull
   - Add to GitHub/Gitea

**View VM git key:**
```bash
make git-show-key
```

## Qwen Authentication

### Method 1: Interactive Login (Recommended)

```bash
make login-qwen
```

**Features:**
- Free 2000 tokens/day
- Google/Gmail authentication
- No API key needed
- Easy setup

**How it works:**
1. SSH to VM with TTY forwarding
2. Run `qwen login` on VM
3. Follow OAuth prompts in terminal
4. Token stored on VM only

### Method 2: API Key (Paid Tier)

```bash
# Store key securely
echo "sk-ant-api03-xxx" > ~/.config/anthropic/api_key
chmod 600 ~/.config/anthropic/api_key

# Set as environment variable
export ANTHROPIC_API_KEY=$(cat ~/.config/anthropic/api_key)

# Deploy (Ansible will configure VM)
make deploy
```

**When to use:**
- Need more than 2000 tokens/day
- Programmatic access required
- Team/organization usage
- Higher priority queue

### Checking Authentication

```bash
# From local machine
make connect

# On VM
qwen auth status
```

## Advanced Configuration

### Multiple VMs

Deploy multiple VMs for different projects:

**VM 1 Configuration:**
```bash
# .env.vm1
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=1234
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192
export TF_VAR_ai_agent_disk=100
```

**VM 2 Configuration:**
```bash
# .env.vm2
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=5678
export TF_VAR_ai_agent_cpu=8
export TF_VAR_ai_agent_mem=16384
export TF_VAR_ai_agent_disk=200
```

**Deploy:**
```bash
# VM 1
cp .env.vm1 .env
make deploy

# VM 2 (in separate directory)
mkdir ../tfgrid-ai-agent-vm2
cd ../tfgrid-ai-agent-vm2
cp ../tfgrid-ai-agent/.env.vm2 .env
make deploy
```

### Ansible Variables Override

Override variables at runtime:

```bash
cd platform
ansible-playbook -i inventory.ini site.yml \
  -e "nodejs_version=20" \
  -e "git_user_name='Custom Name'"
```

### Custom AI-Agent Repository

Use forked or custom ai-agent:

**In `platform/group_vars/all.yml`:**
```yaml
ai_agent_repo: https://github.com/yourusername/custom-ai-agent.git
```

### Ansible Vault for Secrets

For team deployments with shared secrets:

**Create vault:**
```bash
ansible-vault create platform/vault.yml
```

**Add secrets:**
```yaml
qwen_api_key: "sk-ant-api03-xxx"
git_deploy_key: "ssh-ed25519 AAAA..."
```

**Use in playbook:**
```yaml
# platform/group_vars/all.yml
qwen_api_key: "{{ vault_qwen_api_key }}"
```

**Deploy:**
```bash
make deploy --ask-vault-pass
```

### SSH Configuration

**Custom SSH key:**
```bash
# Generate new key
ssh-keygen -t ed25519 -f ~/.ssh/tfgrid_ai_agent

# Set in environment
export SSH_KEY=$(cat ~/.ssh/tfgrid_ai_agent.pub)

# Deploy
make deploy
```

### WireGuard Configuration

**Custom WireGuard interface name:**

Edit `scripts/wg.sh` and `Makefile` to use different interface:
```bash
# Instead of wg-ai-agent, use wg-ai-agent-prod
sudo wg-quick up wg-ai-agent-prod
```

### OpenTofu Backend Configuration

**Use remote backend for state:**

Create `infrastructure/backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket = "my-tfstate-bucket"
    key    = "tfgrid-ai-agent/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Configuration Validation

### Verify Configuration

```bash
# Check .env exists
test -f .env && echo "✅ .env exists" || echo "❌ .env missing"

# Check mnemonic set
test -n "$TF_VAR_mnemonic" && echo "✅ Mnemonic set" || echo "❌ Mnemonic not set"

# Check node ID set
source .env
test -n "$TF_VAR_ai_agent_node" && echo "✅ Node ID set" || echo "❌ Node ID not set"

# Verify deployment
make verify
```

### Configuration Checklist

Before deployment:

- [ ] `.env` created from `.env.example`
- [ ] `TF_VAR_tfgrid_network` set (main/test/dev)
- [ ] `TF_VAR_ai_agent_node` set (valid node ID)
- [ ] `TF_VAR_ai_agent_cpu/mem/disk` set (appropriate resources)
- [ ] `GIT_USER_NAME` and `GIT_USER_EMAIL` set
- [ ] `TF_VAR_mnemonic` environment variable set
- [ ] Prerequisites installed (tofu, ansible, wg)
- [ ] SSH keys exist (`~/.ssh/id_ed25519` or `id_rsa`)

## Environment-Specific Configuration

### Development Environment

```bash
# .env.dev
export TF_VAR_tfgrid_network="test"
export TF_VAR_ai_agent_node=1234
export TF_VAR_ai_agent_cpu=2
export TF_VAR_ai_agent_mem=4096
export TF_VAR_ai_agent_disk=50

export GIT_USER_NAME="AI Agent Dev"
export GIT_USER_EMAIL="dev@example.com"
```

### Production Environment

```bash
# .env.prod
export TF_VAR_tfgrid_network="main"
export TF_VAR_ai_agent_node=5678
export TF_VAR_ai_agent_cpu=8
export TF_VAR_ai_agent_mem=16384
export TF_VAR_ai_agent_disk=200

export GIT_USER_NAME="AI Agent Production"
export GIT_USER_EMAIL="prod@example.com"
```

### Switch Environments

```bash
# Use development
ln -sf .env.dev .env
make deploy

# Use production
ln -sf .env.prod .env
make deploy
```

## Troubleshooting Configuration

**Node not found:**
```bash
# Verify node exists on network
# Check Grid Explorer: https://dashboard.grid.tf/
```

**Insufficient resources:**
```bash
# Reduce resource requirements in .env
export TF_VAR_ai_agent_cpu=2
export TF_VAR_ai_agent_mem=4096
```

**Mnemonic not set:**
```bash
# Check mnemonic file exists
test -f ~/.config/threefold/mnemonic

# Set environment variable
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)
```

**Git identity not configured:**
```bash
# Check configuration
source .env
echo $GIT_USER_NAME
echo $GIT_USER_EMAIL

# Reconfigure and redeploy
make ansible
```

---

**Related Documentation:**
- [QUICKSTART.md](QUICKSTART.md) - Quick setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [SECURITY.md](SECURITY.md) - Security best practices
