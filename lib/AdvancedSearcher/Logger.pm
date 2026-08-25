package AdvancedSearcher::Logger;

use strict;
use warnings;
use POSIX qw(strftime);

sub new {
    my ($class, %args) = @_;
    my $self = {
        log_dir => $args{log_dir} || '/var/log/advanced-searcher',
        log_file => $args{log_file} || 'plugin.log',
        log_level => $args{log_level} || 'info'
    };
    
    # Ensure log directory exists
    $self->_ensure_log_dir();
    
    bless $self, $class;
    return $self;
}

sub _ensure_log_dir {
    my ($self) = @_;
    my $log_dir = $self->{log_dir};
    
    # Create directory if it doesn't exist
    unless (-d $log_dir) {
        my @parts = split '/', $log_dir;
        my $current = '';
        
        foreach my $part (@parts) {
            next unless $part;
            $current .= "/$part";
            unless (-d $current) {
                mkdir $current, 0755 or do {
                    warn "Cannot create directory $current: $!";
                    return;
                };
            }
        }
    }
}

sub log_dir {
    my ($self) = @_;
    return $self->{log_dir};
}

sub log_file {
    my ($self) = @_;
    return "$self->{log_dir}/$self->{log_file}";
}

sub _write_log {
    my ($self, $level, $message) = @_;
    
    my $log_levels = {
        debug => 0,
        info => 1,
        warning => 2,
        error => 3,
        critical => 4
    };
    
    my $current_level = $log_levels->{$self->{log_level}} || 1;
    my $message_level = $log_levels->{$level} || 1;
    
    # Only log if message level is >= current log level
    return if $message_level < $current_level;
    
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $log_entry = "[$timestamp] [$level] $message\n";
    
    my $log_file = $self->log_file();
    
    # Open log file in append mode
    open my $fh, '>>', $log_file or do {
        warn "Cannot open log file $log_file: $!";
        return;
    };
    
    print $fh $log_entry;
    close $fh;
}

sub debug {
    my ($self, $message) = @_;
    $self->_write_log('debug', $message);
}

sub info {
    my ($self, $message) = @_;
    $self->_write_log('info', $message);
}

sub warning {
    my ($self, $message) = @_;
    $self->_write_log('warning', $message);
}

sub error {
    my ($self, $message) = @_;
    $self->_write_log('error', $message);
}

sub critical {
    my ($self, $message) = @_;
    $self->_write_log('critical', $message);
}

sub log_installation {
    my ($self, $version) = @_;
    $self->info("INSTALLATION: Advanced Searcher version $version installed");
}

sub log_update {
    my ($self, $old_version, $new_version) = @_;
    $self->info("UPDATE: Advanced Searcher updated from $old_version to $new_version");
}

sub log_uninstallation {
    my ($self, $version) = @_;
    $self->info("UNINSTALLATION: Advanced Searcher version $version uninstalled");
}

sub log_search {
    my ($self, $search_type, $query, $result) = @_;
    my $status = $result ? 'SUCCESS' : 'FAILED';
    $self->info("SEARCH: $search_type search for '$query' - $status");
}

sub log_api_error {
    my ($self, $api_call, $error) = @_;
    $self->error("API ERROR: $api_call failed - $error");
}

sub log_security_event {
    my ($self, $event) = @_;
    $self->warning("SECURITY: $event");
}

sub rotate_logs {
    my ($self) = @_;
    
    my $log_file = $self->log_file();
    
    # Simple log rotation - keep last 5 logs
    for my $i (4..1) {
        my $old_file = $i > 0 ? "$log_file.$i" : $log_file;
        my $new_file = "$log_file." . ($i + 1);
        
        if (-e $old_file) {
            rename $old_file, $new_file;
        }
    }
    
    if (-e $log_file) {
        rename $log_file, "$log_file.1";
    }
    
    $self->info("Log rotation completed");
}

sub get_log_entries {
    my ($self, $limit) = @_;
    $limit ||= 100;
    
    my $log_file = $self->log_file();
    return [] unless -e $log_file;
    
    my @entries;
    open my $fh, '<', $log_file or return [];
    
    while (my $line = <$fh>) {
        chomp $line;
        push @entries, $line;
    }
    
    close $fh;
    
    # Return last N entries
    my @recent_entries = @entries[-$limit..-1];
    return \@recent_entries;
}

1;