package AdvancedSearcher::DomainSearch;

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
    my ($self, $domain) = @_;
    
    # Load CpanelAPI on demand to avoid circular dependencies
    require AdvancedSearcher::CpanelAPI;
    my $cpanel_api = AdvancedSearcher::CpanelAPI->new(logger => $self->{logger});
    
    return $cpanel_api->search_domain($domain);
}

1;