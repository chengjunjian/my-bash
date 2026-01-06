#!/bin/bash

#########################################################################
#                                                                       #
#       SIP-GSM Audio Bridge Script                                    #
#       Bridges audio between SIP and GSM calls                        #
#       Author: System Administrator                                    #
#       Version: 1.0                                                    #
#       License: GPLv2                                                  #
#                                                                       #
#########################################################################
#                                                                       #
#       Description:                                                    #
#       This script sets up audio bridging between SIP (Session        #
#       Initiation Protocol) and GSM (Global System for Mobile         #
#       Communications) calls using Asterisk PBX and GSM gateway.      #
#                                                                       #
#       Features:                                                       #
#       - Configure SIP trunk settings                                 #
#       - Configure GSM gateway/modem                                  #
#       - Bridge audio streams between SIP and GSM                     #
#       - Call routing and management                                  #
#       - Logging and monitoring                                       #
#                                                                       #
#       Usage: ./sip_gsm_bridge.sh [command] [options]                 #
#                                                                       #
#       Commands:                                                       #
#           install     - Install required dependencies                #
#           configure   - Configure SIP and GSM settings               #
#           start       - Start the audio bridge service               #
#           stop        - Stop the audio bridge service                #
#           status      - Check service status                         #
#           test        - Test SIP and GSM connectivity                #
#           help        - Display this help message                    #
#                                                                       #
#########################################################################

set -e

# Color definitions for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration file path
CONFIG_FILE="/etc/sip-gsm-bridge/config.conf"
LOG_FILE="/var/log/sip-gsm-bridge.log"
PID_FILE="/var/run/sip-gsm-bridge.pid"

# Default configuration values
SIP_SERVER=""
SIP_USERNAME=""
SIP_PASSWORD=""
SIP_PORT="5060"
GSM_DEVICE="/dev/ttyUSB0"
GSM_BAUDRATE="115200"
ASTERISK_CONFIG_DIR="/etc/asterisk"
BRIDGE_PORT="10000"

#########################################################################
# Helper Functions
#########################################################################

# Print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Log messages to file
log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # Validate config file before sourcing to prevent code execution
        if grep -qE '^\s*(rm|mv|sudo|eval|exec|system|`|\$\()' "$CONFIG_FILE"; then
            print_error "Configuration file contains potentially dangerous commands"
            return 1
        fi
        source "$CONFIG_FILE"
        print_info "Configuration loaded from $CONFIG_FILE"
    else
        print_warning "Configuration file not found. Using defaults."
    fi
}

# Save configuration
save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat > "$CONFIG_FILE" <<EOF
# SIP-GSM Bridge Configuration
# Generated on $(date)

# SIP Configuration
SIP_SERVER="$SIP_SERVER"
SIP_USERNAME="$SIP_USERNAME"
SIP_PASSWORD="$SIP_PASSWORD"
SIP_PORT="$SIP_PORT"

# GSM Configuration
GSM_DEVICE="$GSM_DEVICE"
GSM_BAUDRATE="$GSM_BAUDRATE"

# Bridge Configuration
BRIDGE_PORT="$BRIDGE_PORT"
EOF
    # Set secure permissions to protect sensitive data
    chmod 600 "$CONFIG_FILE"
    print_success "Configuration saved to $CONFIG_FILE"
    print_info "File permissions set to 600 (owner read/write only)"
}

#########################################################################
# Installation Functions
#########################################################################

install_dependencies() {
    print_info "Installing required dependencies..."
    
    # Update package list
    apt-get update
    
    # Install Asterisk PBX
    print_info "Installing Asterisk PBX..."
    apt-get install -y asterisk asterisk-modules
    
    # Install GSM tools
    print_info "Installing GSM tools..."
    apt-get install -y gammu gammu-smsd usb-modeswitch
    
    # Install audio tools
    print_info "Installing audio tools..."
    apt-get install -y sox alsa-utils
    
    # Install network tools
    print_info "Installing network tools..."
    apt-get install -y socat netcat
    
    print_success "All dependencies installed successfully"
    log_message "Dependencies installed"
}

#########################################################################
# Configuration Functions
#########################################################################

configure_sip() {
    print_info "Configuring SIP trunk..."
    
    # Prompt for SIP settings if not configured
    if [[ -z "$SIP_SERVER" ]]; then
        read -p "Enter SIP server address: " SIP_SERVER
        read -p "Enter SIP username: " SIP_USERNAME
        read -sp "Enter SIP password: " SIP_PASSWORD
        echo
        print_warning "Note: Password will be stored in plain text in $CONFIG_FILE"
        print_warning "Ensure proper file permissions: chmod 600 $CONFIG_FILE"
        read -p "Enter SIP port [5060]: " SIP_PORT
        SIP_PORT=${SIP_PORT:-5060}
    fi
    
    # Configure Asterisk SIP settings
    cat > "$ASTERISK_CONFIG_DIR/sip_custom.conf" <<EOF
; SIP-GSM Bridge SIP Configuration
; Generated on $(date)

[general]
context=default
allowoverlap=no
bindport=$SIP_PORT
bindaddr=0.0.0.0
srvlookup=yes
disallow=all
allow=ulaw
allow=alaw
allow=gsm

[sip-trunk]
type=peer
host=$SIP_SERVER
username=$SIP_USERNAME
secret=$SIP_PASSWORD
fromuser=$SIP_USERNAME
fromdomain=$SIP_SERVER
insecure=port,invite
canreinvite=no
context=from-sip
qualify=yes
EOF
    
    print_success "SIP trunk configured"
    log_message "SIP trunk configured for $SIP_SERVER"
}

configure_gsm() {
    print_info "Configuring GSM gateway..."
    
    # Prompt for GSM settings if not configured
    if [[ -z "$GSM_DEVICE" ]]; then
        read -p "Enter GSM device path [/dev/ttyUSB0]: " GSM_DEVICE
        GSM_DEVICE=${GSM_DEVICE:-/dev/ttyUSB0}
        read -p "Enter GSM baudrate [115200]: " GSM_BAUDRATE
        GSM_BAUDRATE=${GSM_BAUDRATE:-115200}
    fi
    
    # Check if GSM device exists
    if [[ ! -e "$GSM_DEVICE" ]]; then
        print_error "GSM device $GSM_DEVICE not found"
        print_info "Available USB devices:"
        ls -l /dev/ttyUSB* 2>/dev/null || echo "No USB serial devices found"
        return 1
    fi
    
    # Configure gammu for GSM modem
    mkdir -p /etc/gammu
    cat > /etc/gammu/gammurc <<EOF
; GSM-SIP Bridge Gammu Configuration
; Generated on $(date)

[gammu]
device = $GSM_DEVICE
connection = at$GSM_BAUDRATE
EOF
    
    # Configure Asterisk chan_dongle for GSM
    cat > "$ASTERISK_CONFIG_DIR/dongle.conf" <<EOF
; GSM-SIP Bridge Dongle Configuration
; Generated on $(date)

[general]
interval=15

[gsm0]
audio=/dev/ttyUSB1
data=$GSM_DEVICE
imei=auto
imsi=auto
context=from-gsm
exten=s
dtmf=relax
resetdongle=yes
EOF
    
    print_success "GSM gateway configured"
    print_info "Note: Audio device set to /dev/ttyUSB1 - adjust if your modem uses a different path"
    print_info "Note: Extension set to 's' (wildcard) - calls will be routed via dialplan"
    log_message "GSM gateway configured on $GSM_DEVICE"
}

configure_dialplan() {
    print_info "Configuring Asterisk dialplan for audio bridging..."
    
    # Create dialplan for SIP-GSM bridging
    cat > "$ASTERISK_CONFIG_DIR/extensions_custom.conf" <<EOF
; SIP-GSM Bridge Dialplan
; Generated on $(date)

; Context for incoming SIP calls
[from-sip]
exten => _X.,1,NoOp(Incoming SIP call from \${CALLERID(num)})
same => n,Set(CALLERID(name)=SIP-\${CALLERID(num)})
same => n,Dial(Dongle/gsm0/\${EXTEN},60,tT)
same => n,Hangup()

; Context for incoming GSM calls
[from-gsm]
exten => _X.,1,NoOp(Incoming GSM call from \${CALLERID(num)})
same => n,Set(CALLERID(name)=GSM-\${CALLERID(num)})
same => n,Dial(SIP/sip-trunk/\${EXTEN},60,tT)
same => n,Hangup()

; Default context
[default]
exten => _X.,1,NoOp(Default context - routing to bridge)
same => n,Goto(from-sip,\${EXTEN},1)
EOF
    
    print_success "Dialplan configured for audio bridging"
    log_message "Asterisk dialplan configured"
}

configure_all() {
    print_info "Starting complete configuration..."
    configure_sip
    configure_gsm
    configure_dialplan
    save_config
    print_success "Configuration completed"
}

#########################################################################
# Service Management Functions
#########################################################################

start_service() {
    print_info "Starting SIP-GSM bridge service..."
    
    # Start Asterisk
    systemctl start asterisk
    systemctl enable asterisk
    
    # Initialize GSM modem
    print_info "Initializing GSM modem..."
    if ! gammu identify 2>&1 | tee -a "$LOG_FILE"; then
        print_warning "GSM modem initialization failed"
        print_info "Troubleshooting steps:"
        print_info "  1. Check USB connection: lsusb"
        print_info "  2. Verify device path: ls -l /dev/ttyUSB*"
        print_info "  3. Try USB mode switch: usb_modeswitch"
        print_info "  4. Check logs: tail -f $LOG_FILE"
    fi
    
    # Save PID
    pidof asterisk > "$PID_FILE" 2>/dev/null || true
    
    print_success "SIP-GSM bridge service started"
    log_message "Service started"
}

stop_service() {
    print_info "Stopping SIP-GSM bridge service..."
    
    # Stop Asterisk
    systemctl stop asterisk
    
    # Remove PID file
    rm -f "$PID_FILE"
    
    print_success "SIP-GSM bridge service stopped"
    log_message "Service stopped"
}

restart_service() {
    stop_service
    sleep 2
    start_service
}

check_status() {
    print_info "Checking SIP-GSM bridge status..."
    
    # Check Asterisk status
    if systemctl is-active --quiet asterisk; then
        print_success "Asterisk service is running"
        
        # Check SIP trunk status
        print_info "SIP Trunk Status:"
        asterisk -rx "sip show peers" 2>/dev/null | grep -A 1 "Name/username" || true
        
        # Check GSM dongle status
        print_info "GSM Dongle Status:"
        asterisk -rx "dongle show devices" 2>/dev/null || print_warning "Chan_dongle module may not be loaded"
        
        # Check active calls
        print_info "Active Calls:"
        asterisk -rx "core show channels" 2>/dev/null | tail -1
    else
        print_error "Asterisk service is not running"
    fi
    
    # Check GSM modem
    print_info "GSM Modem Status:"
    if [[ -e "$GSM_DEVICE" ]]; then
        print_success "GSM device $GSM_DEVICE found"
        gammu identify 2>&1 | head -5 || print_warning "Could not query GSM modem"
    else
        print_error "GSM device $GSM_DEVICE not found"
    fi
}

#########################################################################
# Testing Functions
#########################################################################

test_sip() {
    print_info "Testing SIP connectivity..."
    
    if [[ -z "$SIP_SERVER" ]]; then
        print_error "SIP server not configured"
        return 1
    fi
    
    # Test SIP server connectivity
    nc -zv "$SIP_SERVER" "$SIP_PORT" 2>&1 | grep -q succeeded && \
        print_success "SIP server $SIP_SERVER:$SIP_PORT is reachable" || \
        print_error "Cannot reach SIP server $SIP_SERVER:$SIP_PORT"
    
    # Check SIP registration
    if systemctl is-active --quiet asterisk; then
        asterisk -rx "sip show registry" 2>/dev/null
    fi
}

test_gsm() {
    print_info "Testing GSM modem..."
    
    # Check device
    if [[ ! -e "$GSM_DEVICE" ]]; then
        print_error "GSM device $GSM_DEVICE not found"
        return 1
    fi
    
    # Test with gammu
    print_info "Querying GSM modem information..."
    gammu identify || print_error "Failed to communicate with GSM modem"
    
    # Check signal strength
    print_info "Checking signal strength..."
    gammu getsignalquality || print_warning "Could not get signal quality"
    
    # Check network registration
    print_info "Checking network registration..."
    gammu getnetworkinfo || print_warning "Could not get network info"
}

test_all() {
    print_info "Running comprehensive tests..."
    echo
    test_sip
    echo
    test_gsm
    echo
    print_info "Test completed"
}

#########################################################################
# Help Function
#########################################################################

show_help() {
    cat <<EOF

SIP-GSM Audio Bridge Script
============================

This script bridges audio between SIP and GSM calls using Asterisk PBX.

USAGE:
    $0 [command] [options]

COMMANDS:
    install         Install required dependencies (Asterisk, gammu, etc.)
    configure       Configure SIP and GSM settings interactively
    start           Start the audio bridge service
    stop            Stop the audio bridge service
    restart         Restart the audio bridge service
    status          Check service status and connectivity
    test            Test SIP and GSM connectivity
    help            Display this help message

EXAMPLES:
    # Initial setup
    sudo $0 install
    sudo $0 configure
    sudo $0 start

    # Check status
    sudo $0 status

    # Test connectivity
    sudo $0 test

CONFIGURATION:
    Configuration is stored in: $CONFIG_FILE
    Logs are written to: $LOG_FILE

IMPLEMENTATION DETAILS:
    1. SIP Connectivity:
       - Uses Asterisk PBX for SIP protocol handling
       - Configures SIP trunk for outbound/inbound calls
       - Supports standard SIP codecs (ulaw, alaw, gsm)

    2. GSM Connectivity:
       - Uses chan_dongle/gammu for GSM modem communication
       - Supports USB GSM modems via serial interface
       - Handles GSM audio through standard AT commands

    3. Audio Bridging:
       - Asterisk dialplan routes calls between SIP and GSM
       - Audio codecs are transcoded as needed
       - Call control (answer, hangup, hold) is managed by Asterisk

    4. Architecture:
       [SIP Client] <--SIP--> [Asterisk PBX] <--AT Commands--> [GSM Modem] <--GSM--> [Mobile Network]
                               (Audio Bridge)

REQUIREMENTS:
    - Root/sudo access
    - Asterisk PBX
    - GSM modem with USB serial interface
    - gammu/chan_dongle for GSM communication
    - Active SIP account and GSM SIM card

For more information, check the log file: $LOG_FILE

EOF
}

#########################################################################
# Main Function
#########################################################################

main() {
    # Create log directory
    mkdir -p "$(dirname "$LOG_FILE")"
    
    # Load configuration
    load_config
    
    # Parse command
    case "${1:-help}" in
        install)
            check_root
            install_dependencies
            ;;
        configure)
            check_root
            configure_all
            ;;
        start)
            check_root
            start_service
            ;;
        stop)
            check_root
            stop_service
            ;;
        restart)
            check_root
            restart_service
            ;;
        status)
            check_root
            check_status
            ;;
        test)
            check_root
            test_all
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Execute main function
main "$@"
