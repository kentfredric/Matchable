use Test::Most;

use Matchable qw( ph );

use lib 't/lib';
use T1;
use T2;

my $t1 = T1->new( val => 'foo' );

eq_or_diff( $t1->_equiv_one( 2,     2 ),     2,     'numbers equate cleanly' );
eq_or_diff( $t1->_equiv_one( 'foo', 'foo' ), 'foo', 'strings equate cleanly' );

my $ret = $t1->_equiv_one( $t1, $t1 );
eq_or_diff( $ret, $t1, 't1s equate cleanly' );
$ret->{'val'} = 'bar';
eq_or_diff( $t1->val, 'foo', 't1s clone cleanly' );

my ( %t1, %t2 );

my $phbaz = ph(baz);
eq_or_diff( $t1->_equiv_one( $phbaz, 1, \%t1 ), $t1->_equiv_placeholder( $phbaz, 1, \%t2 ),
  'placeholders are handled correctly' );
eq_or_diff( \%t1, \%t2, 'placeholders are set correctly' );
my $ret1 = $t1->_equiv_one( [ $t1, $t1 ], [ $t1, $t1 ] );
my $ret2 = $t1->_equiv_array( [ $t1, $t1 ], [ $t1, $t1 ] );
eq_or_diff( $ret1, $ret2, 'arrays are handled correctly' );
$ret1->[0]->{'val'} = 'bar';
$ret2->[0]->{'val'} = 'bar';
eq_or_diff( $t1->val, 'foo', 'clones cleanly' );
eq_or_diff(
  $t1->_equiv_one( [ qw(a b c d), $t1 ], [ qw(a b c d), $t1 ] ),
  $t1->_equiv_array( [ qw(a b c d), $t1 ], [ qw(a b c d), $t1 ] ),
  'arrays with t1 are handled correctly'
);
eq_or_diff(
  $t1->_equiv_one( { qw(a b c), $t1 }, { qw(a b c), $t1 } ),
  $t1->_equiv_hash( { qw(a b c), $t1 }, { qw(a b c), $t1 } ),
  'hashes with t1 are handled correctly'
);
eq_or_diff( $t1->_equiv_one( {}, $t1 ), undef, 'disjoint types are undef(left)' );
eq_or_diff( $t1->_equiv_one( $t1, {} ), undef, 'disjoint types are undef(right)' );

my %ph = ();

$ret = $t1->_equiv_one( T1->new( val => [ ph(val1), ph(val2) ] ), T1->new( val => [ 6, 12 ] ), \%ph );
eq_or_diff( $ret, T1->new( val => [ 6, 12 ] ), 'placeholders at sublevels are processed properly' );
eq_or_diff( \%ph, { val1 => 6, val2 => 12 }, 'placeholders at sublevels are set properly' );
%ph  = ();
$ret = $t1->_equiv_one(
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
  \%ph
);
%ph = ();
eq_or_diff(
  $ret,
  T1->new( val => [ { a => \%t2, b => \%t1 } ] ),
  'placeholders at sublevels on both sides are processed properly'
);

eq_or_diff( \%ph, { foobar => \%t1, bazfoo => \%t2 }, 'placeholders at sublevels on both sides are set correctly' );

my $t2    = T2->new();
my $phfoo = ph(foo);
$t2->_equiv_one( $t1, $phfoo, \%ph );
eq_or_diff( \%ph, { foo => $t1 }, 'placeholders are set correctly' );
throws_ok {
  $t2->_equiv_one( $t1, $phfoo, \%ph );
}
qr/Placeholder 'foo' already exists. Refusing to overwrite/;
throws_ok {
  $t2->_equiv_one( sub { }, {} );
}
qr/We cannot handle any non-blessed ref types other than ARRAY or HASH/;

done_testing;
