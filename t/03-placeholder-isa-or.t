use Test::Most;

use Matchable qw( ph isa_ph_or );

use lib 't/lib';
use T1;

my $phfoo = ph(foo);

my @classes = qw(Foo Bar Baz T1 Quux);

eq_or_diff( isa_ph_or('foo'),     undef, 'basic types are undef' );
eq_or_diff( isa_ph_or($phfoo),    1,     'matchables are 1' );
eq_or_diff( isa_ph_or( T1->new ), undef, 'empty class lists return undef for non-matchables' );
eq_or_diff( isa_ph_or($phfoo),    1,     'empty class lists return 1 for matchables' );
eq_or_diff( isa_ph_or( T1->new, @classes ), 1, 'the whole list is searched' );

done_testing;
