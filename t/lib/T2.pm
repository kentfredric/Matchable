use strict;
use warnings;

package T2;

# ABSTRACT: T2 is a class that is not clone()able, so that we can test we error out correctly

# AUTHORITY

use Safe::Isa;
use Scalar::Util 'blessed';
use Moo;
with 'Matchable';
has val => ( is => 'ro', );
sub _compare { ['val'] }

sub equiv {
    my ( $self, $other ) = @_;
    return unless $other->$_isa('T1');
    return $self if $self->val eq $other->val;
}

no Moo;

1;
