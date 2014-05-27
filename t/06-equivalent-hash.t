use Test::Most;

use lib 't/lib';
use T1;
my $t1 = T1->new( val => 'foo' );

# _equiv_hash
eq_or_diff( $t1->_equiv_hash( +{qw(a b c d)}, +{qw(a b c d)} ), +{qw(a b c d)}, 'strings equate cleanly' );
eq_or_diff(
  $t1->_equiv_hash( +{ a => $t1, b => $t1 }, +{ a => $t1, b => $t1 } ),
  +{ a => $t1, b => $t1 },
  'mixed types inc t1 equate cleanly'
);

done_testing;
