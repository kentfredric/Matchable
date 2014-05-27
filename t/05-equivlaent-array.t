use Test::Most;

use lib 't/lib';
use T1;
my $t1 = T1->new( val => 'foo' );

# TODO: Nested placeholders
eq_or_diff( $t1->_equiv_array( [ 1, 2, 3 ], [ 1, 2, 3 ] ), [ 1, 2, 3 ], 'integers equate cleanly' );
eq_or_diff( $t1->_equiv_array( [qw(a b c)], [qw(a b c)] ), [qw(a b c)], 'strings equate cleanly' );
eq_or_diff( $t1->_equiv_array( {}, [] ), undef, 'when one argument is a hashref, undef (left)' );
eq_or_diff( $t1->_equiv_array( [], {} ), undef, 'when one argument is a hashref, undef (right)' );
eq_or_diff( $t1->_equiv_array( [ 1 .. 3 ], [ 4 .. 6 ] ), undef, 'unequivalent ARRAYs are undef' );

my $ret = $t1->_equiv_array( [ $t1, $t1 ], [ $t1, $t1 ] );
eq_or_diff( $ret, [ $t1, $t1 ], 't1s equate cleanly' );

$ret->[0]->{'val'} = 'bar';
eq_or_diff( $t1->val, 'foo', 't1s clone cleanly' );

done_testing;
