# Contributing to TFGrid AI-Agent

Thank you for your interest in contributing to TFGrid AI-Agent! This document provides guidelines for contributing to the project.

## Table of Contents
- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity and expression, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behavior includes:**
- Harassment or discriminatory language
- Trolling, insulting comments, or personal attacks
- Public or private harassment
- Publishing others' private information

## Getting Started

### Prerequisites

Before contributing, ensure you have:
- Git installed
- OpenTofu or Terraform
- Ansible
- Basic knowledge of Bash scripting
- ThreeFold account (for testing)

### Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/tfgrid-ai-agent.git
cd tfgrid-ai-agent

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL_OWNER/tfgrid-ai-agent.git
```

## Development Setup

### Local Development

```bash
# Copy configuration
cp .env.example .env

# Set up test environment
export TF_VAR_tfgrid_network="test"  # Use test network
export TF_VAR_ai_agent_node=YOUR_TEST_NODE

# Deploy for testing
make deploy
```

### Testing Changes

```bash
# Test infrastructure changes
cd infrastructure
tofu plan

# Test Ansible changes
cd platform
ansible-playbook -i inventory.ini site.yml --check

# Test scripts
bash -n scripts/script-name.sh  # Syntax check
shellcheck scripts/script-name.sh  # Linting
```

## How to Contribute

### Types of Contributions

**Bug Reports:**
- Use GitHub Issues
- Include clear description
- Provide steps to reproduce
- Include environment details

**Feature Requests:**
- Open GitHub Issue with [Feature Request] tag
- Describe the feature and use case
- Explain why it would be valuable

**Code Contributions:**
- Bug fixes
- New features
- Documentation improvements
- Test additions

**Documentation:**
- Fix typos or errors
- Improve clarity
- Add examples
- Translate documentation

### Finding Issues

Look for issues tagged with:
- `good first issue` - Good for newcomers
- `help wanted` - Community help needed
- `bug` - Bug fixes needed
- `enhancement` - New features

## Pull Request Process

### Before Submitting

1. **Create a branch:**
   ```bash
   git checkout -b feature/my-feature
   # or
   git checkout -b fix/issue-123
   ```

2. **Make your changes:**
   - Follow coding standards
   - Add tests if applicable
   - Update documentation

3. **Test thoroughly:**
   ```bash
   # Test deployment
   make deploy
   
   # Test functionality
   make verify
   
   # Test cleanup
   make clean
   ```

4. **Commit changes:**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

### Commit Message Format

Use clear, descriptive commit messages:

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add support for multiple VM deployments

Added ability to deploy multiple AI agent VMs with different
configurations. Each VM can run independent projects.

Closes #123
```

```
fix: Resolve WireGuard connection timeout

Fixed issue where WireGuard connection would timeout on
slow networks by increasing connection timeout to 30s.

Fixes #456
```

### Submitting Pull Request

1. **Push to your fork:**
   ```bash
   git push origin feature/my-feature
   ```

2. **Create Pull Request:**
   - Go to GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill in PR template

3. **PR Description should include:**
   - What changes were made
   - Why the changes were made
   - How to test the changes
   - Related issues (if any)

4. **PR Checklist:**
   - [ ] Code follows project style
   - [ ] Tests added/updated
   - [ ] Documentation updated
   - [ ] Commits are clear and descriptive
   - [ ] All tests pass
   - [ ] No merge conflicts

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, PR will be merged
4. Your contribution will be in next release!

## Coding Standards

### Bash Scripts

**Style:**
```bash
#!/bin/bash
# Script description
set -e  # Exit on error

# Use lowercase for variables
my_variable="value"

# Use uppercase for constants
readonly API_URL="https://api.example.com"

# Functions should have clear names
function deploy_infrastructure() {
    # Function body
}

# Use quotes around variables
echo "Value: $my_variable"

# Check command success
if command -v tofu &> /dev/null; then
    echo "OpenTofu found"
fi
```

**Best Practices:**
- Use `set -e` to exit on errors
- Quote all variables
- Use meaningful variable names
- Add comments for complex logic
- Handle errors gracefully
- Provide user feedback

### Terraform/OpenTofu

**Style:**
```hcl
# Resource naming: <type>_<name>
resource "grid_network" "ai_agent_network" {
  name     = "ai_agent_net"
  ip_range = "10.1.0.0/16"
}

# Use variables for configurable values
variable "ai_agent_cpu" {
  type        = number
  default     = 4
  description = "CPU cores for AI agent VM"
}

# Add descriptions to outputs
output "ai_agent_wg_ip" {
  value       = grid_network.ai_agent_network.access_wg_config.peers[0].allowed_ips[0]
  description = "AI agent VM WireGuard IP"
}
```

### Ansible

**Style:**
```yaml
---
# Use descriptive task names
- name: Install Node.js from NodeSource repository
  apt:
    name: nodejs
    state: present
    update_cache: yes

# Use variables for configuration
- name: Configure git user
  git_config:
    name: user.name
    value: "{{ git_user_name }}"
    scope: global

# Add tags for selective execution
- name: Update system packages
  apt:
    update_cache: yes
  tags: [common, system]
```

### Documentation

**Markdown Style:**
- Use clear headings
- Include code examples
- Add tables for comparisons
- Use lists for steps
- Include links to related docs
- Keep lines under 80 characters (when practical)

## Testing

### Manual Testing

**Before submitting PR, test:**

1. **Fresh deployment:**
   ```bash
   make clean
   make deploy
   make verify
   ```

2. **Core functionality:**
   ```bash
   make login-qwen
   make create-project project=test
   make run-project project=test
   make stop-project project=test
   ```

3. **Git integration:**
   ```bash
   make git-show-key
   make git-setup project=test provider=github
   ```

4. **Cleanup:**
   ```bash
   make clean
   ```

### Test Checklist

- [ ] Deployment works on fresh system
- [ ] All commands in README work
- [ ] Documentation is accurate
- [ ] No sensitive data in commits
- [ ] Scripts have proper permissions
- [ ] Error messages are clear
- [ ] Cleanup works properly

## Documentation

### When to Update Documentation

Update documentation when:
- Adding new features
- Changing existing behavior
- Fixing bugs that affected docs
- Improving clarity

### Documentation Locations

- `README.md` - Main documentation
- `docs/QUICKSTART.md` - Getting started guide
- `docs/ARCHITECTURE.md` - System design
- `docs/CONFIGURATION.md` - Configuration details
- `docs/USAGE.md` - Usage examples
- `docs/GIT_INTEGRATION.md` - Git workflows
- `docs/TROUBLESHOOTING.md` - Problem solving
- `docs/SECURITY.md` - Security practices

### Documentation Standards

- Use clear, simple language
- Provide examples
- Include expected output
- Link to related documentation
- Keep information up-to-date

## Release Process

### Versioning

We use [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

### Creating a Release

1. Update version numbers
2. Update CHANGELOG.md
3. Create git tag
4. Push tag to GitHub
5. Create GitHub release
6. Announce on community channels

## Community

### Getting Help

- GitHub Issues for bugs/features
- GitHub Discussions for questions
- ThreeFold Forum for general discussion

### Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in commit history

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

---

**Thank you for contributing to TFGrid AI-Agent!** Every contribution, no matter how small, helps make the project better for everyone.
