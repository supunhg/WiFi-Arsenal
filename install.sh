#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Installation banner
print_install_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                 WiFi Arsenal - Setup Script                 ║
    ║              Automated Installation & Configuration          ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${WHITE}Preparing your Kali Linux system for WiFi Arsenal...${NC}"
    echo ""
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This installation script must be run as root${NC}"
        echo -e "${BLUE}[*] Please run: sudo $0${NC}"
        exit 1
    fi
}

# Detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}[!] Cannot detect Linux distribution${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}[*] Detected: $PRETTY_NAME${NC}"
    
    # Check if Kali Linux
    if [[ "$DISTRO" == "kali" ]]; then
        echo -e "${GREEN}[✓] Kali Linux detected - optimal compatibility${NC}"
        KALI_SYSTEM=true
    elif [[ "$DISTRO" == "debian" ]] || [[ "$DISTRO" == "ubuntu" ]]; then
        echo -e "${YELLOW}[!] Debian/Ubuntu detected - some tools may need manual installation${NC}"
        KALI_SYSTEM=false
    else
        echo -e "${YELLOW}[!] Unsupported distribution - proceeding with caution${NC}"
        KALI_SYSTEM=false
    fi
}

# Update system packages
update_system() {
    echo -e "${BLUE}[*] Updating system packages...${NC}"
    apt update -y
    apt upgrade -y
    echo -e "${GREEN}[✓] System updated${NC}"
}

# Install core dependencies
install_core_deps() {
    echo -e "${BLUE}[*] Installing core dependencies...${NC}"
    
    local core_packages=(
        "aircrack-ng"
        "reaver"
        "hostapd"
        "dnsmasq"
        "nmap"
        "macchanger"
        "ettercap-text-only"
        "curl"
        "wget"
        "git"
        "build-essential"
        "libssl-dev"
        "libpcap-dev"
        "python3"
        "python3-pip"
    )
    
    for package in "${core_packages[@]}"; do
        echo -e "${BLUE}[*] Installing $package...${NC}"
        if apt install -y "$package"; then
            echo -e "${GREEN}[✓] $package installed${NC}"
        else
            echo -e "${YELLOW}[!] Failed to install $package${NC}"
        fi
    done
}

# Install advanced tools
install_advanced_tools() {
    echo -e "${BLUE}[*] Installing advanced WiFi tools...${NC}"
    
    # Install hcxtools and hcxdumptool
    if [[ "$KALI_SYSTEM" == true ]]; then
        echo -e "${BLUE}[*] Installing hcxtools and hcxdumptool from Kali repos...${NC}"
        apt install -y hcxtools hcxdumptool
    else
        echo -e "${BLUE}[*] Compiling hcxtools from source...${NC}"
        cd /tmp
        git clone https://github.com/ZerBea/hcxtools.git
        cd hcxtools
        make && make install
        
        echo -e "${BLUE}[*] Compiling hcxdumptool from source...${NC}"
        cd /tmp
        git clone https://github.com/ZerBea/hcxdumptool.git
        cd hcxdumptool
        make && make install
    fi
    
    # Install Bully
    echo -e "${BLUE}[*] Installing Bully...${NC}"
    if ! apt install -y bully; then
        echo -e "${BLUE}[*] Compiling Bully from source...${NC}"
        cd /tmp
        git clone https://github.com/aanarchyy/bully.git
        cd bully/src
        make && make install
    fi
    
    # Install Hashcat if not present
    echo -e "${BLUE}[*] Installing Hashcat...${NC}"
    if ! command -v hashcat &> /dev/null; then
        apt install -y hashcat || {
            echo -e "${BLUE}[*] Installing Hashcat from official source...${NC}"
            cd /tmp
            wget https://hashcat.net/files/hashcat-6.2.6.tar.gz
            tar xzf hashcat-6.2.6.tar.gz
            cd hashcat-6.2.6
            make && make install
        }
    fi
    
    # Install John the Ripper
    echo -e "${BLUE}[*] Installing John the Ripper...${NC}"
    apt install -y john || {
        echo -e "${BLUE}[*] Compiling John from source...${NC}"
        cd /tmp
        git clone https://github.com/openwall/john.git
        cd john/src
        ./configure && make && make install
    }
}

# Install wordlists
install_wordlists() {
    echo -e "${BLUE}[*] Installing wordlists...${NC}"
    
    # Install SecLists if not present
    if [[ ! -d "/usr/share/seclists" ]]; then
        echo -e "${BLUE}[*] Installing SecLists...${NC}"
        apt install -y seclists || {
            cd /usr/share
            git clone https://github.com/danielmiessler/SecLists.git seclists
        }
    fi
    
    # Ensure rockyou.txt is available
    if [[ ! -f "/usr/share/wordlists/rockyou.txt" ]]; then
        echo -e "${BLUE}[*] Setting up rockyou.txt wordlist...${NC}"
        mkdir -p /usr/share/wordlists
        
        if [[ -f "/usr/share/wordlists/rockyou.txt.gz" ]]; then
            gunzip /usr/share/wordlists/rockyou.txt.gz
        else
            echo -e "${YELLOW}[!] rockyou.txt not found, downloading...${NC}"
            cd /usr/share/wordlists
            wget https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt
        fi
    fi
    
    echo -e "${GREEN}[✓] Wordlists configured${NC}"
}

# Setup WiFi Arsenal
setup_wifi_arsenal() {
    echo -e "${BLUE}[*] Setting up WiFi Arsenal...${NC}"
    
    local install_dir="/opt/wifi-arsenal"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Create installation directory
    mkdir -p "$install_dir"
    
    # Copy scripts
    cp "$script_dir/wifi_arsenal.sh" "$install_dir/"
    cp "$script_dir/wifi_automation.sh" "$install_dir/"
    cp "$script_dir/install.sh" "$install_dir/"
    
    # Make scripts executable
    chmod +x "$install_dir"/*.sh
    
    # Create symlinks for easy access
    ln -sf "$install_dir/wifi_arsenal.sh" /usr/local/bin/wifi-arsenal
    ln -sf "$install_dir/wifi_automation.sh" /usr/local/bin/wifi-auto
    
    # Create desktop shortcut for Kali
    if [[ "$KALI_SYSTEM" == true ]]; then
        cat > /home/kali/Desktop/WiFi-Arsenal.desktop << EOF
[Desktop Entry]
Version=1.1
Type=Application
Name=WiFi Arsenal
Comment=Comprehensive WiFi Security Toolkit
Exec=gnome-terminal -- sudo /opt/wifi-arsenal/wifi_arsenal.sh
Icon=network-wireless
Terminal=true
Categories=Network;Security;
EOF
        chmod +x /home/kali/Desktop/WiFi-Arsenal.desktop
        chown kali:kali /home/kali/Desktop/WiFi-Arsenal.desktop
    fi
    
    echo -e "${GREEN}[✓] WiFi Arsenal installed to $install_dir${NC}"
    echo -e "${GREEN}[✓] Command-line access: wifi-arsenal, wifi-auto${NC}"
}

# Configure system settings
configure_system() {
    echo -e "${BLUE}[*] Configuring system settings...${NC}"
    
    # Disable network manager interference
    cat > /etc/NetworkManager/conf.d/wifi-arsenal.conf << EOF
[main]
plugins=ifupdown,keyfile

[ifupdown]
managed=false

[device]
wifi.scan-rand-mac-address=no
EOF
    
    # Create udev rules for USB WiFi adapters
    cat > /etc/udev/rules.d/99-wifi-arsenal.rules << EOF
# Common USB WiFi adapters
SUBSYSTEM=="usb", ATTRS{idVendor}=="148f", ATTRS{idProduct}=="7601", RUN+="/bin/sh -c 'echo 148f 7601 > /sys/bus/usb/drivers/mt7601u/new_id'"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8187", RUN+="/bin/sh -c 'modprobe rtl8187'"
SUBSYSTEM=="usb", ATTRS{idVendor}=="0bda", ATTRS{idProduct}=="8197", RUN+="/bin/sh -c 'modprobe rtl8187'"
EOF
    
    # Reload udev rules
    udevadm control --reload-rules
    
    echo -e "${GREEN}[✓] System configured${NC}"
}

# Install additional Python tools
install_python_tools() {
    echo -e "${BLUE}[*] Installing Python security tools...${NC}"
    
    pip3 install --upgrade pip
    
    local python_tools=(
        "scapy"
        "netdiscover"
        "requests"
        "beautifulsoup4"
        "flask"
        "colorama"
    )
    
    for tool in "${python_tools[@]}"; do
        echo -e "${BLUE}[*] Installing $tool...${NC}"
        pip3 install "$tool"
    done
    
    echo -e "${GREEN}[✓] Python tools installed${NC}"
}

# Create configuration file
create_config() {
    echo -e "${BLUE}[*] Creating configuration file...${NC}"
    
    local config_file="/opt/wifi-arsenal/config.conf"
    
    cat > "$config_file" << EOF
# WiFi Arsenal Configuration File
# Edit these settings to customize tool behavior

# Default wordlist path
WORDLIST_PATH="/usr/share/wordlists/rockyou.txt"

# Output directory
OUTPUT_DIR="\$HOME/wifi_arsenal_output"

# Default attack timeouts (seconds)
WPS_TIMEOUT=300
HANDSHAKE_TIMEOUT=60
PMKID_TIMEOUT=300

# Interface settings
MONITOR_MODE_SUFFIX="mon"

# Automation settings
AUTO_DEAUTH_COUNT=20
AUTO_SCAN_TIME=60

# Report settings
GENERATE_HTML_REPORTS=true
REPORT_INCLUDE_RAW_DATA=false

# Logging
LOG_LEVEL="INFO"
LOG_TO_FILE=true

# Advanced settings
USE_CUSTOM_OUI=false
CUSTOM_MAC_PREFIX="00:11:22"

# GPU acceleration for hashcat (if available)
USE_GPU_ACCELERATION=true
GPU_WORKLOAD_PROFILE=3
EOF
    
    echo -e "${GREEN}[✓] Configuration file created: $config_file${NC}"
}

# Verify installation
verify_installation() {
    echo -e "${BLUE}[*] Verifying installation...${NC}"
    
    local tools=(
        "aircrack-ng"
        "airodump-ng"
        "aireplay-ng"
        "reaver"
        "wash"
        "bully"
        "hostapd"
        "dnsmasq"
        "hcxdumptool"
        "hcxpcapngtool"
        "hashcat"
        "john"
        "macchanger"
        "nmap"
    )
    
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${GREEN}[✓] $tool${NC}"
        else
            echo -e "${RED}[✗] $tool${NC}"
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -eq 0 ]]; then
        echo -e "${GREEN}[✓] All tools installed successfully!${NC}"
    else
        echo -e "${YELLOW}[!] Missing tools: ${missing_tools[*]}${NC}"
        echo -e "${BLUE}[*] You may need to install these manually${NC}"
    fi
}

# Display post-installation instructions
show_post_install() {
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                    Installation Complete!                   ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${GREEN}WiFi Arsenal has been successfully installed!${NC}"
    echo ""
    echo -e "${WHITE}Quick Start:${NC}"
    echo -e "${BLUE}• Run main tool:${NC} wifi-arsenal"
    echo -e "${BLUE}• Run automation:${NC} wifi-auto"
    echo -e "${BLUE}• Full path:${NC} /opt/wifi-arsenal/wifi_arsenal.sh"
    echo ""
    echo -e "${WHITE}Important Notes:${NC}"
    echo -e "${YELLOW}• Always run with sudo/root privileges${NC}"
    echo -e "${YELLOW}• Ensure you have proper authorization before testing${NC}"
    echo -e "${YELLOW}• Use only on networks you own or have permission to test${NC}"
    echo ""
    echo -e "${WHITE}Configuration:${NC}"
    echo -e "${BLUE}• Config file:${NC} /opt/wifi-arsenal/config.conf"
    echo -e "${BLUE}• Logs location:${NC} ~/wifi_arsenal_output/"
    echo ""
    echo -e "${WHITE}For help and documentation:${NC}"
    echo -e "${BLUE}• GitHub:${NC} https://github.com/wifi-arsenal"
    echo -e "${BLUE}• Manual:${NC} man wifi-arsenal"
    echo ""
}

# Create man page
create_man_page() {
    echo -e "${BLUE}[*] Creating manual page...${NC}"
    
    mkdir -p /usr/local/man/man1
    
    cat > /usr/local/man/man1/wifi-arsenal.1 << 'EOF'
.TH WIFI-ARSENAL 1 "2025-07-22" "2.1" "WiFi Arsenal Manual"
.SH NAME
wifi-arsenal \- Comprehensive WiFi Security Testing Toolkit
.SH SYNOPSIS
.B wifi-arsenal
.SH DESCRIPTION
WiFi Arsenal is a comprehensive toolkit for WiFi security testing and penetration testing. It provides automated and manual methods for testing wireless network security.
.SH FEATURES
.IP \[bu] 2
WiFi network scanning and enumeration
.IP \[bu]
WPS attack capabilities (Reaver, Pixie Dust, Bully)
.IP \[bu]
WPA/WPA2 handshake capture and cracking
.IP \[bu]
PMKID attacks
.IP \[bu]
Evil Twin access point deployment
.IP \[bu]
Network discovery and reconnaissance
.IP \[bu]
MAC address manipulation
.IP \[bu]
Automated attack sequences
.IP \[bu]
Comprehensive reporting
.SH REQUIREMENTS
.IP \[bu] 2
Root privileges
.IP \[bu]
Compatible wireless adapter with monitor mode support
.IP \[bu]
Kali Linux or compatible distribution
.SH USAGE
Run the tool with root privileges:
.PP
.nf
.RS
sudo wifi-arsenal
.RE
.fi
.PP
For automated attacks:
.PP
.nf
.RS
sudo wifi-auto
.RE
.fi
.SH FILES
.TP
.I /opt/wifi-arsenal/
Installation directory
.TP
.I /opt/wifi-arsenal/config.conf
Configuration file
.TP
.I ~/wifi_arsenal_output/
Default output directory
.SH AUTHOR
WiFi Arsenal Development Team
.SH DISCLAIMER
Be Responsible!
.SH SEE ALSO
.BR aircrack-ng (1),
.BR reaver (1),
.BR hashcat (1)
EOF
    
    mandb &>/dev/null
    echo -e "${GREEN}[✓] Manual page created${NC}"
}

# Main installation function
main_install() {
    print_install_banner
    
    echo -e "${BLUE}[*] Starting WiFi Arsenal installation...${NC}"
    echo ""
    
    # Pre-installation checks
    check_root
    detect_distro
    
    # Get user confirmation
    echo -e "${YELLOW}This will install WiFi Arsenal and all dependencies.${NC}"
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installation cancelled.${NC}"
        exit 0
    fi
    
    # Installation steps
    update_system
    install_core_deps
    install_advanced_tools
    install_wordlists
    install_python_tools
    configure_system
    setup_wifi_arsenal
    create_config
    create_man_page
    
    # Verification and completion
    verify_installation
    show_post_install
    
    echo -e "${GREEN}[✓] Installation completed successfully!${NC}"
}

# Uninstall function
uninstall_wifi_arsenal() {
    echo -e "${YELLOW}[!] Uninstalling WiFi Arsenal...${NC}"
    
    # Remove files
    rm -rf /opt/wifi-arsenal
    rm -f /usr/local/bin/wifi-arsenal
    rm -f /usr/local/bin/wifi-auto
    rm -f /home/kali/Desktop/WiFi-Arsenal.desktop
    rm -f /etc/NetworkManager/conf.d/wifi-arsenal.conf
    rm -f /etc/udev/rules.d/99-wifi-arsenal.rules
    rm -f /usr/local/man/man1/wifi-arsenal.1
    
    # Update man database
    mandb &>/dev/null
    
    echo -e "${GREEN}[✓] WiFi Arsenal uninstalled${NC}"
}

# Menu for installation options
installation_menu() {
    while true; do
        print_install_banner
        echo -e "${CYAN}=== WiFi Arsenal Installation Menu ===${NC}"
        echo -e "${WHITE}[1]${NC} Full Installation (Recommended)"
        echo -e "${WHITE}[2]${NC} Install Core Dependencies Only"
        echo -e "${WHITE}[3]${NC} Install Advanced Tools Only"
        echo -e "${WHITE}[4]${NC} Setup WiFi Arsenal Scripts Only"
        echo -e "${WHITE}[5]${NC} Verify Installation"
        echo -e "${WHITE}[6]${NC} Uninstall WiFi Arsenal"
        echo -e "${WHITE}[7]${NC} Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) main_install; break ;;
            2) update_system; install_core_deps ;;
            3) install_advanced_tools ;;
            4) setup_wifi_arsenal ;;
            5) verify_installation ;;
            6) uninstall_wifi_arsenal ;;
            7) exit 0 ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        
        if [[ $choice != 1 ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
}

# Check if script is run with arguments
if [[ $# -eq 0 ]]; then
    installation_menu
else
    case "$1" in
        "install") main_install ;;
        "uninstall") uninstall_wifi_arsenal ;;
        "verify") verify_installation ;;
        "help"|"-h"|"--help")
            echo "WiFi Arsenal Installation Script"
            echo "Usage: $0 [install|uninstall|verify|help]"
            echo ""
            echo "Options:"
            echo "  install    - Full installation"
            echo "  uninstall  - Remove WiFi Arsenal"
            echo "  verify     - Verify installation"
            echo "  help       - Show this help"
            ;;
        *) 
            echo "Unknown option: $1"
            echo "Use '$0 help' for usage information"
            ;;
    esac
fi
