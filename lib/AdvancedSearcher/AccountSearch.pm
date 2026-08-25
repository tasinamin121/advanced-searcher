package AdvancedSearcher::AccountSearch;

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
    my ($self, $username) = @_;
    
    # Load CpanelAPI on demand to avoid circular dependencies
    require AdvancedSearcher::CpanelAPI;
    my $cpanel_api = AdvancedSearcher::CpanelAPI->new(logger => $self->{logger});
    
    return $cpanel_api->search_account($username);
}

1;