use Test::Most;

use Matchable qw( ph isa_ph );

my $phfoo = ph(foo);

# isa_ph
eq_or_diff( isa_ph('foo'),  undef, 'strings are undef' );
eq_or_diff( isa_ph(123),    undef, 'numbers are undef' );
eq_or_diff( isa_ph(qr//),   undef, 'regexrefs are undef' );
eq_or_diff( isa_ph($phfoo), 1,     'placeholders are 1' );

done_testing;
