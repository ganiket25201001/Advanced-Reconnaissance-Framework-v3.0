#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# 🔧 RECON FRAMEWORK - CONFIGURATION SETUP SCRIPT
# 📅 Automatically generates ~/.recon_config and ~/api_keys.sh
# ════════════════════════════════════════════════════════════════════════════

set -euo pipefail

# ─── COLORS ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[ℹ]${RESET} $*"; }
success() { echo -e "${GREEN}[✓]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✗]${RESET} $*"; }
question(){ echo -e "${BLUE}[?]${RESET} $*"; }
header()  { echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}"; echo -e "${BOLD}${GREEN}  $*${RESET}"; echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"; }

# ─── CONFIG PATHS ────────────────────────────────────────────────────────────
CONFIG_FILE="${HOME}/.recon_config"
API_KEYS_FILE="${HOME}/api_keys.sh"  # FIXED: Changed from .json to .sh
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── DEFAULT VALUES ──────────────────────────────────────────────────────────
DEFAULT_THREADS=200
DEFAULT_RATE_LIMIT=50
DEFAULT_CRAWL_DEPTH=5
DEFAULT_TIMEOUT=10

# ─── GLOBAL VARIABLES FOR API KEYS ─────────────────────────────────────────
# FIXED: Declare globally so they persist across functions
DISCORD_WEBHOOK=""
SLACK_WEBHOOK=""
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""
SHODAN_KEY=""
VT_KEY=""
ST_KEY=""
CENSYS_ID=""
CENSYS_SECRET=""
GITHUB_TOKEN_VAL=""

# ─── HELPER FUNCTIONS ────────────────────────────────────────────────────────

# Ask yes/no question
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

# Ask for input with default
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

# Ask for sensitive input (hidden) - FIXED: Don't echo the secret
ask_secret() {
    local prompt="$1"
    local response
    read -s -p "$(question "$prompt: ") " response
    echo  # Newline only, don't echo the secret
    echo "$response"  # Return value for variable assignment
}

# Validate email format
validate_email() {
    local email="$1"
    [[ "$email" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]
}

# Validate URL format
validate_url() {
    local url="$1"
    [[ "$url" =~ ^https?:// ]]
}

# ─── CHECK PREREQUISITES ─────────────────────────────────────────────────────
check_prerequisites() {
    header "🔍 CHECKING PREREQUISITES"
    
    local missing=()
    
    # Check Bash version - FIXED: Make it more strict
    if [[ ${BASH_VERSINFO[0]} -lt 4 ]]; then
        error "Bash 4.0+ required (you have ${BASH_VERSINFO[0]})"
    fi
    
    # Check Go
    if ! command -v go &>/dev/null; then
        missing+=("Go (https://go.dev/dl/)")
    fi
    
    # Check Python3
    if ! command -v python3 &>/dev/null; then
        missing+=("Python 3")
    fi
    
    # Check bc - FIXED: Added bc check
    if ! command -v bc &>/dev/null; then
        missing+=("bc (apt-get install bc)")
    fi
    
    # Check required commands
    for cmd in curl git jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Missing dependencies:"
        for dep in "${missing[@]}"; do
            echo -e "  ${RED}✗${RESET} $dep"
        done
        echo
        info "Install missing dependencies and run this script again"
        echo
        if ask_yes_no "Continue anyway?"; then
            warn "Some features may not work properly"
        else
            exit 1
        fi
    else
        success "All prerequisites met!"
    fi
}

# ─── GENERATE CONFIG FILE ────────────────────────────────────────────────────
generate_config() {
    header "⚙️  GENERATING CONFIGURATION FILE"
    
    info "Configuration will be saved to: ${CONFIG_FILE}"
    echo
    
    # Thread Configuration
    header "🧵 THREAD & PERFORMANCE SETTINGS"
    
    THREADS=$(ask_input "Number of concurrent threads" "$DEFAULT_THREADS")
    RATE_LIMIT=$(ask_input "Requests per second rate limit" "$DEFAULT_RATE_LIMIT")
    CRAWL_DEPTH=$(ask_input "Crawl depth for URL discovery" "$DEFAULT_CRAWL_DEPTH")
    TIMEOUT=$(ask_input "Request timeout in seconds" "$DEFAULT_TIMEOUT")
    
    # Mode Settings
    header "🎯 SCANNING MODE SETTINGS"
    
    if ask_yes_no "Enable stealth mode by default (slower, less detectable)"; then
        STEALTH_MODE="true"
        warn "Stealth mode will reduce threads to 50 and rate limit to 10"
    else
        STEALTH_MODE="false"
    fi
    
    if ask_yes_no "Enable aggressive mode by default (faster, more detectable)"; then
        AGGRESSIVE_MODE="true"
        warn "Aggressive mode will increase threads to 500 and rate limit to 100"
    else
        AGGRESSIVE_MODE="false"
    fi
    
    if ask_yes_no "Enable WAF bypass by default"; then
        WAF_BYPASS="true"
    else
        WAF_BYPASS="false"
    fi
    
    # Report Settings
    header "📊 REPORT SETTINGS"
    
    if ask_yes_no "Generate HTML reports by default"; then
        HTML_REPORT="true"
    else
        HTML_REPORT="false"
    fi
    
    if ask_yes_no "Generate JSON reports by default"; then
        JSON_REPORT="true"
    else
        JSON_REPORT="false"
    fi
    
    # Notification Settings
    header "🔔 NOTIFICATION SETTINGS"
    
    if ask_yes_no "Enable notifications after scan completion"; then
        echo
        info "Select notification channel:"
        echo "  1) Discord"
        echo "  2) Slack"
        echo "  3) Telegram"
        echo "  4) Skip for now"
        echo
        
        read -p "$(question "Choose option [1-4]: ") " notify_choice
        
        case "$notify_choice" in
            1)
                NOTIFY_CHANNEL="discord"
                DISCORD_WEBHOOK=$(ask_input "Enter Discord webhook URL")
                SLACK_WEBHOOK=""
                TELEGRAM_BOT_TOKEN=""
                TELEGRAM_CHAT_ID=""
                ;;
            2)
                NOTIFY_CHANNEL="slack"
                SLACK_WEBHOOK=$(ask_input "Enter Slack webhook URL")
                DISCORD_WEBHOOK=""
                TELEGRAM_BOT_TOKEN=""
                TELEGRAM_CHAT_ID=""
                ;;
            3)
                NOTIFY_CHANNEL="telegram"
                TELEGRAM_BOT_TOKEN=$(ask_secret "Enter Telegram Bot Token")
                TELEGRAM_CHAT_ID=$(ask_input "Enter Telegram Chat ID")
                DISCORD_WEBHOOK=""
                SLACK_WEBHOOK=""
                ;;
            *)
                NOTIFY_CHANNEL=""
                DISCORD_WEBHOOK=""
                SLACK_WEBHOOK=""
                TELEGRAM_BOT_TOKEN=""
                TELEGRAM_CHAT_ID=""
                info "Notifications disabled (can be configured later)"
                ;;
        esac
    else
        NOTIFY_CHANNEL=""
        DISCORD_WEBHOOK=""
        SLACK_WEBHOOK=""
        TELEGRAM_BOT_TOKEN=""
        TELEGRAM_CHAT_ID=""
    fi
    
    # Write config file - FIXED: Check if file created successfully
    info "Writing configuration file..."
    
    if cat > "$CONFIG_FILE" << EOF
# ════════════════════════════════════════════════════════════════════════════
# RECON FRAMEWORK CONFIGURATION FILE
# Generated: $(date)
# Location: $CONFIG_FILE
# ════════════════════════════════════════════════════════════════════════════

# ─── THREAD & PERFORMANCE SETTINGS ──────────────────────────────────────────
THREADS=$THREADS
RATE_LIMIT=$RATE_LIMIT
CRAWL_DEPTH=$CRAWL_DEPTH
TIMEOUT=$TIMEOUT

# ─── SCANNING MODE SETTINGS ─────────────────────────────────────────────────
STEALTH_MODE=$STEALTH_MODE
AGGRESSIVE_MODE=$AGGRESSIVE_MODE
WAF_BYPASS=$WAF_BYPASS

# ─── REPORT SETTINGS ────────────────────────────────────────────────────────
HTML_REPORT=$HTML_REPORT
JSON_REPORT=$JSON_REPORT

# ─── NOTIFICATION SETTINGS ──────────────────────────────────────────────────
NOTIFY_CHANNEL="$NOTIFY_CHANNEL"
DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
SLACK_WEBHOOK="$SLACK_WEBHOOK"
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"

# ─── API KEYS (Optional - Can also use ~/api_keys.sh) ───────────────────────
# Get your API keys from:
# - Shodan: https://www.shodan.io/
# - VirusTotal: https://www.virustotal.com/
# - SecurityTrails: https://securitytrails.com/
# - Censys: https://search.censys.io/
# - GitHub: https://github.com/settings/tokens

SHODAN_API_KEY=""
VIRUSTOTAL_API_KEY=""
SECURITYTRAILS_API_KEY=""
CENSYS_API_ID=""
CENSYS_API_SECRET=""
BINARYEDGE_API_KEY=""
GITHUB_TOKEN=""

# ─── ADVANCED SETTINGS ──────────────────────────────────────────────────────
# Proxy Settings
USE_PROXY=false
PROXY_URL=""

# Tor Settings
USE_TOR=false

# Output Settings
OUTPUT_BASE_DIR="\$HOME/recon_scans"

# Log Settings
LOG_LEVEL="INFO"
# Options: DEBUG, INFO, WARN, ERROR

# ════════════════════════════════════════════════════════════════════════════
EOF
    then
        # Set secure permissions - FIXED: Verify file exists first
        if [[ -f "$CONFIG_FILE" ]]; then
            chmod 600 "$CONFIG_FILE"
            success "Configuration file created: $CONFIG_FILE"
            success "Permissions set to 600 (owner read/write only)"
        else
            error "Failed to create configuration file"
        fi
    else
        error "Failed to write configuration file"
    fi
}

# ─── GENERATE API KEYS FILE ──────────────────────────────────────────────────
generate_api_keys() {
    header "🔑 API KEYS SETUP (OPTIONAL)"
    
    info "API keys enhance reconnaissance capabilities"
    info "You can skip this and add keys later in ~/api_keys.sh"
    echo
    
    if ! ask_yes_no "Configure API keys now?"; then
        info "Creating template file without keys..."
        
        if cat > "$API_KEYS_FILE" << 'EOF'
#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# RECON FRAMEWORK - API KEYS FILE
# ⚠️  KEEP THIS FILE SECURE! chmod 600 api_keys.sh
# ════════════════════════════════════════════════════════════════════════════

# ─── SUBDOMAIN & DNS ENUMERATION ────────────────────────────────────────────
export SHODAN_API_KEY=""                    # https://www.shodan.io/
export SECURITYTRAILS_API_KEY=""            # https://securitytrails.com/
export CENSYS_API_ID=""                     # https://search.censys.io/
export CENSYS_API_SECRET=""                 # https://search.censys.io/
export BINARYEDGE_API_KEY=""                # https://www.binaryedge.io/

# ─── VULNERABILITY & THREAT INTELLIGENCE ────────────────────────────────────
export VIRUSTOTAL_API_KEY=""                # https://www.virustotal.com/

# ─── CODE & SECRET DISCOVERY ────────────────────────────────────────────────
export GITHUB_TOKEN=""                      # https://github.com/settings/tokens

# ─── NOTIFICATION WEBHOOKS ──────────────────────────────────────────────────
export SLACK_WEBHOOK=""                     # Slack incoming webhook
export DISCORD_WEBHOOK=""                   # Discord webhook URL
export TELEGRAM_BOT_TOKEN=""                # Telegram bot token from @BotFather
export TELEGRAM_CHAT_ID=""                  # Telegram chat/group ID

# ════════════════════════════════════════════════════════════════════════════
# INSTRUCTIONS:
# 1. Fill in your API keys above
# 2. Run: chmod 600 ~/api_keys.sh
# 3. Use with: sudo ./recon.sh target.com --api-keys ~/api_keys.sh
# ════════════════════════════════════════════════════════════════════════════
EOF
        then
            if [[ -f "$API_KEYS_FILE" ]]; then
                chmod 600 "$API_KEYS_FILE"
                success "API keys template created: $API_KEYS_FILE"
                info "Edit this file to add your API keys later"
            fi
        fi
        return 0
    fi
    
    echo
    info "Get your API keys from the following services:"
    echo "  • Shodan:         https://www.shodan.io/"
    echo "  • VirusTotal:     https://www.virustotal.com/"
    echo "  • SecurityTrails: https://securitytrails.com/"
    echo "  • Censys:         https://search.censys.io/"
    echo "  • GitHub:         https://github.com/settings/tokens"
    echo
    warn "API keys are sensitive - never share or commit them!"
    echo
    
    # Collect API keys - FIXED: Store in global variables
    SHODAN_KEY=$(ask_secret "Shodan API Key (leave empty to skip)")
    VT_KEY=$(ask_secret "VirusTotal API Key (leave empty to skip)")
    ST_KEY=$(ask_secret "SecurityTrails API Key (leave empty to skip)")
    CENSYS_ID=$(ask_secret "Censys API ID (leave empty to skip)")
    CENSYS_SECRET=$(ask_secret "Censys API Secret (leave empty to skip)")
    GITHUB_TOKEN_VAL=$(ask_secret "GitHub Token (leave empty to skip)")
    
    # FIXED: Also collect notification webhooks here for API keys file
    echo
    info "Notification webhooks (leave empty to skip):"
    SLACK_WEBHOOK=$(ask_input "Slack webhook URL")
    DISCORD_WEBHOOK=$(ask_input "Discord webhook URL")
    TELEGRAM_BOT_TOKEN=$(ask_secret "Telegram Bot Token")
    TELEGRAM_CHAT_ID=$(ask_input "Telegram Chat ID")
    
    # Write API keys file - FIXED: Use collected values
    if cat > "$API_KEYS_FILE" << EOF
#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# RECON FRAMEWORK - API KEYS FILE
# Generated: $(date)
# ⚠️  KEEP THIS FILE SECURE! chmod 600 api_keys.sh
# ════════════════════════════════════════════════════════════════════════════

# ─── SUBDOMAIN & DNS ENUMERATION ────────────────────────────────────────────
export SHODAN_API_KEY="$SHODAN_KEY"
export SECURITYTRAILS_API_KEY="$ST_KEY"
export CENSYS_API_ID="$CENSYS_ID"
export CENSYS_API_SECRET="$CENSYS_SECRET"
export BINARYEDGE_API_KEY=""

# ─── VULNERABILITY & THREAT INTELLIGENCE ────────────────────────────────────
export VIRUSTOTAL_API_KEY="$VT_KEY"

# ─── CODE & SECRET DISCOVERY ────────────────────────────────────────────────
export GITHUB_TOKEN="$GITHUB_TOKEN_VAL"

# ─── NOTIFICATION WEBHOOKS ──────────────────────────────────────────────────
export SLACK_WEBHOOK="$SLACK_WEBHOOK"
export DISCORD_WEBHOOK="$DISCORD_WEBHOOK"
export TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
export TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"

# ════════════════════════════════════════════════════════════════════════════
EOF
    then
        if [[ -f "$API_KEYS_FILE" ]]; then
            chmod 600 "$API_KEYS_FILE"
            success "API keys file created: $API_KEYS_FILE"
            success "Permissions set to 600 (owner read/write only)"
        fi
    else
        warn "Failed to create API keys file"
    fi
}

# ─── INSTALL TOOLS ───────────────────────────────────────────────────────────
install_tools() {
    header "🔧 TOOL INSTALLATION"
    
    if ! ask_yes_no "Install required security tools now?"; then
        info "You can install tools manually or run the recon script (it will auto-install)"
        return 0
    fi
    
    echo
    info "This will install the following tools:"
    echo "  • Go-based: subfinder, httpx, nuclei, naabu, dnsx, ffuf, katana..."
    echo "  • Python: wafw00f, sqlmap, whatweb"
    echo "  • APT: amass, nmap, jq, git, bc"
    echo
    warn "This may take 10-15 minutes depending on your connection"
    echo
    
    if ask_yes_no "Continue with installation?"; then
        # Update package list
        info "Updating package list..."
        apt-get update -qq
        
        # Install APT tools - FIXED: Added bc
        info "Installing APT packages..."
        apt-get install -y -qq git curl jq wget python3 python3-pip amass nmap bc 2>/dev/null || \
            warn "Some APT packages failed to install"
        
        # Install Python tools - FIXED: Added fallback for modern Python
        info "Installing Python tools..."
        pip3 install --break-system-packages -q wafw00f sqlmap whatweb 2>/dev/null || \
            pip3 install -q wafw00f sqlmap whatweb 2>/dev/null || \
            warn "Some Python packages failed to install"
        
        # Install Go tools
        if command -v go &>/dev/null; then
            info "Installing Go tools..."
            export PATH="$PATH:$(go env GOPATH)/bin"
            
            go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest 2>/dev/null &
            go install github.com/projectdiscovery/httpx/cmd/httpx@latest 2>/dev/null &
            go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest 2>/dev/null &
            go install github.com/projectdiscovery/naabu/v2/cmd/naabu@latest 2>/dev/null &
            go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest 2>/dev/null &
            go install github.com/ffuf/ffuf/v2@latest 2>/dev/null &
            go install github.com/projectdiscovery/katana/cmd/katana@latest 2>/dev/null &
            go install github.com/tomnomnom/waybackurls@latest 2>/dev/null &
            go install github.com/lc/gau/v2/cmd/gau@latest 2>/dev/null &
            
            wait
            
            success "Go tools installed"
        else
            warn "Go not installed - skipping Go tools"
        fi
        
        # Install SecLists - FIXED: Removed extra spaces in URL
        if [[ ! -d /usr/share/seclists ]]; then
            info "Installing SecLists wordlists..."
            git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null || \
                warn "SecLists installation failed"
        fi
        
        success "Tool installation complete!"
    else
        info "Skipping tool installation"
    fi
}

# ─── CREATE SAMPLE TARGETS FILE ──────────────────────────────────────────────
create_sample_targets() {
    header "📁 CREATING SAMPLE TARGETS FILE"
    
    local sample_file="${SCRIPT_DIR}/targets.txt.example"
    
    if cat > "$sample_file" << 'EOF'
# ════════════════════════════════════════════════════════════════════════════
# RECON FRAMEWORK - SAMPLE TARGETS FILE
# Format: One domain per line
# Comments start with #
# ════════════════════════════════════════════════════════════════════════════

# Replace these with your actual targets
example.com
api.example.com
www.example.com

# Staging/Development (if authorized)
# staging.example.com
# dev.example.com
# test.example.com

# Different TLDs (if owned by same organization)
# example.org
# example.net

# ════════════════════════════════════════════════════════════════════════════
# USAGE:
#   sudo ./recon.sh -f targets.txt.example
#   sudo ./recon.sh -f targets.txt.example --waf-bypass --html-report
# ════════════════════════════════════════════════════════════════════════════
EOF
    then
        success "Sample targets file created: $sample_file"
        info "Edit this file with your actual targets"
    else
        warn "Failed to create sample targets file"
    fi
}

# ─── FINAL SUMMARY ───────────────────────────────────────────────────────────
show_summary() {
    header "🎉 SETUP COMPLETE!"
    
    echo -e "${BOLD}Configuration Summary:${RESET}"
    echo "  ${GREEN}✓${RESET} Config file:      ${CONFIG_FILE}"
    echo "  ${GREEN}✓${RESET} API keys file:    ${API_KEYS_FILE}"
    echo "  ${GREEN}✓${RESET} Sample targets:   ${SCRIPT_DIR}/targets.txt.example"
    echo "  ${GREEN}✓${RESET} Main script:      ${SCRIPT_DIR}/recon.sh"
    echo
    
    echo -e "${BOLD}Quick Start Commands:${RESET}"
    echo "  ${CYAN}# Single target scan${RESET}"
    echo "  sudo ./recon.sh example.com"
    echo
    echo "  ${CYAN}# Multiple targets${RESET}"
    echo "  sudo ./recon.sh -f targets.txt.example"
    echo
    echo "  ${CYAN}# With WAF bypass & HTML report${RESET}"
    echo "  sudo ./recon.sh example.com --waf-bypass --html-report"
    echo
    echo "  ${CYAN}# Using API keys${RESET}"
    echo "  sudo ./recon.sh example.com --api-keys ~/api_keys.sh"
    echo
    echo "  ${CYAN}# Batch with notifications${RESET}"
    echo "  sudo ./recon.sh -f targets.txt --parallel 3 --notify discord"
    echo
    
    echo -e "${BOLD}Important Notes:${RESET}"
    echo "  ${YELLOW}!${RESET} Always run with sudo: sudo ./recon.sh ..."
    echo "  ${YELLOW}!${RESET} Only scan targets you own or have permission to test"
    echo "  ${YELLOW}!${RESET} Keep api_keys.sh secure (chmod 600)"
    echo "  ${YELLOW}!${RESET} Check logs: <target>_recon.log"
    echo
    
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
    echo -e "${GREEN}  Happy Reconnaissance! 🚀${RESET}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${RESET}\n"
}

# ─── MAIN EXECUTION ──────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🔧 RECON FRAMEWORK - SETUP WIZARD                         ║
║   Automatically configure your reconnaissance environment   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${RESET}\n"
    
    # Check if running as root (not required for setup)
    if [[ $EUID -eq 0 ]]; then
        warn "Setup script should NOT be run as root"
        warn "Run as regular user: ./setup_config.sh"
        echo
        if ! ask_yes_no "Continue anyway?"; then
            exit 1
        fi
    fi
    
    check_prerequisites
    generate_config
    generate_api_keys
    install_tools
    create_sample_targets
    show_summary
    
    # Open config file in editor if available - FIXED: Check if interactive
    echo
    if [[ -t 0 ]] && ask_yes_no "Open configuration file for review?"; then
        if command -v nano &>/dev/null; then
            nano "$CONFIG_FILE"
        elif command -v vim &>/dev/null; then
            vim "$CONFIG_FILE"
        elif command -v vi &>/dev/null; then
            vi "$CONFIG_FILE"
        else
            info "No editor found. Manual edit: $CONFIG_FILE"
        fi
    fi
}

# ─── ENTRY POINT ────────────────────────────────────────────────────────────
main "$@"
