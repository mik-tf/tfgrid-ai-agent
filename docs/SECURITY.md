# Security Guide

Comprehensive security guide for TFGrid AI-Agent.

## Table of Contents
- [Security Architecture](#security-architecture)
- [Credential Management](#credential-management)
- [Network Security](#network-security)
- [VM Security](#vm-security)
- [Git Security](#git-security)
- [Best Practices](#best-practices)
- [Security Checklist](#security-checklist)
- [Incident Response](#incident-response)

## Security Architecture

### Defense in Depth

TFGrid AI-Agent implements multiple security layers:

```
┌─────────────────────────────────────────────────────┐
│ Layer 1: Credential Isolation                       │
│ - Mnemonic never in files                           │
│ - API keys in environment variables                 │
│ - SSH private keys with proper permissions          │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│ Layer 2: Encrypted Communication                    │
│ - WireGuard VPN (ChaCha20)                          │
│ - SSH with public key authentication                │
│ - Mycelium end-to-end encryption                    │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│ Layer 3: VM Isolation                               │
│ - Separate VM for agent operations                  │
│ - Code execution isolated from local machine        │
│ - Easy to destroy/recreate                          │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│ Layer 4: Access Control                             │
│ - SSH key-based authentication                      │
│ - Firewall rules (UFW)                              │
│ - No password authentication                        │
└─────────────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────────────┐
│ Layer 5: Audit Trail                                │
│ - All changes in git history                        │
│ - OpenTofu state tracking                           │
│ - System logs on VM                                 │
└─────────────────────────────────────────────────────┘
```

### Trust Boundaries

```
Trusted Zone                Untrusted Zone
├─ Local Machine           ├─ Internet
│  └─ .env (no secrets)    ├─ ThreeFold Grid
│                          ├─ GitHub/Gitea
└─ AI agent VM (isolated)     └─ Qwen API
   └─ Projects
```

## Credential Management

### Sensitive Data Handling

**DO:**
- ✅ Store sensitive data outside repository
- ✅ Use environment variables for secrets
- ✅ Use Ansible Vault for team deployments
- ✅ Rotate credentials regularly
- ✅ Use separate keys for different purposes

**DON'T:**
- ❌ Commit credentials to git
- ❌ Put secrets in .env file
- ❌ Share private keys
- ❌ Use same key for multiple services
- ❌ Store keys in unencrypted files

### Mnemonic Security

**Storage:**
```bash
# Proper storage
chmod 600 ~/.config/threefold/mnemonic
# Only owner can read/write

# File contents: 12-24 word mnemonic
# Never copy to other locations
```

**Usage:**
```bash
# Correct: Read from secure location
export TF_VAR_mnemonic=$(cat ~/.config/threefold/mnemonic)

# WRONG: Don't put in .env
echo "TF_VAR_mnemonic=word1 word2..." >> .env  # ❌ NEVER DO THIS
```

**Backup:**
- Write mnemonic on paper
- Store in secure physical location
- Consider splitting between multiple locations
- Never store digitally unencrypted

### API Key Security

**Storage:**
```bash
# Create secure directory
mkdir -p ~/.config/anthropic
chmod 700 ~/.config/anthropic

# Store API key
echo "sk-ant-api03-xxx" > ~/.config/anthropic/api_key
chmod 600 ~/.config/anthropic/api_key

# Use in deployment
export ANTHROPIC_API_KEY=$(cat ~/.config/anthropic/api_key)
```

**Key Restrictions:**
- Use API key restrictions where available
- Limit by IP address if possible
- Set spending limits
- Use separate keys for dev/prod
- Monitor usage regularly

### SSH Key Security

**Generation:**
```bash
# Use strong algorithm
ssh-keygen -t ed25519 -C "your@email.com"

# Use passphrase
# Enter strong passphrase when prompted

# Verify permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

**Management:**
```bash
# List SSH keys
ls -la ~/.ssh/

# Remove old keys
rm ~/.ssh/old_key*

# Use SSH agent for passphrase management
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

**Best Practices:**
- Use different keys for different purposes
- Rotate keys every 6-12 months
- Remove unused keys from GitHub/Gitea
- Use ed25519 (modern, secure)
- Always use passphrase on private keys

## Network Security

### WireGuard Security

**Features:**
- Modern cryptography (Curve25519, ChaCha20, Poly1305)
- Perfect forward secrecy
- Minimal attack surface
- Fast, secure key exchange

**Configuration Security:**
```bash
# Proper permissions on config
sudo chmod 600 /etc/wireguard/wg-ai-agent.conf

# Only root should access
sudo chown root:root /etc/wireguard/wg-ai-agent.conf

# Don't expose private key
sudo grep -v "PrivateKey" /etc/wireguard/wg-ai-agent.conf
```

**Monitoring:**
```bash
# Check active connections
sudo wg show wg-ai-agent

# Look for unexpected peers
# Only your AI agent VM should be connected
```

### Firewall Configuration

**On VM (automatic via Ansible):**
```bash
# SSH only (port 22)
ufw allow 22/tcp
ufw enable

# WireGuard interface allowed
ufw allow in on wg0

# Mycelium interface allowed
ufw allow in on mycelium
```

**On Local Machine:**
```bash
# Allow WireGuard
sudo ufw allow 51820/udp

# Or allow WireGuard interface
sudo ufw allow in on wg-ai-agent
```

### Network Monitoring

**Detect unusual traffic:**
```bash
# On VM
make connect

# Monitor connections
netstat -tulpn

# Check for unexpected listening services
ss -tulpn

# View firewall logs
journalctl -u ufw
```

## VM Security

### Access Control

**SSH Configuration:**
```bash
# On VM, SSH is configured via cloud-init
# Password authentication: Disabled
# Root login: Public key only
# Port: 22 (standard)
```

**Verify SSH security:**
```bash
make connect

# Check SSH config
grep "PasswordAuthentication" /etc/ssh/sshd_config
# Should be: PasswordAuthentication no

grep "PubkeyAuthentication" /etc/ssh/sshd_config
# Should be: PubkeyAuthentication yes
```

### System Updates

**Keep VM updated:**
```bash
make connect

# Update system
apt update
apt upgrade -y

# Auto-updates (optional)
apt install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

**Update schedule:**
- Weekly for security patches
- Monthly for general updates
- Before major deployments

### Resource Limits

**Prevent resource exhaustion:**
```bash
# On VM
make connect

# Set memory limits for processes
ulimit -m 1048576  # 1GB

# Monitor resource usage
htop
watch -n 1 free -h
```

### Log Management

**Enable logging:**
```bash
make connect

# Ensure logging is active
systemctl status rsyslog

# View logs
journalctl -f

# Log rotation configured
cat /etc/logrotate.d/rsyslog
```

**Important logs:**
- `/var/log/auth.log` - SSH access
- `/var/log/syslog` - System events
- `agent-output.log` - agent activity
- `agent-errors.log` - agent errors

## Git Security

### Repository Security

**Private repositories recommended:**
- Use private repos for sensitive projects
- Public repos expose code to everyone
- Consider GitHub/Gitea access controls

**Branch protection:**
```yaml
# GitHub branch protection rules:
- Require pull request reviews
- Require status checks to pass
- Require signed commits (optional)
- Restrict who can push to main
```

### Commit Signing

**Setup GPG signing (optional):**
```bash
make connect

# Generate GPG key
gpg --full-generate-key

# Configure git
git config --global user.signingkey <KEY_ID>
git config --global commit.gpgsign true

# Export public key
gpg --armor --export <KEY_ID>
# Add to GitHub/Gitea
```

### Secrets in Code

**Prevent secrets in commits:**
```bash
# Use .gitignore
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
echo "*.pem" >> .gitignore
echo "credentials.auto.tfvars" >> .gitignore

# Use git-secrets (optional)
# Install: https://github.com/awslabs/git-secrets
git secrets --install
git secrets --register-aws
```

**Scan for secrets:**
```bash
# Use tools like gitleaks
docker run --rm -v $(pwd):/path zricethezav/gitleaks:latest \
  detect --source="/path" -v
```

## Best Practices

### Development Best Practices

1. **Principle of Least Privilege:**
   - Only grant necessary permissions
   - Use separate accounts for different purposes
   - Limit API key scopes

2. **Defense in Depth:**
   - Multiple security layers
   - Assume any layer can be compromised
   - Implement compensating controls

3. **Secure by Default:**
   - Default configurations are secure
   - Opt-in for risky features
   - Clear warnings for security implications

4. **Regular Audits:**
   - Review access logs monthly
   - Check for unused keys/accounts
   - Update dependencies regularly

### Operational Best Practices

1. **Regular Backups:**
   ```bash
   # Git repositories (automatic via push)
   # Configuration files
   cp .env .env.backup
   
   # OpenTofu state
   cd infrastructure
   cp terraform.tfstate terraform.tfstate.backup
   ```

2. **Monitoring:**
   ```bash
   # Check for unusual activity
   make connect
   last -20  # Recent logins
   journalctl -u ssh -f  # SSH access
   ```

3. **Incident Response Plan:**
   - Document response procedures
   - Know how to destroy compromised VMs
   - Have backup credentials ready

4. **Key Rotation:**
   ```bash
   # Rotate SSH keys every 6 months
   ssh-keygen -t ed25519 -C "new-key"
   # Update in GitHub/Gitea
   # Redeploy infrastructure
   
   # Rotate API keys yearly
   # Generate new key on Anthropic dashboard
   # Update environment variable
   ```

### Team Collaboration Best Practices

1. **Use Ansible Vault:**
   ```bash
   # Create vault for team secrets
   ansible-vault create platform/vault.yml
   
   # Share vault password securely
   # (Not via git, use secure channel)
   ```

2. **Separate Environments:**
   ```bash
   # Development
   tfgrid-ai-agent-dev/
   
   # Production
   tfgrid-ai-agent-prod/
   ```

3. **Access Control:**
   - Limit who can deploy
   - Use separate credentials per person
   - Audit access regularly

## Security Checklist

### Initial Setup

- [ ] Mnemonic stored securely (not in git)
- [ ] `.env` file gitignored
- [ ] SSH keys generated with passphrase
- [ ] API keys stored securely (if used)
- [ ] Firewall enabled on VM
- [ ] WireGuard config permissions set (600)
- [ ] Private git repositories created

### Regular Maintenance

- [ ] Update VM packages monthly
- [ ] Rotate SSH keys every 6 months
- [ ] Review access logs monthly
- [ ] Check for unused projects/keys
- [ ] Backup configuration files
- [ ] Test disaster recovery procedures

### Before Deployment

- [ ] Verify .env doesn't contain secrets
- [ ] Check SSH key exists
- [ ] Confirm mnemonic is set
- [ ] Review node selection (trusted node)
- [ ] Verify firewall rules
- [ ] Test connectivity

### After Deployment

- [ ] Verify SSH access works
- [ ] Check firewall is active
- [ ] Test WireGuard connection
- [ ] Confirm Qwen authentication
- [ ] Review system logs
- [ ] Document VM details

## Incident Response

### Suspected Compromise

**Immediate Actions:**

1. **Isolate:**
   ```bash
   # Destroy compromised VM immediately
   make clean
   
   # Stop WireGuard
   sudo wg-quick down wg-ai-agent
   ```

2. **Investigate:**
   - Check local machine for malware
   - Review access logs
   - Identify entry point

3. **Rotate Credentials:**
   ```bash
   # Rotate all keys
   ssh-keygen -t ed25519  # New SSH key
   # New API key on Anthropic dashboard
   # Update git SSH keys on GitHub/Gitea
   ```

4. **Redeploy:**
   ```bash
   # Fresh deployment with new credentials
   make deploy
   ```

### Lost/Stolen Credentials

**Mnemonic compromised:**
- Transfer TFT to new account immediately
- Create new ThreeFold account
- Update all configurations

**API Key compromised:**
- Revoke key on Anthropic dashboard immediately
- Generate new key
- Check billing for unauthorized usage

**SSH Key compromised:**
- Remove from GitHub/Gitea immediately
- Generate new key pair
- Redeploy infrastructure

### Unauthorized Access

**If unauthorized access detected:**

1. **Change all passwords/keys immediately**
2. **Destroy affected VMs**
3. **Review all git repositories for unauthorized changes**
4. **Check billing/usage for anomalies**
5. **Document incident for future prevention**

## Security Resources

### Tools

- **git-secrets**: Prevent committing secrets
- **gitleaks**: Scan for secrets in git history
- **Ansible Vault**: Encrypt sensitive data
- **WireGuard**: Modern VPN
- **UFW**: Uncomplicated Firewall

### Further Reading

- [ThreeFold Security Manual](https://manual.grid.tf/)
- [WireGuard Documentation](https://www.wireguard.com/)
- [SSH Security Best Practices](https://infosec.mozilla.org/guidelines/openssh)
- [Git Security](https://github.com/github/secure_code)

---

**Remember**: Security is a process, not a product. Regular reviews and updates are essential.

**Related Documentation:**
- [CONFIGURATION.md](CONFIGURATION.md) - Secure configuration
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Security issues
- [GIT_INTEGRATION.md](GIT_INTEGRATION.md) - Git security
