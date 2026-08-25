# Advanced Searcher - Installation Summary

## Quick Reference

### Installation Commands

```bash
# Download and install (from GitHub)
curl -fsSL https://raw.githubusercontent.com/tasinamin121/advanced-searcher/main/install.sh | bash

# Or manual installation
cd /path/to/advanced-searcher
bash install.sh
```

### Uninstallation Commands

```bash
cd /path/to/advanced-searcher
bash uninstall.sh

# Force uninstallation (no confirmation)
bash uninstall.sh --yes
```

### Update Commands

```bash
cd /path/to/advanced-searcher
bash update.sh

# Update to specific version
bash update.sh --version 1.0.0
```

### CLI Commands

```bash
# Display version
advanced-searcher --version

# Display status
advanced-searcher --status

# Run diagnostics
advanced-searcher --diagnose

# Search for domain
advanced-searcher --search example.com

# Search for username
advanced-searcher --search client01 --type username

# Search for reseller
advanced-searcher --search reseller01 --type reseller

# Search for package
advanced-searcher --search Premium-10GB --type package

# Search for IP
advanced-searcher --search 192.168.1.1 --type ip

# JSON output
advanced-searcher --search example.com --json
```

### WHM Access Path

```
WHM → Plugins → Advanced Searcher
```

## Complete Project Tree

```
advanced-searcher/
├── install.sh                      # Installation script
├── uninstall.sh                    # Uninstallation script
├── update.sh                       # Update script
├── README.md                       # Main documentation
├── LICENSE                         # MIT License
├── CHANGELOG.md                    # Version history
├── VERSION                         # Version file (1.0.0)
├── .gitignore                      # Git ignore rules
├── INSTALLATION_SUMMARY.md         # This file
│
├── bin/
│   └── advanced-searcher           # CLI tool (Perl)
│
├── whm/
│   ├── index.cgi                   # Main WHM interface
│   ├── api.cgi                     # API endpoint
│   ├── assets/
│   │   ├── css/
│   │   │   └── style.css           # Main stylesheet
│   │   └── js/
│   │       └── main.js             # Main JavaScript
│   └── templates/
│       ├── header.html             # HTML header template
│       └── footer.html             # HTML footer template
│
├── lib/
│   └── AdvancedSearcher/          # Perl modules
│       ├── CpanelAPI.pm            # cPanel API wrapper
│       ├── Security.pm             # Security functions
│       ├── Logger.pm               # Logging system
│       ├── Config.pm               # Configuration management
│       ├── DomainTypeDetector.pm   # Domain type detection
│       ├── DomainSearch.pm         # Domain search module
│       ├── AccountSearch.pm        # Account search module
│       ├── ResellerSearch.pm       # Reseller search module
│       ├── PackageSearch.pm        # Package search module
│       └── IPSearch.pm             # IP search module
│
├── config/
│   └── config.example.conf        # Example configuration file
│
└── logs/                           # Log directory (created during install)
```

## File Locations After Installation

```
Plugin Directory: /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
CLI Tool: /usr/local/bin/advanced-searcher
Config Directory: /etc/advanced-searcher/
Log Directory: /var/log/advanced-searcher/
Configuration File: /etc/advanced-searcher/config.conf
Log File: /var/log/advanced-searcher/plugin.log
```

## Testing Procedure

### 1. Pre-Installation Testing

```bash
# Check if running as root
whoami  # Should return "root"

# Check cPanel installation
cat /usr/local/cpanel/version

# Check OS
cat /etc/redhat-release  # or /etc/debian_version

# Check Perl installation
perl --version

# Check required Perl modules
perl -MCpanel::AcctUtils::Account -e 'print "OK\n"'
perl -MCpanel::Domains -e 'print "OK\n"'
perl -MCpanel::Reseller -e 'print "OK\n"'
```

### 2. Installation Testing

```bash
# Test fresh installation
bash install.sh

# Verify installation
ls -la /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
ls -la /usr/local/bin/advanced-searcher
ls -la /etc/advanced-searcher/
ls -la /var/log/advanced-searcher/

# Test CLI tool
advanced-searcher --version
advanced-searcher --status
advanced-searcher --diagnose
```

### 3. WHM Interface Testing

1. Log in to WHM as root
2. Navigate to Plugins → Advanced Searcher
3. Test domain search with a known domain
4. Test username search with a known account
5. Test reseller search
6. Test package search
7. Test IP search
8. Test diagnostics page
9. Verify UI responsiveness
10. Test autocomplete functionality

### 4. CLI Testing

```bash
# Test version command
advanced-searcher --version

# Test status command
advanced-searcher --status

# Test diagnostics
advanced-searcher --diagnose

# Test domain search
advanced-searcher --search example.com

# Test username search
advanced-searcher --search client01 --type username

# Test JSON output
advanced-searcher --search example.com --json

# Test invalid search (should handle gracefully)
advanced-searcher --search nonexistentdomain123.com
```

### 5. Reinstallation Testing

```bash
# Test reinstallation (should be idempotent)
bash install.sh

# Verify configuration is preserved
cat /etc/advanced-searcher/config.conf
```

### 6. Update Testing

```bash
# Test update
bash update.sh

# Test version-specific update
bash update.sh --version 1.0.0
```

### 7. Uninstallation Testing

```bash
# Test standard uninstallation
bash uninstall.sh

# Verify removal
ls /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/  # Should fail
ls /usr/local/bin/advanced-searcher  # Should fail
ls /etc/advanced-searcher/  # Should fail
ls /var/log/advanced-searcher/  # Should fail

# Reinstall for further testing
bash install.sh

# Test force uninstallation
bash uninstall.sh --yes
```

### 8. Security Testing

```bash
# Test non-root access (should fail)
su -c "/usr/local/bin/advanced-searcher --version" someuser

# Test input sanitization
advanced-searcher --search "'; DROP TABLE users; --"

# Test rate limiting (make multiple rapid requests)
for i in {1..70}; do advanced-searcher --search example.com; done
```

### 9. Configuration Testing

```bash
# Test configuration loading
cp config/config.example.conf /etc/advanced-searcher/config.conf

# Modify configuration
vim /etc/advanced-searcher/config.conf

# Test with new configuration
advanced-searcher --search example.com
```

### 10. Log Testing

```bash
# Check log file exists
ls -la /var/log/advanced-searcher/plugin.log

# View recent logs
tail -f /var/log/advanced-searcher/plugin.log

# Test log rotation
# (manual testing required)
```

## Troubleshooting Procedure

### Installation Issues

**Problem**: "Root access required"
```bash
# Solution: Run as root
sudo bash install.sh
# or
su - root
bash install.sh
```

**Problem**: "cPanel not detected"
```bash
# Solution: Verify cPanel installation
cat /usr/local/cpanel/version
# Ensure cPanel is properly installed
```

**Problem**: "Missing dependencies"
```bash
# Solution: Manually install dependencies
yum install perl python3 jq  # CentOS/RHEL
# or
apt-get install perl python3 jq  # Debian/Ubuntu
```

**Problem**: "Plugin not appearing in WHM"
```bash
# Solution: Check installation and reload WHM
ls -la /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
# Reload WHM interface
# Check cPanel error logs: /usr/local/cpanel/logs/error_log
```

### Runtime Issues

**Problem**: "Access denied" in WHM
```bash
# Solution: Ensure logged in as root
# Check configuration: cat /etc/advanced-searcher/config.conf
# Verify root_only setting
```

**Problem**: "Search returns no results"
```bash
# Solution: Verify search term and account exists
# Check cPanel account list: whmapi1 listaccts
# Check API availability: advanced-searcher --diagnose
```

**Problem**: "API errors in logs"
```bash
# Solution: Check cPanel API availability
# Verify cPanel version compatibility
# Check log file: tail -f /var/log/advanced-searcher/plugin.log
```

**Problem**: Permission errors
```bash
# Solution: Fix permissions
bash install.sh  # Re-run installer
# Or manually fix:
chown -R root:root /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
chmod 755 /usr/local/cpanel/whostmgr/docroot/cgi/advanced-searcher/
```

### Performance Issues

**Problem**: Slow search performance
```bash
# Solution: Enable caching in configuration
vim /etc/advanced-searcher/config.conf
# Set: enable_cache=true
# Set: cache_ttl=3600
```

**Problem**: High memory usage
```bash
# Solution: Reduce max_results in configuration
vim /etc/advanced-searcher/config.conf
# Set: max_results=50
```

## Security Notes

### Important Security Considerations

1. **Root Access**: The plugin requires root access by design. Ensure your server's root access is properly secured.

2. **Input Sanitization**: All user input is sanitized, but always review the code before deployment in sensitive environments.

3. **No External Communication**: The plugin does not send data to external servers. All operations remain local.

4. **File Permissions**: The installer sets secure permissions (755 for directories, 644 for files, 700 for config/log directories).

5. **Rate Limiting**: API requests are rate-limited to prevent abuse (60 requests per minute by default).

6. **CSRF Protection**: The plugin includes CSRF token validation for web requests.

7. **XSS Prevention**: All HTML output is properly escaped to prevent XSS attacks.

8. **Credential Storage**: The plugin does not store any passwords or credentials.

### Security Best Practices

1. Keep the plugin updated to the latest version
2. Review configuration settings regularly
3. Monitor log files for suspicious activity
4. Use firewall rules to restrict WHM access if needed
5. Enable only necessary features in configuration
6. Regular security audits of the server
7. Keep cPanel/WHM updated to the latest version

### Before Production Deployment

1. Test thoroughly in a development environment
2. Review all configuration settings
3. Verify file permissions are correct
4. Test all search types with real data
5. Review log files for any errors
6. Verify WHM integration works correctly
7. Test CLI functionality
8. Review security settings
9. Create backups before installation
10. Have a rollback plan ready

## Configuration Before Publishing

Before publishing the plugin, update these variables in `install.sh`:

```bash
PLUGIN_NAME="advanced-searcher"
PLUGIN_VERSION="1.0.0"
REPOSITORY_URL="https://github.com/tasinamin121/advanced-searcher.git"
DOWNLOAD_URL="https://github.com/tasinamin121/advanced-searcher/archive/refs/heads/main.tar.gz"
```

Also update:
- Repository URLs in README.md
- Support links in documentation
- GitHub links in various files

## Code Review Checklist

- [x] No syntax errors in Perl scripts
- [x] No syntax errors in shell scripts
- [x] No syntax errors in JavaScript
- [x] No syntax errors in CSS
- [x] All file paths are correct
- [x] File permissions are appropriate
- [x] Input sanitization implemented
- [x] Output escaping implemented
- [x] No command injection vulnerabilities
- [x] No XSS vulnerabilities
- [x] CSRF protection implemented
- [x] Rate limiting implemented
- [x] Error handling implemented
- [x] Logging implemented
- [x] Configuration system functional
- [x] Installation script idempotent
- [x] Uninstallation script safe
- [x] Update script preserves configuration
- [x] cPanel API usage correct
- [x] Compatible with modern cPanel versions
- [x] No external dependencies that aren't standard
- [x] Documentation complete
- [x] License included
- [x] Version file included

## Final Verification

Before considering the project complete:

1. **Review all files** for syntax errors and logical issues
2. **Test installation** on a clean system
3. **Test all search types** with real data
4. **Test CLI functionality** thoroughly
5. **Test WHM integration** in a browser
6. **Verify security measures** are in place
7. **Check documentation** is complete and accurate
8. **Test upgrade/uninstall** procedures
9. **Review error handling** and edge cases
10. **Verify no hardcoded credentials** or sensitive data

## Support and Maintenance

### Regular Maintenance Tasks

1. Monitor log files for errors
2. Check for cPanel API changes
3. Review security advisories
4. Test on new cPanel versions
5. Update dependencies as needed
6. Review and optimize performance
7. Gather user feedback
8. Plan feature updates

### Getting Help

- GitHub Issues: https://github.com/tasinamin121/advanced-searcher/issues
- Documentation: https://github.com/tasinamin121/advanced-searcher/wiki
- cPanel Forums: https://forums.cpanel.net/

## Conclusion

The Advanced Searcher plugin is now ready for deployment. Follow the testing procedure thoroughly before deploying to production. Ensure all security considerations are reviewed and configuration is properly set for your environment.