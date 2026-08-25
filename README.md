# Advanced Searcher

A production-ready WHM (Web Host Manager) plugin that provides advanced search and lookup capabilities for cPanel/WHM servers. This plugin allows root administrators to quickly search for domains, accounts, resellers, packages, and IP addresses with detailed ownership and hierarchy information.

## Features

- **Domain Search**: Find which cPanel account owns any domain, including domain type detection (primary, addon, alias, subdomain)
- **Account Search**: Look up cPanel accounts by username with full domain listings
- **Reseller Search**: View reseller information and all associated accounts
- **Package Search**: Find all accounts using a specific hosting package
- **IP Search**: Locate all accounts/domains on a specific IP address
- **Account Hierarchy**: Visual display of ownership chain (Domain → Account → Reseller → Package → Server)
- **Web Interface**: Professional WHM-integrated UI with responsive design
- **CLI Tool**: Command-line interface for server administrators
- **Security**: Root-only access by default, input sanitization, rate limiting
- **Performance**: Efficient cPanel API usage with caching support
- **Diagnostics**: Built-in system diagnostics and status checking

## Requirements

- cPanel/WHM 11.x or later
- Root access to the server
- Perl 5.x with core modules (no external dependencies required)
- Linux-based operating system (CentOS, AlmaLinux, Rocky Linux, Debian, etc.)

### Perl Dependencies

The plugin uses only core Perl modules for maximum portability:
- **JSON::PP** - Included with Perl 5.14+ (no installation needed)
- **No external dependencies** - Does not require CGI.pm, HTML::Entities, or File::Path

This ensures the plugin works on any modern cPanel server without additional package installation.

## Installation

### Quick Installation

```bash
# Download and run the installer
curl -fsSL https://raw.githubusercontent.com/tasinamin121/advanced-searcher/main/install.sh | bash
```

### Manual Installation

```bash
# Download the plugin
git clone https://github.com/tasinamin121/advanced-searcher.git
cd advanced-searcher

# Run the installer
bash install.sh
```

### Installation Steps

The installer performs the following:

1. Checks for root access
2. Detects cPanel/WHM installation and version
3. Detects OS and architecture
4. Checks and installs missing dependencies
5. Creates plugin directories
6. Copies plugin files
7. Registers the plugin in WHM
8. Sets correct ownership and permissions
9. Reloads required cPanel services
10. Verifies installation

### Installation Output

```
========================================
 Advanced Searcher Installer
========================================

[✓] Root access detected
[✓] cPanel detected
[✓] OS detected
[✓] Dependencies verified
[✓] Installing Advanced Searcher
[✓] Registering WHM plugin
[✓] Permissions configured
[✓] Installation completed

Open WHM:
WHM → Plugins → Advanced Searcher

========================================
```

## WHM Usage

### Accessing the Plugin

1. Log in to WHM as root
2. Navigate to **Plugins** → **Advanced Searcher**

### Search Types

The plugin supports the following search types:

- **Domain**: Search for a domain name (e.g., `example.com`)
- **Username**: Search for a cPanel username (e.g., `client01`)
- **Account**: Search for a cPanel account (same as username)
- **Reseller**: Search for a reseller
- **Package**: Search for a hosting package
- **IP Address**: Search for an IP address

### Domain Search Example

Search for `example.com`:

```
Domain Information

Domain: example.com
Domain Type: PRIMARY DOMAIN
cPanel Username: client01
Account Owner: John Doe
Reseller: reseller01
Package: Premium-10GB
Account Status: ACTIVE
Main Domain: example.com
IP Address: 139.99.123.63
Home Directory: /home/client01
Created: 2026-08-20

Account Hierarchy
=================
example.com
  ↓
client01
  ↓
reseller01
  ↓
Premium-10GB
  ↓
139.99.123.63
```

### Account Search Example

Search for username `client01`:

```
Account Information

Username: client01
Main Domain: example.com
Reseller: reseller01
Package: Premium-10GB
Status: ACTIVE
IP: 139.99.123.63
Home Directory: /home/client01

Domains
=======
1. example.com - PRIMARY DOMAIN
2. shop.example.com - ADDON DOMAIN
3. blog.example.com - SUBDOMAIN
```

## CLI Usage

The plugin includes a command-line tool for server administrators.

### Basic Commands

```bash
# Display version
advanced-searcher --version

# Display status
advanced-searcher --status

# Run diagnostics
advanced-searcher --diagnose

# Search for a domain
advanced-searcher --search example.com

# Search for a username
advanced-searcher --search client01 --type username

# Search for a reseller
advanced-searcher --search reseller01 --type reseller

# Search with JSON output
advanced-searcher --search example.com --json
```

### CLI Help

```bash
advanced-searcher --help
```

## Configuration

### Configuration File

The plugin configuration is stored in `/etc/advanced-searcher/config.conf`.

### Default Configuration

```ini
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

# UI Settings
results_per_page=50
enable_autocomplete=true
max_autocomplete_suggestions=10
```

### Configuration Options

- `root_only`: Only allow root access (default: true)
- `max_results`: Maximum number of results per search (default: 100)
- `enable_cache`: Enable search result caching (default: true)
- `cache_ttl`: Cache time-to-live in seconds (default: 3600)
- `log_level`: Logging level (debug, info, warning, error, critical)
- `enable_debug`: Enable debug mode (default: false)
- `check_updates`: Check for plugin updates (default: false)
- `update_check_interval`: Update check interval in seconds (default: 86400)
- `enable_rate_limiting`: Enable API rate limiting (default: true)
- `rate_limit_per_minute`: Maximum requests per minute (default: 60)
- `results_per_page`: Results per page in web interface (default: 50)
- `enable_autocomplete`: Enable autocomplete suggestions (default: true)
- `max_autocomplete_suggestions`: Maximum autocomplete suggestions (default: 10)

## Updating

### Update to Latest Version

```bash
cd /path/to/advanced-searcher
bash update.sh
```

### Update to Specific Version

```bash
bash update.sh --version 1.0.0
```

## Uninstallation

### Standard Uninstallation

```bash
cd /path/to/advanced-searcher
bash uninstall.sh
```

### Force Uninstallation (No Confirmation)

```bash
bash uninstall.sh --yes
```

The uninstaller will:
- Unregister the WHM plugin
- Remove plugin files
- Remove configuration files
- Remove log files
- Remove CLI tool
- Remove cron jobs
- Remove temporary files

**Important**: The uninstaller will NOT:
- Delete or modify cPanel accounts
- Modify DNS zones
- Modify packages
- Modify reseller accounts

## File Locations

### Plugin Files
- WHM Interface: `/usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/`
- CLI Tool: `/usr/local/bin/advanced-searcher`
- Configuration: `/etc/advanced-searcher/`
- Logs: `/var/log/advanced-searcher/`

### Important Files
- Main Config: `/etc/advanced-searcher/config.conf`
- Plugin Log: `/var/log/advanced-searcher/plugin.log`
- Version File: `/usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/VERSION`

## Security

### Security Features

- **Root-Only Access**: By default, only root users can access the plugin
- **Input Sanitization**: All user input is sanitized to prevent injection attacks
- **Rate Limiting**: API requests are rate-limited to prevent abuse
- **CSRF Protection**: Built-in CSRF token validation
- **XSS Prevention**: HTML output is properly escaped
- **Secure Permissions**: Files use secure ownership and permissions
- **No External Telemetry**: No data is sent to external servers
- **No Credential Storage**: No passwords or credentials are stored

### Security Best Practices

1. Keep the plugin updated to the latest version
2. Review configuration settings regularly
3. Monitor log files for suspicious activity
4. Ensure root access is properly secured
5. Use firewall rules to restrict access if needed

## Troubleshooting

### Installation Issues

**Problem**: Installation fails with "cPanel not detected"
- **Solution**: Ensure cPanel/WHM is properly installed and accessible

**Problem**: Installation fails with "Missing dependencies"
- **Solution**: The installer should auto-install dependencies. If it fails, manually install Perl and required modules

**Problem**: Plugin doesn't appear in WHM
- **Solution**: Check that the installation completed successfully and try reloading WHM

### Search Issues

**Problem**: Search returns no results
- **Solution**: Verify the search term is correct and the account/domain exists on the server

**Problem**: Search is slow
- **Solution**: Enable caching in configuration or check server performance

**Problem**: API errors in logs
- **Solution**: Check cPanel API availability and ensure proper permissions

### Permission Issues

**Problem**: "Access denied" error
- **Solution**: Ensure you're running as root when using CLI or accessing WHM as root

**Problem**: Permission errors in logs
- **Solution**: Run the installer again to fix permissions: `bash install.sh`

### Log Analysis

View plugin logs:

```bash
tail -f /var/log/advanced-searcher/plugin.log
```

## Diagnostics

Run built-in diagnostics:

```bash
# Via CLI
advanced-searcher --diagnose

# Via WHM
# Navigate to Advanced Searcher → Diagnostics
```

Diagnostics check:
- Plugin version and installation status
- cPanel version and API availability
- OS information
- Plugin permissions
- Configuration status
- Log directory status

## Supported cPanel Versions

- cPanel/WHM 11.x
- cPanel/WHM 100+ (latest versions)

The plugin uses official cPanel APIs and is designed to work across modern cPanel versions.

## Development

### Project Structure

```
advanced-searcher/
├── install.sh              # Installation script
├── uninstall.sh            # Uninstallation script
├── update.sh               # Update script
├── README.md               # This file
├── LICENSE                 # MIT License
├── VERSION                 # Version file
├── bin/
│   └── advanced-searcher   # CLI tool
├── whm/
│   ├── index.cgi           # Main WHM interface
│   ├── api.cgi             # API endpoint
│   ├── assets/
│   │   ├── css/style.css   # Styles
│   │   └── js/main.js      # JavaScript
│   └── templates/          # HTML templates
├── lib/
│   └── AdvancedSearcher/   # Perl modules
│       ├── CpanelAPI.pm
│       ├── Security.pm
│       ├── Logger.pm
│       ├── Config.pm
│       └── DomainTypeDetector.pm
├── config/
│   └── config.example.conf # Example configuration
└── logs/                   # Log directory (created during install)
```

## Contributing

Contributions are welcome! Please ensure:

1. Code follows existing style and conventions
2. Security best practices are maintained
3. Documentation is updated
4. Changes are tested on modern cPanel versions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues, questions, or contributions:

- GitHub Issues: https://github.com/tasinamin121/advanced-searcher/issues
- Documentation: https://github.com/tasinamin121/advanced-searcher/wiki

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and changes.

## Credits

Developed for the cPanel/WHM community to provide advanced search capabilities for server administrators.

## Disclaimer

This plugin is provided as-is without warranty. Users should test thoroughly in development environments before production use. Always maintain proper backups before installing or updating system software.