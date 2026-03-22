# 🚀 ARF - Advanced Reconnaissance Framework v3.0

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Bash-4.0+-green.svg" alt="Bash">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Status-Active-success.svg" alt="Status">
</p>

<p align="center">
  <strong>Enterprise-grade reconnaissance and vulnerability scanning framework with WAF bypass, multi-target support, and automated setup.</strong>
</p>

<p align="center">
  🔐 <strong>Requires Sudo</strong> | 📁 <strong>Multi-Target</strong> | 🛡️ <strong>WAF Bypass</strong> | ⚡ <strong>One-Command Setup</strong>
</p>

---

## 📋 Table of Contents

- [🚀 Quick Start](#-quick-start)
- [✨ Features](#-features)
- [📦 Requirements](#-requirements)
- [🛠️ Installation](#-installation)
- [⚙️ Configuration](#️-configuration)
- [📖 Usage](#-usage)
- [📁 Output Structure](#-output-structure)
- [🔑 API Keys Setup](#-api-keys-setup)
- [🛡️ WAF Bypass](#️-waf-bypass)
- [📊 Batch Processing](#-batch-processing)
- [🔔 Notifications](#-notifications)
- [🐛 Troubleshooting](#-troubleshooting)
- [⚠️ Legal Disclaimer](#-legal-disclaimer)
- [🤝 Contributing](#-contributing)

---

## 🚀 Quick Start

### One-Command Installation & Setup

```bash
# Clone the repository
git clone https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0.git
cd Advanced-Reconnaissance-Framework-v3.0

# Run setup (requires sudo)
sudo ./setup.sh

# Run configuration wizard (as regular user)
./setup.sh --config

# Start scanning!
sudo arf example.com
```

### Verify Installation

```bash
# Check arf help
arf --help

# Check version
arf --version
```

---

## ✨ Features

### 🎯 Core Capabilities

| Feature | Description |
|---------|-------------|
| **Subdomain Enumeration** | Multi-source discovery (Subfinder, Amass, Assetfinder, AlterX, CRT.sh, APIs) |
| **Port Scanning** | Fast scanning with Naabu + optional Nmap deep scans |
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

| Feature | Description |
|---------|-------------|
| **🔐 Stealth Mode** | Reduced threads and rate limits for low-profile scanning |
| **💥 Aggressive Mode** | Maximum intensity scanning (may trigger IDS/WAF) |
| **🔄 Resume Capability** | Resume interrupted scans |
| **⏭️ Skip Completed** | Skip already processed targets in batch mode |
| **🧅 Tor Support** | Route traffic through Tor network |
| **🌐 Proxy Support** | HTTP/HTTPS proxy configuration |
| **📬 Notifications** | Slack, Discord, Telegram integration |
| **🔌 API Integration** | Shodan, VirusTotal, SecurityTrails, GitHub, and more |
| **⚙️ Auto Configuration** | Interactive setup wizard for easy configuration |
| **📦 One-Command Install** | Full installation with single command |

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
- Bash 4.0+
- Go 1.20+
- Python 3.8+
- Git
- Curl
- JQ
- bc (for calculations)
```

### Tools (Auto-Installed)

The script automatically installs these tools if missing:

| Category | Tools |
|----------|-------|
| **Go Tools** | subfinder, assetfinder, httpx, katana, nuclei, dnsx, naabu, ffuf, waybackurls, gau, alterx, dalfox, hakrawler, gospider, subzy, gowitness, cdncheck, tlsx |
| **Python Tools** | wafw00f, sqlmap, whatweb |
| **APT Tools** | amass, nmap, curl, jq, git, bc |

---

## 🛠️ Installation

### One-Command Setup (Recommended)

```bash
# Clone repository
git clone https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0.git
cd Advanced-Reconnaissance-Framework-v3.0

# Step 1: Install dependencies and tools (requires sudo)
sudo ./setup.sh

# Step 2: Configure ARF (as regular user)
./setup.sh --config

# Step 3: Start scanning!
sudo arf example.com
```

### Manual Installation (if setup.sh fails)

```bash
# 1. Install system dependencies
sudo apt-get update
sudo apt-get install -y git curl jq wget python3 python3-pip bc

# 2. Install Go
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -n1)
wget "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz"
sudo tar -C /usr/local -xzf "${GO_VERSION}.linux-amd64.tar.gz"
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# 3. Run configuration wizard
./setup.sh --config
```

### Verify Installation

```bash
# Check Go installation
go version

# Check arf help
arf --help

# Verify setup
ls -la ~/.recon_config ~/api_keys.sh
```

---

## ⚙️ Configuration

### Interactive Setup Wizard

After installation, run the configuration wizard:

```bash
# Run setup wizard (as regular user, NOT root)
./setup.sh --config
```

**The wizard will guide you through:**

1. ✅ Thread & performance settings
2. ✅ Scanning mode preferences (stealth/aggressive)
3. ✅ Report format preferences (HTML/JSON)
4. ✅ Notification channel setup (Discord/Slack/Telegram)
5. ✅ API keys configuration (optional)
6. ✅ Tool installation (optional)

### Configuration Files

| File | Purpose | Permissions |
|------|---------|-------------|
| `~/.recon_config` | Main configuration | 600 (owner only) |
| `~/api_keys.sh` | API keys & webhooks | 600 (owner only) |
| `targets.txt.example` | Sample targets file | 644 (readable) |

### Manual Configuration

```bash
# Edit configuration file
nano ~/.recon_config

# Edit API keys file
nano ~/api_keys.sh

# Set secure permissions
chmod 600 ~/.recon_config ~/api_keys.sh
```

### Quick Test

```bash
# Test arf help (works without sudo)
arf --help
arf -h

# Check version
arf --version
```

### Configuration Options

```bash
# ~/.recon_config

# Thread & Performance
THREADS=200
RATE_LIMIT=50
CRAWL_DEPTH=5
TIMEOUT=10

# Scanning Mode
STEALTH_MODE=false
AGGRESSIVE_MODE=false
WAF_BYPASS=false

# Reports
HTML_REPORT=true
JSON_REPORT=true

# Notifications
NOTIFY_CHANNEL="discord"
DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."

# API Keys
SHODAN_API_KEY="your_key"
VIRUSTOTAL_API_KEY="your_key"
GITHUB_TOKEN="your_token"
```

---

## 📖 Usage

### Basic Syntax

```bash
# Single target
sudo arf <target.com> [options]

# Multiple targets from file
sudo arf -f targets.txt [options]

# Or use recon.sh directly
sudo ./recon.sh <target.com> [options]
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `-f, --targets FILE` | File containing multiple targets | - |
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
| `--notify CHANNEL` | Notification channel | - |
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

#### Single Target Scans

```bash
# Basic scan
sudo arf example.com

# With WAF bypass and HTML report
sudo arf example.com --waf-bypass --html-report

# Full aggressive scan
sudo arf example.com --aggressive --html-report --json-report

# Stealth mode
sudo arf example.com --stealth --threads 50 --rate-limit 10

# With API keys
sudo arf example.com --api-keys ~/api_keys.sh

# Through proxy
sudo arf example.com --proxy http://127.0.0.1:8080

# Through Tor
sudo arf example.com --tor --stealth
```

#### Multi-Target Scans

```bash
# Create targets file
cat > targets.txt << EOF
example.com
api.example.com
test.example.org
EOF

# Basic batch scan
sudo arf -f targets.txt

# Parallel processing (3 targets at once)
sudo arf -f targets.txt --parallel 3

# Skip already completed targets
sudo arf -f targets.txt --skip-done

# Full batch with all features
sudo arf -f targets.txt \
    --parallel 3 \
    --waf-bypass \
    --html-report \
    --json-report \
    --notify discord \
    --api-keys ~/api_keys.sh
```

#### Advanced Usage

```bash
# Resume interrupted scan
sudo arf example.com --resume recon_example.com_20260320_120000

# Custom output directory
sudo arf example.com --output /path/to/output

# With scope file (bug bounty)
sudo arf example.com --scope scope.txt

# Debug mode
sudo arf example.com --debug

# Quiet mode (minimal output)
sudo arf example.com --quiet
```

---

## 📁 Output Structure

### Single Target Output

```
recon_example.com_20260320_120000/
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
│   └── waf_bypass/               # WAF bypass payloads & results
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
└── ../example.com_recon.log      # Full execution log
```

### Batch Mode Output

```
recon_batch_20260320_120000/
├── recon_example.com_20260320_120100/
├── recon_api.example.com_20260320_120500/
├── recon_staging.example.com_20260320_121000/
└── MASTER_REPORT_20260320_121500.txt    # Consolidated batch report
```

---

## 🔑 API Keys Setup

### Getting API Keys

| Service | Purpose | Get Key | Free Tier |
|---------|---------|---------|-----------|
| **Shodan** | Infrastructure discovery | [shodan.io](https://www.shodan.io/) | ✅ Limited |
| **VirusTotal** | Domain/subdomain intel | [virustotal.com](https://www.virustotal.com/) | ✅ Yes |
| **SecurityTrails** | DNS history & subdomains | [securitytrails.com](https://securitytrails.com/) | ✅ Limited |
| **Censys** | Certificate & host data | [censys.io](https://search.censys.io/) | ✅ Limited |
| **BinaryEdge** | Internet scanning data | [binaryedge.io](https://www.binaryedge.io/) | ✅ Trial |
| **GitHub** | Code/secret discovery | [github.com](https://github.com/settings/tokens) | ✅ Yes |

### Configure API Keys

```bash
# Option 1: During setup wizard
./setup_config.sh

# Option 2: Manual edit
nano ~/api_keys.sh

# Option 3: Command line
sudo ./recon.sh example.com --api-keys ~/api_keys.sh
```

### API Keys File Format

```bash
# ~/api_keys.sh
#!/bin/bash

# Subdomain & DNS Enumeration
export SHODAN_API_KEY="your_shodan_key"
export SECURITYTRAILS_API_KEY="your_st_key"
export CENSYS_API_ID="your_censys_id"
export CENSYS_API_SECRET="your_censys_secret"
export BINARYEDGE_API_KEY="your_be_key"

# Vulnerability & Threat Intelligence
export VIRUSTOTAL_API_KEY="your_vt_key"

# Code & Secret Discovery
export GITHUB_TOKEN="your_github_token"

# Notification Webhooks
export SLACK_WEBHOOK="https://hooks.slack.com/..."
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"
```

### Security Best Practices

```bash
# Set secure permissions
chmod 600 ~/api_keys.sh ~/.recon_config

# Never commit to git
echo "api_keys.sh" >> .gitignore
echo ".recon_config" >> .gitignore

# Verify permissions
ls -la ~/api_keys.sh ~/.recon_config
# Should show: -rw------- (600)
```

---

## 🛡️ WAF Bypass

### Detection

The script automatically detects WAFs using:
- **wafw00f** - Dedicated WAF detection tool
- **httpx** - Header analysis
- **cdncheck** - CDN presence detection

### Bypass Techniques

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

# Batch with WAF bypass
sudo ./recon.sh -f targets.txt --waf-bypass --parallel 3
```

### Common WAF Bypass Headers

```
X-Forwarded-For: 127.0.0.1
X-Original-URL: /admin
X-Rewrite-URL: /admin
X-Custom-IP-Authorization: 127.0.0.1
X-Host: 127.0.0.1
X-Forwarded-Host: 127.0.0.1
True-Client-IP: 127.0.0.1
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

# Staging environments (if authorized)
# staging.example.com
# dev.example.com

# Different TLDs (if same organization)
# example.org
# example.net
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
    --api-keys ~/api_keys.sh
```

### Batch Progress Tracking

```
╔══════════════════════════════════════════════════════════════╗
║   🔥 ADVANCED RECONNAISSANCE FRAMEWORK v3.0                 ║
║   📁 BATCH MODE - Multiple Targets                           ║
║   📊 Total Targets: 10                                       ║
║   🔀 Parallel: 3                                             ║
╚══════════════════════════════════════════════════════════════╝

[1/10] Processing: example.com
[+] Completed: example.com
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Completed: 1 | Skipped: 0 | Failed: 0 | Remaining: 9
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[2/10] Processing: api.example.com
...
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
# In ~/.recon_config or ~/api_keys.sh
export SLACK_WEBHOOK="https://hooks.slack.com/services/..."
export DISCORD_WEBHOOK="https://discord.com/api/webhooks/..."
export TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234..."
export TELEGRAM_CHAT_ID="-1001234567890"
```

### Getting Webhooks

#### Discord
1. Go to Server Settings → Integrations → Webhooks
2. Click "New Webhook"
3. Copy the webhook URL

#### Slack
1. Go to slack.com/apps → Incoming Webhooks
2. Add to your workspace
3. Copy the webhook URL

#### Telegram
1. Message @BotFather to create a bot
2. Get the bot token
3. Add bot to your group/channel
4. Get chat ID via @getidsbot

### Usage

```bash
# Slack notification
sudo arf target.com --notify slack

# Discord notification
sudo arf target.com --notify discord

# Telegram notification
sudo arf target.com --notify telegram

# Batch with notification
sudo arf -f targets.txt --notify discord
```

### Sample Notification

```
🔍 Recon complete for example.com
📊 Subdomains: 150
🌐 Alive Hosts: 45
🐛 Vulnerabilities: 12
⚠️ Critical: 2
📅 2026-03-20 14:30:00
```

---

## 🐛 Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| **Permission denied** | Run with `sudo` |
| **Go not found** | Install Go from [go.dev](https://go.dev/dl/) |
| **Tools not installing** | Check internet, run `sudo apt-get update` |
| **API rate limits** | Reduce `--threads` and `--rate-limit` |
| **Scan too slow** | Increase `--threads`, use `--aggressive` |
| **Too many false positives** | Use `--stealth` mode |
| **Memory issues** | Reduce `--threads` to 100 or less |
| **WAF blocking** | Enable `--waf-bypass`, use `--tor` |
| **Setup wizard fails** | Run as regular user (not root) |
| **bc not found** | Install with `sudo apt-get install bc` |
| **arf command not found** | Run `sudo ./setup.sh` to install |

### Debug Mode

```bash
# Enable debug logging
sudo arf target.com --debug

# Check logs
cat target.com_recon.log

# Minimal output
sudo arf target.com --quiet
```

### Tool Verification

```bash
# Check installed tools
which subfinder httpx nuclei ffuf dnsx naabu

# Reinstall tools
sudo ./setup.sh

# Update nuclei templates
nuclei -update-templates
```

### Performance Tuning

```bash
# Low-resource system (4GB RAM)
sudo arf target.com --stealth --threads 50 --rate-limit 10

# Medium system (8GB RAM)
sudo arf target.com --threads 200 --rate-limit 50

# High-performance system (16GB+ RAM)
sudo arf target.com --aggressive --threads 500 --rate-limit 150
```

### Reset Configuration

```bash
# Remove existing config
rm ~/.recon_config ~/api_keys.sh

# Run setup wizard again
./setup.sh --config
```

### Common Errors

**Error: `unexpected token conditional binary operator expected`**
```
Solution: Reinstall arf command
  sudo cp recon.sh /usr/local/bin/arf
  sudo chmod +x /usr/local/bin/arf
```

**Error: `Could not open lock file /var/lib/apt/lists/lock`**
```
Solution: Tool installation in --config mode needs sudo
  Run: sudo ./setup.sh  (for full installation)
  Then: ./setup.sh --config  (for configuration)
```

---

## 📁 Project Structure

```
Advanced-Reconnaissance-Framework-v3.0/
├── recon.sh              # 🚀 Main script with built-in help (run as: arf)
├── setup.sh              # ⚙️  Setup script (install + configure)
├── targets.txt.example   # 📁 Sample targets file (auto-generated)
├── README.md             # 📖 This documentation
├── LICENSE               # 📄 MIT License
└── .gitignore            # 🚫 Git ignore rules
```

**After installation:**
- `arf` command is installed to `/usr/local/bin/arf`
- Config files are created in your home directory (`~/.recon_config`, `~/api_keys.sh`)

---

## ⚠️ Legal Disclaimer

> **IMPORTANT: This tool is for authorized security testing only.**

- ✅ **Authorized Use Only** - Only scan targets you own or have written permission to test
- ✅ **Compliance** - Ensure compliance with applicable laws and regulations
- ✅ **Bug Bounty** - Follow program rules when testing bug bounty targets
- ✅ **No Warranty** - This tool is provided "as is" without warranty
- ✅ **Responsibility** - Users are responsible for their actions

**Unauthorized scanning of systems you do not own or have permission to test is illegal and may result in criminal prosecution.**

### Responsible Use Guidelines

1. **Get Written Permission** - Always obtain explicit authorization before scanning
2. **Follow Scope** - Stay within the defined scope of your engagement
3. **Respect Rate Limits** - Don't overwhelm target infrastructure
4. **Report Responsibly** - Follow responsible disclosure practices
5. **Document Everything** - Keep records of authorization and findings

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

### How to Contribute

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
- Ensure all scripts have proper error handling

### Areas for Contribution

- 🐛 Bug fixes
- ✨ New features
- 📝 Documentation improvements
- 🧪 Test cases
- 🌍 Translations
- 🔒 Security improvements

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2026 Recon Framework

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

Thanks to the amazing security community and tool developers:

| Project | Tools |
|---------|-------|
| [ProjectDiscovery](https://github.com/projectdiscovery) | subfinder, httpx, nuclei, naabu, dnsx, katana |
| [TomNomNom](https://github.com/tomnomnom) | assetfinder, waybackurls |
| [ffuf](https://github.com/ffuf/ffuf) | Fast web fuzzer |
| [OWASP Amass](https://github.com/owasp-amass/amass) | Subdomain enumeration |
| [SecLists](https://github.com/danielmiessler/SecLists) | Wordlists |
| [Dalfox](https://github.com/hahwul/dalfox) | XSS scanner |
| [Gowitness](https://github.com/sensepost/gowitness) | Screenshot tool |

---

## 📞 Support

| Channel | Link |
|---------|------|
| **Issues** | [GitHub Issues](https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0/issues) |
| **Discussions** | [GitHub Discussions](https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0/discussions) |
| **Documentation** | [Wiki](https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0/wiki) |
| **Security** | [Security Policy](https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0/security) |

### Getting Help

1. Check the [Troubleshooting](#-troubleshooting) section
2. Search existing [Issues](https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0/issues)
3. Run with `--debug` flag for detailed logs
4. Open a new issue with reproduction steps

---

## 📈 Roadmap

### v3.0 (Current)
- ✅ Multi-target file support
- ✅ Interactive setup wizard
- ✅ One-command installer
- ✅ WAF bypass techniques
- ✅ Batch processing with parallel execution
- ✅ Multiple report formats

### v3.1 (Planned)
- 🔄 Docker container support
- 🔄 REST API interface
- 🔄 Web dashboard
- 🔄 Real-time progress tracking
- 🔄 Database integration (PostgreSQL)

### v3.2 (Planned)
- 🔄 AI-powered vulnerability prioritization
- 🔄 Automated report sharing
- 🔄 Integration with ticketing systems (Jira, ServiceNow)
- 🔄 Custom template support

---

<p align="center">
  <strong>Made with ❤️ by the Security Community</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-3.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/Last_Updated-March_2026-green.svg" alt="Updated">
  <img src="https://img.shields.io/badge/Maintained-Yes-success.svg" alt="Maintained">
</p>

---

## 🎯 Quick Reference Card

```bash
# ═══════════════════════════════════════════════════════════════
# RECON FRAMEWORK - QUICK REFERENCE
# ═══════════════════════════════════════════════════════════════

# INSTALL
git clone https://github.com/ganiket25201001/Advanced-Reconnaissance-Framework-v3.0.git
cd Advanced-Reconnaissance-Framework-v3.0
sudo ./install.sh
./setup_config.sh

# SINGLE TARGET
sudo ./recon.sh example.com
sudo ./recon.sh example.com --waf-bypass --html-report
sudo ./recon.sh example.com --stealth --api-keys ~/api_keys.sh

# MULTI-TARGET
sudo ./recon.sh -f targets.txt
sudo ./recon.sh -f targets.txt --parallel 3 --notify discord

# ADVANCED
sudo ./recon.sh example.com --aggressive --html-report --json-report
sudo ./recon.sh example.com --tor --stealth --skip-install
sudo ./recon.sh example.com --resume recon_example.com_20260320_120000

# CONFIGURATION
nano ~/.recon_config
nano ~/api_keys.sh
chmod 600 ~/.recon_config ~/api_keys.sh

# TROUBLESHOOTING
sudo ./recon.sh example.com --debug
cat example.com_recon.log

# ═══════════════════════════════════════════════════════════════
```
