#!/usr/bin/perl

#===============================================================================
# Advanced Searcher - WHM Plugin API Endpoint
#===============================================================================
# This provides a JSON API for AJAX calls from the frontend
#===============================================================================

use strict;
use warnings;
use JSON::PP;
use FindBin;
use lib "$FindBin::Bin/../../lib";
use lib "$FindBin::Bin/../../lib/AdvancedSearcher";

# Import our custom modules
use AdvancedSearcher::CGICompat;
use AdvancedSearcher::Security;
use AdvancedSearcher::Logger;
use AdvancedSearcher::CpanelAPI;

# Configuration
my $PLUGIN_NAME = "advanced-searcher";
my $LOG_DIR = "/var/log/$PLUGIN_NAME";

# Initialize objects
my $cgi = AdvancedSearcher::CGICompat->new();
my $security = AdvancedSearcher::Security->new();
my $logger = AdvancedSearcher::Logger->new(log_dir => $LOG_DIR);
my $cpanel_api = AdvancedSearcher::CpanelAPI->new(logger => $logger);

# Simple error handler
$SIG{__DIE__} = sub {
    my $error = shift;
    print "Content-Type: application/json\r\n\r\n";
    print JSON::PP->new->utf8->encode({success => 0, message => $error});
    exit 1;
};

# Security check - only allow root access
# In WHM CGI context, we check the REMOTE_USER environment variable
my $remote_user = $ENV{'REMOTE_USER'} || '';
unless ($remote_user eq 'root' || $security->is_root()) {
    send_json_response({
        success => 0,
        message => 'Access denied. This plugin requires root access.'
    });
    exit;
}

# Set JSON content type
print $cgi->header('application/json');

# Get action parameter
my $action = $cgi->param('action') || '';

# Initialize response
my $response = {
    success => 0,
    message => '',
    data => undef
};

# Route to appropriate handler
if ($action eq 'search') {
    handle_search();
} elsif ($action eq 'autocomplete') {
    handle_autocomplete();
} elsif ($action eq 'diagnostics') {
    handle_diagnostics();
} else {
    $response->{message} = 'Invalid action';
    send_json_response($response);
}

#===============================================================================
# Handlers
#===============================================================================

sub handle_search {
    my $query = $cgi->param('query') || '';
    my $search_type = $cgi->param('search_type') || 'domain';
    
    # Sanitize input
    $query = $security->sanitize_input($query);
    $search_type = $security->sanitize_input($search_type);
    
    unless ($query) {
        $response->{message} = 'Query parameter required';
        send_json_response($response);
        return;
    }
    
    # Validate search type
    my @valid_types = qw(domain username account reseller package ip);
    unless (grep { $_ eq $search_type } @valid_types) {
        $response->{message} = 'Invalid search type';
        send_json_response($response);
        return;
    }
    
    # Perform search
    eval {
        if ($search_type eq 'domain') {
            $response->{data} = $cpanel_api->search_domain($query);
        } elsif ($search_type eq 'username' || $search_type eq 'account') {
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
        $response->{message} = 'Search failed: ' . $security->escape_html($@);
        $logger->error("API search failed: $@");
    }
    
    send_json_response($response);
}

sub handle_autocomplete {
    my $query = $cgi->param('query') || '';
    my $search_type = $cgi->param('search_type') || 'domain';
    
    # Sanitize input
    $query = $security->sanitize_input($query);
    $search_type = $security->sanitize_input($search_type);
    
    unless ($query) {
        $response->{message} = 'Query parameter required';
        send_json_response($response);
        return;
    }
    
    # For autocomplete, we return a limited set of suggestions
    eval {
        if ($search_type eq 'domain') {
            $response->{data} = $cpanel_api->autocomplete_domains($query);
        } elsif ($search_type eq 'username' || $search_type eq 'account') {
            $response->{data} = $cpanel_api->autocomplete_accounts($query);
        } elsif ($search_type eq 'reseller') {
            $response->{data} = $cpanel_api->autocomplete_resellers($query);
        } elsif ($search_type eq 'package') {
            $response->{data} = $cpanel_api->autocomplete_packages($query);
        }
        $response->{success} = 1;
    };
    
    if ($@) {
        $response->{message} = 'Autocomplete failed: ' . $security->escape_html($@);
        $logger->error("API autocomplete failed: $@");
    }
    
    send_json_response($response);
}

sub handle_diagnostics {
    eval {
        $response->{data} = get_diagnostics_data();
        $response->{success} = 1;
    };
    
    if ($@) {
        $response->{message} = 'Diagnostics failed: ' . $security->escape_html($@);
        $logger->error("API diagnostics failed: $@");
    }
    
    send_json_response($response);
}

#===============================================================================
# Diagnostics Data
#===============================================================================

sub get_diagnostics_data {
    my $data = {};
    
    $data->{'plugin_version'} = get_plugin_version();
    $data->{'cpanel_version'} = get_cpanel_version();
    $data->{'os'} = get_os_info();
    $data->{'perl_version'} = $^V;
    $data->{'plugin_directory'} = $FindBin::Bin;
    $data->{'log_directory'} = $LOG_DIR;
    $data->{'installation_status'} = (-e "$FindBin::Bin/../VERSION") ? 'installed' : 'not_installed';
    $data->{'api_availability'} = $cpanel_api->check_api_availability() ? 'available' : 'not_available';
    $data->{'plugin_permissions'} = get_plugin_permissions();
    $data->{'config_exists'} = (-e "/etc/$PLUGIN_NAME/config.conf") ? 'yes' : 'no';
    $data->{'log_writable'} = (-w $LOG_DIR) ? 'yes' : 'no';
    
    return $data;
}

sub get_plugin_version {
    my $version_file = "$FindBin::Bin/../VERSION";
    if (-e $version_file) {
        open my $fh, '<', $version_file or return 'unknown';
        my $version = <$fh>;
        close $fh;
        chomp $version;
        return $version;
    }
    return 'unknown';
}

sub get_cpanel_version {
    my $version_file = '/usr/local/cpanel/version';
    if (-e $version_file) {
        open my $fh, '<', $version_file or return 'unknown';
        my $version = <$fh>;
        close $fh;
        chomp $version;
        return $version;
    }
    return 'unknown';
}

sub get_os_info {
    if (-e '/etc/redhat-release') {
        open my $fh, '<', '/etc/redhat-release' or return 'unknown';
        my $os = <$fh>;
        close $fh;
        chomp $os;
        return $os;
    } elsif (-e '/etc/debian_version') {
        open my $fh, '<', '/etc/debian_version' or return 'unknown';
        my $os = <$fh>;
        close $fh;
        chomp $os;
        return "Debian $os";
    }
    return 'unknown';
}

sub get_plugin_permissions {
    my $dir = $FindBin::Bin;
    my $perms = (stat $dir)[2] & 0777;
    return sprintf("%04o", $perms);
}

#===============================================================================
# Utility Functions
#===============================================================================

sub send_json_response {
    my ($data) = @_;
    my $json = JSON::PP->new->utf8->encode($data);
    print $json;
}

1;