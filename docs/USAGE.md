# Usage Guide

Comprehensive guide to using TFGrid AI-Agent with real-world examples.

## Table of Contents
- [Basic Workflow](#basic-workflow)
- [Project Management](#project-management)
- [Agent Operations](#ai-agent-operations)
- [Git Workflows](#git-workflows)
- [Monitoring and Control](#monitoring-and-control)
- [Multi-Project Management](#multi-project-management)
- [Real-World Examples](#real-world-examples)
- [Advanced Usage](#advanced-usage)

## Basic Workflow

### Complete End-to-End Example

```bash
# 1. Setup (one-time)
cd tfgrid-ai-agent
cp .env.example .env
nano .env  # Configure

# 2. Set mnemonic
set -x TF_VAR_mnemonic (cat ~/.config/threefold/mnemonic)

# 3. Deploy infrastructure
make deploy

# 4. Verify deployment
make verify
make address

# 5. Login to Qwen
make login-qwen

# 6. Create and run project
make create-project project=my-website
make run-project project=my-website

# 7. Monitor (in another terminal)
make monitor-project project=my-website

# 8. Setup git (optional)
make git-show-key  # Add to GitHub
make git-setup project=my-website provider=github

# 9. Stop when done
make stop-project project=my-website
```

## Project Management

### Creating Projects

**Basic creation:**
```bash
make create-project project=my-app
```

**Interactive prompts:**
1. Project name confirmation
2. Time constraint (30m, 1h, 2h30m, indefinite)
3. Prompt type (custom or generic template)
4. Template selection (if generic)
5. Auto-start option

**Behind the scenes:**
- Creates `/opt/ai-agent-projects/my-app/` on VM
- Initializes git repository
- Sets up prompt.md with instructions
- Configures agent metadata
- Creates workspace structure

### Listing Projects

```bash
make list-projects
```

**Output:**
```
📋 AI agent projects on VM
========================

agent projects in workspace:
  - my-website
  - api-service
  - mobile-app
```

### Project Structure

**On VM (`/opt/ai-agent-projects/my-app/`):**
```
my-app/
├── .agent/              # Agent metadata
│   ├── config.json      # Project configuration
│   └── time.log         # Time tracking
├── .git/               # Git repository
├── prompt.md           # AI instructions
├── agent-output.log    # Execution log
├── agent-errors.log    # Error log
├── .gitignore          # Git ignore rules
└── <project-files>     # Generated code
```

### Deleting Projects

**From local machine:**
```bash
make connect
cd /opt/ai-agent-projects
rm -rf my-old-project
```

**Or via SSH:**
```bash
ssh root@$(cd infrastructure && tofu output -raw ai_agent_wg_ip) \
  "rm -rf /opt/ai-agent-projects/my-old-project"
```

## Agent Operations

### Starting the agent

**Basic start:**
```bash
make run-project project=my-app
```

**What happens:**
1. Verifies Qwen authentication
2. Checks project exists
3. Starts agent-loop.sh in background
4. Logs to agent-output.log and agent-errors.log

**agent loop:**
```bash
while :; do
  cat prompt.md | qwen
  git add .
  git commit -m "Agent: automated changes"
  git push origin main
done
```

### Monitoring the agent

**Real-time monitoring:**
```bash
make monitor-project project=my-app
```

**Shows:**
- Recent log output
- Current activity
- Commit history
- Time elapsed

**Manual monitoring:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
tail -f agent-output.log
```

### Stopping the agent

**Graceful stop:**
```bash
make stop-project project=my-app
```

**Force stop (if needed):**
```bash
make connect
pkill -f "agent-loop.*my-app"
```

### Checking the agent Status

```bash
make connect

# Check if The agent is running
ps aux | grep agent-loop

# Check recent activity
cd /opt/ai-agent-projects/my-app
tail -20 agent-output.log

# Check git commits
git log --oneline -10
```

## Git Workflows

### GitHub Workflow

**Setup:**
```bash
# 1. Create project
make create-project project=my-app

# 2. Show git SSH key
make git-show-key

# 3. Add key to GitHub
# Visit: https://github.com/settings/keys

# 4. Create repository on GitHub
# Via web UI or: gh repo create my-app --private

# 5. Setup remote
make git-setup project=my-app provider=github

# 6. Start AI agent (will auto-push)
make run-project project=my-app
```

**Verify pushes:**
```bash
# Check GitHub repository
# Or connect to VM:
make connect
cd /opt/ai-agent-projects/my-app
git log --oneline
git remote -v
```

### Gitea Workflow

**Configure in .env:**
```bash
export GITEA_URL="git.example.com"
export GITEA_USER="myusername"
```

**Setup:**
```bash
# 1. Create project
make create-project project=my-app

# 2. Show and add SSH key to Gitea
make git-show-key

# 3. Create repository on Gitea (via web UI)

# 4. Setup remote
make git-setup project=my-app provider=gitea

# 5. Start AI agent
make run-project project=my-app
```

### Custom Git Server

**Direct URL:**
```bash
make git-setup project=my-app provider=git@custom.com:org/my-app.git
```

**Manual setup:**
```bash
make git-setup project=my-app provider=manual

# Then follow instructions:
make connect
cd /opt/ai-agent-projects/my-app
git remote add origin git@custom.com:org/my-app.git
git push -u origin main
```

### Working with Existing Repositories

**Clone existing project:**
```bash
make create-project project=existing-app

make connect
cd /opt/ai-agent-projects/existing-app
rm -rf *  # Clear ai-agent-created files
git remote add origin git@github.com:user/existing-app.git
git pull origin main

# Update prompt.md with instructions
nano prompt.md

# Start AI agent
make run-project project=existing-app
```

## Monitoring and Control

### VM Monitoring

**Check VM status:**
```bash
make verify
```

**Show VM addresses:**
```bash
make address
```

**Test connectivity:**
```bash
make ping
```

**Connect to VM:**
```bash
make connect

# Inside VM:
htop           # Resource usage
df -h          # Disk space
free -h        # Memory usage
uptime         # System uptime
```

### Network Monitoring

**WireGuard status:**
```bash
sudo wg show wg-ai-agent
```

**Test SSH connectivity:**
```bash
make ping
```

**Check Mycelium (on VM):**
```bash
make connect
mycelium inspect --json
```

### Agent Process Monitoring

**Check running agent instances:**
```bash
make connect
ps aux | grep agent-loop
```

**Monitor specific project:**
```bash
make monitor-project project=my-app
```

**Check logs:**
```bash
make connect
cd /opt/ai-agent-projects/my-app

# Recent output
tail -50 agent-output.log

# Recent errors
tail -50 agent-errors.log

# Follow in real-time
tail -f agent-output.log
```

### Resource Monitoring

**On VM:**
```bash
make connect

# CPU and memory
htop

# Disk usage
du -sh /opt/ai-agent-projects/*

# Network connections
netstat -tulpn

# System logs
journalctl -f
```

## Multi-Project Management

### Running Multiple Projects

**Sequential:**
```bash
# Project 1
make create-project project=frontend
make run-project project=frontend

# Wait for completion or stop
make stop-project project=frontend

# Project 2
make create-project project=backend
make run-project project=backend
```

**Parallel (if resources allow):**
```bash
# Project 1
make create-project project=frontend
make run-project project=frontend

# Project 2 (in another terminal)
make create-project project=backend
make run-project project=backend

# Monitor both
make monitor-project project=frontend  # Terminal 1
make monitor-project project=backend   # Terminal 2
```

### Project Organization

**Convention:**
```
/opt/ai-agent-projects/
├── frontend-react/       # Frontend projects
├── backend-api/          # Backend services
├── mobile-ios/           # Mobile apps
├── docs-website/         # Documentation
└── scripts-automation/   # Utility scripts
```

### Managing Multiple VMs

**Deploy separate VMs for different purposes:**

**VM 1: Frontend projects**
```bash
# .env.frontend
export TF_VAR_ai_agent_node=1234
export TF_VAR_ai_agent_cpu=4
export TF_VAR_ai_agent_mem=8192
```

**VM 2: Backend projects**
```bash
# .env.backend
export TF_VAR_ai_agent_node=5678
export TF_VAR_ai_agent_cpu=8
export TF_VAR_ai_agent_mem=16384
```

**Deploy:**
```bash
# Frontend VM
cd tfgrid-ai-agent-frontend
cp .env.frontend .env
make deploy

# Backend VM
cd tfgrid-ai-agent-backend
cp .env.backend .env
make deploy
```

## Real-World Examples

### Example 1: React to Vue Migration

```bash
# 1. Create project
make create-project project=react-to-vue

# 2. Configure prompt (on VM)
make connect
cd /opt/ai-agent-projects/react-to-vue
nano prompt.md
```

**prompt.md:**
```markdown
Your job is to port this React application to Vue 3.

Guidelines:
- Convert React components to Vue SFC format
- Replace React hooks with Vue Composition API
- Update routing from react-router to vue-router
- Maintain the same functionality and UI
- Test each component after conversion
- Keep the same folder structure

Current progress: Starting migration
```

```bash
# 3. Clone existing React app
git remote add origin git@github.com:user/react-app.git
git pull origin main

# 4. Setup git for Vue version
make git-setup project=react-to-vue provider=github

# 5. Start AI agent
make run-project project=react-to-vue

# 6. Monitor progress
make monitor-project project=react-to-vue
```

### Example 2: API Development from Spec

```bash
# 1. Create project
make create-project project=user-api

# 2. Add API specification
make connect
cd /opt/ai-agent-projects/user-api
nano api-spec.yaml  # Paste OpenAPI spec
nano prompt.md
```

**prompt.md:**
```markdown
Implement a RESTful API based on api-spec.yaml.

Requirements:
- Use Express.js with TypeScript
- Implement all endpoints from the spec
- Add input validation with Joi
- Include comprehensive tests with Jest
- Add API documentation with Swagger
- Follow RESTful best practices
- Include error handling middleware

Current progress: Setting up project structure
```

```bash
# 3. Setup git
make git-setup project=user-api provider=github

# 4. Start AI agent
make run-project project=user-api

# 5. Monitor
make monitor-project project=user-api
```

### Example 3: Documentation Website

```bash
# 1. Create project
make create-project project=docs-site

# 2. Configure
make connect
cd /opt/ai-agent-projects/docs-site
nano prompt.md
```

**prompt.md:**
```markdown
Create a beautiful documentation website using VitePress.

Content:
- Getting started guide
- API reference
- Tutorials
- Examples
- FAQ

Design:
- Clean, modern UI
- Dark mode support
- Search functionality
- Mobile responsive
- Easy navigation

Current progress: Initial setup
```

```bash
# 3. Start AI agent
make git-setup project=docs-site provider=github
make run-project project=docs-site
```

### Example 4: Bug Fixing Campaign

```bash
# 1. Create project from existing repo
make create-project project=bugfix-sprint

make connect
cd /opt/ai-agent-projects/bugfix-sprint
git remote add origin git@github.com:user/app.git
git pull origin main

# 2. List bugs in prompt
nano prompt.md
```

**prompt.md:**
```markdown
Fix the following bugs in this codebase:

Priority 1:
- Bug #123: Memory leak in WebSocket handler
- Bug #124: Race condition in data sync

Priority 2:
- Bug #125: UI glitch on mobile
- Bug #126: Wrong timezone in date picker

Approach:
1. Fix one bug at a time
2. Write test to reproduce bug
3. Implement fix
4. Verify test passes
5. Commit with "Fix #<number>: <description>"

Current progress: Starting with Bug #123
```

```bash
# 3. Run AI agent
make run-project project=bugfix-sprint
make monitor-project project=bugfix-sprint
```

## Advanced Usage

### Custom Prompts

**Iterative refinement:**
```bash
# Start AI agent
make run-project project=my-app

# If stuck or off-track:
make stop-project project=my-app

# Update prompt
make connect
cd /opt/ai-agent-projects/my-app
nano prompt.md  # Add guidance, constraints, or corrections

# Restart
make run-project project=my-app
```

### Time-Limited Runs

**In project creation:**
- Set time constraint: "30m", "1h", "2h30m"
- The agent stops automatically when time expires

**Manual time limit:**
```bash
# Start AI agent
make run-project project=my-app

# In another terminal, stop after 1 hour
sleep 3600 && make stop-project project=my-app
```

### Checkpoint and Resume

```bash
# Work for a while
make run-project project=my-app

# Stop for checkpoint
make stop-project project=my-app

# Review progress
make connect
cd /opt/ai-agent-projects/my-app
git log --oneline -20
cat prompt.md

# Update prompt with progress notes
nano prompt.md
# Add: "Current progress: Completed user auth, now working on API endpoints"

# Resume
make run-project project=my-app
```

### Testing the agent Output

**Periodic checks:**
```bash
# Let the agent run for 30 minutes
make run-project project=my-app
sleep 1800
make stop-project project=my-app

# Test the output
make connect
cd /opt/ai-agent-projects/my-app
npm install
npm test
npm run build

# If good, continue
make run-project project=my-app

# If issues, update prompt and restart
nano prompt.md
make run-project project=my-app
```

### Integration with CI/CD

**GitHub Actions example:**

The agent pushes to `agent-dev` branch, CI runs tests:

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
      - uses: actions/setup-node@v3
      - run: npm install
      - run: npm test
      - run: npm run build
```

**Configure the agent to use branch:**
```bash
make connect
cd /opt/ai-agent-projects/my-app
git checkout -b agent-dev
git push -u origin agent-dev

# The agent will now push to agent-dev branch
```

---

**Related Documentation:**
- [QUICKSTART.md](QUICKSTART.md) - Quick setup
- [CONFIGURATION.md](CONFIGURATION.md) - Configuration details
- [GIT_INTEGRATION.md](GIT_INTEGRATION.md) - Git workflows
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Problem solving
