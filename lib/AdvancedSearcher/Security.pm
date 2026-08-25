package AdvancedSearcher::Security;

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

sub is_root {
    my ($self) = @_;
    
    # Check if running as root
    my $uid = $<;
    return $uid == 0;
}

sub sanitize_input {
    my ($self, $input) = @_;
    
    return '' unless defined $input;
    
    # Remove potentially dangerous characters
    $input =~ s/[;<>&|`$()]/ /g;
    
    # Remove leading/trailing whitespace
    $input =~ s/^\s+//;
    $input =~ s/\s+$//;
    
    # Limit length
    $input = substr($input, 0, 255);
    
    return $input;
}

sub escape_html {
    my ($self, $input) = @_;
    
    return '' unless defined $input;
    
    # Simple HTML escaping - replace special characters with entities
    $input =~ s/&/&amp;/g;
    $input =~ s/</&lt;/g;
    $input =~ s/>/&gt;/g;
    $input =~ s/"/&quot;/g;
    $input =~ s/'/&#39;/g;
    
    return $input;
}

sub validate_domain {
    my ($self, $domain) = @_;
    
    return 0 unless defined $domain;
    
    # Basic domain validation
    $domain =~ s/^\s+//;
    $domain =~ s/\s+$//;
    $domain = lc($domain);
    
    # Remove www prefix for normalization
    $domain =~ s/^www\.//;
    
    # Remove trailing dot
    $domain =~ s/\.$//;
    
    # Basic domain format check
    return 0 unless $domain =~ /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)*$/;
    
    return $domain;
}

sub validate_username {
    my ($self, $username) = @_;
    
    return 0 unless defined $username;
    
    # cPanel username validation (max 8 characters, alphanumeric)
    $username =~ s/^\s+//;
    $username =~ s/\s+$//;
    $username = lc($username);
    
    return 0 unless $username =~ /^[a-z][a-z0-9]{0,7}$/;
    
    return $username;
}

sub validate_ip {
    my ($self, $ip) = @_;
    
    return 0 unless defined $ip;
    
    $ip =~ s/^\s+//;
    $ip =~ s/\s+$//;
    
    # IPv4 validation
    return 0 unless $ip =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
    
    my @octets = ($1, $2, $3, $4);
    foreach my $octet (@octets) {
        return 0 if $octet > 255;
    }
    
    return $ip;
}

sub normalize_search_term {
    my ($self, $term, $type) = @_;
    
    return '' unless defined $term;
    
    if ($type eq 'domain') {
        return $self->validate_domain($term) || '';
    } elsif ($type eq 'username' || $type eq 'account') {
        return $self->validate_username($term) || '';
    } elsif ($type eq 'ip') {
        return $self->validate_ip($term) || '';
    }
    
    # Default sanitization
    return $self->sanitize_input($term);
}

sub check_rate_limit {
    my ($self, $identifier) = @_;
    
    # Simple rate limiting using file-based tracking
    # In production, consider using Redis or similar
    my $rate_limit_file = "/tmp/advanced-searcher-rate-limit";
    
    my $current_time = time();
    my $window = 60; # 1 minute window
    my $max_requests = 60; # 60 requests per minute
    
    # Read existing rate limit data
    my %rate_data;
    if (-e $rate_limit_file) {
        open my $fh, '<', $rate_limit_file or return 0;
        while (my $line = <$fh>) {
            chomp $line;
            my ($id, $count, $timestamp) = split /:/, $line;
            # Remove entries outside the time window
            if ($current_time - $timestamp < $window) {
                $rate_data{$id} = {count => $count, timestamp => $timestamp};
            }
        }
        close $fh;
    }
    
    # Check current user's rate limit
    my $user_data = $rate_data{$identifier} || {count => 0, timestamp => $current_time};
    
    if ($user_data->{count} >= $max_requests) {
        return 0; # Rate limit exceeded
    }
    
    # Increment count
    $user_data->{count}++;
    $user_data->{timestamp} = $current_time;
    $rate_data{$identifier} = $user_data;
    
    # Write back to file
    open my $fh, '>', $rate_limit_file or return 0;
    foreach my $id (keys %rate_data) {
        print $fh "$id:$rate_data{$id}{count}:$rate_data{$id}{timestamp}\n";
    }
    close $fh;
    
    return 1; # Allow request
}

sub generate_csrf_token {
    my ($self) = @_;
    
    # Generate a simple CSRF token
    my $token = join '', map { ('a'..'z', 'A'..'Z', '0'..'9')[rand 62] } 1..32;
    return $token;
}

sub validate_csrf_token {
    my ($self, $token) = @_;
    
    # In production, implement proper CSRF validation
    # For now, return true for development
    return 1;
}

1;