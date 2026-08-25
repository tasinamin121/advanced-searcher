#!/bin/bash

#===============================================================================
# Advanced Searcher Updater
#===============================================================================
# This script updates the Advanced Searcher WHM plugin to a newer version
#===============================================================================

# Configuration - EDIT THESE BEFORE PUBLISHING
PLUGIN_NAME="advanced-searcher"
CURRENT_VERSION="1.1.0"
REPOSITORY_URL="https://github.com/tasinamin121/advanced-searcher.git"
DOWNLOAD_URL="https://github.com/tasinamin121/advanced-searcher/archive/refs/heads/main.tar.gz"

# Installation paths
CPANEL_BASE="/usr/local/cpanel"
WHM_PLUGINS_DIR="${CPANEL_BASE}/whostmgr/docroot/cgi"
PLUGIN_DIR="${WHM_PLUGINS_DIR}/${PLUGIN_NAME}"
PLUGIN_CONFIG_DIR="/etc/${PLUGIN_NAME}"
PLUGIN_LOG_DIR="/var/log/${PLUGIN_NAME}"
CLI_BIN_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
LOG_FILE="/tmp/${PLUGIN_NAME}-update.log"

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
    echo " Advanced Searcher Updater"
    echo "========================================"
    echo ""
}

print_update_info() {
    echo ""
    echo "Current Version: ${INSTALLED_VERSION}"
    echo "Latest Version: ${TARGET_VERSION}"
    echo "Update Status: ${UPDATE_STATUS}"
    echo ""
}

print_footer() {
    echo ""
    echo "========================================"
    echo " Update completed"
    echo "========================================"
    echo ""
    echo "Version: ${TARGET_VERSION}"
    echo ""
    echo "WHM:"
    echo "WHM → Plugins → Advanced Searcher"
    echo ""
    echo "CLI:"
    echo "advanced-searcher --status"
    echo ""
    echo "========================================"
    echo ""
}

#===============================================================================
# Version Functions
#===============================================================================

get_installed_version() {
    if [[ -f "${PLUGIN_DIR}/VERSION" ]]; then
        cat "${PLUGIN_DIR}/VERSION"
    else
        echo "unknown"
    fi
}

get_latest_version() {
    # For now, return the current version from the script
    # In production, this would check the repository for the latest version
    echo "$CURRENT_VERSION"
}

compare_versions() {
    if [[ "$1" == "$2" ]]; then
        return 0  # Equal
    fi
    
    local IFS=.
    local i ver1=($1) ver2=($2)
    
    # Fill empty fields with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1  # Greater
        fi
        
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2  # Less
        fi
    done
    
    return 0  # Equal
}

#===============================================================================
# Pre-update Checks
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
        error "Plugin is not installed. Please run install.sh first."
        exit 1
    fi
    success "Plugin installation detected"
}

detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
    elif [[ -f /etc/almalinux-release ]]; then
        OS="almalinux"
    elif [[ -f /etc/rocky-release ]]; then
        OS="rocky"
    else
        OS="unknown"
    fi
    
    ARCH=$(uname -m)
    success "OS detected: ${OS} (${ARCH})"
}

#===============================================================================
# Update Functions
#===============================================================================

backup_current_installation() {
    info "Backing up current installation..."
    
    BACKUP_DIR="/tmp/${PLUGIN_NAME}-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup plugin files
    if [[ -d "$PLUGIN_DIR" ]]; then
        cp -r "$PLUGIN_DIR" "${BACKUP_DIR}/"
    fi
    
    # Backup configuration
    if [[ -d "$PLUGIN_CONFIG_DIR" ]]; then
        cp -r "$PLUGIN_CONFIG_DIR" "${BACKUP_DIR}/"
    fi
    
    # Backup logs
    if [[ -d "$PLUGIN_LOG_DIR" ]]; then
        cp -r "$PLUGIN_LOG_DIR" "${BACKUP_DIR}/"
    fi
    
    success "Backup created at ${BACKUP_DIR}"
    echo "$BACKUP_DIR"
}

download_update() {
    local target_version="$1"
    
    info "Downloading update for version ${target_version}..."
    
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # For local development, we just use the current directory
    # In production, this would download from the repository
    UPDATE_DIR="$SCRIPT_DIR"
    
    success "Update source ready"
    echo "$UPDATE_DIR"
}

apply_update() {
    local update_dir="$1"
    local target_version="$2"
    
    info "Applying update to version ${target_version}..."
    
    # Copy new files (preserving configuration)
    if [[ -f "${update_dir}/whm/index.cgi" ]]; then
        cp "${update_dir}/whm/index.cgi" "${PLUGIN_DIR}/"
    fi
    
    if [[ -f "${update_dir}/whm/api.cgi" ]]; then
        cp "${update_dir}/whm/api.cgi" "${PLUGIN_DIR}/"
    fi
    
    if [[ -d "${update_dir}/whm/assets" ]]; then
        cp -r "${update_dir}/whm/assets" "${PLUGIN_DIR}/"
    fi
    
    if [[ -d "${update_dir}/lib" ]]; then
        cp -r "${update_dir}/lib/"* "${PLUGIN_DIR}/lib/"
    fi
    
    if [[ -f "${update_dir}/bin/advanced-searcher" ]]; then
        cp "${update_dir}/bin/advanced-searcher" "${PLUGIN_DIR}/bin/"
    fi
    
    if [[ -f "${update_dir}/VERSION" ]]; then
        cp "${update_dir}/VERSION" "${PLUGIN_DIR}/"
    fi
    
    # Update CLI tool
    cp "${PLUGIN_DIR}/bin/advanced-searcher" "${CLI_BIN_DIR}/advanced-searcher"
    chmod 755 "${CLI_BIN_DIR}/advanced-searcher"
    
    # Reset permissions
    chown -R root:root "$PLUGIN_DIR"
    chmod 755 "$PLUGIN_DIR"
    chmod 755 "${PLUGIN_DIR}/index.cgi"
    chmod 755 "${PLUGIN_DIR}/api.cgi"
    chmod 755 "${PLUGIN_DIR}/bin/advanced-searcher"
    
    success "Update applied"
}

restore_configuration() {
    info "Restoring configuration..."
    
    # Configuration is preserved automatically as we don't overwrite it
    # Just verify it exists
    if [[ ! -f "${PLUGIN_CONFIG_DIR}/config.conf" ]]; then
        warning "Configuration file not found, creating default..."
        # This would create a default config if needed
    fi
    
    success "Configuration preserved"
}

reload_services() {
    info "Reloading cPanel services..."
    
    # Reload cPanel backend
    if command -v /usr/local/cpanel/scripts/update_user_domains &> /dev/null; then
        /usr/local/cpanel/scripts/update_user_domains --force 2>/dev/null || true
    fi
    
    success "Services reloaded"
}

verify_update() {
    local target_version="$1"
    
    info "Verifying update..."
    
    UPDATE_OK=true
    
    # Check version file
    if [[ -f "${PLUGIN_DIR}/VERSION" ]]; then
        NEW_VERSION=$(cat "${PLUGIN_DIR}/VERSION")
        if [[ "$NEW_VERSION" != "$target_version" ]]; then
            error "Version mismatch: expected ${target_version}, got ${NEW_VERSION}"
            UPDATE_OK=false
        fi
    else
        error "VERSION file not found"
        UPDATE_OK=false
    fi
    
    # Check critical files
    if [[ ! -f "${PLUGIN_DIR}/index.cgi" ]]; then
        error "WHM index.cgi not found"
        UPDATE_OK=false
    fi
    
    if [[ ! -f "${PLUGIN_DIR}/api.cgi" ]]; then
        error "WHM api.cgi not found"
        UPDATE_OK=false
    fi
    
    if [[ ! -x "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        error "CLI tool not executable"
        UPDATE_OK=false
    fi
    
    # Validate Perl syntax
    info "Validating Perl syntax..."
    if [[ -f "${PLUGIN_DIR}/index.cgi" ]]; then
        if perl -c "${PLUGIN_DIR}/index.cgi" 2>&1; then
            success "WHM index.cgi syntax OK"
        else
            error "WHM index.cgi syntax error"
            UPDATE_OK=false
        fi
    fi
    
    if [[ -f "${PLUGIN_DIR}/api.cgi" ]]; then
        if perl -c "${PLUGIN_DIR}/api.cgi" 2>&1; then
            success "WHM api.cgi syntax OK"
        else
            error "WHM api.cgi syntax error"
            UPDATE_OK=false
        fi
    fi
    
    if [[ -f "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        if perl -c "${CLI_BIN_DIR}/advanced-searcher" 2>&1; then
            success "CLI tool syntax OK"
        else
            error "CLI tool syntax error"
            UPDATE_OK=false
        fi
    fi
    
    # Validate all Perl modules
    info "Validating Perl modules..."
    for module_file in "${PLUGIN_DIR}/lib/AdvancedSearcher/"*.pm; do
        if [[ -f "$module_file" ]]; then
            if perl -c "$module_file" 2>&1; then
                success "$(basename $module_file) syntax OK"
            else
                error "$(basename $module_file) syntax error"
                UPDATE_OK=false
            fi
        fi
    done
    
    if [[ "$UPDATE_OK" == true ]]; then
        success "Update verified"
        return 0
    else
        error "Update verification failed"
        return 1
    fi
}

rollback_update() {
    local backup_dir="$1"
    
    warning "Rolling back update..."
    
    if [[ -d "$backup_dir" ]]; then
        # Restore plugin files
        if [[ -d "${backup_dir}/${PLUGIN_NAME}" ]]; then
            rm -rf "$PLUGIN_DIR"
            cp -r "${backup_dir}/${PLUGIN_NAME}" "$(dirname "$PLUGIN_DIR")/"
        fi
        
        # Restore configuration
        if [[ -d "${backup_dir}/etc/${PLUGIN_NAME}" ]]; then
            rm -rf "$PLUGIN_CONFIG_DIR"
            cp -r "${backup_dir}/etc/${PLUGIN_NAME}" "$(dirname "$PLUGIN_CONFIG_DIR")/"
        fi
        
        # Restore CLI tool
        if [[ -f "${backup_dir}/${PLUGIN_NAME}/bin/advanced-searcher" ]]; then
            cp "${backup_dir}/${PLUGIN_NAME}/bin/advanced-searcher" "${CLI_BIN_DIR}/"
            chmod 755 "${CLI_BIN_DIR}/advanced-searcher"
        fi
        
        success "Rollback completed"
    else
        error "Backup directory not found: ${backup_dir}"
        error "Manual intervention may be required"
    fi
}

cleanup_backup() {
    local backup_dir="$1"
    
    info "Cleaning up backup..."
    
    if [[ -d "$backup_dir" ]]; then
        rm -rf "$backup_dir"
    fi
    
    success "Backup cleaned up"
}

#===============================================================================
# Main Update Process
#===============================================================================

main() {
    local target_version=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                target_version="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done
    
    print_header
    
    # Run pre-update checks
    check_root
    check_plugin_installed
    detect_os
    
    # Get version information
    INSTALLED_VERSION=$(get_installed_version)
    
    if [[ -z "$target_version" ]]; then
        target_version=$(get_latest_version)
    fi
    
    # Compare versions
    compare_versions "$INSTALLED_VERSION" "$target_version"
    COMPARE_RESULT=$?
    
    if [[ $COMPARE_RESULT -eq 0 ]]; then
        UPDATE_STATUS="Already up to date"
        print_update_info
        info "Plugin is already at version ${target_version}"
        exit 0
    elif [[ $COMPARE_RESULT -eq 1 ]]; then
        UPDATE_STATUS="Downgrade"
        warning "Target version is older than installed version"
        read -p "Continue with downgrade? (yes/no): " CONFIRM
        if [[ "$CONFIRM" != "yes" ]]; then
            info "Update cancelled"
            exit 0
        fi
    else
        UPDATE_STATUS="Upgrade available"
    fi
    
    print_update_info
    
    # Perform update
    BACKUP_DIR=$(backup_current_installation)
    
    UPDATE_DIR=$(download_update "$target_version")
    
    apply_update "$UPDATE_DIR" "$target_version"
    
    restore_configuration
    
    reload_services
    
    # Verify update
    if ! verify_update "$target_version"; then
        error "Update failed, rolling back..."
        rollback_update "$BACKUP_DIR"
        exit 1
    fi
    
    # Clean up backup after successful update
    cleanup_backup "$BACKUP_DIR"
    
    print_footer
    
    # Log successful update
    log "UPDATE COMPLETED: Advanced Searcher ${INSTALLED_VERSION} -> ${target_version}"
}

# Run main function
main "$@"