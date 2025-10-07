# Multi-AI Provider Support

Guide to expanding TFGrid AI-Agent to support multiple AI providers beyond Qwen.

## Table of Contents
- [Overview](#overview)
- [Current Architecture](#current-architecture)
- [Multi-Provider Architecture](#multi-provider-architecture)
- [Supported Providers](#supported-providers)
- [Implementation Guide](#implementation-guide)
- [Configuration](#configuration)
- [Provider Comparison](#provider-comparison)
- [Migration Path](#migration-path)

## Overview

Currently, TFGrid AI-Agent uses **Qwen** (Alibaba Cloud's AI model) as the AI provider. **Qwen offers a FREE tier with 2,000 tokens/day via Google login - no credit card required!**

However, the architecture can be extended to support **any AI provider with an API**, including:

- **Qwen** (Alibaba Cloud - current default)
- **Anthropic Claude**
- **OpenAI GPT-4/GPT-4o**
- **Google Gemini**
- **DeepSeek**
- **Mistral AI**
- **Local models** (Ollama, LM Studio)
- **Custom APIs**

### Why Multi-Provider Support?

**Benefits:**
1. ✅ **Cost Optimization**: Choose cheapest provider for task
2. ✅ **Feature Selection**: Use best model for specific use cases
3. ✅ **Redundancy**: Fallback if one provider is down
4. ✅ **Compliance**: Some regions/industries require specific providers
5. ✅ **Performance**: Different models excel at different tasks
6. ✅ **Avoid Lock-in**: Not dependent on single vendor

**Use Cases:**
- Use Qwen for general coding (current default, good balance)
- Use DeepSeek for cost-effective code generation (cheapest)
- Use Claude for complex reasoning (best quality)
- Use Gemini for long context (2M tokens)
- Use local models for sensitive data (privacy)
- Use GPT-4o for speed (fastest responses)

## Current Architecture

### How Qwen Integration Works

**Current Stack:**
```
┌─────────────────────────────────────┐
│  TFGrid AI-Agent (Makefile/Scripts)    │
│  ├─ Infrastructure (OpenTofu)       │
│  ├─ Configuration (Ansible)         │
│  └─ Execution (Bash Scripts)        │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  AI agent VM (ThreeFold Grid)          │
│  ├─ ai-agent framework            │
│  ├─ Qwen CLI (Alibaba Cloud)       │
│  └─ Project workspace               │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  Qwen API (Alibaba Cloud)           │
└─────────────────────────────────────┘
```

**Key Components:**
1. **Qwen CLI**: `@qwen-code/qwen-code` npm package
2. **Authentication**: `qwen login` or Alibaba Cloud credentials
3. **AI agent loop**: Uses Qwen CLI to process prompts
4. **Configuration**: Managed by ai-agent framework
5. **Default Model**: `qwen-max` (Alibaba's most capable model)

### Limitations of Current Approach

- ❌ Locked to Qwen (Alibaba Cloud) only
- ❌ Can't switch providers without code changes
- ❌ No cost optimization options
- ❌ No fallback if Qwen is down
- ❌ Can't use other providers or local models

## Multi-Provider Architecture

### Proposed Architecture

**Provider-Agnostic Design:**
```
┌─────────────────────────────────────┐
│  TFGrid AI-Agent (Makefile/Scripts)    │
│  ├─ Infrastructure (OpenTofu)       │
│  ├─ Configuration (Ansible)         │
│  └─ Execution (Bash Scripts)        │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  AI agent VM (ThreeFold Grid)          │
│  ├─ ai-agent framework (core)     │
│  ├─ AI Provider Abstraction Layer   │ ◄─ NEW
│  │   ├─ Anthropic adapter           │
│  │   ├─ OpenAI adapter              │
│  │   ├─ Gemini adapter              │
│  │   ├─ DeepSeek adapter            │
│  │   ├─ Mistral adapter             │
│  │   └─ Local model adapter         │
│  └─ Project workspace               │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  Multiple AI Providers              │
│  ├─ Anthropic API                   │
│  ├─ OpenAI API                      │
│  ├─ Google Gemini API               │
│  ├─ DeepSeek API                    │
│  ├─ Mistral API                     │
│  └─ Local Models (Ollama)           │
└─────────────────────────────────────┘
```

### Key Design Principles

1. **Provider Interface**: Abstract API that all providers implement
2. **Provider Adapters**: Concrete implementations for each AI service
3. **Provider Manager**: Handles selection, fallbacks, and routing
4. **Configuration System**: Environment-based provider configuration
5. **Backward Compatibility**: Existing Qwen setup continues to work

## Supported Providers

### 1. Qwen (Alibaba Cloud) ⭐ (Current Default)

**Models:**
- `qwen-max` - Most capable (current default)
- `qwen-plus` - Balanced performance
- `qwen-turbo` - Faster, cheaper

**🎁 FREE TIER AVAILABLE!**
- ✅ **Login with Google Account** - No credit card required!
- ✅ **2,000 free tokens daily** via `qwen login`
- ✅ Perfect for testing and light usage
- ✅ No Alibaba Cloud account needed

**Pricing** (per 1M tokens):
- **Free Tier**: 2,000 tokens/day (Google login)
- Qwen-Max: ~$2 input / ~$6 output
- Qwen-Plus: ~$0.50 input / ~$1.50 output
- Qwen-Turbo: ~$0.20 input / ~$0.60 output

**Configuration:**

**Option 1: Free Tier (Google Login)** - Recommended for getting started
```bash
# No API key needed!
# Just run: make login-qwen
# Then login with your Google account
AI_PROVIDER=qwen
# Default model will be used
```

**Option 2: Paid API Key** - For production/heavy usage
```bash
AI_PROVIDER=qwen
QWEN_API_KEY=xxx  # Alibaba Cloud credentials
QWEN_MODEL=qwen-max
```

**Strengths:**
- ✅ **FREE tier available** (2,000 tokens/day)
- ✅ **No credit card required** (Google login)
- ✅ Good code generation capabilities
- ✅ Reasonable pricing for paid tier
- ✅ 32K token context window
- ✅ Strong at Chinese languages
- ✅ Current default in ai-agent

### 2. Anthropic Claude

**Models:**
- `claude-3-5-sonnet-20241022` - Best overall
- `claude-3-opus-20240229` - Most capable
- `claude-3-haiku-20240307` - Fastest

**Pricing** (per 1M tokens):
- Sonnet: $3 input / $15 output
- Opus: $15 input / $75 output

**Configuration:**
```bash
AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=sk-ant-api03-xxx
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
```

**Strengths:**
- ✅ Best reasoning and complex tasks
- ✅ 200K token context window
- ✅ Excellent code generation
- ✅ Strong safety features

### 3. OpenAI GPT-4 🚀

**Models:**
- `gpt-4o` - Fastest, multimodal
- `gpt-4o-mini` - Cheaper, fast
- `o1-preview` - Reasoning model

**Pricing** (per 1M tokens):
- GPT-4o: $2.50 input / $10 output
- GPT-4o-mini: $0.15 input / $0.60 output

**Configuration:**
```bash
AI_PROVIDER=openai
OPENAI_API_KEY=sk-xxx
OPENAI_MODEL=gpt-4o
```

**Strengths:**
- ✅ Fastest response times
- ✅ Good code generation
- ✅ Large ecosystem
- ✅ Multimodal capabilities

### 4. Google Gemini 📚

**Models:**
- `gemini-1.5-pro` - 2M token context
- `gemini-1.5-flash` - Faster, cheaper

**Pricing** (per 1M tokens):
- Flash: $0.075 input / $0.30 output
- Pro: $1.25 input / $5.00 output

**Configuration:**
```bash
AI_PROVIDER=gemini
GEMINI_API_KEY=xxx
GEMINI_MODEL=gemini-1.5-pro
```

**Strengths:**
- ✅ Massive context window (2M tokens)
- ✅ Very affordable
- ✅ Good at code
- ✅ Multimodal

### 5. DeepSeek 💰 (Best Value)

**Models:**
- `deepseek-chat` - General purpose
- `deepseek-coder` - Code specialized

**Pricing** (per 1M tokens):
- Input: $0.14
- Output: $0.28
- **~20x cheaper than Claude!**

**Configuration:**
```bash
AI_PROVIDER=deepseek
DEEPSEEK_API_KEY=xxx
DEEPSEEK_MODEL=deepseek-coder
```

**Strengths:**
- ✅ Excellent at code (trained on code)
- ✅ Very cheap ($0.14/1M input tokens)
- ✅ Good performance/cost ratio
- ✅ 64K context window

### 6. Mistral AI 🇪🇺

**Models:**
- `mistral-large-latest` - Most capable
- `codestral-latest` - Code specialized

**Pricing** (per 1M tokens):
- Small: $0.20 input / $0.60 output
- Large: $2 input / $6 output

**Configuration:**
```bash
AI_PROVIDER=mistral
MISTRAL_API_KEY=xxx
MISTRAL_MODEL=codestral-latest
```

**Strengths:**
- ✅ European (GDPR compliant)
- ✅ Code-specialized model
- ✅ Affordable
- ✅ Good performance

### 7. Local Models (Ollama) 🔒

**Models:**
- `codellama` - Code generation
- `deepseek-coder` - Code specialized
- `qwen2.5-coder` - Qwen for code

**Pricing**: **FREE** (hardware costs only)

**Setup:**
```bash
# Install Ollama on VM
curl -fsSL https://ollama.com/install.sh | sh

# Download model
ollama pull codellama

# Run server
ollama serve
```

**Configuration:**
```bash
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=codellama
```

**Strengths:**
- ✅ Completely free (after hardware)
- ✅ Full privacy (data never leaves VM)
- ✅ No API rate limits
- ✅ Offline capable
- ✅ Compliance-friendly

**Considerations:**
- ⚠️ Requires more VM resources (GPU recommended)
- ⚠️ Slower than cloud APIs
- ⚠️ Quality depends on model size

## Implementation Guide

### Phase 1: Add Provider Support to ai-agent

**1. Extend ai-agent framework:**
```bash
# Fork/modify ai-agent
cd /opt/ai-agent
mkdir -p lib/providers
```

**2. Create provider wrapper script:**
```bash
#!/bin/bash
# scripts/ai-provider.sh
# Universal AI provider wrapper

PROVIDER="${AI_PROVIDER:-anthropic}"
PROMPT="$1"

case "$PROVIDER" in
  anthropic)
    qwen "$PROMPT"
    ;;
  
  openai)
    curl -s https://api.openai.com/v1/chat/completions \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$OPENAI_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}]}" \
      | jq -r '.choices[0].message.content'
    ;;
  
  deepseek)
    curl -s https://api.deepseek.com/v1/chat/completions \
      -H "Authorization: Bearer $DEEPSEEK_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"$DEEPSEEK_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}]}" \
      | jq -r '.choices[0].message.content'
    ;;
  
  ollama)
    curl -s http://localhost:11434/api/chat \
      -d "{\"model\":\"$OLLAMA_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"stream\":false}" \
      | jq -r '.message.content'
    ;;
  
  *)
    echo "Unknown provider: $PROVIDER"
    exit 1
    ;;
esac
```

### Phase 2: Update Configuration

**Add to `.env`:**
```bash
# AI Provider Configuration
export AI_PROVIDER=deepseek

# Provider API Keys
export ANTHROPIC_API_KEY=sk-ant-xxx
export OPENAI_API_KEY=sk-xxx
export DEEPSEEK_API_KEY=xxx
export GEMINI_API_KEY=xxx
export MISTRAL_API_KEY=xxx

# Local model settings
export OLLAMA_BASE_URL=http://localhost:11434
export OLLAMA_MODEL=codellama
```

### Phase 3: Update Ansible

**In `platform/group_vars/all.yml`:**
```yaml
# AI Provider configuration
ai_provider: "{{ lookup('env', 'AI_PROVIDER') | default('anthropic', true) }}"

# Provider API keys (optional)
anthropic_api_key: "{{ lookup('env', 'ANTHROPIC_API_KEY') | default('', true) }}"
openai_api_key: "{{ lookup('env', 'OPENAI_API_KEY') | default('', true) }}"
deepseek_api_key: "{{ lookup('env', 'DEEPSEEK_API_KEY') | default('', true) }}"
gemini_api_key: "{{ lookup('env', 'GEMINI_API_KEY') | default('', true) }}"
mistral_api_key: "{{ lookup('env', 'MISTRAL_API_KEY') | default('', true) }}"
```

**Update Ansible role:**
```yaml
# platform/roles/ai_agent_setup/tasks/main.yml
- name: Configure AI provider environment
  blockinfile:
    path: /root/.bashrc
    block: |
      export AI_PROVIDER="{{ ai_provider }}"
      export ANTHROPIC_API_KEY="{{ anthropic_api_key }}"
      export OPENAI_API_KEY="{{ openai_api_key }}"
      export DEEPSEEK_API_KEY="{{ deepseek_api_key }}"
      export GEMINI_API_KEY="{{ gemini_api_key }}"
      export MISTRAL_API_KEY="{{ mistral_api_key }}"
    create: yes
  no_log: yes
```

## Configuration

### Per-Project Configuration

**Create `.ai-agent-config` in project directory:**
```bash
# Primary provider
AI_PROVIDER=deepseek

# Fallback providers
AI_FALLBACK_PROVIDERS=openai,anthropic

# DeepSeek configuration
DEEPSEEK_API_KEY=xxx
DEEPSEEK_MODEL=deepseek-coder

# OpenAI configuration (fallback)
OPENAI_API_KEY=xxx
OPENAI_MODEL=gpt-4o-mini

# Model parameters
MAX_TOKENS=4000
TEMPERATURE=0.7
```

### Global Defaults

**In `.env`:**
```bash
# Default provider for all projects
export AI_PROVIDER=deepseek

# API keys
export DEEPSEEK_API_KEY=xxx
export OPENAI_API_KEY=xxx
export ANTHROPIC_API_KEY=xxx
```

## Provider Comparison

### Cost Comparison (per 1M tokens)

| Provider | Input Cost | Output Cost | Relative Cost |
|----------|------------|-------------|---------------|
| **Ollama (Local)** | $0 | $0 | **FREE** |
| **DeepSeek** | $0.14 | $0.28 | **1x (cheapest cloud)** |
| **Gemini Flash** | $0.075 | $0.30 | **0.9x** |
| **GPT-4o-mini** | $0.15 | $0.60 | **1.8x** |
| **Qwen-Turbo** | $0.20 | $0.60 | **1.9x** |
| **Mistral Small** | $0.20 | $0.60 | **1.9x** |
| **Qwen-Plus** | $0.50 | $1.50 | **5x** |
| **Qwen-Max** | $2.00 | $6.00 | **20x (current default)** |
| **GPT-4o** | $2.50 | $10.00 | **30x** |
| **Claude Sonnet** | $3.00 | $15.00 | **43x** |

### Recommended Use Cases

**For Current Setup (Default)**:
1. Qwen-Max (Alibaba Cloud - currently configured)
2. Qwen-Plus (cheaper alternative)
3. Qwen-Turbo (fastest, most affordable)

**For Production Code (Quality First)**:
1. Claude Sonnet (best quality)
2. GPT-4o (speed + quality)
3. Qwen-Max (good balance)

**For Cost Optimization**:
1. DeepSeek (best value - $0.14/1M tokens)
2. Gemini Flash (cheap + good)
3. Qwen-Turbo (affordable)
4. GPT-4o-mini (OpenAI ecosystem)

**For Privacy/Compliance**:
1. Ollama (fully local - free)
2. Mistral (European GDPR)
3. Self-hosted Qwen models

**For Long Context**:
1. Gemini Pro (2M tokens)
2. Claude Sonnet (200K tokens)
3. GPT-4o (128K tokens)
4. DeepSeek (64K tokens)

## Migration Path

### Step 1: Add Provider Script (Immediate)

Add universal provider wrapper to ai-agent that can call any API.

### Step 2: Update Configuration (Week 1)

Add provider configuration to `.env` and Ansible.

### Step 3: Test Alternative Providers (Week 2)

Test with DeepSeek, OpenAI, and local models.

### Step 4: Documentation (Week 2-3)

Document provider setup for each supported option.

### Step 5: Advanced Features (Month 2+)

- Smart provider selection based on task
- Cost tracking and optimization
- Automatic fallbacks
- Load balancing across providers

---

**Summary**: Supporting multiple AI providers significantly increases flexibility, reduces costs, and provides redundancy. The implementation is straightforward and can be done incrementally without breaking existing Qwen functionality.

For questions or implementation help, see the TFGrid AI-Agent community.
