#!/bin/bash
# Zero-Boot Deployment Script
# Automated deployment to push configuration to OpenWrt router

set -e

# Configuration
ROUTER_IP="${ROUTER_IP:-192.168.1.1}"
ROUTER_USER="${ROUTER_USER:-root}"
ROUTER_PASSWORD="${ROUTER_PASSWORD}"
SSH_PORT="${SSH_PORT:-22}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

check_requirements() {
    print_info "Checking requirements..."
    
    if ! command -v ssh &> /dev/null; then
        print_error "ssh command not found. Please install OpenSSH client."
        exit 1
    fi
    
    if ! command -v scp &> /dev/null; then
        print_error "scp command not found. Please install OpenSSH client."
        exit 1
    fi
    
    print_success "All requirements met"
}

test_connection() {
    print_info "Testing connection to router at ${ROUTER_IP}..."
    
    if ! ping -c 1 -W 2 "${ROUTER_IP}" &> /dev/null; then
        print_error "Cannot reach router at ${ROUTER_IP}"
        print_info "Please ensure:"
        echo "  1. Router is powered on and connected"
        echo "  2. Your computer is connected to the router's LAN"
        echo "  3. Router IP is correct (default: 192.168.1.1)"
        exit 1
    fi
    
    print_success "Router is reachable"
}

backup_config() {
    print_info "Creating backup of current router configuration..."
    
    BACKUP_DIR="backups"
    BACKUP_FILE="${BACKUP_DIR}/router-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    
    mkdir -p "${BACKUP_DIR}"
    
    if ssh -p "${SSH_PORT}" "${ROUTER_USER}@${ROUTER_IP}" "sysupgrade -b /tmp/backup.tar.gz" &> /dev/null; then
        if scp -P "${SSH_PORT}" "${ROUTER_USER}@${ROUTER_IP}:/tmp/backup.tar.gz" "${BACKUP_FILE}" &> /dev/null; then
            print_success "Backup saved to ${BACKUP_FILE}"
        else
            print_warning "Could not download backup file"
        fi
    else
        print_warning "Could not create backup (continuing anyway)"
    fi
}

deploy_configuration() {
    print_info "Deploying Zero-Boot configuration..."
    
    # Copy configuration file
    print_info "Copying router configuration..."
    scp -P "${SSH_PORT}" router-config.uci "${ROUTER_USER}@${ROUTER_IP}:/tmp/" || {
        print_error "Failed to copy configuration file"
        exit 1
    }
    
    # Copy trap interface HTML
    print_info "Copying trap interface..."
    scp -P "${SSH_PORT}" trap-interface.html "${ROUTER_USER}@${ROUTER_IP}:/www/index.html" || {
        print_error "Failed to copy trap interface"
        exit 1
    }
    
    # Copy unlock script
    print_info "Copying unlock script..."
    scp -P "${SSH_PORT}" unlock-wan.sh "${ROUTER_USER}@${ROUTER_IP}:/www/cgi-bin/unlock-wan.sh" || {
        print_error "Failed to copy unlock script"
        exit 1
    }
    
    print_success "Files copied successfully"
}

apply_configuration() {
    print_info "Applying configuration to router..."
    
    ssh -p "${SSH_PORT}" "${ROUTER_USER}@${ROUTER_IP}" << 'EOF'
        # Make unlock script executable
        chmod +x /www/cgi-bin/unlock-wan.sh
        
        # Apply Zero-Boot specific configuration
        # Set WAN to disabled
        uci set network.wan.disabled='1' 2>/dev/null || true
        uci set network.wan6.disabled='1' 2>/dev/null || true
        
        # Ensure LAN-to-WAN forwarding is disabled initially
        # Find or create the forwarding rule
        FORWARD_INDEX=$(uci show firewall | grep "forwarding\[" | grep -m1 "src='lan'" | sed -n "s/.*forwarding\[\([0-9]*\)\].*/\1/p")
        if [ -n "$FORWARD_INDEX" ]; then
            uci set firewall.@forwarding[$FORWARD_INDEX].enabled='0'
        else
            # Create forwarding rule (disabled by default)
            uci add firewall forwarding
            uci set firewall.@forwarding[-1].src='lan'
            uci set firewall.@forwarding[-1].dest='wan'
            uci set firewall.@forwarding[-1].enabled='0'
        fi
        
        # Commit all changes
        uci commit network
        uci commit firewall
        
        # Restart services
        /etc/init.d/network restart
        /etc/init.d/firewall restart
        /etc/init.d/uhttpd restart
        
        echo "Configuration applied successfully"
EOF
    
    if [ $? -eq 0 ]; then
        print_success "Configuration applied successfully"
    else
        print_error "Failed to apply configuration"
        exit 1
    fi
}

show_summary() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_success "Zero-Boot deployment completed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Router Status:"
    echo "  • WAN Interface: LOCKED (disabled)"
    echo "  • Trap Interface: Active at http://${ROUTER_IP}"
    echo "  • VLAN Isolation: Enabled"
    echo "  • Default Password: unlock123 (CHANGE THIS!)"
    echo ""
    echo "Next Steps:"
    echo "  1. Open http://${ROUTER_IP} in your browser"
    echo "  2. Enter the unlock password to enable WAN"
    echo "  3. Change the default password hash in the files"
    echo ""
    print_warning "IMPORTANT: Change the default password immediately!"
    echo "  Edit 'trap-interface.html' and 'unlock-wan.sh'"
    echo "  Replace VALID_PASSWORD_HASH with your own SHA-256 hash"
    echo ""
}

generate_password_hash() {
    if [ -n "$1" ]; then
        echo -n "$1" | sha256sum | cut -d' ' -f1
    fi
}

# Main execution
main() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Zero-Boot Deployment Script"
    echo "  Router Security Configuration Tool"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --router-ip)
                ROUTER_IP="$2"
                shift 2
                ;;
            --user)
                ROUTER_USER="$2"
                shift 2
                ;;
            --port)
                SSH_PORT="$2"
                shift 2
                ;;
            --generate-hash)
                if [ -z "$2" ]; then
                    read -sp "Enter password to hash: " password
                    echo ""
                    hash=$(generate_password_hash "$password")
                else
                    hash=$(generate_password_hash "$2")
                    shift
                fi
                echo "Password hash: $hash"
                exit 0
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --router-ip IP      Router IP address (default: 192.168.1.1)"
                echo "  --user USER         SSH username (default: root)"
                echo "  --port PORT         SSH port (default: 22)"
                echo "  --generate-hash PWD Generate SHA-256 hash for password"
                echo "  --help              Show this help message"
                echo ""
                echo "Environment Variables:"
                echo "  ROUTER_IP          Router IP address"
                echo "  ROUTER_USER        SSH username"
                echo "  ROUTER_PASSWORD    SSH password"
                echo "  SSH_PORT           SSH port"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    check_requirements
    test_connection
    backup_config
    deploy_configuration
    apply_configuration
    show_summary
}

# Run main function
main "$@"
