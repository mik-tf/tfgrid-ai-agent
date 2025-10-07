# Troubleshooting Guide

Comprehensive guide to solving common issues with TFGrid AI-Agent.

## Table of Contents
- [Deployment Issues](#deployment-issues)
- [Network Issues](#network-issues)
- [Authentication Issues](#authentication-issues)
- [Agent Issues](#ai-agent-issues)
- [Git Issues](#git-issues)
- [Performance Issues](#performance-issues)
- [Recovery Procedures](#recovery-procedures)

## Deployment Issues

### OpenTofu/Terraform Not Found

**Problem**: `command not found: tofu`

**Solution:**
```bash
# Install OpenTofu
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh | bash

# Verify installation
tofu version

# Or install Terraform
# Ubuntu: sudo apt install terraform
# macOS: brew install terraform
```

### Mnemonic Not Set

**Problem**: `Error: TF_VAR_mnemonic not set`

**Solution:**
```bash
# Check if mnemonic file exists
ls ~/.config/threefold/mnemonic

# Set environment variable
# Bash:
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)

# Fish:
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)

# Verify
echo $TF_VAR_mnemonic  # Should show your mnemonic
```

### Node Not Found

**Problem**: `Error: Node 1234 not found on network`

**Solutions:**

1. **Verify node exists:**
   - Visit [Grid Explorer](https://dashboard.grid.tf/)
   - Search for your node ID
   - Check if node is online

2. **Check network selection:**
   ```bash
   # In .env, verify:
   export TF_VAR_tfgrid_network="main"  # or "test", "dev"
   ```

3. **Try different node:**
   - Find alternative node on Grid Explorer
   - Update `.env` with new node ID

### Insufficient Resources

**Problem**: `Error: Node has insufficient resources`

**Solution:**
```bash
# Reduce resource requirements in .env
export TF_VAR_ai_agent_cpu=2
export TF_VAR_ai_agent_mem=4096
export TF_VAR_ai_agent_disk=50

# Redeploy
make clean
make deploy
```

### Deployment Hangs

**Problem**: Deployment stuck at "Waiting for VM..."

**Solutions:**

1. **Check node status:**
   - Verify node is online on Grid Explorer
   - Try different node if current is unreliable

2. **Restart deployment:**
   ```bash
   # Cancel current deployment (Ctrl+C)
   make clean
   make deploy
   ```

3. **Check logs:**
   ```bash
   cd infrastructure
   tofu plan  # See if there are issues
   ```

### Ansible Fails

**Problem**: `UNREACHABLE! => {"changed": false, "msg": "Failed to connect"}`

**Solutions:**

1. **Check WireGuard:**
   ```bash
   make wireguard
   make ping
   ```

2. **Verify inventory:**
   ```bash
   cat platform/inventory.ini
   # Verify IP address is correct
   ```

3. **Test SSH manually:**
   ```bash
   cd infrastructure
   VM_IP=$(tofu output -raw ai_agent_wg_ip)
   ssh -o StrictHostKeyChecking=no root@$VM_IP
   ```

4. **Regenerate and retry:**
   ```bash
   make inventory
   make ansible
   ```

## Network Issues

### Cannot Connect to VM

**Problem**: `ssh: connect to host X.X.X.X port 22: No route to host`

**Solutions:**

1. **Check WireGuard status:**
   ```bash
   sudo wg show wg-ai-agent
   # Should show interface is up
   ```

2. **Restart WireGuard:**
   ```bash
   make wireguard
   ```

3. **Test connectivity:**
   ```bash
   make ping
   ```

4. **Check firewall:**
   ```bash
   # On local machine
   sudo iptables -L
   sudo ufw status
   ```

5. **Verify IP address:**
   ```bash
   make address
   # Verify you're using correct WireGuard IP
   ```

### WireGuard Won't Start

**Problem**: `wg-quick: `wg-ai-agent' already exists`

**Solution:**
```bash
# Stop existing interface
sudo wg-quick down wg-ai-agent

# Restart
make wireguard

# Or force restart
sudo wg-quick down wg-ai-agent 2>/dev/null || true
sudo wg-quick up wg-ai-agent
```

### Permission Denied on WireGuard

**Problem**: `Permission denied when running make wireguard`

**Solution:**
```bash
# WireGuard requires sudo
# Commands are already using sudo in scripts

# If still issues, check sudo permissions
sudo -v

# Or run with explicit sudo
sudo ./scripts/wg.sh
```

### High Latency

**Problem**: Slow connection to VM

**Solutions:**

1. **Choose closer node:**
   - Deploy on node in your region
   - Check node location on Grid Explorer

2. **Check network:**
   ```bash
   # Test latency
   ping $(cd infrastructure && tofu output -raw ai_agent_wg_ip)
   
   # Check hops
   traceroute $(cd infrastructure && tofu output -raw ai_agent_wg_ip)
   ```

3. **Use Mycelium as alternative:**
   ```bash
   cd infrastructure
   MYCELIUM_IP=$(tofu output -raw ai_agent_mycelium_ip)
   ping6 $MYCELIUM_IP
   ```

## Authentication Issues

### Qwen Not Authenticated

**Problem**: `Error: Qwen not authenticated on VM`

**Solution:**
```bash
# Login to Qwen
make login-qwen

# Verify authentication
make connect
qwen auth status

# Should show: "Authenticated as: your@email.com"
```

### Qwen Login Fails

**Problem**: `Error during Qwen login`

**Solutions:**

1. **Check internet on VM:**
   ```bash
   make connect
   ping -c 3 8.8.8.8
   curl -I https://www.anthropic.com
   ```

2. **Try API key method:**
   ```bash
   # Set API key
   export ANTHROPIC_API_KEY=sk-ant-api03-xxx
   
   # Reconfigure VM
   make ansible
   ```

3. **Update Qwen CLI:**
   ```bash
   make connect
   npm update -g @anthropics/claude-cli
   qwen version
   ```

### SSH Key Issues

**Problem**: `Permission denied (publickey)`

**Solutions:**

1. **Verify SSH key exists:**
   ```bash
   ls ~/.ssh/id_ed25519 ~/.ssh/id_rsa
   ```

2. **Generate if missing:**
   ```bash
   ssh-keygen -t ed25519 -C "your@email.com"
   ```

3. **Check key permissions:**
   ```bash
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

4. **Redeploy infrastructure:**
   ```bash
   make clean
   make deploy
   ```

## Agent Issues

### Project Not Found

**Problem**: `Error: Project 'my-app' not found on VM`

**Solution:**
```bash
# List existing projects
make list-projects

# Create project if doesn't exist
make create-project project=my-app

# Or check name spelling
make connect
ls /opt/ai-agent-projects/
```

### AI agent loop Not Starting

**Problem**: The agent doesn't start or exits immediately

**Solutions:**

1. **Check Qwen authentication:**
   ```bash
   make connect
   qwen auth status
   ```

2. **Check project exists:**
   ```bash
   make list-projects
   ```

3. **View error logs:**
   ```bash
   make connect
   cd /opt/ai-agent-projects/my-app
   cat agent-errors.log
   ```

4. **Manually start and debug:**
   ```bash
   make connect
   cd /opt/ai-agent-projects/my-app
   cat prompt.md | qwen
   # See what error occurs
   ```

### Agent Stuck in Loop

**Problem**: The agent repeatedly tries same approach

**Solution:**
```bash
# Stop AI agent
make stop-project project=my-app

# Update prompt with guidance
make connect
cd /opt/ai-agent-projects/my-app
nano prompt.md
# Add: "Previous approach failed. Try alternative: ..."

# Restart
make run-project project=my-app
```

### Agent Making Unwanted Changes

**Problem**: Agent modifying wrong files or going off-track

**Solution:**
```bash
# Stop immediately
make stop-project project=my-app

# Review changes
make connect
cd /opt/ai-agent-projects/my-app
git log --oneline -10
git diff HEAD~5..HEAD

# Rollback if needed
git reset --hard HEAD~5

# Update prompt with constraints
nano prompt.md
# Add: "Only modify files in src/ directory. Don't touch config files."

# Restart
make run-project project=my-app
```

### Out of Tokens

**Problem**: `Error: Rate limit exceeded`

**Solutions:**

1. **Wait for reset (free tier):**
   - 2000 tokens/day resets daily
   - Check current usage on Anthropic dashboard

2. **Use API key (paid tier):**
   ```bash
   export ANTHROPIC_API_KEY=sk-ant-api03-xxx
   make ansible  # Reconfigure VM
   ```

3. **Optimize prompts:**
   - Make prompts more concise
   - Reduce context size
   - Focus on specific tasks

## Git Issues

### Git Push Fails

**Problem**: `Permission denied (publickey)`

**Solution:**
```bash
# Show git SSH key
make git-show-key

# Add to GitHub/Gitea/GitLab
# Then retry setup
make git-setup project=my-app provider=github
```

See [GIT_INTEGRATION.md](GIT_INTEGRATION.md) for detailed git troubleshooting.

### Repository Already Exists

**Problem**: `repository already exists on GitHub`

**Solution:**
```bash
# Use existing repository
make git-setup project=my-app provider=git@github.com:user/my-app.git

# Or delete remote repository and recreate
# GitHub: Settings → Delete Repository
```

### Merge Conflicts

**Problem**: The agent encounters merge conflicts

**Solution:**
```bash
make stop-project project=my-app
make connect
cd /opt/ai-agent-projects/my-app

# Check status
git status

# Resolve conflicts
nano conflicted-file.txt
git add conflicted-file.txt
git commit -m "Resolve conflicts"

# Continue
make run-project project=my-app
```

## Performance Issues

### VM Running Slow

**Problem**: High CPU/RAM usage, slow responses

**Solutions:**

1. **Check resources on VM:**
   ```bash
   make connect
   htop
   df -h
   free -h
   ```

2. **Increase resources:**
   ```bash
   # In .env
   export TF_VAR_ai_agent_cpu=8
   export TF_VAR_ai_agent_mem=16384
   
   # Redeploy
   make clean
   make deploy
   ```

3. **Stop other processes:**
   ```bash
   make connect
   
   # Stop other agent instances
   make stop-project project=other-app
   
   # Check running processes
   ps aux | grep agent
   ```

4. **Clean up disk space:**
   ```bash
   make connect
   
   # Remove old projects
   rm -rf /opt/ai-agent-projects/old-project
   
   # Clean package caches
   apt clean
   npm cache clean --force
   ```

### Disk Full

**Problem**: `No space left on device`

**Solution:**
```bash
make connect

# Check disk usage
df -h
du -sh /opt/ai-agent-projects/*

# Clean up
rm -rf /opt/ai-agent-projects/old-project
apt clean
journalctl --vacuum-time=7d

# Or increase disk size
# In .env:
export TF_VAR_ai_agent_disk=200
make clean
make deploy
```

### High Memory Usage

**Problem**: VM running out of RAM

**Solutions:**

1. **Check memory usage:**
   ```bash
   make connect
   free -h
   top
   ```

2. **Increase RAM:**
   ```bash
   export TF_VAR_ai_agent_mem=16384
   make clean
   make deploy
   ```

3. **Limit concurrent projects:**
   ```bash
   # Run only one agent instance at a time
   make stop-project project=project1
   make run-project project=project2
   ```

## Recovery Procedures

### Complete Infrastructure Reset

**When**: Everything is broken, start fresh

```bash
# 1. Destroy everything
make clean

# 2. Verify clean state
sudo wg show wg-ai-agent  # Should fail
cd infrastructure && tofu state list  # Should be empty

# 3. Redeploy from scratch
make deploy

# 4. Verify
make verify
make address
```

### Recover Lost Project

**When**: Project deleted or corrupted on VM

```bash
# If git remote exists:
make create-project project=my-app
make connect
cd /opt/ai-agent-projects/my-app

# Clone from remote
git remote add origin git@github.com:user/my-app.git
git pull origin main

# Continue work
make run-project project=my-app
```

### Recover from Bad Commits

**When**: The agent made bad changes, need to rollback

```bash
make stop-project project=my-app
make connect
cd /opt/ai-agent-projects/my-app

# View history
git log --oneline -20

# Rollback to good commit
git reset --hard abc123

# Force push to remote (if needed)
git push -f origin main

# Update prompt and restart
nano prompt.md
make run-project project=my-app
```

### Reset VM Without Destroying Infrastructure

**When**: VM is messed up but infrastructure is fine

```bash
# Connect and clean up
make connect

# Stop all agent processes
pkill -f agent-loop

# Remove all projects
rm -rf /opt/ai-agent-projects/*

# Reinstall ai-agent
cd /opt
rm -rf ai-agent
git clone https://github.com/mik-tf/ai-agent.git

# Reconfigure
exit
make ansible
```

## Getting Help

### Debug Mode

```bash
# Run with verbose output
cd infrastructure
tofu apply -debug

# Ansible verbose mode
cd platform
ansible-playbook -i inventory.ini site.yml -vvv

# Check all logs
make connect
journalctl -f
tail -f /var/log/syslog
```

### Collect Diagnostic Information

```bash
# System info
make verify

# Network info
make address
sudo wg show wg-ai-agent

# VM info
make connect
uname -a
free -h
df -h
uptime

# Agent info
cd /opt/ai-agent-projects/my-app
git log --oneline -10
tail -50 agent-output.log
tail -50 agent-errors.log
```

### Report Issues

When reporting issues, include:

1. **Environment:**
   - OS and version
   - OpenTofu/Terraform version
   - Ansible version
   - WireGuard version

2. **Configuration:**
   - `.env` contents (without sensitive data)
   - Network selected (main/test/dev)
   - VM resources

3. **Error messages:**
   - Complete error output
   - Relevant log files
   - Steps to reproduce

4. **What you've tried:**
   - Troubleshooting steps attempted
   - Any workarounds found

---

**Related Documentation:**
- [QUICKSTART.md](QUICKSTART.md) - Setup guide
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration
- [GIT_INTEGRATION.md](GIT_INTEGRATION.md) - Git issues
- [SECURITY.md](SECURITY.md) - Security practices
