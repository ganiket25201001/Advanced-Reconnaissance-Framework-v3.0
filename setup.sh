#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# 🚀 ARF - ADVANCED RECONNAISSANCE FRAMEWORK
# 📦 Complete Setup Script - Installation + Configuration
# ════════════════════════════════════════════════════════════════════════════
# Usage:
#   sudo ./setup.sh        - Install dependencies and tools
#   ./setup.sh --config    - Run interactive configuration wizard
# ════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── COLORS ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[ℹ]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✗]${RESET} $*"; }
question(){ echo -e "${BLUE}[?]${RESET} $*"; }

header() {
    echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${GREEN}  $*${RESET}"
    echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"
}

show_banner() {
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀 ARF - ADVANCED RECONNAISSANCE FRAMEWORK                ║
║   Complete Setup Script - Installation & Configuration      ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOME}/.recon_config"
API_KEYS_FILE="${HOME}/api_keys.sh"

# ─── INSTALLER SECTION (requires sudo) ───────────────────────────────────────
run_installer() {
    if [[ $EUID -ne 0 ]]; then
        error "Installer requires sudo privileges"
        error "Run: sudo ./setup.sh"
        exit 1
    fi

    show_banner
    header "🚀 ARF INSTALLER"

    # Update system
    info "Updating system packages..."
    apt-get update -qq

    # Install dependencies
    info "Installing system dependencies..."
    apt-get install -y -qq git curl jq wget python3 python3-pip apt-transport-https ca-certificates gnupg bc 2>/dev/null || \
        warn "Some packages failed to install"

    # Install Go
    if ! command -v go &>/dev/null; then
        info "Installing Go..."
        GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
        GO_URL="https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"

        info "Downloading Go ${GO_VERSION}..."
        wget -q "$GO_URL" || error "Failed to download Go"

        tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz" || error "Failed to extract Go"
        rm "${GO_VERSION}.linux-amd64.tar.gz"

        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
        echo 'export PATH=$PATH:$HOME/go/bin' >> /etc/profile
        source /etc/profile
        export PATH=$PATH:/usr/local/go/bin
        success "Go installed: $(go version)"
    fi

    # Install Python tools
    info "Installing Python security tools..."
    pip3 install --break-system-packages -q wafw00f sqlmap whatweb 2>/dev/null || \
        pip3 install -q wafw00f sqlmap whatweb 2>/dev/null || \
        warn "Some Python packages failed to install"

    # Install APT tools
    info "Installing APT security tools..."
    apt-get install -y -qq amass nmap 2>/dev/null || warn "Some tools failed"

    # Install SecLists
    if [[ ! -d /usr/share/seclists ]]; then
        info "Installing SecLists wordlists..."
        git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null || \
            warn "SecLists installation failed"
    fi

    # Make scripts executable
    for script in recon.sh setup.sh; do
        if [[ -f "$script" ]]; then
            chmod +x "$script"
            success "Made $script executable"
        fi
    done

    # Install arf symlink to /usr/local/bin
    info "Installing 'arf' command..."
    if [[ -f "recon.sh" ]]; then
        cp "recon.sh" /usr/local/bin/arf
        chmod +x /usr/local/bin/arf
        success "ARF command installed! Run 'arf --help' to get started"
    fi

    # Verify installations
    info "Verifying installations..."
    local missing_tools=()
    for tool in git curl jq wget python3; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        warn "Some tools are missing: ${missing_tools[*]}"
    else
        success "All core tools verified!"
    fi

    success "Installation complete!"
    echo
    info "Next steps:"
    echo "  1. Run: ./setup.sh --config (as regular user, NOT root)"
    echo "  2. Edit: ~/.recon_config and ~/api_keys.sh"
    echo "  3. Run: sudo arf example.com"
    echo
    info "IMPORTANT: Source your profile or restart terminal for Go PATH:"
    echo "  source /etc/profile"
    echo
}

# ─── CONFIGURATION WIZARD SECTION (regular user) ─────────────────────────────
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    while true; do
        if [[ "$default" == "y" ]]; then
            read -p "$(question "$prompt [Y/n]: ") " response
            response="${response:-y}"
        else
            read -p "$(question "$prompt [y/N]: ") " response
            response="${response:-n}"
        fi

        case "$response" in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) warn "Please answer yes or no" ;;
        esac
    done
}

ask_input() {
    local prompt="$1"
    local default="${2:-}"
    local response

    if [[ -n "$default" ]]; then
        read -p "$(question "$prompt [$default]: ") " response
        echo "${response:-$default}"
    else
        read -p "$(question "$prompt: ") " response
        echo "$response"
    fi
}

ask_secret() {
    local prompt="$1"
    local response
    read -s -p "$(question "$prompt: ") " response
    echo
    echo "$response"
}

check_prerequisites() {
    header "🔍 CHECKING PREREQUISITES"

    local missing=()

    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        error "Bash 4.0+ required"
    fi

    for cmd in curl git jq go python3 bc; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing: ${missing[*]}"
        echo
        info "Run 'sudo ./setup.sh' first to install dependencies"
        exit 1
    else
        success "All prerequisites met!"
    fi
}

generate_config() {
    header "⚙️  GENERATING CONFIGURATION"

    info "Configuration will be saved to: ${CONFIG_FILE}"

    # Thread Configuration
    header "🧵 THREAD & PERFORMANCE"
    THREADS=$(ask_input "Number of concurrent threads" "200")
    RATE_LIMIT=$(ask_input "Requests per second" "50")
    CRAWL_DEPTH=$(ask_input "Crawl depth" "5")
    TIMEOUT=$(ask_input "Request timeout (seconds)" "10")

    # Mode Settings
    header "🎯 SCANNING MODE"
    if ask_yes_no "Enable stealth mode by default"; then
        STEALTH_MODE="true"
    else
        STEALTH_MODE="false"
    fi

    if ask_yes_no "Enable WAF bypass by default"; then
        WAF_BYPASS="true"
    else
        WAF_BYPASS="false"
    fi

    if ask_yes_no "Generate HTML reports by default"; then
        HTML_REPORT="true"
    else
        HTML_REPORT="false"
    fi

    # Notifications
    header "🔔 NOTIFICATIONS"
    NOTIFY_CHANNEL=""
    DISCORD_WEBHOOK=""
    SLACK_WEBHOOK=""

    if ask_yes_no "Enable notifications"; then
        echo "  1) Discord  2) Slack  3) Skip"
        read -p "$(question "Choose [1-3]: ") " notify_choice
        case "$notify_choice" in
            1) NOTIFY_CHANNEL="discord"; DISCORD_WEBHOOK=$(ask_input "Discord webhook URL") ;;
            2) NOTIFY_CHANNEL="slack"; SLACK_WEBHOOK=$(ask_input "Slack webhook URL") ;;
        esac
    fi

    # Write config
    cat > "$CONFIG_FILE" << EOF
# ARF Configuration - Generated: $(date)
THREADS=$THREADS
RATE_LIMIT=$RATE_LIMIT
CRAWL_DEPTH=$CRAWL_DEPTH
TIMEOUT=$TIMEOUT
STEALTH_MODE=$STEALTH_MODE
WAF_BYPASS=$WAF_BYPASS
HTML_REPORT=$HTML_REPORT
NOTIFY_CHANNEL="$NOTIFY_CHANNEL"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
SLACK_WEBHOOK="$SLACK_WEBHOOK"

# API Keys (optional - can also use ~/api_keys.sh)
SHODAN_API_KEY=""
VIRUSTOTAL_API_KEY=""
SECURITYTRAILS_API_KEY=""
GITHUB_TOKEN=""
EOF

    chmod 600 "$CONFIG_FILE"
    success "Configuration saved: $CONFIG_FILE"
}

generate_api_keys() {
    header "🔑 API KEYS (OPTIONAL)"

    if ! ask_yes_no "Configure API keys now?"; then
        cat > "$API_KEYS_FILE" << 'EOF'
#!/bin/bash
# ARF API Keys - Keep secure! chmod 600
export SHODAN_API_KEY=""
export SECURITYTRAILS_API_KEY=""
export CENSYS_API_ID=""
export CENSYS_API_SECRET=""
export VIRUSTOTAL_API_KEY=""
export GITHUB_TOKEN=""
export DISCORD_WEBHOOK=""
export SLACK_WEBHOOK=""
EOF
        chmod 600 "$API_KEYS_FILE"
        success "API keys template created: $API_KEYS_FILE"
        return 0
    fi

    echo "Get keys from: shodan.io, virustotal.com, securitytrails.com, github.com"
    echo

    SHODAN_KEY=$(ask_secret "Shodan API Key")
    VT_KEY=$(ask_secret "VirusTotal API Key")
    ST_KEY=$(ask_secret "SecurityTrails API Key")
    GITHUB_TOKEN_VAL=$(ask_secret "GitHub Token")
    DISCORD_WEBHOOK=$(ask_input "Discord webhook (optional)")

    cat > "$API_KEYS_FILE" << EOF
#!/bin/bash
# ARF API Keys - Generated: $(date) - Keep secure!
export SHODAN_API_KEY="$SHODAN_KEY"
export SECURITYTRAILS_API_KEY="$ST_KEY"
export VIRUSTOTAL_API_KEY="$VT_KEY"
export GITHUB_TOKEN="$GITHUB_TOKEN_VAL"
export DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
export SLACK_WEBHOOK=""
EOF

    chmod 600 "$API_KEYS_FILE"
    success "API keys saved: $API_KEYS_FILE"
}

install_tools_interactive() {
    header "🔧 TOOL INSTALLATION"

    if ! ask_yes_no "Install security tools now?"; then
        return 0
    fi

    info "This may take 10-15 minutes..."

    # Check if running as root for apt operations
    if [[ $EUID -eq 0 ]]; then
        apt-get update -qq
        apt-get install -y -qq git curl jq wget python3 python3-pip amass nmap bc 2>/dev/null || true
    else
        info "Installing Python tools (system-wide requires sudo)..."
        pip3 install --break-system-packages -q wafw00f sqlmap whatweb 2>/dev/null || \
            pip3 install -q wafw00f sqlmap whatweb 2>/dev/null || \
            warn "Some Python packages failed to install"
        echo
        warn "For full tool installation, run: sudo ./setup.sh"
        return 0
    fi

    pip3 install --break-system-packages -q wafw00f sqlmap whatweb 2>/dev/null || true

    if command -v go &>/dev/null; then
        export PATH="$PATH:$(go env GOPATH)/bin"
        info "Installing Go tools..."
        go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null &
        go install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null &
        go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>/dev/null &
        go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>/dev/null &
        wait
        success "Go tools installed"
    fi

    if [[ ! -d /usr/share/seclists ]]; then
        git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null || true
    fi

    success "Tool installation complete!"
}

create_sample_targets() {
    header "📁 SAMPLE TARGETS FILE"

    cat > "${SCRIPT_DIR}/targets.txt.example" << 'EOF'
# ARF Sample Targets File
# Format: One domain per line
# Comments start with #

example.com
api.example.com
www.example.com
EOF

    success "Sample targets created: ${SCRIPT_DIR}/targets.txt.example"
}

show_summary() {
    header "🎉 SETUP COMPLETE!"

    echo -e "${BOLD}Configuration Summary:${RESET}"
    echo "  ✓ Config:      ${CONFIG_FILE}"
    echo "  ✓ API keys:    ${API_KEYS_FILE}"
    echo "  ✓ Sample:      ${SCRIPT_DIR}/targets.txt.example"
    echo

    echo -e "${BOLD}Quick Start:${RESET}"
    echo "  sudo arf example.com"
    echo "  sudo arf -f targets.txt.example"
    echo "  arf --help"
    echo

    echo -e "${BOLD}Important:${RESET}"
    echo "  • Always use: sudo arf ..."
    echo "  • Only scan targets you own or have permission to test"
    echo "  • Keep api_keys.sh secure (chmod 600)"
    echo

    echo -e "${GREEN}  Happy Reconnaissance! 🚀${RESET}"
}

run_config_wizard() {
    show_banner
    check_prerequisites
    generate_config
    generate_api_keys
    install_tools_interactive
    create_sample_targets
    show_summary
}

# ─── MAIN ────────────────────────────────────────────────────────────────────
main() {
    if [[ "${1:-}" == "--config" ]]; then
        run_config_wizard
    elif [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
        echo "Usage:"
        echo "  sudo ./setup.sh        - Install dependencies and tools"
        echo "  ./setup.sh --config    - Run interactive configuration wizard"
        echo "  ./setup.sh --help      - Show this help"
    else
        # Default: run installer if sudo, otherwise show message
        if [[ $EUID -eq 0 ]]; then
            run_installer
        else
            show_banner
            echo
            info "ARF Setup - Two modes:"
            echo
            echo -e "  ${GREEN}1. Install (requires sudo):${RESET}"
            echo -e "     sudo ./setup.sh"
            echo
            echo -e "  ${GREEN}2. Configure (as regular user):${RESET}"
            echo -e "     ./setup.sh --config"
            echo
            echo "Run with --help for more information."
            echo
        fi
    fi
}

main "$@"
