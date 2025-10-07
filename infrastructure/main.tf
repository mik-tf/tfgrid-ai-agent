terraform {
  required_providers {
    grid = {
      source = "threefoldtech/grid"
    }
  }
}

# ==============================================================================
# VARIABLES
# ==============================================================================

variable "mnemonic" {
  type        = string
  sensitive   = true
  description = "ThreeFold mnemonic for authentication"
}

variable "SSH_KEY" {
  type        = string
  default     = null
  description = "SSH public key content (if null, will auto-detect from ~/.ssh/)"
}

variable "tfgrid_network" {
  type        = string
  default     = "main"
  description = "ThreeFold Grid network (main, test, dev)"
}

variable "ai_agent_node" {
  type        = number
  description = "Node ID for AI Agent VM"
}

variable "ai_agent_cpu" {
  type    = number
  default = 4
}

variable "ai_agent_mem" {
  type    = number
  default = 8192 # 8GB RAM
}

variable "ai_agent_disk" {
  type    = number
  default = 100 # 100GB storage
}

# ==============================================================================
# LOCALS
# ==============================================================================

locals {
  # Auto-detect SSH key from local machine
  ssh_key = var.SSH_KEY != null ? var.SSH_KEY : (
    fileexists(pathexpand("~/.ssh/id_ed25519.pub")) ?
    file(pathexpand("~/.ssh/id_ed25519.pub")) :
    file(pathexpand("~/.ssh/id_rsa.pub"))
  )
}

# ==============================================================================
# PROVIDER
# ==============================================================================

provider "grid" {
  mnemonic  = var.mnemonic
  network   = var.tfgrid_network
  relay_url = var.tfgrid_network == "main" ? "wss://relay.grid.tf" : "wss://relay.test.grid.tf"
}

# ==============================================================================
# RANDOM RESOURCES
# ==============================================================================

resource "random_bytes" "mycelium_key" {
  length = 32
}

resource "random_bytes" "ai_agent_ip_seed" {
  length = 6
}

# ==============================================================================
# NETWORK
# ==============================================================================

resource "grid_network" "ai_agent_network" {
  name          = "ai_agent_net"
  nodes         = [var.ai_agent_node]
  ip_range      = "10.1.0.0/16"
  add_wg_access = true
  mycelium_keys = {
    tostring(var.ai_agent_node) = random_bytes.mycelium_key.hex
  }
}

# ==============================================================================
# AI AGENT VM
# ==============================================================================

resource "grid_deployment" "ai_agent" {
  node         = var.ai_agent_node
  network_name = grid_network.ai_agent_network.name

  vms {
    name             = "ai_agent_vm"
    flist            = "https://hub.grid.tf/tf-official-vms/ubuntu-24.04-full.flist"
    cpu              = var.ai_agent_cpu
    memory           = var.ai_agent_mem
    rootfs_size      = var.ai_agent_disk * 1024  # Convert GB to MB
    entrypoint       = "/sbin/zinit init"
    planetary        = true
    env_vars = {
      SSH_KEY = local.ssh_key
    }
  }
}

# ==============================================================================
# OUTPUTS
# ==============================================================================

output "ai_agent_node_id" {
  value       = var.ai_agent_node
  description = "Node ID where AI Agent VM is deployed"
}

output "ai_agent_wg_ip" {
  value       = regex("Address = ([0-9.]+)", grid_network.ai_agent_network.access_wg_config)[0]
  description = "AI Agent VM WireGuard IP address"
}

output "ai_agent_mycelium_ip" {
  value       = grid_deployment.ai_agent.vms[0].mycelium_ip
  description = "AI Agent VM Mycelium IPv6 address"
}

output "wg_config" {
  value       = grid_network.ai_agent_network.access_wg_config
  sensitive   = true
  description = "WireGuard configuration for accessing AI Agent VM"
}

output "network_name" {
  value       = grid_network.ai_agent_network.name
  description = "Network name"
}
