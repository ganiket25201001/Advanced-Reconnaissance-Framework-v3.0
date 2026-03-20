#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# 🚀 RECON FRAMEWORK - ONE-COMMAND INSTALLER
# Installs dependencies, configures, and sets up everything
# ════════════════════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

info() { echo -e "${CYAN}[ℹ]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
error() { echo -e "${RED}[✗]${RESET} $*"; exit 1; }

header() {
    echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${GREEN}  $*${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"
}

# Check sudo
if [[ $EUID -ne 0 ]]; then
    error "This installer requires sudo privileges"
    error "Run: sudo ./install.sh"
fi

header "🚀 RECON FRAMEWORK INSTALLER"

# Update system
info "Updating system packages..."
apt-get update -qq

# Install dependencies
info "Installing system dependencies..."
apt-get install -y -qq git curl jq wget python3 python3-pip apt-transport-https ca-certificates gnupg

# Install Go
if ! command -v go &>/dev/null; then
    info "Installing Go..."
    wget -q https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm go1.21.0.linux-amd64.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> /etc/profile
    export PATH=$PATH:/usr/local/go/bin
    success "Go installed"
fi

# Install Python tools
info "Installing Python security tools..."
pip3 install -q wafw00f sqlmap whatweb

# Install APT tools
info "Installing APT security tools..."
apt-get install -y -qq amass nmap 2>/dev/null || warn "Some tools failed"

# Install SecLists
if [[ ! -d /usr/share/seclists ]]; then
    info "Installing SecLists wordlists..."
    git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null
fi

# Make scripts executable
chmod +x recon.sh setup_config.sh 2>/dev/null || true

success "Installation complete!"
echo
info "Next steps:"
echo "  1. Run: ./setup_config.sh (as regular user)"
echo "  2. Edit: ~/.recon_config and ~/api_keys.json"
echo "  3. Run: sudo ./recon.sh example.com"
echo
