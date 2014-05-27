use strict;
use warnings;

package T1;

# ABSTRACT: T1 is a class that conforms to what we expect of a matchable

# AUTHORITY

use Safe::Isa;
use Scalar::Util 'blessed';
use Moo;
with 'Matchable';
has val => ( is => 'ro', );
sub _compare { ['val'] }

sub clone {
    return bless { %{ (shift) } }, 'T1';
}

no Moo;

1;

