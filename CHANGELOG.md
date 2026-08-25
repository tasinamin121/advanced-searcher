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