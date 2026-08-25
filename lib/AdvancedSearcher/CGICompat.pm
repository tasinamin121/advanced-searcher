package AdvancedSearcher::CGICompat;

use strict;
use warnings;

sub new {
    my ($class) = @_;
    my $self = {
        params => {},
        method => $ENV{'REQUEST_METHOD'} || 'GET',
        content_type => $ENV{'CONTENT_TYPE'} || '',
        query_string => $ENV{'QUERY_STRING'} || ''
    };
    
    # Parse query string and POST data
    $self->_parse_request();
    
    bless $self, $class;
    return $self;
}

sub _parse_request {
    my ($self) = @_;
    
    # Parse GET parameters
    if ($self->{query_string}) {
        $self->_parse_params($self->{query_string});
    }
    
    # Parse POST parameters
    if ($self->{method} eq 'POST') {
        my $content_length = $ENV{'CONTENT_LENGTH'} || 0;
        if ($content_length > 0 && $content_length < 100000) {  # Limit to 100KB
            my $post_data;
            read(STDIN, $post_data, $content_length);
            
            if ($self->{content_type} =~ /application\/x-www-form-urlencoded/i) {
                $self->_parse_params($post_data);
            }
        }
    }
}

sub _parse_params {
    my ($self, $data) = @_;
    
    my @pairs = split /&/, $data;
    foreach my $pair (@pairs) {
        my ($key, $value) = split /=/, $pair, 2;
        $key = $self->_url_decode($key) if defined $key;
        $value = $self->_url_decode($value) if defined $value;
        
        if (exists $self->{params}{$key}) {
            # Convert to array if multiple values
            if (ref $self->{params}{$key} eq 'ARRAY') {
                push @{$self->{params}{$key}}, $value;
            } else {
                $self->{params}{$key} = [$self->{params}{$key}, $value];
            }
        } else {
            $self->{params}{$key} = $value;
        }
    }
}

sub _url_decode {
    my ($self, $str) = @_;
    return '' unless defined $str;
    
    $str =~ s/\+/ /g;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    
    return $str;
}

sub param {
    my ($self, $name) = @_;
    
    return unless defined $name;
    
    if (exists $self->{params}{$name}) {
        my $value = $self->{params}{$name};
        return ref $value eq 'ARRAY' ? $value->[0] : $value;
    }
    
    return;
}

sub header {
    my ($self, $type) = @_;
    
    my $content_type = $type || 'text/html';
    
    return "Content-Type: $content_type\r\n\r\n";
}

sub import {
    # No-op for compatibility
}

1;
