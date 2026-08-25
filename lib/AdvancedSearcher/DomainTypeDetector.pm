package AdvancedSearcher::DomainTypeDetector;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        logger => $args{logger}
    };
    bless $self, $class;
    return $self;
}

sub detect {
    my ($self, $domain, $main_domain, $username) = @_;
    
    return 'UNKNOWN' unless $domain;
    return 'PRIMARY DOMAIN' if $domain eq $main_domain;
    
    # Check if it's a subdomain
    if ($self->_is_subdomain($domain, $main_domain)) {
        return 'SUBDOMAIN';
    }
    
    # Check if it's an addon domain
    if ($self->_is_addon_domain($domain, $username)) {
        return 'ADDON DOMAIN';
    }
    
    # Check if it's an alias/parked domain
    if ($self->_is_alias_domain($domain, $username)) {
        return 'ALIAS / PARKED DOMAIN';
    }
    
    return 'UNKNOWN';
}

sub _is_subdomain {
    my ($self, $domain, $main_domain) = @_;
    
    return 0 unless $main_domain;
    
    # Check if domain ends with main domain and is not the main domain itself
    if ($domain =~ /\.\Q$main_domain\E$/ && $domain ne $main_domain) {
        return 1;
    }
    
    return 0;
}

sub _is_addon_domain {
    my ($self, $domain, $username) = @_;
    
    return 0 unless $username;
    
    # Check addon domains configuration
    my $addon_file = "/var/cpanel/userdata/$username/addon-domains";
    
    if (-e $addon_file) {
        open my $fh, '<', $addon_file or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            if ($line eq $domain) {
                close $fh;
                return 1;
            }
        }
        close $fh;
    }
    
    return 0;
}

sub _is_alias_domain {
    my ($self, $domain, $username) = @_;
    
    return 0 unless $username;
    
    # Check parked domains configuration
    my $parked_file = "/var/cpanel/userdata/$username/parked-domains";
    
    if (-e $parked_file) {
        open my $fh, '<', $parked_file or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            if ($line eq $domain) {
                close $fh;
                return 1;
            }
        }
        close $fh;
    }
    
    return 0;
}

1;