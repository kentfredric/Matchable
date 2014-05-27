use Test::Most;

use Matchable qw( ph );

use lib 't/lib';
use T1;

my $t1 = T1->new( val => 'foo' );
my $ret;

my ( %t1, %t2 );

# equiv
my $ph;
( $ret, $ph ) = $t1->equiv(
  T1->new(
    val => [
      {
        a => \%t2,
        b => ph(foobar),
      }
    ]
  ),
  T1->new(
    val => [
      {
        a => ph(bazfoo),
        b => \%t1,
      }
    ]
  ),
);
eq_or_diff(
  $ret,
  T1->new( val => [ { a => \%t2, b => \%t1 } ] ),
  'placeholders at sublevels on both sides are processed properly'
);
eq_or_diff( $ph, { foobar => \%t1, bazfoo => \%t2 }, 'placeholders at sublevels on both sides are set correctly' );

# - it basically punts the list of attributes to _equiv_one
done_testing;
