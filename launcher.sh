#!/bin/bash

# WiFi Arsenal Launcher Script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Display launcher banner
print_launcher_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                     WiFi Arsenal Launcher                   ║
    ║                 Quick Access & Environment Setup            ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check environment
check_environment() {
    local issues=()
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        issues+=("Must run as root")
    fi
    
    # Check if main scripts exist
    if [[ ! -f "$SCRIPT_DIR/wifi_arsenal.sh" ]]; then
        issues+=("wifi_arsenal.sh not found")
    fi
    
    if [[ ! -f "$SCRIPT_DIR/wifi_automation.sh" ]]; then
        issues+=("wifi_automation.sh not found")
    fi
    
    # Check basic dependencies
    local deps=("aircrack-ng" "iwconfig" "ifconfig")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            issues+=("Missing dependency: $dep")
        fi
    done
    
    # Check for WiFi interfaces
    local wifi_interfaces=$(iwconfig 2>/dev/null | grep -c "IEEE 802.11")
    if [[ $wifi_interfaces -eq 0 ]]; then
        issues+=("No WiFi interfaces detected")
    fi
    
    if [[ ${#issues[@]} -gt 0 ]]; then
        echo -e "${RED}[!] Environment Issues Detected:${NC}"
        for issue in "${issues[@]}"; do
            echo -e "${YELLOW}  • $issue${NC}"
        done
        echo ""
        
        if [[ $EUID -ne 0 ]]; then
            echo -e "${BLUE}[*] Please run: sudo $0${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}[*] Some issues detected. Continue anyway? (y/N)${NC}"
        read -p "> " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}[✓] Environment check passed${NC}"
    fi
}

# Display system info
show_system_info() {
    echo -e "${BLUE}[*] System Information:${NC}"
    echo -e "${WHITE}  OS:${NC} $(lsb_release -d 2>/dev/null | cut -f2 || uname -o)"
    echo -e "${WHITE}  Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}  WiFi Interfaces:${NC}"
    
    iwconfig 2>/dev/null | grep "IEEE 802.11" -A 1 | while read -r line; do
        if [[ "$line" =~ ^[a-zA-Z0-9]+ ]]; then
            local interface=$(echo "$line" | awk '{print $1}')
            local status=$(ip link show "$interface" 2>/dev/null | grep -o "state [A-Z]*" | cut -d' ' -f2 || echo "UNKNOWN")
            echo -e "${WHITE}    • $interface${NC} (${status})"
        fi
    done
    echo ""
}

# Quick setup function
quick_setup() {
    echo -e "${BLUE}[*] Performing quick setup...${NC}"
    
    # Kill interfering processes
    echo -e "${BLUE}[*] Stopping interfering processes...${NC}"
    airmon-ng check kill &>/dev/null
    
    # Update package lists if needed
    if [[ ! -f "/var/lib/apt/periodic/update-success-stamp" ]] || [[ $(find /var/lib/apt/periodic/update-success-stamp -mtime +7) ]]; then
        echo -e "${BLUE}[*] Updating package lists...${NC}"
        apt update &>/dev/null &
    fi
    
    echo -e "${GREEN}[✓] Quick setup completed${NC}"
}

# Main launcher menu
launcher_menu() {
    while true; do
        print_launcher_banner
        show_system_info
        
        echo -e "${CYAN}=== WiFi Arsenal Launcher ===${NC}"
        echo -e "${WHITE}[1]${NC} Launch WiFi Arsenal (Main Tool)"
        echo -e "${WHITE}[2]${NC} Launch Automation Suite"
        echo -e "${WHITE}[3]${NC} Run Installation/Setup"
        echo -e "${WHITE}[4]${NC} Quick Environment Check"
        echo -e "${WHITE}[5]${NC} View Documentation"
        echo -e "${WHITE}[6]${NC} System Preparation"
        echo -e "${WHITE}[7]${NC} Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1)
                if [[ -f "$SCRIPT_DIR/wifi_arsenal.sh" ]]; then
                    echo -e "${BLUE}[*] Launching WiFi Arsenal...${NC}"
                    exec "$SCRIPT_DIR/wifi_arsenal.sh"
                else
                    echo -e "${RED}[!] wifi_arsenal.sh not found${NC}"
                fi
                ;;
            2)
                if [[ -f "$SCRIPT_DIR/wifi_automation.sh" ]]; then
                    echo -e "${BLUE}[*] Launching Automation Suite...${NC}"
                    exec "$SCRIPT_DIR/wifi_automation.sh"
                else
                    echo -e "${RED}[!] wifi_automation.sh not found${NC}"
                fi
                ;;
            3)
                if [[ -f "$SCRIPT_DIR/install.sh" ]]; then
                    echo -e "${BLUE}[*] Running installation script...${NC}"
                    "$SCRIPT_DIR/install.sh"
                else
                    echo -e "${RED}[!] install.sh not found${NC}"
                fi
                ;;
            4)
                check_environment
                ;;
            5)
                if [[ -f "$SCRIPT_DIR/README.md" ]]; then
                    echo -e "${BLUE}[*] Opening documentation...${NC}"
                    if command -v less &> /dev/null; then
                        less "$SCRIPT_DIR/README.md"
                    else
                        cat "$SCRIPT_DIR/README.md"
                    fi
                else
                    echo -e "${YELLOW}[!] README.md not found${NC}"
                fi
                ;;
            6)
                quick_setup
                ;;
            7)
                echo -e "${BLUE}[*] Exiting launcher...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] Invalid option${NC}"
                ;;
        esac
        
        if [[ $choice != 1 && $choice != 2 ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
}

# Help function
show_help() {
    echo "WiFi Arsenal Launcher"
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -m, --main     Launch main WiFi Arsenal tool"
    echo "  -a, --auto     Launch automation suite"
    echo "  -i, --install  Run installation script"
    echo "  -c, --check    Check environment"
    echo "  -s, --setup    Quick system setup"
    echo ""
    echo "If no option is provided, the interactive menu will be shown."
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -m|--main)
        check_environment
        exec "$SCRIPT_DIR/wifi_arsenal.sh"
        ;;
    -a|--auto)
        check_environment
        exec "$SCRIPT_DIR/wifi_automation.sh"
        ;;
    -i|--install)
        exec "$SCRIPT_DIR/install.sh"
        ;;
    -c|--check)
        check_environment
        exit 0
        ;;
    -s|--setup)
        check_environment
        quick_setup
        exit 0
        ;;
    "")
        # No arguments - show interactive menu
        check_environment
        launcher_menu
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use '$0 --help' for usage information"
        exit 1
        ;;
esac
