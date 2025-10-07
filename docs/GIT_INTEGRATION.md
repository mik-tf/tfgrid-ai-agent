# Git Integration Guide

Complete guide to git workflows and integration with TFGrid AI-Agent.

## Table of Contents
- [Overview](#overview)
- [SSH Key Management](#ssh-key-management)
- [GitHub Integration](#github-integration)
- [Gitea Integration](#gitea-integration)
- [GitLab Integration](#gitlab-integration)
- [Git Workflows](#git-workflows)
- [Branch Strategies](#branch-strategies)
- [Troubleshooting](#troubleshooting)

## Overview

TFGrid AI-Agent integrates with git to automatically commit and push changes made by the AI agent. This provides:

- **Version Control**: Track all changes The agent makes
- **Backup**: Code is safely stored remotely
- **Collaboration**: Review the agent's work via pull requests
- **Recovery**: Easy rollback if needed

### Git Architecture

```
AI agent VM                      Git Remote
  ↓                              ↓
Project files changed      GitHub/Gitea/GitLab
  ↓                              ↓
git add .                    Repository
  ↓                              ↓
git commit                   History
  ↓                              ↓
git push ──(SSH)─────────────▶ Updates
```

## SSH Key Management

### Two SSH Keys Explained

**1. Local Machine SSH Key** (`~/.ssh/id_ed25519`):
- **Purpose**: SSH access from your machine to AI agent VM
- **Location**: Your local machine
- **Auto-detected**: By OpenTofu during deployment
- **Usage**: `ssh root@VM_IP`

**2. VM Git SSH Key** (`/root/.ssh/id_ed25519_git`):
- **Purpose**: Git operations from VM to GitHub/Gitea
- **Location**: AI agent VM
- **Generated**: During `make ansible`
- **Usage**: The AI agent's git push/pull operations

### Generate Local SSH Key (if needed)

```bash
# Check if you have a key
ls ~/.ssh/id_ed25519 ~/.ssh/id_rsa

# Generate new key if needed
ssh-keygen -t ed25519 -C "your@email.com"

# Use default location: ~/.ssh/id_ed25519
# Set passphrase (optional but recommended)
```

### View VM Git SSH Key

**From local machine:**
```bash
make git-show-key
```

**Manual method:**
```bash
make connect
cat /root/.ssh/id_ed25519_git.pub
```

**Output:**
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIxxx... ai-agent@tfgrid
```

### SSH Key Security

**Best Practices:**
- ✅ Generate separate keys for different purposes
- ✅ Use ed25519 (modern, secure)
- ✅ Add passphrase to private keys
- ✅ Restrict key permissions (chmod 600)
- ❌ Never share private keys
- ❌ Never commit keys to git

## GitHub Integration

### Setup GitHub

**Method 1: Using GitHub CLI**
```bash
# Install GitHub CLI
# Ubuntu: sudo apt install gh
# macOS: brew install gh

# Login
gh auth login

# Create repository
gh repo create my-app --private

# Get SSH URL
gh repo view --json sshUrl -q .sshUrl
```

**Method 2: Via Web Interface**
1. Visit [GitHub](https://github.com/new)
2. Create new repository
3. Don't initialize with README
4. Copy SSH URL: `git@github.com:user/my-app.git`

### Add SSH Key to GitHub

**Via Web:**
1. Get VM git key: `make git-show-key`
2. Visit [GitHub SSH Keys](https://github.com/settings/keys)
3. Click "New SSH key"
4. Title: "TFGrid AI-Agent VM"
5. Paste public key
6. Click "Add SSH key"

**Via CLI:**
```bash
# Get key
VM_KEY=$(make git-show-key | tail -1)

# Add to GitHub
gh ssh-key add <(echo "$VM_KEY") --title "TFGrid AI-Agent VM"
```

### Configure TFGrid AI-Agent for GitHub

**In `.env`:**
```bash
export GITHUB_USER="yourusername"
```

### Setup Git Remote (GitHub)

**Automatic setup:**
```bash
make git-setup project=my-app provider=github
```

This constructs: `git@github.com:yourusername/my-app.git`

**Manual setup:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
git remote add origin git@github.com:yourusername/my-app.git
git push -u origin main
```

**With custom username:**
```bash
make git-setup project=my-app provider=github user=differentuser
```

### Verify GitHub Integration

```bash
make connect
cd /opt/ai-agent-projects/my-app

# Check remote
git remote -v

# Test SSH connection
ssh -T git@github.com

# Make test push
git push origin main

# Check on GitHub
# Visit: https://github.com/yourusername/my-app
```

## Gitea Integration

### Setup Gitea

**Prerequisites:**
- Gitea instance URL (e.g., `git.example.com`)
- Gitea account

**Configure in `.env`:**
```bash
export GITEA_URL="git.example.com"
export GITEA_USER="yourusername"
```

### Add SSH Key to Gitea

1. Get VM git key: `make git-show-key`
2. Visit your Gitea instance: `https://git.example.com`
3. User Settings → SSH Keys → Add Key
4. Title: "TFGrid AI-Agent VM"
5. Paste public key
6. Click "Add Key"

### Create Repository on Gitea

**Via Web Interface:**
1. Click "+" → New Repository
2. Repository name: `my-app`
3. Visibility: Private/Public
4. Don't initialize with README
5. Create Repository

**Via API (if available):**
```bash
curl -X POST "https://git.example.com/api/v1/user/repos" \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"my-app","private":true}'
```

### Setup Git Remote (Gitea)

**Automatic:**
```bash
make git-setup project=my-app provider=gitea
```

This constructs: `git@git.example.com:yourusername/my-app.git`

**Manual:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
git remote add origin git@git.example.com:yourusername/my-app.git
git push -u origin main
```

### Verify Gitea Integration

```bash
make connect
cd /opt/ai-agent-projects/my-app

# Check remote
git remote -v

# Test SSH connection
ssh -T git@git.example.com

# Test push
git push origin main
```

## GitLab Integration

### Setup GitLab

**Configure in `.env`:**
```bash
export GITLAB_USER="yourusername"
```

### Add SSH Key to GitLab

1. Get VM git key: `make git-show-key`
2. Visit [GitLab SSH Keys](https://gitlab.com/-/profile/keys)
3. Key: Paste public key
4. Title: "TFGrid AI-Agent VM"
5. Click "Add key"

### Create Repository on GitLab

**Via Web:**
1. New Project → Create blank project
2. Project name: `my-app`
3. Visibility: Private/Public
4. Uncheck "Initialize repository with a README"
5. Create project

**Via CLI:**
```bash
# Install glab
# macOS: brew install glab

# Login
glab auth login

# Create repo
glab repo create my-app --private
```

### Setup Git Remote (GitLab)

**Automatic:**
```bash
make git-setup project=my-app provider=gitlab
```

**Manual:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
git remote add origin git@gitlab.com:yourusername/my-app.git
git push -u origin main
```

## Git Workflows

### Basic Workflow

```bash
# 1. Create project
make create-project project=my-app

# 2. Setup git
make git-show-key  # Add to GitHub/Gitea/GitLab
make git-setup project=my-app provider=github

# 3. Start AI agent (auto-commits and pushes)
make run-project project=my-app

# 4. The agent makes changes, commits, and pushes automatically
# Check commits on GitHub/Gitea/GitLab
```

### Workflow with Code Review

**Setup:**
```bash
# Configure the agent to push to dev branch
make connect
cd /opt/ai-agent-projects/my-app

# Create and switch to dev branch
git checkout -b agent-dev
git push -u origin agent-dev
```

**agent loop modified:**
```bash
# Edit agent-loop.sh to use agent-dev branch
git push origin agent-dev  # Instead of main
```

**Review workflow:**
1. The agent pushes to `agent-dev` branch
2. Review changes on GitHub/Gitea/GitLab
3. Create pull request: `agent-dev` → `main`
4. Review, test, approve
5. Merge to main

### Workflow with CI/CD

**Example: GitHub Actions**

```yaml
# .github/workflows/ai-agent-ci.yml
name: AI Agent CI

on:
  push:
    branches: [agent-dev]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Build
        run: npm run build
      - name: Lint
        run: npm run lint

  auto-merge:
    needs: test
    if: success()
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Create Pull Request
        run: gh pr create --base main --head agent-dev --fill
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Setup:**
```bash
# Create workflow directory
make connect
cd /opt/ai-agent-projects/my-app
mkdir -p .github/workflows
nano .github/workflows/ai-agent-ci.yml
# Paste workflow above

git add .github/workflows/ai-agent-ci.yml
git commit -m "Add CI workflow"
git push origin agent-dev
```

### Workflow with Multiple Remotes

**Use case**: Push to both GitHub and Gitea

```bash
make connect
cd /opt/ai-agent-projects/my-app

# Add second remote
git remote add gitea git@git.example.com:user/my-app.git

# Push to both
git push origin main
git push gitea main

# Or set up push to multiple remotes
git remote set-url --add --push origin git@github.com:user/my-app.git
git remote set-url --add --push origin git@git.example.com:user/my-app.git

# Now git push origin main pushes to both
```

## Branch Strategies

### Strategy 1: Direct to Main

**Best for**: Personal projects, experimentation

```
agent-dev (AI agent works here)
    ↓ push
main (production)
```

**Setup:**
```bash
# The agent pushes directly to main
# Default behavior
```

### Strategy 2: Development Branch

**Best for**: Projects requiring review

```
agent-dev (AI agent works here)
    ↓ push
    ↓ pull request
main (production, reviewed)
```

**Setup:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
git checkout -b agent-dev
git push -u origin agent-dev
```

### Strategy 3: Feature Branches

**Best for**: Multiple features in parallel

```
ai-agent-feature-1 (Feature 1)
    ↓
ai-agent-feature-2 (Feature 2)
    ↓
agent-dev (integration)
    ↓
main (production)
```

**Setup:**
```bash
# Manually create feature branches as needed
make connect
cd /opt/ai-agent-projects/my-app
git checkout -b ai-agent-feature-auth
# Configure the agent to work on this branch
```

### Strategy 4: Checkpoint Branches

**Best for**: Long-running agent sessions

```
main
 ├─ checkpoint-day1
 ├─ checkpoint-day2
 └─ checkpoint-day3
```

**Setup:**
```bash
# Periodically create checkpoint branches
make connect
cd /opt/ai-agent-projects/my-app
git checkout -b checkpoint-$(date +%Y%m%d)
git push origin checkpoint-$(date +%Y%m%d)
git checkout main
```

## Troubleshooting

### SSH Key Not Working

**Problem**: `Permission denied (publickey)`

**Solution:**
```bash
# Verify key is added to GitHub/Gitea/GitLab
make git-show-key

# Test SSH connection
make connect
ssh -T git@github.com
# Should see: "Hi username! You've successfully authenticated..."

# Check SSH key on VM
cat /root/.ssh/id_ed25519_git.pub

# Verify key is in GitHub settings
```

### Remote Already Exists

**Problem**: `fatal: remote origin already exists`

**Solution:**
```bash
make connect
cd /opt/ai-agent-projects/my-app

# Remove existing remote
git remote remove origin

# Add correct remote
git remote add origin git@github.com:user/my-app.git
```

### Push Rejected

**Problem**: `! [rejected] main -> main (fetch first)`

**Solution:**
```bash
make connect
cd /opt/ai-agent-projects/my-app

# Pull first (if repository initialized with files)
git pull origin main --rebase

# Or force push (if safe to do so)
git push -f origin main
```

### Wrong Repository URL

**Problem**: Pushing to wrong repository

**Solution:**
```bash
make connect
cd /opt/ai-agent-projects/my-app

# Check current remote
git remote -v

# Update remote URL
git remote set-url origin git@github.com:user/correct-repo.git

# Verify
git remote -v
```

### Large File Issues

**Problem**: `remote: error: File large-file.bin is 156 MB; this exceeds GitHub's file size limit`

**Solution:**
```bash
make connect
cd /opt/ai-agent-projects/my-app

# Add to .gitignore
echo "large-file.bin" >> .gitignore
git add .gitignore
git commit -m "Ignore large files"

# Or use Git LFS
git lfs install
git lfs track "*.bin"
git add .gitattributes
```

### Merge Conflicts

**Problem**: The agent encounters merge conflicts

**Solution:**
```bash
make stop-project project=my-app
make connect
cd /opt/ai-agent-projects/my-app

# Resolve conflicts manually
git status
nano conflicted-file.txt  # Resolve conflicts
git add conflicted-file.txt
git commit -m "Resolve conflicts"
git push origin main

# Restart the agent
make run-project project=my-app
```

---

**Related Documentation:**
- [USAGE.md](USAGE.md) - Usage examples
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - General troubleshooting
