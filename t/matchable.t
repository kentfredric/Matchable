use Test::Most;

use Matchable qw( ph isa_ph isa_ph_or );
use Matchable::Placeholder;
use Scalar::Util 'blessed';

use lib 't/lib';
use T1;
use T2;

my $phfoo = ph(foo);
my $phbar = ph(bar);
my $phbaz = ph(baz);
my $t1    = T1->new( val => 'foo' );
my $ret;

# _equiv_array

my %ph;

# _equiv_one
eq_or_diff($t1->_equiv_one(2,2),2, "_equiv_one: numbers equate cleanly");
eq_or_diff($t1->_equiv_one("foo","foo"),"foo", "_equiv_one: strings equate cleanly");

$ret = $t1->_equiv_one($t1,$t1);
eq_or_diff($ret,$t1, "_equiv_one: t1s equate cleanly");
$ret->{'val'} = 'bar';
eq_or_diff($t1->val,'foo', "_equiv_one: t1s clone cleanly");
my (%t1, %t2);
eq_or_diff($t1->_equiv_one($phbaz,1,\%t1),$t1->_equiv_placeholder($phbaz,1,\%t2),"_equiv_one: placeholders are handled correctly");
eq_or_diff(\%t1, \%t2, "_equiv_one: placeholders are set correctly");
my $ret1 = $t1->_equiv_one([$t1,$t1],[$t1,$t1]);
my $ret2 = $t1->_equiv_array([$t1,$t1],[$t1,$t1]);
eq_or_diff($ret1, $ret2, "_equiv_one: arrays are handled correctly");
$ret1->[0]->{'val'} = "bar";
$ret2->[0]->{'val'} = "bar";
eq_or_diff($t1->val,'foo', "_equiv_one: clones cleanly");
eq_or_diff($t1->_equiv_one([qw(a b c d), $t1],[qw(a b c d), $t1]),
           $t1->_equiv_array([qw(a b c d), $t1],[qw(a b c d), $t1]), "_equiv_one: arrays with t1 are handled correctly");
eq_or_diff($t1->_equiv_one({qw(a b c), $t1},{qw(a b c), $t1}),
           $t1->_equiv_hash({qw(a b c), $t1},{qw(a b c), $t1}), "_equiv_one: hashes with t1 are handled correctly");
eq_or_diff($t1->_equiv_one({},$t1),undef, "_equiv_one: disjoint types are undef (left)");
eq_or_diff($t1->_equiv_one($t1,{}),undef, "_equiv_one: disjoint types are undef (right)");
%ph = ();
$ret = $t1->_equiv_one(T1->new(val => [ph(val1), ph(val2)]), T1->new(val => [6,12]), \%ph);
eq_or_diff($ret, T1->new(val => [6,12]), "_equiv_one: placeholders at sublevels are processed properly");
eq_or_diff(\%ph, {val1 => 6, val2 => 12}, "_equiv_one: placeholders at sublevels are set properly");
%ph = ();
$ret = $t1->_equiv_one(
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
  \%ph
);
%ph = ();
eq_or_diff($ret, T1->new(val => [{a=>\%t2,b=>\%t1}]), "_equiv_one: placeholders at sublevels on both sides are processed properly");
eq_or_diff(\%ph, {foobar => \%t1, bazfoo => \%t2},    "_equiv_one: placeholders at sublevels on both sides are set correctly");

my $t2 = T2->new();
$t2->_equiv_one($t1,$phfoo,\%ph);
eq_or_diff(\%ph,{foo=>$t1}, "_equiv_one: placeholders are set correctly");
throws_ok {
  $t2->_equiv_one($t1,$phfoo,\%ph);
} qr/Placeholder 'foo' already exists. Refusing to overwrite/;
throws_ok {
  $t2->_equiv_one(sub {},{});
} qr/We cannot handle any non-blessed ref types other than ARRAY or HASH/;
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
