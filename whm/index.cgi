#!/usr/bin/perl

#===============================================================================
# Advanced Searcher - WHM Plugin Main Interface
#===============================================================================
# This is the main WHM interface for the Advanced Searcher plugin
#===============================================================================

use strict;
use warnings;
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/lib/AdvancedSearcher";

# Import our custom modules
use AdvancedSearcher::CGICompat;
use AdvancedSearcher::Security;
use AdvancedSearcher::Logger;
use AdvancedSearcher::CpanelAPI;

# Configuration
my $PLUGIN_NAME = "advanced-searcher";
my $PLUGIN_VERSION = "1.2.0";
my $CONFIG_DIR = "/etc/$PLUGIN_NAME";
my $LOG_DIR = "/var/log/$PLUGIN_NAME";

# Initialize objects
my $cgi = AdvancedSearcher::CGICompat->new();
my $security = AdvancedSearcher::Security->new();
my $logger = AdvancedSearcher::Logger->new(log_dir => $LOG_DIR);
my $cpanel_api = AdvancedSearcher::CpanelAPI->new(logger => $logger);

# Simple error handler
$SIG{__DIE__} = sub {
    my $error = shift;
    print "Content-Type: text/html\r\n\r\n";
    print "<h1>Error</h1><pre>$error</pre>";
    exit 1;
};

# Security check - only allow root access
# In WHM CGI context, we check the REMOTE_USER environment variable
my $remote_user = $ENV{'REMOTE_USER'} || '';
unless ($remote_user eq 'root' || $security->is_root()) {
    print_error("Access denied. This plugin requires root access.");
    exit;
}

# Get action parameter
my $action = $cgi->param('action') || 'index';

# Route to appropriate handler
if ($action eq 'index') {
    render_index();
} elsif ($action eq 'search') {
    handle_search();
} elsif ($action eq 'diagnostics') {
    render_diagnostics();
} elsif ($action eq 'api') {
    handle_api();
} else {
    render_index();
}

#===============================================================================
# Page Renderers
#===============================================================================

sub render_index {
    my $search_type = $cgi->param('search_type') || 'domain';
    
    print_header();
    print_search_form($search_type);
    print_footer();
}

sub render_diagnostics {
    print_header();
    print_diagnostics_content();
    print_footer();
}

#===============================================================================
# Search Handler
#===============================================================================

sub handle_search {
    my $query = $cgi->param('query') || '';
    my $search_type = $cgi->param('search_type') || 'domain';
    
    # Sanitize input
    $query = $security->sanitize_input($query);
    $search_type = $security->sanitize_input($search_type);
    
    unless ($query) {
        print_error("Please enter a search query.");
        return;
    }
    
    # Validate search type
    my @valid_types = qw(domain username account reseller package ip);
    unless (grep { $_ eq $search_type } @valid_types) {
        print_error("Invalid search type.");
        return;
    }
    
    # Perform search based on type
    my $results;
    eval {
        if ($search_type eq 'domain') {
            $results = $cpanel_api->search_domain($query);
        } elsif ($search_type eq 'username') {
            $results = $cpanel_api->search_account($query);
        } elsif ($search_type eq 'account') {
            $results = $cpanel_api->search_account($query);
        } elsif ($search_type eq 'reseller') {
            $results = $cpanel_api->search_reseller($query);
        } elsif ($search_type eq 'package') {
            $results = $cpanel_api->search_package($query);
        } elsif ($search_type eq 'ip') {
            $results = $cpanel_api->search_ip($query);
        }
    };
    
    if ($@) {
        $logger->error("Search failed: $@");
        print_error("Search failed: " . $security->escape_html($@));
        return;
    }
    
    # Render results
    print_header();
    print_search_form($search_type);
    print_search_results($results, $search_type, $query);
    print_footer();
}

#===============================================================================
# API Handler
#===============================================================================

sub handle_api {
    my $api_action = $cgi->param('api_action') || '';
    
    # Set JSON content type
    print $cgi->header('application/json');
    
    my $response = {
        success => 0,
        message => '',
        data => undef
    };
    
    if ($api_action eq 'search') {
        my $query = $cgi->param('query') || '';
        my $search_type = $cgi->param('search_type') || 'domain';
        
        $query = $security->sanitize_input($query);
        $search_type = $security->sanitize_input($search_type);
        
        unless ($query) {
            $response->{message} = "Query parameter required";
            print_json($response);
            return;
        }
        
        eval {
            if ($search_type eq 'domain') {
                $response->{data} = $cpanel_api->search_domain($query);
            } elsif ($search_type eq 'username') {
                $response->{data} = $cpanel_api->search_account($query);
            } elsif ($search_type eq 'reseller') {
                $response->{data} = $cpanel_api->search_reseller($query);
            } elsif ($search_type eq 'package') {
                $response->{data} = $cpanel_api->search_package($query);
            } elsif ($search_type eq 'ip') {
                $response->{data} = $cpanel_api->search_ip($query);
            }
            $response->{success} = 1;
        };
        
        if ($@) {
            $response->{message} = "Search failed: " . $security->escape_html($@);
            $logger->error("API search failed: $@");
        }
    } elsif ($api_action eq 'diagnostics') {
        $response->{data} = get_diagnostics_data();
        $response->{success} = 1;
    } else {
        $response->{message} = "Invalid API action";
    }
    
    print_json($response);
}

#===============================================================================
# HTML Components
#===============================================================================

sub print_header {
    print $cgi->header();
    
    # Get the base URL for assets
    my $base_url = $ENV{'SCRIPT_NAME'} || '';
    $base_url =~ s/\/[^\/]*$//; # Remove script name
    
    print qq{
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Advanced Searcher - WHM Plugin</title>
    <link rel="stylesheet" href="${base_url}/assets/css/style.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Advanced Searcher</h1>
            <p class="subtitle">Search domains, accounts, usernames, resellers, packages and IP addresses</p>
        </div>
};
}

sub print_footer {
    # Get the base URL for assets
    my $base_url = $ENV{'SCRIPT_NAME'} || '';
    $base_url =~ s/\/[^\/]*$//; # Remove script name
    
    print qq{
        <div class="footer">
            <p>Advanced Searcher v$PLUGIN_VERSION | <a href="?action=diagnostics">Diagnostics</a></p>
        </div>
    </div>
    <script src="${base_url}/assets/js/main.js"></script>
</body>
</html>
};
}

sub print_search_form {
    my ($current_type) = @_;
    
    my @search_types = (
        {value => 'domain', label => 'Domain'},
        {value => 'username', label => 'Username'},
        {value => 'account', label => 'Account'},
        {value => 'reseller', label => 'Reseller'},
        {value => 'package', label => 'Package'},
        {value => 'ip', label => 'IP Address'}
    );
    
    print qq{
        <div class="search-section">
            <form method="POST" action="?action=search" class="search-form">
                <div class="search-input-group">
                    <input type="text" 
                           name="query" 
                           class="search-input" 
                           placeholder="Enter search term..." 
                           required
                           autofocus>
                    <select name="search_type" class="search-type-select">
};
    
    foreach my $type (@search_types) {
        my $selected = ($type->{value} eq $current_type) ? 'selected' : '';
        print qq{
                        <option value="$type->{value}" $selected>$type->{label}</option>
};
    }
    
    print qq{
                    </select>
                    <button type="submit" class="search-button">Search</button>
                </div>
            </form>
        </div>
};
}

sub print_search_results {
    my ($results, $search_type, $query) = @_;
    
    unless ($results && ref $results eq 'HASH' && $results->{found}) {
        print qq{
        <div class="no-results">
            <p>No matching results found for "<strong>$query</strong>"</p>
        </div>
};
        return;
    }
    
    # Render results based on search type
    if ($search_type eq 'domain') {
        print_domain_result($results);
    } elsif ($search_type eq 'username' || $search_type eq 'account') {
        print_account_result($results);
    } elsif ($search_type eq 'reseller') {
        print_reseller_result($results);
    } elsif ($search_type eq 'package') {
        print_package_result($results);
    } elsif ($search_type eq 'ip') {
        print_ip_result($results);
    }
}

sub print_domain_result {
    my ($result) = @_;
    
    my $domain = $security->escape_html($result->{domain} || '');
    my $domain_type = $security->escape_html($result->{domain_type} || 'UNKNOWN');
    my $username = $security->escape_html($result->{username} || '');
    my $owner = $security->escape_html($result->{owner} || '');
    my $reseller = $security->escape_html($result->{reseller} || 'ROOT');
    my $package = $security->escape_html($result->{package} || '');
    my $status = $security->escape_html($result->{status} || 'UNKNOWN');
    my $main_domain = $security->escape_html($result->{main_domain} || '');
    my $ip = $security->escape_html($result->{ip} || '');
    my $home_dir = $security->escape_html($result->{home_dir} || '');
    my $created = $security->escape_html($result->{created} || '');
    
    my $status_class = lc($status);
    
    print qq{
        <div class="result-card">
            <h2>Domain Information</h2>
            <div class="result-grid">
                <div class="result-item">
                    <span class="label">Domain:</span>
                    <span class="value">$domain</span>
                </div>
                <div class="result-item">
                    <span class="label">Domain Type:</span>
                    <span class="badge domain-type">$domain_type</span>
                </div>
                <div class="result-item">
                    <span class="label">cPanel Username:</span>
                    <span class="value">$username</span>
                </div>
                <div class="result-item">
                    <span class="label">Account Owner:</span>
                    <span class="value">$owner</span>
                </div>
                <div class="result-item">
                    <span class="label">Reseller:</span>
                    <span class="value">$reseller</span>
                </div>
                <div class="result-item">
                    <span class="label">Package:</span>
                    <span class="value">$package</span>
                </div>
                <div class="result-item">
                    <span class="label">Account Status:</span>
                    <span class="badge status $status_class">$status</span>
                </div>
                <div class="result-item">
                    <span class="label">Main Domain:</span>
                    <span class="value">$main_domain</span>
                </div>
                <div class="result-item">
                    <span class="label">IP Address:</span>
                    <span class="value">$ip</span>
                </div>
                <div class="result-item">
                    <span class="label">Home Directory:</span>
                    <span class="value">$home_dir</span>
                </div>
};
    
    if ($created) {
        print qq{
                <div class="result-item">
                    <span class="label">Created:</span>
                    <span class="value">$created</span>
                </div>
};
    }
    
    print qq{
            </div>
};
    
    # Show hierarchy
    print_hierarchy($domain, $username, $reseller, $package, $ip);
    
    print qq{
        </div>
};
}

sub print_account_result {
    my ($result) = @_;
    
    my $username = $security->escape_html($result->{username} || '');
    my $main_domain = $security->escape_html($result->{main_domain} || '');
    my $reseller = $security->escape_html($result->{reseller} || 'ROOT');
    my $package = $security->escape_html($result->{package} || '');
    my $status = $security->escape_html($result->{status} || 'UNKNOWN');
    my $ip = $security->escape_html($result->{ip} || '');
    my $home_dir = $security->escape_html($result->{home_dir} || '');
    
    my $status_class = lc($status);
    
    print qq{
        <div class="result-card">
            <h2>Account Information</h2>
            <div class="result-grid">
                <div class="result-item">
                    <span class="label">Username:</span>
                    <span class="value">$username</span>
                </div>
                <div class="result-item">
                    <span class="label">Main Domain:</span>
                    <span class="value">$main_domain</span>
                </div>
                <div class="result-item">
                    <span class="label">Reseller:</span>
                    <span class="value">$reseller</span>
                </div>
                <div class="result-item">
                    <span class="label">Package:</span>
                    <span class="value">$package</span>
                </div>
                <div class="result-item">
                    <span class="label">Status:</span>
                    <span class="badge status $status_class">$status</span>
                </div>
                <div class="result-item">
                    <span class="label">IP:</span>
                    <span class="value">$ip</span>
                </div>
                <div class="result-item">
                    <span class="label">Home Directory:</span>
                    <span class="value">$home_dir</span>
                </div>
            </div>
};
    
    # Show domains if available
    if ($result->{domains} && ref $result->{domains} eq 'ARRAY') {
        print qq{
            <h3>Domains</h3>
            <div class="domains-list">
};
        foreach my $domain_info (@{$result->{domains}}) {
            my $dname = $security->escape_html($domain_info->{domain} || '');
            my $dtype = $security->escape_html($domain_info->{type} || 'UNKNOWN');
            my $dtype_class = lc($dtype);
            $dtype_class =~ s/\s+/-/g;
            
            print qq{
                <div class="domain-item">
                    <span class="domain-name">$dname</span>
                    <span class="badge domain-type $dtype_class">$dtype</span>
                </div>
};
        }
        print qq{
            </div>
};
    }
    
    print qq{
        </div>
};
}

sub print_reseller_result {
    my ($result) = @_;
    
    my $reseller = $security->escape_html($result->{reseller} || '');
    my $owner = $security->escape_html($result->{owner} || 'root');
    my $package = $security->escape_html($result->{package} || '');
    my $account_count = $security->escape_html($result->{account_count} || 0);
    
    print qq{
        <div class="result-card">
            <h2>Reseller Information</h2>
            <div class="result-grid">
                <div class="result-item">
                    <span class="label">Reseller:</span>
                    <span class="value">$reseller</span>
                </div>
                <div class="result-item">
                    <span class="label">Owner:</span>
                    <span class="value">$owner</span>
                </div>
                <div class="result-item">
                    <span class="label">Package:</span>
                    <span class="value">$package</span>
                </div>
                <div class="result-item">
                    <span class="label">Accounts:</span>
                    <span class="value">$account_count</span>
                </div>
            </div>
};
    
    # Show accounts if available
    if ($result->{accounts} && ref $result->{accounts} eq 'ARRAY') {
        print qq{
            <h3>Accounts</h3>
            <div class="accounts-table">
                <table>
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>Main Domain</th>
                            <th>Package</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
};
        foreach my $account (@{$result->{accounts}}) {
            my $username = $security->escape_html($account->{username} || '');
            my $domain = $security->escape_html($account->{domain} || '');
            my $pkg = $security->escape_html($account->{package} || '');
            my $status = $security->escape_html($account->{status} || 'UNKNOWN');
            my $status_class = lc($status);
            
            print qq{
                        <tr>
                            <td>$username</td>
                            <td>$domain</td>
                            <td>$pkg</td>
                            <td><span class="badge status $status_class">$status</span></td>
                        </tr>
};
        }
        print qq{
                    </tbody>
                </table>
            </div>
};
    }
    
    print qq{
        </div>
};
}

sub print_package_result {
    my ($result) = @_;
    
    my $package = $security->escape_html($result->{package} || '');
    
    print qq{
        <div class="result-card">
            <h2>Package: $package</h2>
};
    
    if ($result->{accounts} && ref $result->{accounts} eq 'ARRAY') {
        print qq{
            <h3>Accounts using this package</h3>
            <div class="accounts-table">
                <table>
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>Main Domain</th>
                            <th>Reseller</th>
                            <th>Status</th>
                            <th>IP</th>
                        </tr>
                    </thead>
                    <tbody>
};
        foreach my $account (@{$result->{accounts}}) {
            my $username = $security->escape_html($account->{username} || '');
            my $domain = $security->escape_html($account->{domain} || '');
            my $reseller = $security->escape_html($account->{reseller} || 'ROOT');
            my $status = $security->escape_html($account->{status} || 'UNKNOWN');
            my $ip = $security->escape_html($account->{ip} || '');
            my $status_class = lc($status);
            
            print qq{
                        <tr>
                            <td>$username</td>
                            <td>$domain</td>
                            <td>$reseller</td>
                            <td><span class="badge status $status_class">$status</span></td>
                            <td>$ip</td>
                        </tr>
};
        }
        print qq{
                    </tbody>
                </table>
            </div>
};
    } else {
        print qq{
            <p>No accounts found using this package.</p>
};
    }
    
    print qq{
        </div>
};
}

sub print_ip_result {
    my ($result) = @_;
    
    my $ip = $security->escape_html($result->{ip} || '');
    
    print qq{
        <div class="result-card">
            <h2>IP Address: $ip</h2>
};
    
    if ($result->{accounts} && ref $result->{accounts} eq 'ARRAY') {
        print qq{
            <h3>Accounts on this IP</h3>
            <div class="accounts-table">
                <table>
                    <thead>
                        <tr>
                            <th>Username</th>
                            <th>Main Domain</th>
                            <th>Reseller</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
};
        foreach my $account (@{$result->{accounts}}) {
            my $username = $security->escape_html($account->{username} || '');
            my $domain = $security->escape_html($account->{domain} || '');
            my $reseller = $security->escape_html($account->{reseller} || 'ROOT');
            my $status = $security->escape_html($account->{status} || 'UNKNOWN');
            my $status_class = lc($status);
            
            print qq{
                        <tr>
                            <td>$username</td>
                            <td>$domain</td>
                            <td>$reseller</td>
                            <td><span class="badge status $status_class">$status</span></td>
                        </tr>
};
        }
        print qq{
                    </tbody>
                </table>
            </div>
};
    } else {
        print qq{
            <p>No accounts found on this IP address.</p>
};
    }
    
    print qq{
        </div>
};
}

sub print_hierarchy {
    my ($domain, $username, $reseller, $package, $ip) = @_;
    
    print qq{
        <div class="hierarchy">
            <h3>Account Hierarchy</h3>
            <div class="hierarchy-chain">
                <div class="hierarchy-item">$domain</div>
                <div class="hierarchy-arrow">↓</div>
                <div class="hierarchy-item">$username</div>
                <div class="hierarchy-arrow">↓</div>
                <div class="hierarchy-item">$reseller</div>
                <div class="hierarchy-arrow">↓</div>
                <div class="hierarchy-item">$package</div>
                <div class="hierarchy-arrow">↓</div>
                <div class="hierarchy-item">$ip</div>
            </div>
        </div>
};
}

sub print_diagnostics_content {
    my $diagnostics = get_diagnostics_data();
    
    print qq{
        <div class="diagnostics-section">
            <h2>System Diagnostics</h2>
            <div class="diagnostics-grid">
};
    
    foreach my $key (keys %$diagnostics) {
        my $label = $security->escape_html($key);
        my $value = $security->escape_html($diagnostics->{$key});
        
        print qq{
                <div class="diagnostic-item">
                    <span class="label">$label:</span>
                    <span class="value">$value</span>
                </div>
};
    }
    
    print qq{
            </div>
            <div class="diagnostics-actions">
                <button onclick="runDiagnostics()" class="action-button">Run Diagnostics</button>
            </div>
        </div>
};
}

sub get_diagnostics_data {
    my $data = {};
    
    $data->{'Plugin Version'} = $PLUGIN_VERSION;
    $data->{'cPanel Version'} = get_cpanel_version();
    $data->{'OS'} = get_os_info();
    $data->{'Perl Version'} = $^V;
    $data->{'Plugin Directory'} = $FindBin::Bin;
    $data->{'Config Directory'} = $CONFIG_DIR;
    $data->{'Log Directory'} = $LOG_DIR;
    $data->{'Installation Status'} = (-e "$FindBin::Bin/VERSION") ? 'Installed' : 'Not Installed';
    $data->{'API Availability'} = $cpanel_api->check_api_availability() ? 'Available' : 'Not Available';
    $data->{'Plugin Permissions'} = get_plugin_permissions();
    
    return $data;
}

sub get_cpanel_version {
    my $version_file = '/usr/local/cpanel/version';
    if (-e $version_file) {
        open my $fh, '<', $version_file or return 'Unknown';
        my $version = <$fh>;
        close $fh;
        chomp $version;
        return $version;
    }
    return 'Unknown';
}

sub get_os_info {
    if (-e '/etc/redhat-release') {
        open my $fh, '<', '/etc/redhat-release' or return 'Unknown';
        my $os = <$fh>;
        close $fh;
        chomp $os;
        return $os;
    } elsif (-e '/etc/debian_version') {
        open my $fh, '<', '/etc/debian_version' or return 'Unknown';
        my $os = <$fh>;
        close $fh;
        chomp $os;
        return "Debian $os";
    }
    return 'Unknown';
}

sub get_plugin_permissions {
    my $dir = $FindBin::Bin;
    my $perms = (stat $dir)[2] & 0777;
    return sprintf("%04o", $perms);
}

#===============================================================================
# Utility Functions
#===============================================================================

sub print_error {
    my ($message) = @_;
    my $safe_message = $security->escape_html($message);
    
    # Get the base URL for assets
    my $base_url = $ENV{'SCRIPT_NAME'} || '';
    $base_url =~ s/\/[^\/]*$//; # Remove script name
    
    print $cgi->header();
    print qq{
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Error - Advanced Searcher</title>
    <link rel="stylesheet" href="${base_url}/assets/css/style.css">
</head>
<body>
    <div class="container">
        <div class="error-message">
            <h2>Error</h2>
            <p>$safe_message</p>
            <p><a href="?action=index">Return to search</a></p>
        </div>
    </div>
</body>
</html>
};
}

sub print_json {
    my ($data) = @_;
    my $json = JSON::PP->new->utf8->encode($data);
    print $json;
}

1;