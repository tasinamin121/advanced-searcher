package AdvancedSearcher::CpanelAPI;

use strict;
use warnings;

# Conditionally load cPanel modules
my $cpanel_available = 0;
eval {
    require lib;
    lib->import('/usr/local/cpanel');
    require Cpanel::Config::LoadConfig;
    require Cpanel::PwCache;
    $cpanel_available = 1;
};

sub new {
    my ($class, %args) = @_;
    my $self = {
        logger => $args{logger},
        cpanel_available => $cpanel_available
    };
    
    bless $self, $class;
    
    # Initialize logger if not provided
    unless ($self->{logger}) {
        require AdvancedSearcher::Logger;
        $self->{logger} = AdvancedSearcher::Logger->new(log_dir => '/var/log/advanced-searcher');
    }
    
    return $self;
}

sub check_api_availability {
    my ($self) = @_;
    
    # Return cached availability status
    return $self->{cpanel_available};
}

sub search_domain {
    my ($self, $domain) = @_;
    
    return {found => 0} unless $domain;
    
    my $result = {
        found => 0,
        domain => $domain,
        domain_type => 'UNKNOWN',
        username => '',
        owner => '',
        reseller => 'ROOT',
        package => '',
        status => 'UNKNOWN',
        main_domain => '',
        ip => '',
        home_dir => '',
        created => ''
    };
    
    eval {
        # Normalize domain
        $domain = lc($domain);
        $domain =~ s/^www\.//;
        $domain =~ s/\.$//;
        
        # Search for account by domain using /etc/userdomains
        my $username = $self->_find_user_by_domain($domain);
        
        if ($username) {
            $result->{found} = 1;
            $result->{username} = $username;
            
            # Get account details
            my $account_details = $self->_get_account_details($username);
            
            if ($account_details) {
                $result->{main_domain} = $account_details->{domain} || $domain;
                $result->{owner} = $account_details->{owner} || '';
                $result->{reseller} = $account_details->{reseller} || 'ROOT';
                $result->{package} = $account_details->{package} || '';
                $result->{status} = $account_details->{status} || 'ACTIVE';
                $result->{ip} = $account_details->{ip} || '';
                $result->{home_dir} = $account_details->{home_dir} || '';
                $result->{created} = $account_details->{created} || '';
            }
            
            # Determine domain type
            $result->{domain_type} = $self->_determine_domain_type($domain, $result->{main_domain}, $username);
        }
    };
    
    if ($@) {
        $self->logger->error("Domain search failed for '$domain': $@") if $self->{logger};
        $result->{error} = $@;
    }
    
    return $result;
}

sub search_account {
    my ($self, $username) = @_;
    
    return {found => 0} unless $username;
    
    my $result = {
        found => 0,
        username => $username,
        main_domain => '',
        reseller => 'ROOT',
        package => '',
        status => 'UNKNOWN',
        ip => '',
        home_dir => '',
        domains => []
    };
    
    eval {
        # Check if user exists
        if ($self->_user_exists($username)) {
            $result->{found} = 1;
            
            # Get account details
            my $account_details = $self->_get_account_details($username);
            
            if ($account_details) {
                $result->{main_domain} = $account_details->{domain} || '';
                $result->{reseller} = $account_details->{reseller} || 'ROOT';
                $result->{package} = $account_details->{package} || '';
                $result->{status} = $account_details->{status} || 'ACTIVE';
                $result->{ip} = $account_details->{ip} || '';
                $result->{home_dir} = $account_details->{home_dir} || '';
            }
            
            # Get all domains for this account
            $result->{domains} = $self->_get_account_domains($username);
        }
    };
    
    if ($@) {
        $self->logger->error("Account search failed for '$username': $@") if $self->{logger};
        $result->{error} = $@;
    }
    
    return $result;
}

sub search_reseller {
    my ($self, $reseller) = @_;
    
    return {found => 0} unless $reseller;
    
    my $result = {
        found => 0,
        reseller => $reseller,
        owner => 'root',
        package => '',
        account_count => 0,
        accounts => []
    };
    
    eval {
        # Check if user is a reseller by checking reseller file
        my $is_reseller = $self->_is_reseller($reseller);
        
        if ($is_reseller) {
            $result->{found} = 1;
            
            # Get reseller details
            my $reseller_details = $self->_get_reseller_details($reseller);
            
            if ($reseller_details) {
                $result->{owner} = $reseller_details->{owner} || 'root';
                $result->{package} = $reseller_details->{package} || '';
            }
            
            # Get all accounts owned by this reseller
            $result->{accounts} = $self->_get_reseller_accounts($reseller);
            $result->{account_count} = scalar @{$result->{accounts}};
        }
    };
    
    if ($@) {
        $self->logger->error("Reseller search failed for '$reseller': $@") if $self->{logger};
        $result->{error} = $@;
    }
    
    return $result;
}

sub search_package {
    my ($self, $package) = @_;
    
    return {found => 0} unless $package;
    
    my $result = {
        found => 0,
        package => $package,
        accounts => []
    };
    
    eval {
        # Get all accounts
        my $accounts = $self->_get_all_accounts();
        
        # Filter by package
        my @matching_accounts;
        foreach my $account (@$accounts) {
            if ($account->{package} eq $package) {
                push @matching_accounts, $account;
            }
        }
        
        if (@matching_accounts) {
            $result->{found} = 1;
            $result->{accounts} = \@matching_accounts;
        }
    };
    
    if ($@) {
        $self->logger->error("Package search failed for '$package': $@") if $self->{logger};
        $result->{error} = $@;
    }
    
    return $result;
}

sub search_ip {
    my ($self, $ip) = @_;
    
    return {found => 0} unless $ip;
    
    my $result = {
        found => 0,
        ip => $ip,
        accounts => []
    };
    
    eval {
        # Get all accounts
        my $accounts = $self->_get_all_accounts();
        
        # Filter by IP
        my @matching_accounts;
        foreach my $account (@$accounts) {
            if ($account->{ip} eq $ip) {
                push @matching_accounts, $account;
            }
        }
        
        if (@matching_accounts) {
            $result->{found} = 1;
            $result->{accounts} = \@matching_accounts;
        }
    };
    
    if ($@) {
        $self->logger->error("IP search failed for '$ip': $@") if $self->{logger};
        $result->{error} = $@;
    }
    
    return $result;
}

# Autocomplete functions

sub autocomplete_domains {
    my ($self, $query) = @_;
    
    return [] unless $query;
    
    my $suggestions = [];
    
    eval {
        my $accounts = $self->_get_all_accounts();
        
        foreach my $account (@$accounts) {
            if ($account->{domain} =~ /^\Q$query\E/i) {
                push @$suggestions, {
                    value => $account->{domain},
                    label => $account->{domain}
                };
                last if scalar @$suggestions >= 10;
            }
        }
    };
    
    return $suggestions;
}

sub autocomplete_accounts {
    my ($self, $query) = @_;
    
    return [] unless $query;
    
    my $suggestions = [];
    
    eval {
        my $accounts = $self->_get_all_accounts();
        
        foreach my $account (@$accounts) {
            if ($account->{user} =~ /^\Q$query\E/i) {
                push @$suggestions, {
                    value => $account->{user},
                    label => "$account->{user} ($account->{domain})"
                };
                last if scalar @$suggestions >= 10;
            }
        }
    };
    
    return $suggestions;
}

sub autocomplete_resellers {
    my ($self, $query) = @_;
    
    return [] unless $query;
    
    my $suggestions = [];
    
    eval {
        my $resellers = $self->_get_all_resellers();
        
        foreach my $reseller (@$resellers) {
            if ($reseller =~ /^\Q$query\E/i) {
                push @$suggestions, {
                    value => $reseller,
                    label => $reseller
                };
                last if scalar @$suggestions >= 10;
            }
        }
    };
    
    return $suggestions;
}

sub autocomplete_packages {
    my ($self, $query) = @_;
    
    return [] unless $query;
    
    my $suggestions = [];
    
    eval {
        my $packages = $self->_get_all_packages();
        
        foreach my $package (@$packages) {
            if ($package =~ /^\Q$query\E/i) {
                push @$suggestions, {
                    value => $package,
                    label => $package
                };
                last if scalar @$suggestions >= 10;
            }
        }
    };
    
    return $suggestions;
}

# Internal helper functions

sub _get_account_details {
    my ($self, $username) = @_;
    
    my $details = {};
    
    # Return early if cPanel modules not available
    return $details unless $self->{cpanel_available};
    
    eval {
        # Get account user data
        if ($self->{cpanel_available}) {
            my $user_data = Cpanel::PwCache::getpwdata($username);
            
            if ($user_data) {
                $details->{home_dir} = $user_data->{dir} || '';
                # Use the account owner from cpanel config instead of gecos
                $details->{owner} = $username; # Default to username
            }
        }
        
        # Get account configuration
        my $account_file = "/var/cpanel/users/$username";
        if (-e $account_file) {
            my $account_config;
            if ($self->{cpanel_available}) {
                $account_config = Cpanel::Config::LoadConfig::loadconfig($account_file);
            } else {
                $account_config = $self->_load_config_file($account_file);
            }
            
            $details->{domain} = $account_config->{DNS} || $account_config->{DOMAIN} || '';
            $details->{package} = $account_config->{PLAN} || '';
            $details->{ip} = $account_config->{IP} || '';
            $details->{reseller} = $account_config->{RESELLER} || 'ROOT';
            $details->{status} = $account_config->{SUSPENDED} ? 'SUSPENDED' : 'ACTIVE';
            
            # Get creation time from file modification time
            my $mtime = (stat $account_file)[9];
            $details->{created} = scalar localtime $mtime if $mtime;
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get account details for '$username': $@") if $self->{logger};
    }
    
    return $details;
}

sub _get_account_domains {
    my ($self, $username) = @_;
    
    my $domains = [];
    
    # Return early if cPanel modules not available
    return $domains unless $self->{cpanel_available};
    
    eval {
        # Get main domain from user file
        my $user_file = "/var/cpanel/users/$username";
        if (-e $user_file) {
            my $user_config;
            if ($self->{cpanel_available}) {
                $user_config = Cpanel::Config::LoadConfig::loadconfig($user_file);
            } else {
                $user_config = $self->_load_config_file($user_file);
            }
            my $main_domain = $user_config->{DNS} || $user_config->{DOMAIN} || '';
            
            if ($main_domain) {
                push @$domains, {
                    domain => $main_domain,
                    type => 'PRIMARY DOMAIN'
                };
            }
        }
        
        # Get addon domains
        my $addon_file = "/var/cpanel/userdata/$username/addon-domains";
        if (-e $addon_file) {
            open my $fh, '<', $addon_file or die "Cannot read addon file: $!";
            while (my $line = <$fh>) {
                chomp $line;
                next unless $line;
                push @$domains, {
                    domain => $line,
                    type => 'ADDON DOMAIN'
                };
            }
            close $fh;
        }
        
        # Get parked domains
        my $parked_file = "/var/cpanel/userdata/$username/parked-domains";
        if (-e $parked_file) {
            open my $fh, '<', $parked_file or die "Cannot read parked file: $!";
            while (my $line = <$fh>) {
                chomp $line;
                next unless $line;
                push @$domains, {
                    domain => $line,
                    type => 'ALIAS / PARKED DOMAIN'
                };
            }
            close $fh;
        }
        
        # Get subdomains
        my $sub_file = "/var/cpanel/userdata/$username/subdomains";
        if (-e $sub_file) {
            open my $fh, '<', $sub_file or die "Cannot read subdomain file: $!";
            while (my $line = <$fh>) {
                chomp $line;
                next unless $line;
                push @$domains, {
                    domain => $line,
                    type => 'SUBDOMAIN'
                };
            }
            close $fh;
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get domains for '$username': $@") if $self->{logger};
    }
    
    return $domains;
}

sub _get_reseller_details {
    my ($self, $reseller) = @_;
    
    my $details = {};
    
    # Return early if cPanel modules not available
    return $details unless $self->{cpanel_available};
    
    eval {
        my $reseller_file = "/var/cpanel/resellers/$reseller";
        if (-e $reseller_file) {
            my $reseller_config;
            if ($self->{cpanel_available}) {
                $reseller_config = Cpanel::Config::LoadConfig::loadconfig($reseller_file);
            } else {
                $reseller_config = $self->_load_config_file($reseller_file);
            }
            $details->{owner} = $reseller_config->{owner} || 'root';
            $details->{package} = $reseller_config->{package} || '';
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get reseller details for '$reseller': $@") if $self->{logger};
    }
    
    return $details;
}

sub _get_reseller_accounts {
    my ($self, $reseller) = @_;
    
    my $accounts = [];
    
    eval {
        my $all_accounts = $self->_get_all_accounts();
        
        foreach my $account (@$all_accounts) {
            if ($account->{reseller} eq $reseller) {
                push @$accounts, $account;
            }
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get reseller accounts for '$reseller': $@") if $self->{logger};
    }
    
    return $accounts;
}

sub _get_all_accounts {
    my ($self) = @_;
    
    my $accounts = [];
    
    # Return early if cPanel modules not available
    return $accounts unless $self->{cpanel_available};
    
    eval {
        # Read all user files from /var/cpanel/users
        my $users_dir = '/var/cpanel/users';
        if (-d $users_dir) {
            opendir my $dh, $users_dir or die "Cannot open users directory: $!";
            while (my $username = readdir $dh) {
                next if $username =~ /^\./;
                next if $username eq 'system';
                
                my $user_file = "$users_dir/$username";
                if (-f $user_file) {
                    my $user_config;
                    if ($self->{cpanel_available}) {
                        $user_config = Cpanel::Config::LoadConfig::loadconfig($user_file);
                    } else {
                        $user_config = $self->_load_config_file($user_file);
                    }
                    
                    push @$accounts, {
                        user => $username,
                        domain => $user_config->{DNS} || $user_config->{DOMAIN} || '',
                        package => $user_config->{PLAN} || '',
                        ip => $user_config->{IP} || '',
                        reseller => $user_config->{RESELLER} || 'ROOT',
                        suspended => $user_config->{SUSPENDED} || 0,
                        status => $user_config->{SUSPENDED} ? 'SUSPENDED' : 'ACTIVE'
                    };
                }
            }
            closedir $dh;
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get all accounts: $@") if $self->{logger};
    }
    
    return $accounts;
}

sub _get_all_resellers {
    my ($self) = @_;
    
    my $resellers = [];
    
    eval {
        # Get resellers from reseller file
        if (-d '/var/cpanel/resellers') {
            opendir my $dh, '/var/cpanel/resellers' or return;
            while (my $file = readdir $dh) {
                next if $file =~ /^\./;
                push @$resellers, $file;
            }
            closedir $dh;
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get all resellers: $@") if $self->{logger};
    }
    
    return $resellers;
}

sub _get_all_packages {
    my ($self) = @_;
    
    my $packages = [];
    
    eval {
        # Get packages from packages directory
        if (-d '/var/cpanel/packages') {
            opendir my $dh, '/var/cpanel/packages' or return;
            while (my $file = readdir $dh) {
                next if $file =~ /^\./;
                next unless $file =~ /^[a-zA-Z0-9_-]+$/;
                push @$packages, $file;
            }
            closedir $dh;
        }
    };
    
    if ($@) {
        $self->logger->error("Failed to get all packages: $@") if $self->{logger};
    }
    
    return $packages;
}

sub _determine_domain_type {
    my ($self, $domain, $main_domain, $username) = @_;
    
    return 'PRIMARY DOMAIN' if $domain eq $main_domain;
    
    # Check if it's a subdomain
    if ($domain =~ /\.\Q$main_domain\E$/ && $domain ne $main_domain) {
        return 'SUBDOMAIN';
    }
    
    # Check addon domains
    if ($self->_is_addon_domain($domain, $username)) {
        return 'ADDON DOMAIN';
    }
    
    # Check parked/alias domains
    if ($self->_is_parked_domain($domain, $username)) {
        return 'ALIAS / PARKED DOMAIN';
    }
    
    return 'UNKNOWN';
}

sub _find_user_by_domain {
    my ($self, $domain) = @_;
    
    my $userdomains_file = '/etc/userdomains';
    return unless -e $userdomains_file;
    
    open my $fh, '<', $userdomains_file or return;
    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^\Q$domain\E:\s*(.+)$/) {
            close $fh;
            my $users = $1;
            # Return the first user (main owner)
            my ($first_user) = split /\s+/, $users;
            return $first_user;
        }
    }
    close $fh;
    
    return;
}

sub _user_exists {
    my ($self, $username) = @_;
    
    # Check if user exists in /etc/passwd or cpanel user files
    my $user_file = "/var/cpanel/users/$username";
    return 0 unless -e $user_file;
    
    # Also check if user exists in system
    my $pw = getpwnam($username);
    return $pw ? 1 : 0;
}

sub _is_addon_domain {
    my ($self, $domain, $username) = @_;
    
    my $addon_file = "/var/cpanel/userdata/$username/addon-domains";
    return 0 unless -e $addon_file;
    
    open my $fh, '<', $addon_file or return 0;
    while (my $line = <$fh>) {
        chomp $line;
        return 1 if $line eq $domain;
    }
    close $fh;
    
    return 0;
}

sub _is_parked_domain {
    my ($self, $domain, $username) = @_;
    
    my $parked_file = "/var/cpanel/userdata/$username/parked-domains";
    return 0 unless -e $parked_file;
    
    open my $fh, '<', $parked_file or return 0;
    while (my $line = <$fh>) {
        chomp $line;
        return 1 if $line eq $domain;
    }
    close $fh;
    
    return 0;
}

sub _is_reseller {
    my ($self, $username) = @_;
    
    # Check if reseller file exists
    my $reseller_file = "/var/cpanel/resellers/$username";
    return 1 if -e $reseller_file;
    
    # Also check if user has reseller ACLs
    my $acl_file = "/var/cpanel/acls/$username";
    if (-e $acl_file) {
        open my $fh, '<', $acl_file or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ /reseller/i || $line =~ /all/i) {
                close $fh;
                return 1;
            }
        }
        close $fh;
    }
    
    return 0;
}

sub _load_config_file {
    my ($self, $file) = @_;
    
    my $config = {};
    
    return $config unless -e $file;
    
    open my $fh, '<', $file or return $config;
    while (my $line = <$fh>) {
        chomp $line;
        
        # Skip comments and empty lines
        next if $line =~ /^\s*#/;
        next if $line =~ /^\s*$/;
        
        # Parse key=value pairs
        if ($line =~ /^\s*([A-Z_][A-Z0-9_]*)\s*=\s*(.*?)\s*$/) {
            my $key = $1;
            my $value = $2;
            
            # Remove quotes if present
            $value =~ s/^["']|["']$//g;
            
            $config->{$key} = $value;
        }
    }
    close $fh;
    
    return $config;
}

1;