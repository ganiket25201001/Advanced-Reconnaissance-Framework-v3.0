# 🔥 Advanced Reconnaissance Framework v3.0

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Bash-5.0+-green.svg" alt="Bash">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Status-Active-success.svg" alt="Status">
</p>

<p align="center">
  <strong>A comprehensive, enterprise-grade reconnaissance and vulnerability scanning framework with WAF bypass capabilities and multi-target support.</strong>
</p>

<p align="center">
  🔐 <strong>Requires Sudo Privileges</strong> | 📁 <strong>Multi-Target Support</strong> | 🛡️ <strong>WAF Bypass</strong>
</p>

---

## 📋 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Configuration](#-configuration)
- [Output Structure](#-output-structure)
- [API Keys Setup](#-api-keys-setup)
- [WAF Bypass Techniques](#-waf-bypass-techniques)
- [Batch Processing](#-batch-processing)
- [Notifications](#-notifications)
- [Troubleshooting](#-troubleshooting)
- [Legal Disclaimer](#-legal-disclaimer)
- [Contributing](#-contributing)

---

## ✨ Features

### 🎯 Core Capabilities

| Feature | Description |
|---------|-------------|
| **Subdomain Enumeration** | Multi-source subdomain discovery (Subfinder, Amass, Assetfinder, AlterX, CRT.sh, APIs) |
| **Port Scanning** | Fast port scanning with Naabu + optional Nmap deep scans |
| **Live Host Detection** | HTTP/HTTPS probing with technology detection |
| **URL Discovery** | Crawling with Katana, Gospider, Hakrawler + Archive sources |
| **JS Analysis** | JavaScript file extraction and secret scanning |
| **Parameter Discovery** | URL parameter extraction and FFUF-based discovery |
| **Directory Fuzzing** | Path enumeration with FFUF |
| **VHost Discovery** | Virtual host fuzzing |
| **Vulnerability Scanning** | Nuclei templates + Dalfox XSS + Subzy takeover |
| **WAF Detection & Bypass** | WAF identification with bypass payload generation |
| **Cloud Enumeration** | S3, Azure Blob, GCS bucket discovery |
| **GitHub Dorking** | Secret leak detection in GitHub repositories |
| **Screenshot Capture** | Automated webpage screenshots with Gowitness |
| **Multi-Target Support** | Process multiple targets from file |
| **Parallel Processing** | Concurrent target scanning |
| **Multiple Report Formats** | Text, JSON, and HTML reports |

### 🚀 Advanced Features

- ✅ **Stealth Mode** - Reduced threads and rate limits for low-profile scanning
- ✅ **Aggressive Mode** - Maximum intensity scanning (may trigger IDS/WAF)
- ✅ **Resume Capability** - Resume interrupted scans
- ✅ **Skip Completed** - Skip already processed targets in batch mode
- ✅ **Tor Support** - Route traffic through Tor network
- ✅ **Proxy Support** - HTTP/HTTPS proxy configuration
- ✅ **Notifications** - Slack, Discord, Telegram integration
- ✅ **API Integration** - Shodan, VirusTotal, SecurityTrails, GitHub, and more

---

## 📦 Requirements

### System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **OS** | Linux (Ubuntu/Debian/Kali) | Kali Linux 2024+ |
| **RAM** | 4 GB | 8 GB+ |
| **Storage** | 10 GB free | 50 GB+ SSD |
| **Network** | Stable internet | High-bandwidth connection |
| **Privileges** | Sudo/Root | Root access |

### Dependencies

```bash
# Required
- Bash 5.0+
- Go 1.20+
- Python 3.8+
- Git
- Curl
- JQ
```

### Tools (Auto-Installed)

The script automatically installs these tools if missing:

| Category | Tools |
|----------|-------|
| **Go Tools** | subfinder, assetfinder, httpx, katana, nuclei, dnsx, naabu, ffuf, waybackurls, gau, alterx, dalfox, hakrawler, gospider, subzy, gowitness, cdncheck, tlsx |
| **Python Tools** | wafw00f, sqlmap, whatweb |
| **APT Tools** | amass, nmap, curl, jq, git |

---

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0.git
cd Advanced-Reconnaissance-Framework-v3.0
```

### 2. Make Executable

```bash
chmod +x recon.sh
```

### 3. Install System Dependencies

```bash
# Update package list
sudo apt-get update

# Install core dependencies
sudo apt-get install -y git curl jq wget python3 python3-pip
```

### 4. Install Go (if not installed)

```bash
# Download and install Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
source ~/.bashrc
```

### 5. Verify Installation

```bash
# Check Go installation
go version

# Run script help
sudo ./recon.sh --help
```

---

## ⚡ Quick Start

### Single Target Scan

```bash
# Basic scan
sudo ./recon.sh example.com

# With WAF bypass and HTML report
sudo ./recon.sh example.com --waf-bypass --html-report

# Full aggressive scan
sudo ./recon.sh example.com --aggressive --html-report --json-report
```

### Multiple Targets Scan

```bash
# Create targets file
cat > targets.txt << EOF
example.com
api.example.com
test.example.org
EOF

# Run batch scan
sudo ./recon.sh -f targets.txt

# Parallel batch processing
sudo ./recon.sh -f targets.txt --parallel 3 --waf-bypass
```

---

## 📖 Usage

### Basic Syntax

```bash
sudo ./recon.sh <target.com> [options]
sudo ./recon.sh -f targets.txt [options]
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --targets FILE` | File containing multiple targets (one per line) | - |
| `--threads N` | Number of concurrent threads | 200 |
| `--scope FILE` | Scope file with allowed domains | - |
| `--output DIR` | Output directory | recon_<target>_<timestamp> |
| `--config FILE` | Configuration file | ~/.recon_config |
| `--proxy URL` | HTTP/HTTPS proxy URL | - |
| `--tor` | Route traffic through Tor | false |
| `--rate-limit N` | Requests per second | 50 |
| `--depth N` | Crawl depth | 5 |
| `--timeout N` | Request timeout (seconds) | 10 |
| `--api-keys FILE` | File containing API keys | - |
| `--waf-bypass` | Enable WAF detection and bypass | false |
| `--aggressive` | Aggressive scanning mode | false |
| `--stealth` | Stealth mode (slower, less detectable) | false |
| `--resume ID` | Resume previous scan by ID | - |
| `--notify CHANNEL` | Notification channel (slack/discord/telegram) | - |
| `--html-report` | Generate HTML report | false |
| `--json-report` | Generate JSON report | false |
| `--skip-install` | Skip tool installation check | false |
| `--debug` | Enable debug logging | false |
| `--quiet` | Minimal output | false |
| `--parallel N` | Process N targets in parallel | 1 |
| `--skip-done` | Skip completed targets in batch | false |
| `--help, -h` | Show help message | - |
| `--version, -v` | Show version | - |

### Examples

```bash
# Standard reconnaissance
sudo ./recon.sh target.com

# Stealth mode with reduced footprint
sudo ./recon.sh target.com --stealth --threads 50 --rate-limit 10

# Aggressive full scan
sudo ./recon.sh target.com --aggressive --threads 500 --rate-limit 100

# With WAF bypass techniques
sudo ./recon.sh target.com --waf-bypass --html-report

# Using API keys for enhanced enumeration
sudo ./recon.sh target.com --api-keys ~/api_keys.json --json-report

# Batch processing with notifications
sudo ./recon.sh -f targets.txt --parallel 3 --notify discord --html-report

# Resume interrupted scan
sudo ./recon.sh target.com --resume recon_target_20260320_120000

# Skip already completed targets in batch
sudo ./recon.sh -f targets.txt --skip-done

# Through proxy
sudo ./recon.sh target.com --proxy http://127.0.0.1:8080

# Through Tor
sudo ./recon.sh target.com --tor --stealth
```

---

## ⚙️ Configuration

### Configuration File (~/.recon_config)

```bash
# Create configuration file
cat > ~/.recon_config << EOF
# Thread Configuration
THREADS=200
RATE_LIMIT=50
CRAWL_DEPTH=5
TIMEOUT=10

# Mode Settings
STEALTH_MODE=false
AGGRESSIVE_MODE=false
WAF_BYPASS=false

# Report Settings
HTML_REPORT=true
JSON_REPORT=true

# Notification Settings
NOTIFY_CHANNEL=discord
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
SLACK_WEBHOOK=https://hooks.slack.com/...
TELEGRAM_BOT_TOKEN=your_bot_token
TELEGRAM_CHAT_ID=your_chat_id

# API Keys
SHODAN_API_KEY=your_shodan_key
VIRUSTOTAL_API_KEY=your_vt_key
SECURITYTRAILS_API_KEY=your_st_key
GITHUB_TOKEN=your_github_token
EOF
```

### API Keys File (api_keys.json)

```bash
cat > ~/api_keys.json << EOF
export SHODAN_API_KEY="your_shodan_api_key"
export CENSYS_API_ID="your_censys_id"
export CENSYS_API_SECRET="your_censys_secret"
export VIRUSTOTAL_API_KEY="your_virustotal_key"
export SECURITYTRAILS_API_KEY="your_securitytrails_key"
export BINARYEDGE_API_KEY="your_binaryedge_key"
export GITHUB_TOKEN="your_github_token"
export SLACK_WEBHOOK="your_slack_webhook"
export DISCORD_WEBHOOK="your_discord_webhook"
export TELEGRAM_BOT_TOKEN="your_telegram_bot_token"
export TELEGRAM_CHAT_ID="your_telegram_chat_id"
EOF

# Secure the file
chmod 600 ~/api_keys.json
```

---

## 📁 Output Structure

```
recon_target.com_20260320_120000/
├── subs/
│   ├── all_subs.txt              # All validated subdomains
│   ├── subfinder.txt             # Subfinder results
│   ├── assetfinder.txt           # Assetfinder results
│   ├── amass.txt                 # Amass results
│   ├── crtsh.txt                 # Certificate transparency
│   └── ports.txt                 # Port scan results
├── urls/
│   ├── alive.txt                 # Live hosts with metadata
│   ├── alive_urls.txt            # Live URLs only
│   ├── all_urls.txt              # All discovered URLs
│   └── tech_detect.txt           # Technology detection
├── fuzz/
│   ├── params_raw.txt            # Parameterized URLs
│   ├── param_names.txt           # Unique parameter names
│   ├── dirs_*.json               # Directory fuzzing results
│   ├── vhosts.json               # Virtual host results
│   └── waf_bypass/               # WAF bypass payloads
├── js/
│   ├── js_files.txt              # JavaScript files
│   ├── sensitive_files.txt       # Sensitive file leaks
│   ├── js_secrets.txt            # Secrets in JS
│   └── downloads/                # Downloaded JS files
├── vulns/
│   ├── nuclei.txt                # All Nuclei findings
│   ├── nuclei_critical.txt       # Critical severity
│   ├── nuclei_high.txt           # High severity
│   ├── nuclei_medium.txt         # Medium severity
│   ├── xss.txt                   # XSS findings
│   ├── takeover.txt              # Subdomain takeover
│   └── waf_detection.txt         # WAF detection results
├── cloud/
│   ├── s3_buckets.txt            # S3 bucket findings
│   ├── azure_blobs.txt           # Azure blob findings
│   └── gcs_buckets.txt           # GCS bucket findings
├── github/
│   ├── code_mentions.txt         # GitHub code mentions
│   └── potential_leaks.txt       # Potential secret leaks
├── screenshots/                  # Website screenshots
├── reports/
│   ├── summary_*.txt             # Text report
│   ├── summary_*.json            # JSON report
│   └── summary_*.html            # HTML report
└── ../target.com_recon.log       # Full execution log
```

### Master Report (Batch Mode)

```
recon_batch_20260320_120000/
├── recon_example.com_*/
├── recon_api.example.com_*/
├── recon_test.example.org_*/
└── MASTER_REPORT_*.txt           # Consolidated batch report
```

---

## 🔑 API Keys Setup

### Getting API Keys

| Service | Purpose | Get Key |
|---------|---------|---------|
| **Shodan** | Infrastructure discovery | [shodan.io](https://www.shodan.io/) |
| **VirusTotal** | Domain/subdomain intel | [virustotal.com](https://www.virustotal.com/) |
| **SecurityTrails** | DNS history & subdomains | [securitytrails.com](https://securitytrails.com/) |
| **Censys** | Certificate & host data | [censys.io](https://search.censys.io/) |
| **BinaryEdge** | Internet scanning data | [binaryedge.io](https://www.binaryedge.io/) |
| **GitHub** | Code/secret discovery | [github.com](https://github.com/settings/tokens) |

### Best Practices

```bash
# Store keys securely
chmod 600 ~/api_keys.json

# Never commit keys to git
echo "api_keys.json" >> .gitignore

# Use environment variables for CI/CD
export SHODAN_API_KEY="${SHODAN_API_KEY}"
```

---

## 🛡️ WAF Bypass Techniques

### Detection

The script automatically detects WAFs using:
- **wafw00f** - Dedicated WAF detection tool
- **httpx** - Header analysis
- **cdncheck** - CDN presence detection

### Bypass Payloads Generated

| Type | Location | Description |
|------|----------|-------------|
| **Headers** | `fuzz/waf_bypass/bypass_headers.txt` | X-Forwarded-For, X-Original-URL, etc. |
| **Encoding** | `fuzz/waf_bypass/encoding_bypass.txt` | URL encoding, double encoding |
| **SQLi** | `fuzz/waf_bypass/sqli_bypass.txt` | SQL injection bypass payloads |
| **XSS** | `fuzz/waf_bypass/xss_bypass.txt` | XSS filter bypass payloads |
| **LFI** | `fuzz/waf_bypass/lfi_bypass.txt` | Path traversal bypass payloads |

### Usage

```bash
# Enable WAF bypass
sudo ./recon.sh target.com --waf-bypass

# Aggressive with WAF bypass
sudo ./recon.sh target.com --waf-bypass --aggressive
```

---

## 📊 Batch Processing

### Targets File Format

```bash
# targets.txt
# Comments start with #

# Production domains
example.com
api.example.com
www.example.com

# Staging environments
staging.example.com
dev.example.com

# Different TLDs
example.org
example.net
```

### Batch Commands

```bash
# Basic batch scan
sudo ./recon.sh -f targets.txt

# Parallel processing (3 targets at once)
sudo ./recon.sh -f targets.txt --parallel 3

# Skip already completed targets
sudo ./recon.sh -f targets.txt --skip-done

# Full batch with all features
sudo ./recon.sh -f targets.txt \
    --parallel 3 \
    --waf-bypass \
    --html-report \
    --json-report \
    --notify discord \
    --api-keys ~/api_keys.json
```

### Batch Output

```
recon_batch_20260320_120000/
├── recon_example.com_20260320_120100/
├── recon_api.example.com_20260320_120500/
├── recon_staging.example.com_20260320_121000/
└── MASTER_REPORT_20260320_121500.txt
```

---

## 🔔 Notifications

### Supported Channels

| Channel | Setup |
|---------|-------|
| **Slack** | Create incoming webhook in Slack app settings |
| **Discord** | Create webhook in Discord channel settings |
| **Telegram** | Create bot via @BotFather, get chat ID |

### Configuration

```bash
# In ~/.recon_config or api_keys.json
export SLACK_WEBHOOK="https://hooks.slack.com/services/..."
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
export TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234..."
export TELEGRAM_CHAT_ID="-1001234567890"
```

### Usage

```bash
# Slack notification
sudo ./recon.sh target.com --notify slack

# Discord notification
sudo ./recon.sh target.com --notify discord

# Telegram notification
sudo ./recon.sh target.com --notify telegram

# Batch with notification
sudo ./recon.sh -f targets.txt --notify discord
```

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Permission denied** | Run with `sudo` |
| **Go not found** | Install Go from [go.dev](https://go.dev/dl/) |
| **Tools not installing** | Check internet connection, run `sudo apt-get update` |
| **API rate limits** | Reduce `--threads` and `--rate-limit` |
| **Scan too slow** | Increase `--threads`, use `--aggressive` |
| **Too many false positives** | Use `--stealth` mode |
| **Memory issues** | Reduce `--threads` to 100 or less |
| **WAF blocking** | Enable `--waf-bypass`, use `--tor` |

### Debug Mode

```bash
# Enable debug logging
sudo ./recon.sh target.com --debug

# Check logs
cat target.com_recon.log

# Minimal output
sudo ./recon.sh target.com --quiet
```

### Tool Verification

```bash
# Check installed tools
which subfinder httpx nuclei ffuf dnsx naabu

# Reinstall tools
sudo ./recon.sh target.com --skip-install
```

### Performance Tuning

```bash
# Low-resource system
sudo ./recon.sh target.com --stealth --threads 50 --rate-limit 10

# High-performance system
sudo ./recon.sh target.com --aggressive --threads 500 --rate-limit 150

# Balanced (default)
sudo ./recon.sh target.com --threads 200 --rate-limit 50
```

---

## ⚠️ Legal Disclaimer

> **IMPORTANT: This tool is for authorized security testing only.**

- ✅ **Authorized Use Only** - Only scan targets you own or have written permission to test
- ✅ **Compliance** - Ensure compliance with applicable laws and regulations
- ✅ **Bug Bounty** - Follow program rules when testing bug bounty targets
- ✅ **No Warranty** - This tool is provided "as is" without warranty
- ✅ **Responsibility** - Users are responsible for their actions

**Unauthorized scanning of systems you do not own or have permission to test is illegal and may result in criminal prosecution.**

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Code Standards

- Follow existing code style
- Add comments for complex logic
- Test thoroughly before submitting
- Update documentation for new features

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

Thanks to the amazing security community and tool developers:

- [ProjectDiscovery](https://github.com/projectdiscovery) - subfinder, httpx, nuclei, naabu, dnsx, katana
- [TomNomNom](https://github.com/tomnomnom) - assetfinder, waybackurls
- [ffuf](https://github.com/ffuf/ffuf) - Fast web fuzzer
- [OWASP Amass](https://github.com/owasp-amass/amass) - Subdomain enumeration
- [SecLists](https://github.com/danielmiessler/SecLists) - Wordlists
- [All other open-source security tool developers](https://github.com/topics/security-tools)

---

## 📞 Support

| Channel | Link |
|---------|------|
| **Issues** | [GitHub Issues](https://github.com/yourusername/recon-framework/issues) |
| **Discussions** | [GitHub Discussions](https://github.com/yourusername/recon-framework/discussions) |
| **Documentation** | [Wiki](https://github.com/yourusername/recon-framework/wiki) |

---

<p align="center">
  <strong>Made with ❤️ by the Security Community</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Last_Updated-March_2026-green.svg" alt="Updated">
</p>
