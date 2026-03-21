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
apt-get install -y -qq git curl jq wget python3 python3-pip apt-transport-https ca-certificates gnupg bc 2>/dev/null || \
    warn "Some packages failed to install"

# Install Go (FIXED: Dynamic version detection)
if ! command -v go &>/dev/null; then
    info "Installing Go..."
    
    # Get latest stable Go version dynamically
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
    GO_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
    
    info "Downloading Go ${GO_VERSION}..."
    wget -q "$GO_URL" || error "Failed to download Go"
    
    tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz" || error "Failed to extract Go"
    rm "${GO_VERSION}.linux-amd64.tar.gz"
    
    # FIXED: PATH export - use literal paths, not command substitution
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    echo 'export PATH=$PATH:$HOME/go/bin' >> /etc/profile
    source /etc/profile
    
    export PATH=$PATH:/usr/local/go/bin
    success "Go installed: $(go version)"
fi

# Install Python tools (FIXED: Handle externally-managed-environment)
info "Installing Python security tools..."
pip3 install --break-system-packages -q wafw00f sqlmap whatweb 2>/dev/null || \
    pip3 install -q wafw00f sqlmap whatweb 2>/dev/null || \
    warn "Some Python packages failed to install"

# Install APT tools
info "Installing APT security tools..."
apt-get install -y -qq amass nmap 2>/dev/null || warn "Some tools failed"

# Install SecLists (FIXED: Removed extra spaces in URL)
if [[ ! -d /usr/share/seclists ]]; then
    info "Installing SecLists wordlists..."
    git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null || \
        warn "SecLists installation failed"
fi

# Make scripts executable (FIXED: Check if files exist first)
for script in recon.sh setup_config.sh; do
    if [[ -f "$script" ]]; then
        chmod +x "$script"
        success "Made $script executable"
    else
        warn "$script not found in current directory"
    fi
done

# Verify installations
info "Verifying installations..."
local missing_tools=()

for tool in git curl jq wget python3 go; do
    if ! command -v "$tool" &>/dev/null; then
        missing_tools+=("$tool")
    fi
done

if [[ ${#missing_tools[@]} -gt 0 ]]; then
    warn "Some tools are missing: ${missing_tools[*]}"
    warn "You may need to install them manually"
else
    success "All core tools verified!"
fi

success "Installation complete!"
echo
info "Next steps:"
echo "  1. Run: ./setup_config.sh (as regular user, NOT root)"
echo "  2. Edit: ~/.recon_config and ~/api_keys.sh"
echo "  3. Run: sudo ./recon.sh example.com"
echo
info "IMPORTANT: Source your profile or restart terminal for Go PATH to take effect:"
echo "  source /etc/profile"
echo
