use Test::Most;

use Matchable qw( ph );

use lib 't/lib';
use T1;

my $t1    = T1->new( val => 'foo' );
my $ret;

my %ph;
my ( %t1, %t2 );

# equiv
my $ph;
($ret, $ph) = $t1->equiv(
  T1->new(val => [
    {
      a => \%t2,
      b => ph(foobar),
    }
  ]),
  T1->new(val => [
    {
      a => ph(bazfoo),
      b => \%t1,
    }
  ]),
);
eq_or_diff($ret, T1->new(val => [{a=>\%t2,b=>\%t1}]), "equiv: placeholders at sublevels on both sides are processed properly");
eq_or_diff($ph,  {foobar => \%t1, bazfoo => \%t2},    "equiv: placeholders at sublevels on both sides are set correctly");
# - it basically punts the list of attributes to _equiv_one

# against/match
my $leaky;
eq_or_diff(T1->new(val=>'foo')->against(sub{
  T1->new(val => 'bar')->match(sub {
    # Using $_ to prove that we can get the current item in the subref
    $leaky .= 'bar'.$_->val;
  });
  T1->new(val => 'foo')->match(sub {
    $leaky .= 'foo'.$_->val;
  });
  # If it didn't fall out, it'll add this again, and the tests will fail
  T1->new(val => 'foo')->match(sub {
    $leaky .= 'foo'.$_->val;
  });
}),'foofoo', "match/against: The correct function was called, execution was terminated after");

done_testing;
