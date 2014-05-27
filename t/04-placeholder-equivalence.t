use Test::Most;

use Matchable qw( ph );

use lib 't/lib';
use T1;
use T2;

my $phfoo  = ph(foo);
my $phbar  = ph(bar);
my $phbaz  = ph(baz);
my $phquux = ph(quux);

my $t1 = T1->new( val => 'foo' );
my %ph;
my $ret;

$ret = $t1->_equiv_placeholder( $phfoo, $t1, \%ph );
eq_or_diff( $ret, $t1, 'complex classes are returned' );
$ret->{'val'} = 'bar';
eq_or_diff( $t1->val, 'foo', 'clones cleanly' );
$ret = $t1->_equiv_placeholder( 12, $phbar, \%ph );
eq_or_diff( $ret, 12, 'numeric data are returned' );

eq_or_diff( \%ph, { foo => $t1, bar => 12 }, 'placeholders have been set correctly' );
%ph = ();
eq_or_diff( $t1->_equiv_placeholder( $phfoo, [qw(foo bar)], \%ph ), [qw(foo bar)], 'ARRAY refs are looped (left)' );
eq_or_diff( $t1->_equiv_placeholder( [qw(bar foo)], $phbar, \%ph ), [qw(bar foo)], 'ARRAY refs are looped (right)' );
eq_or_diff( \%ph, { foo => [qw(foo bar)], bar => [qw(bar foo)] }, 'placeholders have been set correctly' );
%ph = ();
eq_or_diff( $t1->_equiv_placeholder( $phfoo, {qw(foo bar baz quux)}, \%ph ),
  {qw(foo bar baz quux)}, 'HASH refs are looped (left)' );
eq_or_diff( $t1->_equiv_placeholder( {qw(bar foo quux baz)}, $phbar, \%ph ),
  {qw(bar foo quux baz)}, 'HASH refs are looped (right)' );
eq_or_diff( \%ph, { foo => {qw(foo bar baz quux)}, bar => {qw(bar foo quux baz)} }, 'placeholders have been set correctly' );

my $t2 = T2->new;

throws_ok {
  $t2->_equiv_placeholder( $t2, $phfoo );
}
qr/We don't support objects we can't clone\(\)/;

throws_ok {
  $t2->_equiv_placeholder( $t1, $phfoo, \%ph );
}
qr/Placeholder 'foo' already exists. Refusing to overwrite/;

throws_ok {
  $t1->_equiv_placeholder( $phfoo, $phbar );
}
qr/We expect ONE placeholder in _equiv_placeholder. Two or zero will not work/;

throws_ok {
  $t1->_equiv_placeholder( 1, 2 );
}
qr/We expect ONE placeholder in _equiv_placeholder. Two or zero will not work/;

done_testing;
