# Changelog

All notable changes to the Advanced Searcher WHM plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned Features
- Enhanced caching mechanisms
- Advanced filtering options
- Export functionality for search results
- Integration with cPanel's native search
- Multi-language support

## [1.2.4] - 2026-08-25

### Fixed
- **CRITICAL**: Fixed file copying logic to properly separate local vs GitHub installation paths
- Ensured GitHub download path uses correct extracted directory structure
- Fixed logic flow to prevent local file checks from executing during GitHub download
- Fixed version to 1.2.4

### Installation
- Local installation now checks for whm/index.cgi and VERSION before attempting copy
- GitHub download path now correctly uses advanced-searcher-main directory
- Improved separation between local and remote installation code paths
- Better error messages with correct path information

## [1.2.3] - 2026-08-25

### Fixed
- **CRITICAL**: Added comprehensive extraction debugging to diagnose tarball structure
- Added listing of temp directory contents after extraction
- Added full directory tree listing of extracted directory
- Added file search for .cgi files if standard structure not found
- Fixed version to 1.2.3

### Installation
- Shows detailed extraction debugging information
- Lists all files in extracted directory before copying
- Better error messages when file structure is unexpected
- Uses maxdepth 1 to find extracted directory to avoid recursion issues

## [1.2.2] - 2026-08-25

### Fixed
- **CRITICAL**: Fixed tarball extraction to correctly locate files
- Added directory tree listing for debugging extraction issues
- Added better source directory detection logic
- Added detailed logging of extracted directory contents
- Fixed version to 1.2.2

### Installation
- Now correctly finds and copies files from GitHub tarball
- Shows detailed extraction debugging information
- Better error messages when file structure is unexpected

## [1.2.1] - 2026-08-25

### Fixed
- **CRITICAL**: Fixed AppConfig name validation - changed from "Advanced Searcher" to "advanced_searcher"
- cPanel requires app names to contain only letters, numbers, hyphens, and underscores
- Fixed file copying to download from GitHub when running via curl pipe
- Added detailed logging for file copying process
- Added fallback to download from GitHub when local files not found
- Fixed version to 1.2.1

### Installation
- Now works correctly when installed via: curl -fsSL URL | bash
- Downloads plugin from GitHub when running from pipe
- Validates all files exist before installation
- Shows detailed progress for file copying

## [1.2.0] - 2026-08-25

### Fixed
- **CRITICAL**: Fixed AppConfig registration format to use correct flat key=value format
- Changed from YAML format to cPanel-compatible key=value format
- Fixed WHM CGI module paths to use absolute paths from plugin directory
- Fixed installation structure to place files directly in plugin directory
- Fixed installation verification to check actual installed files at correct paths
- Fixed uninstall.sh to properly remove AppConfig configuration
- Fixed update.sh to use correct file paths and verification
- Fixed asset path references in index.cgi to use dynamic base URL
- Added AppConfig registration verification with detailed output
- Added Perl module syntax validation to installation verification

### Changed
- Plugin files now installed directly to /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
- Library path changed from ../../lib to ./lib in CGI scripts
- AppConfig configuration now uses service=whostmgr, acls=all format
- Installation verification now validates all Perl modules individually
- Error page now uses dynamic asset path instead of hardcoded /plugins/ path

### Installation
- AppConfig URL: /cgi/advanced-searcher/index.cgi
- Plugin directory: /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
- Library directory: /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/lib/
- CLI path: /usr/local/bin/advanced-searcher
- AppConfig config: /var/cpanel/apps/advanced-searcher.conf

## [1.1.0] - 2026-08-25

### Changed
- **CRITICAL**: Removed dependency on CGI.pm to improve portability
- Implemented lightweight CGI-compatible module (CGICompat.pm) using core Perl
- Removed dependency on HTML::Entities, implemented custom HTML escaping
- Removed dependency on File::Path, implemented custom directory creation
- Modified all search modules to load CpanelAPI on-demand to avoid circular dependencies
- Made cPanel-specific module loading conditional using eval/require for better compatibility

### Fixed
- Fixed syntax errors when running outside of cPanel environment
- Fixed circular dependency issues between search modules and CpanelAPI
- Fixed missing module errors on systems without CGI.pm installed
- Improved error handling with custom error handlers in CGI scripts

### Security
- Maintained all security features while removing external dependencies
- Input sanitization still enforced
- HTML escaping still implemented (now custom implementation)
- Root-only access still enforced

### Compatibility
- Now compatible with systems that have only core Perl modules
- No longer requires CGI.pm, HTML::Entities, or File::Path
- Gracefully handles environments without cPanel installed
- Uses JSON::PP (included with modern Perl) instead of external JSON.pm

## [1.0.0] - 2026-08-25

### Added
- Initial release of Advanced Searcher WHM plugin
- Domain search with domain type detection (primary, addon, alias, subdomain)
- Account search by username with full domain listings
- Reseller search with account listings
- Package search to find all accounts using a specific package
- IP address search to find accounts on specific IPs
- Visual account hierarchy display
- Professional WHM-integrated web interface
- Command-line interface (CLI) tool
- Security features (root-only access, input sanitization, rate limiting)
- Configuration system with customizable settings
- Logging system with multiple log levels
- System diagnostics functionality
- Autocomplete suggestions for searches
- Responsive web design
- Installation script with dependency checking
- Uninstallation script with confirmation
- Update script with version management
- Comprehensive documentation

### Security
- Root-only access by default
- Input sanitization to prevent injection attacks
- Rate limiting for API requests
- CSRF protection
- XSS prevention
- Secure file permissions
- No external telemetry or data collection
- No credential storage

### Performance
- Efficient cPanel API usage
- Caching support for search results
- Optimized search algorithms
- Pagination for large result sets

### Documentation
- Comprehensive README with installation instructions
- CLI usage documentation
- Configuration reference
- Troubleshooting guide
- Security best practices

## [0.1.0] - 2026-08-20

### Added
- Initial development version
- Basic domain search functionality
- Basic WHM interface
- Installation framework

---

## Version Format

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality in a backwards compatible manner
- **PATCH**: Backwards compatible bug fixes

## Categories

- **Added**: New features
- **Changed**: Changes in existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security vulnerabilities or improvements