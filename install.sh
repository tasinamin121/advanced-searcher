#!/bin/bash

#===============================================================================
# Advanced Searcher Installer
#===============================================================================
# This script installs the Advanced Searcher WHM plugin
#===============================================================================

# Configuration - EDIT THESE BEFORE PUBLISHING
PLUGIN_NAME="advanced-searcher"
PLUGIN_VERSION="1.1.0"
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
LOG_FILE="/tmp/${PLUGIN_NAME}-install.log"

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
    echo " Advanced Searcher Installer"
    echo "========================================"
    echo ""
}

print_footer() {
    echo ""
    echo "========================================"
    echo " Advanced Searcher installed successfully"
    echo "========================================"
    echo ""
    echo "Version: ${PLUGIN_VERSION}"
    echo ""
    echo "WHM:"
    echo "WHM → Plugins → Advanced Searcher"
    echo ""
    echo "CLI:"
    echo "advanced-searcher --status"
    echo ""
    echo "Documentation:"
    echo "README.md"
    echo ""
    echo "========================================"
    echo ""
}

#===============================================================================
# Pre-installation Checks
#===============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
    success "Root access detected"
}

check_cpanel() {
    if [[ ! -d "$CPANEL_BASE" ]]; then
        error "cPanel is not installed"
        exit 1
    fi
    
    if [[ ! -f "${CPANEL_BASE}/version" ]]; then
        error "Cannot determine cPanel version"
        exit 1
    fi
    
    CPANEL_VERSION=$(cat "${CPANEL_BASE}/version")
    success "cPanel detected (version ${CPANEL_VERSION})"
}

detect_os() {
    if [[ -f /etc/redhat-release ]]; then
        OS="centos"
        OS_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release 2>/dev/null || rpm -q --queryformat '%{VERSION}' redhat-release 2>/dev/null || echo "unknown")
    elif [[ -f /etc/debian_version ]]; then
        OS="debian"
        OS_VERSION=$(cat /etc/debian_version)
    elif [[ -f /etc/almalinux-release ]]; then
        OS="almalinux"
        OS_VERSION=$(rpm -q --queryformat '%{VERSION}' almalinux-release 2>/dev/null || echo "unknown")
    elif [[ -f /etc/rocky-release ]]; then
        OS="rocky"
        OS_VERSION=$(rpm -q --queryformat '%{VERSION}' rocky-release 2>/dev/null || echo "unknown")
    else
        OS="unknown"
        OS_VERSION="unknown"
    fi
    
    ARCH=$(uname -m)
    success "OS detected: ${OS} ${OS_VERSION} (${ARCH})"
}

check_dependencies() {
    MISSING_DEPS=()
    
    # Check for required commands
    for cmd in perl; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING_DEPS+=("$cmd")
        fi
    done
    
    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        warning "Missing dependencies: ${MISSING_DEPS[*]}"
        info "Installing missing dependencies..."
        
        if [[ "$OS" == "centos" ]] || [[ "$OS" == "almalinux" ]] || [[ "$OS" == "rocky" ]]; then
            yum install -y perl 2>/dev/null || dnf install -y perl 2>/dev/null
        elif [[ "$OS" == "debian" ]]; then
            apt-get update && apt-get install -y perl
        else
            error "Cannot automatically install dependencies on ${OS}"
            exit 1
        fi
        
        # Verify installation
        for cmd in "${MISSING_DEPS[@]}"; do
            if ! command -v "$cmd" &> /dev/null; then
                error "Failed to install $cmd"
                exit 1
            fi
        done
        
        success "Dependencies installed"
    else
        success "Dependencies verified"
    fi
    
    # Verify JSON::PP is available (included with modern Perl)
    info "Checking for JSON::PP module..."
    if perl -MJSON::PP -e 'print "JSON::PP available\n"' 2>/dev/null; then
        success "JSON::PP module available"
    else
        error "JSON::PP module not found. This should be included with modern Perl."
        exit 1
    fi
}

#===============================================================================
# Installation Functions
#===============================================================================

create_directories() {
    info "Creating plugin directories..."
    
    mkdir -p "$PLUGIN_DIR"
    mkdir -p "$PLUGIN_CONFIG_DIR"
    mkdir -p "$PLUGIN_LOG_DIR"
    mkdir -p "${PLUGIN_DIR}/whm/assets/css"
    mkdir -p "${PLUGIN_DIR}/whm/assets/js"
    mkdir -p "${PLUGIN_DIR}/whm/templates"
    mkdir -p "${PLUGIN_DIR}/lib/AdvancedSearcher"
    mkdir -p "${PLUGIN_DIR}/bin"
    
    success "Directories created"
}

copy_files() {
    info "Copying plugin files..."
    
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Copy WHM files
    if [[ -d "${SCRIPT_DIR}/whm" ]]; then
        cp -r "${SCRIPT_DIR}/whm/"* "${PLUGIN_DIR}/whm/"
    fi
    
    # Copy library files
    if [[ -d "${SCRIPT_DIR}/lib" ]]; then
        cp -r "${SCRIPT_DIR}/lib/"* "${PLUGIN_DIR}/lib/"
    fi
    
    # Copy AdvancedSearcher modules
    if [[ -d "${SCRIPT_DIR}/lib/AdvancedSearcher" ]]; then
        cp -r "${SCRIPT_DIR}/lib/AdvancedSearcher/"* "${PLUGIN_DIR}/lib/AdvancedSearcher/"
    fi
    
    # Copy CLI binary
    if [[ -f "${SCRIPT_DIR}/bin/advanced-searcher" ]]; then
        cp "${SCRIPT_DIR}/bin/advanced-searcher" "${PLUGIN_DIR}/bin/"
    fi
    
    # Copy version file
    if [[ -f "${SCRIPT_DIR}/VERSION" ]]; then
        cp "${SCRIPT_DIR}/VERSION" "${PLUGIN_DIR}/"
    fi
    
    success "Files copied"
}

install_cli() {
    info "Installing CLI tool..."
    
    cp "${PLUGIN_DIR}/bin/advanced-searcher" "${CLI_BIN_DIR}/advanced-searcher"
    chmod 755 "${CLI_BIN_DIR}/advanced-searcher"
    
    success "CLI tool installed"
}

register_plugin() {
    info "Registering WHM plugin with AppConfig..."
    
    # Ensure apps directory exists
    mkdir -p "/var/cpanel/apps"
    chmod 755 "/var/cpanel/apps"
    
    # Create AppConfig configuration file
    cat > "/tmp/${PLUGIN_NAME}.conf" <<EOF
advanced_searcher:
  name: Advanced Searcher
  description: Search domains, accounts, resellers, packages and IP addresses
  version: ${PLUGIN_VERSION}
  url: /cgi/${PLUGIN_NAME}/index.cgi
  icon: paper-plane
  display_name: Advanced Searcher
  acls:
    -
      acl: all
      required: 1
  feature:
    feature: advanced_searcher
    display_name: Advanced Searcher
    description: Advanced search functionality
  type: link
  order: 100
EOF
    
    # Register with AppConfig
    if command -v /usr/local/cpanel/bin/register_appconfig &> /dev/null; then
        /usr/local/cpanel/bin/register_appconfig "/tmp/${PLUGIN_NAME}.conf"
        if [[ $? -eq 0 ]]; then
            success "WHM plugin registered with AppConfig"
        else
            error "AppConfig registration failed"
            return 1
        fi
    else
        error "register_appconfig command not found"
        return 1
    fi
    
    # Clean up temp file
    rm -f "/tmp/${PLUGIN_NAME}.conf"
}

set_permissions() {
    info "Setting permissions..."
    
    # Set ownership
    chown -R root:root "$PLUGIN_DIR"
    chown -R root:root "$PLUGIN_CONFIG_DIR"
    chown -R root:root "$PLUGIN_LOG_DIR"
    
    # Set permissions
    chmod 755 "$PLUGIN_DIR"
    chmod 755 "${PLUGIN_DIR}/whm"
    chmod 755 "${PLUGIN_DIR}/whm/index.cgi"
    chmod 755 "${PLUGIN_DIR}/whm/api.cgi"
    chmod 755 "${PLUGIN_DIR}/bin/advanced-searcher"
    chmod 644 "${PLUGIN_DIR}/whm/assets/css"/*
    chmod 644 "${PLUGIN_DIR}/whm/assets/js"/*
    chmod 644 "${PLUGIN_DIR}/whm/templates"/*
    chmod 644 "${PLUGIN_DIR}/lib/AdvancedSearcher/"*
    chmod 755 "${PLUGIN_DIR}/lib/AdvancedSearcher"
    
    chmod 700 "$PLUGIN_CONFIG_DIR"
    chmod 700 "$PLUGIN_LOG_DIR"
    
    success "Permissions configured"
}

create_default_config() {
    info "Creating default configuration..."
    
    if [[ ! -f "${PLUGIN_CONFIG_DIR}/config.conf" ]]; then
        cat > "${PLUGIN_CONFIG_DIR}/config.conf" <<EOF
# Advanced Searcher Configuration
# Generated by installer

# Access Control
root_only=true

# Search Settings
max_results=100
enable_cache=true
cache_ttl=3600

# Logging
log_level=info
enable_debug=false

# Update Checking
check_updates=false
update_check_interval=86400

# Security
enable_rate_limiting=true
rate_limit_per_minute=60
EOF
        success "Default configuration created"
    else
        info "Configuration already exists, preserving"
    fi
}

reload_services() {
    info "Reloading cPanel services..."
    
    # Reload cPanel backend
    if command -v /usr/local/cpanel/scripts/update_user_domains &> /dev/null; then
        /usr/local/cpanel/scripts/update_user_domains --force 2>/dev/null || true
    fi
    
    success "Services reloaded"
}

verify_installation() {
    info "Verifying installation..."
    
    INSTALLATION_OK=true
    
    # Check critical files
    if [[ ! -f "${PLUGIN_DIR}/whm/index.cgi" ]]; then
        error "WHM index.cgi not found"
        INSTALLATION_OK=false
    fi
    
    if [[ ! -f "${PLUGIN_DIR}/whm/api.cgi" ]]; then
        error "WHM api.cgi not found"
        INSTALLATION_OK=false
    fi
    
    if [[ ! -x "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        error "CLI tool not executable"
        INSTALLATION_OK=false
    fi
    
    if [[ ! -f "${PLUGIN_CONFIG_DIR}/config.conf" ]]; then
        error "Configuration file not found"
        INSTALLATION_OK=false
    fi
    
    # Validate Perl syntax
    info "Validating Perl syntax..."
    if [[ -f "${PLUGIN_DIR}/whm/index.cgi" ]]; then
        if perl -c "${PLUGIN_DIR}/whm/index.cgi" 2>/dev/null; then
            success "WHM index.cgi syntax OK"
        else
            error "WHM index.cgi syntax error"
            INSTALLATION_OK=false
        fi
    fi
    
    if [[ -f "${PLUGIN_DIR}/whm/api.cgi" ]]; then
        if perl -c "${PLUGIN_DIR}/whm/api.cgi" 2>/dev/null; then
            success "WHM api.cgi syntax OK"
        else
            error "WHM api.cgi syntax error"
            INSTALLATION_OK=false
        fi
    fi
    
    if [[ -f "${CLI_BIN_DIR}/advanced-searcher" ]]; then
        if perl -c "${CLI_BIN_DIR}/advanced-searcher" 2>/dev/null; then
            success "CLI tool syntax OK"
        else
            error "CLI tool syntax error"
            INSTALLATION_OK=false
        fi
    fi
    
    if [[ "$INSTALLATION_OK" == true ]]; then
        success "Installation verified"
        return 0
    else
        error "Installation verification failed"
        return 1
    fi
}

cleanup_failed_installation() {
    warning "Cleaning up failed installation..."
    
    rm -rf "$PLUGIN_DIR"
    rm -rf "$PLUGIN_CONFIG_DIR"
    rm -rf "$PLUGIN_LOG_DIR"
    rm -f "${CLI_BIN_DIR}/advanced-searcher"
    rm -f "/var/cpanel/apps/${PLUGIN_NAME}.conf"
    rm -f "${CPANEL_BASE}/base/frontend/${PLUGIN_NAME}.conf"
    rm -f "${CPANEL_BASE}/whostmgr/docroot/cgi/addon_${PLUGIN_NAME}.cgi"
    
    info "Cleanup completed"
}

#===============================================================================
# Upgrade Handling
#===============================================================================

check_existing_installation() {
    if [[ -f "${PLUGIN_DIR}/VERSION" ]]; then
        INSTALLED_VERSION=$(cat "${PLUGIN_DIR}/VERSION")
        info "Existing installation detected: version ${INSTALLED_VERSION}"
        return 0
    else
        return 1
    fi
}

upgrade_plugin() {
    info "Upgrading from version ${INSTALLED_VERSION} to ${PLUGIN_VERSION}..."
    
    # Backup existing configuration
    if [[ -f "${PLUGIN_CONFIG_DIR}/config.conf" ]]; then
        cp "${PLUGIN_CONFIG_DIR}/config.conf" "${PLUGIN_CONFIG_DIR}/config.conf.backup"
        info "Configuration backed up"
    fi
    
    # Copy new files (preserving config)
    copy_files
    
    # Restore configuration if needed
    if [[ -f "${PLUGIN_CONFIG_DIR}/config.conf.backup" ]]; then
        # Merge configurations (simple copy for now)
        cp "${PLUGIN_CONFIG_DIR}/config.conf.backup" "${PLUGIN_CONFIG_DIR}/config.conf"
        info "Configuration restored"
    fi
    
    # Reinstall CLI
    install_cli
    
    # Re-register plugin
    register_plugin
    
    # Reset permissions
    set_permissions
    
    success "Upgrade completed"
}

#===============================================================================
# Main Installation
#===============================================================================

main() {
    print_header
    
    # Run pre-installation checks
    check_root
    check_cpanel
    detect_os
    check_dependencies
    
    # Check for existing installation
    if check_existing_installation; then
        if [[ "$INSTALLED_VERSION" == "$PLUGIN_VERSION" ]]; then
            info "Plugin version ${PLUGIN_VERSION} is already installed"
            info "Reinstalling to ensure integrity..."
        else
            info "Upgrading existing installation"
        fi
        
        # Perform upgrade/reinstall
        upgrade_plugin
    else
        # Fresh installation
        create_directories
        copy_files
        install_cli
        register_plugin
        set_permissions
        create_default_config
    fi
    
    # Reload services
    reload_services
    
    # Verify installation
    if ! verify_installation; then
        error "Installation failed"
        cleanup_failed_installation
        exit 1
    fi
    
    print_footer
    
    # Log successful installation
    log "INSTALLATION COMPLETED: Advanced Searcher v${PLUGIN_VERSION}"
}

# Run main function
main "$@"