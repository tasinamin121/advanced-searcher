#!/bin/bash

#===============================================================================
# Advanced Searcher Uninstaller
#===============================================================================
# This script removes the Advanced Searcher WHM plugin
#===============================================================================

# Configuration
PLUGIN_NAME="advanced-searcher"
CPANEL_BASE="/usr/local/cpanel"
WHM_PLUGINS_DIR="${CPANEL_BASE}/whostmgr/docroot/cgi"
PLUGIN_DIR="${WHM_PLUGINS_DIR}/${PLUGIN_NAME}"
PLUGIN_CONFIG_DIR="/etc/${PLUGIN_NAME}"
PLUGIN_LOG_DIR="/var/log/${PLUGIN_NAME}"
CLI_BIN_DIR="/usr/local/bin"
REPOSITORY_URL="https://github.com/tasinamin121/advanced-searcher.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/tmp/${PLUGIN_NAME}-uninstall.log"

#===============================================================================
# Utility Functions
#===============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log "INFO: $1"
}

success() {
    echo -e "${GREEN}[OK]${NC} $1"
    log "SUCCESS: $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log "WARNING: $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log "ERROR: $1"
}

print_header() {
    echo ""
    echo "========================================"
    echo " Advanced Searcher Uninstaller"
    echo "========================================"
    echo ""
}

print_footer() {
    echo ""
    echo "========================================"
    echo " Uninstallation completed"
    echo "========================================"
    echo ""
}

#===============================================================================
# Safety Checks
#===============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
    success "Root access detected"
}

check_plugin_installed() {
    if [[ ! -d "$PLUGIN_DIR" ]]; then
        error "Plugin is not installed"
        exit 1
    fi
    
    if [[ -f "${PLUGIN_DIR}/VERSION" ]]; then
        INSTALLED_VERSION=$(cat "${PLUGIN_DIR}/VERSION")
        info "Installed version: ${INSTALLED_VERSION}"
    fi
    
    success "Plugin installation detected"
}

#===============================================================================
# Uninstallation Functions
#===============================================================================

confirm_uninstall() {
    # Check for --yes flag
    if [[ "$1" == "--yes" ]]; then
        info "Uninstalling without confirmation (--yes flag provided)"
        return 0
    fi
    
    echo ""
    warning "This will completely remove the Advanced Searcher plugin."
    echo "The following will be removed:"
    echo "  - Plugin files from ${PLUGIN_DIR}"
    echo "  - Configuration from ${PLUGIN_CONFIG_DIR}"
    echo "  - Logs from ${PLUGIN_LOG_DIR}"
    echo "  - CLI tool from ${CLI_BIN_DIR}/advanced-searcher"
    echo ""
    echo "This will NOT:"
    echo "  - Delete or modify cPanel accounts"
    echo "  - Modify DNS zones"
    echo "  - Modify packages"
    echo "  - Modify reseller accounts"
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " CONFIRM
    
    if [[ "$CONFIRM" != "yes" ]]; then
        info "Uninstallation cancelled"
        exit 0
    fi
    
    success "Confirmation received"
}

unregister_plugin() {
    info "Unregistering WHM plugin from AppConfig..."
    
    # Unregister from AppConfig
    if command -v /usr/local/cpanel/bin/unregister_appconfig &> /dev/null; then
        /usr/local/cpanel/bin/unregister_appconfig "${PLUGIN_NAME}" 2>/dev/null || true
    fi
    
    # Remove AppConfig configuration file
    if [[ -f "/var/cpanel/apps/${PLUGIN_NAME}.conf" ]]; then
        rm -f "/var/cpanel/apps/${PLUGIN_NAME}.conf"
        success "AppConfig configuration removed"
    fi
    
    # Remove old-style configuration if it exists
    if [[ -f "${CPANEL_BASE}/base/frontend/${PLUGIN_NAME}.conf" ]]; then
        rm -f "${CPANEL_BASE}/base/frontend/${PLUGIN_NAME}.conf"
    fi
    
    # Remove old-style symlink if it exists
    if [[ -L "${CPANEL_BASE}/whostmgr/docroot/cgi/addon_${PLUGIN_NAME}.cgi" ]]; then
        rm -f "${CPANEL_BASE}/whostmgr/docroot/cgi/addon_${PLUGIN_NAME}.cgi"
    fi
    
    success "WHM plugin unregistered"
}

remove_plugin_files() {
    info "Removing plugin files..."
    
    if [[ -d "$PLUGIN_DIR" ]]; then
        rm -rf "$PLUGIN_DIR"
    fi
    
    success "Plugin files removed"
}

remove_configuration() {
    info "Removing plugin configuration..."
    
    if [[ -d "$PLUGIN_CONFIG_DIR" ]]; then
        rm -rf "$PLUGIN_CONFIG_DIR"
    fi
    
    success "Configuration removed"
}

remove_logs() {
    info "Removing plugin logs..."
    
    if [[ -d "$PLUGIN_LOG_DIR" ]]; then
        rm -rf "$PLUGIN_LOG_DIR"
    fi
    
    success "Logs removed"
}

remove_cli() {
    info "Removing CLI tool..."
    
    if [[ -f "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        rm -f "${CLI_BIN_DIR}/advanced-searcher"
    fi
    
    success "CLI tool removed"
}

remove_cron_jobs() {
    info "Checking for cron jobs..."
    
    # Remove any cron jobs created by this plugin
    if command -v crontab &> /dev/null; then
        crontab -l 2>/dev/null | grep -v "${PLUGIN_NAME}" | crontab - 2>/dev/null || true
    fi
    
    success "Cron jobs checked"
}

remove_temporary_files() {
    info "Removing temporary files..."
    
    # Remove temporary files
    rm -f "/tmp/${PLUGIN_NAME}-"*
    rm -f "/tmp/${PLUGIN_NAME}.conf"
    
    success "Temporary files removed"
}

verify_removal() {
    info "Verifying removal..."
    
    REMOVAL_OK=true
    
    if [[ -d "$PLUGIN_DIR" ]]; then
        error "Plugin directory still exists"
        REMOVAL_OK=false
    fi
    
    if [[ -d "$PLUGIN_CONFIG_DIR" ]]; then
        error "Configuration directory still exists"
        REMOVAL_OK=false
    fi
    
    if [[ -f "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        error "CLI tool still exists"
        REMOVAL_OK=false
    fi
    
    if [[ "$REMOVAL_OK" == true ]]; then
        success "Removal verified"
        return 0
    else
        error "Removal verification failed"
        return 1
    fi
}

#===============================================================================
# Main Uninstallation
#===============================================================================

main() {
    print_header
    
    # Run safety checks
    check_root
    check_plugin_installed
    
    # Confirm uninstallation
    confirm_uninstall "$1"
    
    # Perform uninstallation
    unregister_plugin
    remove_plugin_files
    remove_configuration
    remove_logs
    remove_cli
    remove_cron_jobs
    remove_temporary_files
    
    # Verify removal
    if ! verify_removal; then
        error "Uninstallation failed"
        exit 1
    fi
    
    print_footer
    
    # Log successful uninstallation
    log "UNINSTALLATION COMPLETED: Advanced Searcher"
}

# Run main function
main "$@"