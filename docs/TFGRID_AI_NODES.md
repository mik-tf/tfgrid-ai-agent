# TFGrid AI Nodes - Self-Hosted AI Phase

Guide for running AI models directly on ThreeFold Grid GPU nodes instead of external APIs.

## Table of Contents
- [Overview](#overview)
- [Current vs Future Architecture](#current-vs-future-architecture)
- [Architecture Options](#architecture-options)
- [GPU Requirements](#gpu-requirements)
- [Model Serving Options](#model-serving-options)
- [Cost Analysis](#cost-analysis)
- [Implementation Roadmap](#implementation-roadmap)
- [Technical Specifications](#technical-specifications)

## Overview

**Current State**: TFGrid AI-Agent uses **external AI APIs** (Qwen/Alibaba Cloud, OpenAI, Claude, etc.)

**Next Phase**: Run AI models **directly on ThreeFold Grid GPU VMs** for:
- ✅ **Full Decentralization**: No external dependencies
- ✅ **Complete Privacy**: Data never leaves TFGrid
- ✅ **Cost Control**: No per-token API fees
- ✅ **Compliance**: Perfect for regulated industries
- ✅ **Performance**: Low-latency local inference
- ✅ **Censorship Resistance**: Fully self-contained

### Vision

Transform TFGrid AI-Agent from **"AI-assisted coding on decentralized infrastructure"** to **"fully decentralized AI coding"** where both the infrastructure AND the AI models run on ThreeFold Grid.

## Current vs Future Architecture

### Current Architecture (API-Based)

```
┌─────────────────────────────────────┐
│  Local Machine                      │
│  ├─ OpenTofu (infrastructure)       │
│  ├─ Ansible (configuration)         │
│  └─ Makefile (orchestration)        │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  ThreeFold Grid                     │
│  ┌───────────────────────────────┐  │
│  │  AI agent VM (Standard VM)       │  │
│  │  ├─ ai-agent framework      │  │
│  │  ├─ Qwen CLI                  │  │
│  │  └─ Project workspace         │  │
│  └───────────────┬───────────────┘  │
└──────────────────┼───────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│  External AI Providers              │
│  ├─ Qwen API (Alibaba Cloud) ❌    │
│  ├─ OpenAI API ❌                   │
│  ├─ Claude API ❌                   │
│  └─ Gemini API ❌                   │
└─────────────────────────────────────┘
```

**Limitations:**
- ❌ Dependent on external services
- ❌ Data leaves TFGrid
- ❌ Per-token costs
- ❌ API rate limits
- ❌ Privacy concerns
- ❌ Potential censorship

### Future Architecture (TFGrid AI Nodes)

```
┌─────────────────────────────────────┐
│  Local Machine                      │
│  ├─ OpenTofu (infrastructure)       │
│  ├─ Ansible (configuration)         │
│  └─ Makefile (orchestration)        │
└─────────────────┬───────────────────┘
                  │
                  ▼
┌─────────────────────────────────────┐
│  ThreeFold Grid (Fully Self-Hosted)│
│                                     │
│  ┌───────────────────────────────┐  │
│  │  AI agent VM (Orchestration)     │  │
│  │  ├─ ai-agent framework      │  │
│  │  ├─ Project workspace         │  │
│  │  └─ AI client (local)         │  │
│  └───────────────┬───────────────┘  │
│                  │                   │
│                  │ Internal Network  │
│                  │ (WireGuard/       │
│                  │  Mycelium)        │
│                  ▼                   │
│  ┌───────────────────────────────┐  │
│  │  AI GPU VM(s)                 │  │
│  │  ├─ GPU(s)                    │  │
│  │  ├─ vLLM / Ollama / TGI       │  │
│  │  ├─ Code models (DeepSeek,    │  │
│  │  │   CodeLlama, Qwen-Coder)   │  │
│  │  └─ API endpoint (local)      │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Benefits:**
- ✅ Fully decentralized (no external dependencies)
- ✅ Complete privacy (data stays on TFGrid)
- ✅ No per-token costs (only infrastructure)
- ✅ No rate limits
- ✅ Full control
- ✅ Censorship-resistant

## Architecture Options

### Option 1: Separate VMs (Recommended for Production)

**2-VM Setup**: AI agent VM + AI GPU VM

```
ThreeFold Grid
├── AI agent VM (Standard, No GPU)
│   ├── CPU: 4 cores
│   ├── RAM: 8GB
│   ├── Disk: 100GB
│   ├── Role: Orchestration, project management
│   └── Cost: ~$20-40/month
│
└── AI GPU VM (GPU Node)
    ├── GPU: 1x NVIDIA (A100, RTX 4090, etc.)
    ├── CPU: 8-16 cores
    ├── RAM: 32-64GB
    ├── Disk: 200GB
    ├── Role: AI model serving
    └── Cost: ~$200-800/month (depending on GPU)
```

**Communication:**
- AI agent VM ↔ AI GPU VM via **internal network** (WireGuard or Mycelium)
- API endpoint: `http://ai-gpu-vm:8000/v1/chat/completions`
- No external traffic for AI inference

**Advantages:**
- ✅ Cost-effective: Only pay for GPU when needed
- ✅ Can scale: Add multiple AI VMs
- ✅ Separation of concerns
- ✅ Can upgrade GPU without touching AI agent VM
- ✅ Multiple projects can share AI VM

**Similar to tfgrid-gateway pattern:**
- Gateway VM (orchestration) ↔ Backend VMs (services)
- AI agent VM (orchestration) ↔ AI GPU VM (inference)

### Option 2: Single VM (All-in-One)

**1-VM Setup**: Everything on GPU VM

```
ThreeFold Grid
└── GPU VM (All-in-One)
    ├── GPU: 1x NVIDIA
    ├── CPU: 16 cores
    ├── RAM: 64GB
    ├── Disk: 500GB
    ├── Role: Both AI agent orchestration AND AI serving
    └── Cost: ~$200-800/month
    
    Services:
    ├── ai-agent framework
    ├── Project workspaces
    ├── vLLM/Ollama server
    └── AI models
```

**Communication:**
- Localhost: `http://localhost:8000/v1/chat/completions`
- No network overhead

**Advantages:**
- ✅ Simpler setup (one VM to manage)
- ✅ Lower latency (localhost)
- ✅ No network configuration needed
- ✅ Good for single-user/project

**Disadvantages:**
- ⚠️ More expensive (always paying for GPU)
- ⚠️ Less flexible (can't scale easily)
- ⚠️ GPU idle when not coding

### Option 3: Hybrid (Best of Both Worlds)

**3+ VM Setup**: AI agent VM + Multiple AI GPU VMs

```
ThreeFold Grid
├── AI agent VM (Orchestration)
│   └── Routes to different AI VMs based on need
│
├── AI GPU VM 1 (Code Generation)
│   └── DeepSeek-Coder-33B
│
├── AI GPU VM 2 (Complex Reasoning)
│   └── Qwen2.5-72B-Instruct
│
└── AI GPU VM 3 (Fast Responses)
    └── Qwen2.5-7B-Instruct
```

**Advantages:**
- ✅ Best model for each task
- ✅ Load balancing
- ✅ High availability
- ✅ Cost optimization (different GPU tiers)

**Use Cases:**
- Large teams
- Production environments
- Multiple projects with different needs

## GPU Requirements

### Minimum Requirements (Budget)

**For 7B models** (e.g., Qwen2.5-7B, CodeLlama-7B):
- **GPU**: 1x RTX 3090 (24GB VRAM) or RTX 4090
- **RAM**: 32GB system RAM
- **Disk**: 100GB SSD
- **Cost**: ~$200-300/month on TFGrid
- **Performance**: 20-50 tokens/sec

**Recommended Models:**
- `qwen2.5-coder-7b-instruct`
- `codellama-7b-instruct`
- `deepseek-coder-6.7b-instruct`

### Recommended (Production)

**For 30-34B models** (e.g., DeepSeek-Coder-33B):
- **GPU**: 1x A100 (40GB or 80GB) or 2x RTX 4090
- **RAM**: 64GB system RAM
- **Disk**: 200GB SSD
- **Cost**: ~$500-800/month on TFGrid
- **Performance**: 30-80 tokens/sec

**Recommended Models:**
- `deepseek-coder-33b-instruct`
- `qwen2.5-coder-32b-instruct`
- `codellama-34b-instruct`

### High-End (Best Quality)

**For 70B+ models** (e.g., Qwen2.5-72B):
- **GPU**: 2x A100 (80GB) or 4x A100 (40GB)
- **RAM**: 128GB+ system RAM
- **Disk**: 500GB SSD
- **Cost**: ~$1,500-2,500/month on TFGrid
- **Performance**: 40-100 tokens/sec

**Recommended Models:**
- `qwen2.5-72b-instruct`
- `llama-3.1-70b-instruct`
- `deepseek-coder-v2-instruct` (236B, requires 8x A100)

## Model Serving Options

### Option A: vLLM (Recommended)

**Best for: Production, high-throughput**

**Features:**
- ✅ Fastest inference (PagedAttention)
- ✅ Continuous batching
- ✅ OpenAI-compatible API
- ✅ Multi-GPU support
- ✅ Quantization support (AWQ, GPTQ)

**Setup:**
```bash
# Install vLLM on GPU VM
pip install vllm

# Start server with DeepSeek-Coder
python -m vllm.entrypoints.openai.api_server \
  --model deepseek-ai/deepseek-coder-33b-instruct \
  --host 0.0.0.0 \
  --port 8000 \
  --tensor-parallel-size 1
```

**Usage from AI agent VM:**
```bash
curl http://ai-gpu-vm:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-ai/deepseek-coder-33b-instruct",
    "messages": [{"role": "user", "content": "Write a Python function"}]
  }'
```

### Option B: Ollama (Easiest)

**Best for: Development, quick setup**

**Features:**
- ✅ Very easy to use
- ✅ Model management (download, update)
- ✅ Good performance
- ✅ REST API
- ✅ Docker support

**Setup:**
```bash
# Install Ollama on GPU VM
curl -fsSL https://ollama.com/install.sh | sh

# Download model
ollama pull deepseek-coder:33b

# Start server (runs automatically)
ollama serve
```

**Usage from AI agent VM:**
```bash
curl http://ai-gpu-vm:11434/api/chat \
  -d '{
    "model": "deepseek-coder:33b",
    "messages": [{"role": "user", "content": "Write a Python function"}],
    "stream": false
  }'
```

### Option C: Text Generation Inference (TGI)

**Best for: HuggingFace models, enterprise**

**Features:**
- ✅ HuggingFace integration
- ✅ Production-ready
- ✅ Quantization support
- ✅ Streaming
- ✅ Prometheus metrics

**Setup:**
```bash
# Run TGI in Docker on GPU VM
docker run --gpus all \
  -p 8080:80 \
  -v $PWD/data:/data \
  ghcr.io/huggingface/text-generation-inference:latest \
  --model-id deepseek-ai/deepseek-coder-33b-instruct \
  --num-shard 1
```

### Option D: LM Studio Server

**Best for: Desktop-like experience, testing**

**Features:**
- ✅ GUI interface
- ✅ Easy model management
- ✅ Good for testing
- ⚠️ Less production-ready

## Cost Analysis

### External APIs (Current)

**Using Qwen-Max (current default):**
```
Usage: 100M tokens/month
- Input:  50M tokens × $2.00/1M  = $100
- Output: 50M tokens × $6.00/1M  = $300
Total: $400/month per project
```

**Using Claude Sonnet:**
```
Usage: 100M tokens/month
- Input:  50M tokens × $3.00/1M  = $150
- Output: 50M tokens × $15.00/1M = $750
Total: $900/month per project
```

### TFGrid GPU Nodes (Proposed)

**Option 1: Budget (7B model):**
```
Infrastructure:
- AI agent VM (4 CPU, 8GB RAM):     $30/month
- GPU VM (RTX 4090, 32GB RAM):   $250/month
Total: $280/month (unlimited usage)

Break-even: ~70M tokens/month vs Qwen-Max
Break-even: ~30M tokens/month vs Claude
```

**Option 2: Production (33B model):**
```
Infrastructure:
- AI agent VM (4 CPU, 8GB RAM):     $30/month
- GPU VM (A100 40GB, 64GB RAM):  $600/month
Total: $630/month (unlimited usage)

Break-even: ~160M tokens/month vs Qwen-Max
Break-even: ~70M tokens/month vs Claude
```

**Option 3: Single VM (All-in-One 33B):**
```
Infrastructure:
- GPU VM (A100 40GB, 64GB RAM):  $600/month
Total: $600/month (unlimited usage)

Break-even: ~150M tokens/month vs Qwen-Max
```

### Cost Comparison Summary

| Scenario | External API | TFGrid GPU | Savings |
|----------|--------------|------------|---------|
| 50M tokens/month | $200 (Qwen) | $280 (7B) | -$80 |
| 100M tokens/month | $400 (Qwen) | $280 (7B) | **+$120** |
| 200M tokens/month | $800 (Qwen) | $280 (7B) | **+$520** |
| 500M tokens/month | $2,000 (Qwen) | $280 (7B) | **+$1,720** |
| 100M tokens/month | $900 (Claude) | $630 (33B) | **+$270** |
| 200M tokens/month | $1,800 (Claude) | $630 (33B) | **+$1,170** |

**Break-even Point:**
- **7B model**: ~70M tokens/month vs Qwen-Max
- **33B model**: ~160M tokens/month vs Qwen-Max
- **For heavy users** (500M+ tokens): **~80% cost reduction**

**Additional Benefits (not priced):**
- ✅ Unlimited usage (no token counting)
- ✅ Complete privacy
- ✅ No rate limits
- ✅ Full control

## Implementation Roadmap

### Phase 1: Proof of Concept (Week 1-2)

**Goal**: Validate GPU node deployment on TFGrid

**Tasks:**
1. Deploy GPU VM on TFGrid manually
2. Install Ollama and test with small model (7B)
3. Deploy AI agent VM
4. Configure internal network (WireGuard/Mycelium)
5. Test API connectivity between VMs
6. Run simple agent loop with local AI

**Deliverables:**
- Working 2-VM setup (manual)
- Performance benchmarks
- Cost validation
- Documentation of process

### Phase 2: Automation (Week 3-4)

**Goal**: Automate deployment with OpenTofu + Ansible

**Tasks:**
1. Create OpenTofu configuration for GPU VM
2. Extend existing `main.tf` to support GPU nodes
3. Create Ansible role for AI node setup
4. Implement model download/setup automation
5. Add GPU node to `make deploy` workflow
6. Create helper commands (`make ai-node`, `make test-ai`)

**Deliverables:**
- `infrastructure/gpu-node.tf`
- `platform/roles/ai_node/`
- Updated Makefile
- Documentation

### Phase 3: Integration (Week 5-6)

**Goal**: Seamless integration with ai-agent

**Tasks:**
1. Modify ai-agent to support local AI endpoints
2. Add provider adapter for local TFGrid AI
3. Implement automatic failover (local → external API)
4. Add model selection in project config
5. Create monitoring/logging for GPU usage
6. Performance optimization

**Deliverables:**
- Updated ai-agent with TFGrid AI support
- `AI_PROVIDER=tfgrid-local` configuration
- Monitoring dashboard
- Performance report

### Phase 4: Production Hardening (Week 7-8)

**Goal**: Production-ready solution

**Tasks:**
1. Implement load balancing (multiple GPU VMs)
2. Add health checks and auto-recovery
3. Security hardening (firewall rules, API auth)
4. Cost tracking and optimization
5. Comprehensive testing
6. User documentation

**Deliverables:**
- Production-ready deployment
- Security audit
- User guide
- Migration guide (API → TFGrid AI)

### Phase 5: Advanced Features (Month 3+)

**Goal**: Enterprise features and optimizations

**Tasks:**
1. Multi-model support (switch models per project)
2. GPU sharing between projects
3. Auto-scaling (spin up/down GPU VMs)
4. Model fine-tuning support
5. Distributed inference (multi-GPU)
6. Cost optimization (spot instances, model quantization)

## Technical Specifications

### Network Configuration

**Internal Network (AI agent VM ↔ AI GPU VM):**
```
┌─────────────────────────────────────┐
│  ThreeFold Grid Network             │
│                                     │
│  AI agent VM                           │
│  ├─ WireGuard IP: 10.1.0.10        │
│  └─ Mycelium IP: [ipv6]            │
│                                     │
│  AI GPU VM                          │
│  ├─ WireGuard IP: 10.1.0.20        │
│  └─ Mycelium IP: [ipv6]            │
│  └─ API: http://10.1.0.20:8000     │
└─────────────────────────────────────┘
```

**Security:**
- Only AI agent VM can access AI GPU VM
- No external access to AI API
- Encrypted communication (WireGuard/Mycelium)

### OpenTofu Configuration

**Extend `main.tf` with GPU node:**
```hcl
# AI GPU VM
resource "grid_deployment" "ai_gpu" {
  node         = var.ai_gpu_node  # GPU-enabled node
  network_name = grid_network.ai_agent_network.name

  vms {
    name        = "ai_gpu_vm"
    flist       = "https://hub.grid.tf/tf-official-vms/ubuntu-22.04-lts-cuda.flist"
    cpu         = var.ai_gpu_cpu
    memory      = var.ai_gpu_mem
    rootfs_size = var.ai_gpu_disk * 1024 * 1024 * 1024
    entrypoint  = "/sbin/zinit init"
    planetary   = true
    
    # GPU configuration
    gpus = ["GPU-${var.gpu_type}"]  # e.g., "GPU-A100", "GPU-RTX4090"
    
    env_vars = {
      SSH_KEY = local.ssh_key
    }
  }
}

output "ai_gpu_wg_ip" {
  value       = grid_network.ai_agent_network.access_wg_config.peers[1].allowed_ips[0]
  description = "AI GPU VM WireGuard IP"
}
```

### Ansible Configuration

**New role: `platform/roles/ai_node/tasks/main.yml`:**
```yaml
---
- name: Install NVIDIA drivers
  apt:
    name:
      - nvidia-driver-535
      - nvidia-cuda-toolkit
    state: present

- name: Install Docker with GPU support
  include_role:
    name: geerlingguy.docker

- name: Install NVIDIA Container Toolkit
  shell: |
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | apt-key add -
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | \
      tee /etc/apt/sources.list.d/nvidia-docker.list
    apt-get update && apt-get install -y nvidia-container-toolkit

- name: Install vLLM or Ollama
  shell: |
    pip install vllm
    # OR
    curl -fsSL https://ollama.com/install.sh | sh

- name: Download AI model
  shell: |
    # For Ollama
    ollama pull deepseek-coder:33b
    # For vLLM (HuggingFace)
    huggingface-cli download deepseek-ai/deepseek-coder-33b-instruct

- name: Start AI server
  systemd:
    name: ai-server
    enabled: yes
    state: started
```

### Project Configuration

**`.ai-agent-config` with TFGrid AI:**
```bash
# Use local TFGrid AI
AI_PROVIDER=tfgrid-local

# AI GPU VM endpoint
TFGRID_AI_ENDPOINT=http://10.1.0.20:8000

# Model selection
TFGRID_AI_MODEL=deepseek-coder-33b-instruct

# Fallback to external API if local fails
AI_FALLBACK_PROVIDER=deepseek
DEEPSEEK_API_KEY=xxx
```

## Migration Guide

### Migrating from External APIs to TFGrid AI

**Step 1: Deploy AI GPU VM**
```bash
# Add GPU node configuration to .env
export TF_VAR_ai_gpu_node=5678  # GPU-enabled node ID
export TF_VAR_gpu_type=A100

# Deploy
make infrastructure
make ansible
```

**Step 2: Test AI Endpoint**
```bash
# Test from AI agent VM
make connect
curl http://10.1.0.20:8000/v1/models
```

**Step 3: Update Project Configuration**
```bash
cd /opt/ai-agent-projects/my-project
echo "AI_PROVIDER=tfgrid-local" >> .ai-agent-config
echo "TFGRID_AI_ENDPOINT=http://10.1.0.20:8000" >> .ai-agent-config
```

**Step 4: Run AI agent with Local AI**
```bash
make run-project project=my-project
```

## Benefits Summary

### Technical Benefits
- ✅ **Full Decentralization**: No external dependencies
- ✅ **Complete Privacy**: Data never leaves TFGrid
- ✅ **Low Latency**: Local network, no internet roundtrip
- ✅ **No Rate Limits**: Unlimited usage
- ✅ **Customization**: Fine-tune models for your use case
- ✅ **Offline Capable**: Works without internet

### Business Benefits
- ✅ **Cost Predictable**: Fixed monthly cost, not per-token
- ✅ **Cost Savings**: 50-80% reduction for heavy users
- ✅ **Compliance**: Perfect for regulated industries
- ✅ **Vendor Independence**: Not locked to any AI provider
- ✅ **Competitive Advantage**: Unique fully-decentralized solution

### Strategic Benefits
- ✅ **ThreeFold Ecosystem**: Strengthens TFGrid use case
- ✅ **GPU Utilization**: Monetizes TFGrid GPU capacity
- ✅ **Community Growth**: Attracts AI/ML developers to TFGrid
- ✅ **Future-Proof**: Own the full stack

## Next Steps

### Immediate Actions
1. **Validate GPU availability** on ThreeFold Grid
2. **Test GPU node deployment** manually
3. **Benchmark performance** with different models
4. **Calculate real costs** on TFGrid GPU nodes
5. **Gather community feedback** on proposed architecture

### Decision Points
- [ ] Prefer 2-VM or 1-VM setup?
- [ ] Which model serving solution? (vLLM, Ollama, TGI)
- [ ] Which models to support? (7B, 33B, 70B+)
- [ ] Pricing strategy for TFGrid GPU time?
- [ ] Timeline for implementation?

---

**This represents the ultimate vision for TFGrid AI-Agent: A fully decentralized, privacy-preserving, AI-powered development environment running entirely on ThreeFold Grid.** 🚀

Ready to proceed with implementation once architecture decisions are made.
