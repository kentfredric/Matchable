use Test::Most;

use Matchable qw( ph );
use Scalar::Util 'blessed';

# ph
my $phfoo = ph(foo);
eq_or_diff( blessed($phfoo), 'Matchable::Placeholder', 'foo is a placeholder' );
eq_or_diff( $phfoo->name, 'foo', "foo's name is foo" );

my $phbar = ph(bar);
eq_or_diff( blessed($phbar), 'Matchable::Placeholder', 'bar is a placeholder' );
eq_or_diff( $phbar->name, 'bar', "bar's name is bar" );

done_testing;
