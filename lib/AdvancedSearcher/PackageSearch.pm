package AdvancedSearcher::PackageSearch;

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

sub search {
    my ($self, $package) = @_;
    
    # Load CpanelAPI on demand to avoid circular dependencies
    require AdvancedSearcher::CpanelAPI;
    my $cpanel_api = AdvancedSearcher::CpanelAPI->new(logger => $self->{logger});
    
    return $cpanel_api->search_package($package);
}

1;