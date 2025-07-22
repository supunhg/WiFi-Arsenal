# WiFi Arsenal - Comprehensive WiFi Security Testing Toolkit

[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Version: 2.0](https://img.shields.io/badge/Version-2.0-green.svg)](https://github.com/wifi-arsenal)

> ⚠️ **IMPORTANT DISCLAIMER** ⚠️  
> This tool is for **authorized security testing and educational purposes only**. Unauthorized access to networks is illegal and unethical. Always ensure you have proper permission before testing any wireless networks.

## 🚀 Overview

WiFi Arsenal is a powerful, comprehensive toolkit designed for WiFi security professionals, penetration testers, and researchers. It combines multiple attack vectors, automation capabilities, and advanced reporting into a single, easy-to-use framework.

### ✨ Key Features

- 📡 **Comprehensive WiFi Scanning** - Advanced network discovery and enumeration
- 🔓 **WPS Attacks** - Reaver, Pixie Dust, Bully, and more
- 🔐 **WPA/WPA2 Testing** - Handshake capture, PMKID attacks, dictionary attacks
- 👥 **Evil Twin Attacks** - Automated rogue access point deployment
- 🤖 **Full Automation** - Batch processing and automated attack sequences
- 🔍 **Network Discovery** - ARP scanning, port scanning, host enumeration
- 🎭 **MAC Spoofing** - Advanced MAC address manipulation
- 📊 **Professional Reporting** - HTML reports with detailed analysis
- 🗂️ **Session Management** - Save and resume attack sessions
- ⚙️ **Advanced Configuration** - Customizable settings and profiles

## 🛠️ Installation

### Quick Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/wifi-arsenal/wifi-arsenal.git
cd wifi-arsenal

# Run the installation script
sudo chmod +x install.sh
sudo ./install.sh
```

### Manual Installation

```bash
# Install dependencies
sudo apt update && sudo apt install -y \
    aircrack-ng reaver hostapd dnsmasq nmap \
    macchanger ettercap-text-only hcxtools \
    hcxdumptool hashcat john bully

# Make scripts executable
chmod +x *.sh

# Run WiFi Arsenal
sudo ./wifi_arsenal.sh
```

### Kali Linux

WiFi Arsenal is optimized for Kali Linux and includes automatic detection of the environment for enhanced compatibility.

## 🎯 Quick Start

### Basic Usage

```bash
# Start WiFi Arsenal
sudo wifi-arsenal

# Run automation suite
sudo wifi-auto

# Install and verify
sudo ./install.sh install
sudo ./install.sh verify
```

### Command Line Options

```bash
# Main tool
wifi-arsenal

# Automation suite
wifi-auto

# Direct script execution
sudo /opt/wifi-arsenal/wifi_arsenal.sh
sudo /opt/wifi-arsenal/wifi_automation.sh
```

## 📖 Detailed Usage Guide

### 1. Network Discovery

WiFi Arsenal provides multiple methods for network discovery:

```bash
# Automated network discovery
Select: [1] WiFi Network Scanning

# Advanced discovery with classification
Use automation suite: [1] Automated Network Discovery
```

**Features:**
- Passive WiFi scanning
- WPS enumeration
- Security classification
- Signal strength analysis
- Channel utilization mapping

### 2. WPS Attacks

Multiple WPS attack vectors are supported:

```bash
# WPS Attack Menu
Select: [2] WPS Attacks

# Available attacks:
[1] WPS PIN Attack (Reaver)
[2] WPS Pixie Dust Attack  
[3] WPS Null PIN Attack
[4] WPS Scan
```

**Attack Types:**
- **Pixie Dust**: Exploits weak random number generation
- **PIN Attack**: Brute force WPS PIN
- **Null PIN**: Tests for default/empty PINs
- **Bully**: Alternative WPS attack tool

### 3. WPA/WPA2 Testing

Comprehensive WPA/WPA2 security testing:

```bash
# WPA Attack Menu
Select: [3] WPA/WPA2 Attacks

# Available options:
[1] Capture Handshake
[2] Deauth Attack
[3] Dictionary Attack
[4] PMKID Attack
[5] Crack Captured Handshake
```

**Capabilities:**
- **Handshake Capture**: Automated 4-way handshake collection
- **PMKID**: Clientless WPA2 attack
- **Deauthentication**: Force client reconnection
- **Dictionary Attacks**: Password cracking with wordlists
- **GPU Acceleration**: Hashcat integration for fast cracking

### 4. Evil Twin Attacks

Deploy rogue access points:

```bash
# Evil Twin Attack
Select: [4] Evil Twin Attack

# Features:
- Captive portal templates
- Credential harvesting
- DNS hijacking
- HTTPS downgrade
```

**Templates:**
- Basic WiFi authentication
- Router administration panel
- Social media login page
- Custom portal creation

### 5. Automation Suite

Advanced automation for batch processing:

```bash
# Automation Menu
sudo wifi-auto

# Available automations:
[1] Automated Network Discovery
[2] Automated Handshake Collection  
[3] Automated WPS Attacks
[4] Batch Handshake Cracking
[5] Automated PMKID Collection
[6] Automated Evil Twin
[7] Full Security Assessment
```

## ⚙️ Configuration

### Configuration File

Location: `/opt/wifi-arsenal/config.conf`

```bash
# Default wordlist path
WORDLIST_PATH="/usr/share/wordlists/rockyou.txt"

# Output directory
OUTPUT_DIR="$HOME/wifi_arsenal_output"

# Attack timeouts (seconds)
WPS_TIMEOUT=300
HANDSHAKE_TIMEOUT=60
PMKID_TIMEOUT=300

# GPU acceleration
USE_GPU_ACCELERATION=true
GPU_WORKLOAD_PROFILE=3
```

### Environment Variables

```bash
export WIFI_ARSENAL_OUTPUT="/custom/output/path"
export WIFI_ARSENAL_WORDLIST="/custom/wordlist.txt"
export WIFI_ARSENAL_INTERFACE="wlan0"
```

## 📊 Reporting

WiFi Arsenal generates comprehensive reports:

### HTML Reports

```bash
# Generate report
Select: [8] Generate Report

# Features:
- Executive summary
- Detailed findings
- Security recommendations
- Technical appendix
- Risk assessment
```

### Report Contents

- **Network Inventory**: All discovered networks
- **Vulnerability Assessment**: Security weaknesses found
- **Attack Results**: Successful attacks and captured data
- **Recommendations**: Specific mitigation strategies
- **Technical Details**: Raw data and evidence

## 🔧 Advanced Features

### Session Management

```bash
# Session operations
Select: [7] Session Management

[1] List saved sessions
[2] Load session
[3] Delete session  
[4] Export session data
```

### MAC Address Operations

```bash
# MAC operations
Select: [6] MAC Address Operations

[1] Randomize MAC address
[2] Set specific MAC address
[3] Reset to original MAC
[4] Show current MAC
```

### Custom Wordlists

```bash
# Custom wordlist usage
/opt/wifi-arsenal/wordlists/
├── common-passwords.txt
├── wifi-specific.txt
├── device-defaults.txt
└── custom-list.txt
```

## 🛡️ Hardware Requirements

### Recommended WiFi Adapters

**USB WiFi Adapters with Monitor Mode:**
- Alfa AWUS036ACS (802.11ac, dual-band)
- Alfa AWUS036NHA (high power, long range)
- Panda PAU09 (compact, reliable)
- TP-Link AC600T1U (budget option)

**Internal WiFi Cards:**
- Intel WiFi cards (good compatibility)
- Atheros chipset cards (excellent monitor mode)

### System Requirements

- **OS**: Kali Linux (recommended), Ubuntu 18.04+, Debian 10+
- **RAM**: 2GB minimum, 4GB recommended
- **Storage**: 10GB free space
- **CPU**: Multi-core for GPU acceleration
- **GPU**: CUDA-compatible for hashcat acceleration

## 🔍 Troubleshooting

### Common Issues

**Monitor Mode Issues:**
```bash
# Check interface capabilities
iw list | grep -A 8 "Supported interface modes"

# Kill interfering processes
sudo airmon-ng check kill

# Manual monitor mode
sudo ip link set wlan0 down
sudo iw wlan0 set monitor control
sudo ip link set wlan0 up
```

**Permission Errors:**
```bash
# Ensure root privileges
sudo wifi-arsenal

# Check file permissions
sudo chmod +x /opt/wifi-arsenal/*.sh
```

**Missing Dependencies:**
```bash
# Verify installation
sudo /opt/wifi-arsenal/install.sh verify

# Reinstall dependencies
sudo /opt/wifi-arsenal/install.sh install
```

### Debug Mode

```bash
# Enable debug logging
export WIFI_ARSENAL_DEBUG=1
sudo wifi-arsenal

# Check logs
tail -f ~/wifi_arsenal_output/wifi_arsenal.log
```

## 📚 Educational Resources

### Learning Materials

- **WiFi Security Fundamentals**: Understanding WPA/WPA2/WPA3
- **Attack Methodologies**: Common WiFi attack vectors
- **Defense Strategies**: How to protect against these attacks
- **Legal Considerations**: Laws and regulations regarding WiFi testing

### Recommended Reading

- "The Hacker Playbook 3" by Peter Kim
- "WiFi Security: WEP, WPA and WPA2" by Jennifer Kolb
- "Penetration Testing: A Hands-On Introduction to Hacking" by Georgia Weidman

## 🤝 Contributing

We welcome contributions to WiFi Arsenal!

### Development Setup

```bash
# Fork the repository
git clone https://github.com/your-username/wifi-arsenal.git
cd wifi-arsenal

# Create feature branch
git checkout -b feature/new-attack-method

# Make changes and test
sudo ./wifi_arsenal.sh

# Submit pull request
```

### Contribution Guidelines

- Follow bash scripting best practices
- Include comprehensive error handling
- Add documentation for new features
- Test on multiple Linux distributions
- Ensure legal compliance

## ⚖️ Legal Notice

**IMPORTANT**: This tool is designed for:
- Authorized penetration testing
- Educational purposes
- Security research
- Testing your own networks

**PROHIBITED USES**:
- Unauthorized network access
- Illegal activities
- Privacy violations
- Commercial use without permission

Users are responsible for complying with all applicable laws and regulations.

## 🙏 Acknowledgments

WiFi Arsenal builds upon the excellent work of:
- **Aircrack-ng Suite** - Core WiFi testing tools
- **Reaver** - WPS PIN attack tool
- **Hashcat** - Password recovery tool
- **John the Ripper** - Password cracking tool
- **hcxtools** - Modern WiFi auditing tools

## 📞 Support

### Getting Help

- **Documentation**: Read this README and man pages
- **Issues**: Report bugs on GitHub Issues
- **Discussions**: Join community discussions
- **Security**: Report security issues privately

### Community

- **GitHub**: https://github.com/wifi-arsenal
- **Documentation**: https://wifi-arsenal.readthedocs.io
- **Wiki**: Community-maintained guides and tutorials

---

**Remember**: Always hack responsibly and ethically! 🛡️
