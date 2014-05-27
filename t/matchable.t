use Test::Most;

use Matchable qw( ph isa_ph isa_ph_or );
use Matchable::Placeholder;
use Scalar::Util 'blessed';

use lib 't/lib';
use T1;
use T2;

my $phfoo = ph(foo);
my $phbar = ph(bar);

# isa_ph
eq_or_diff( isa_ph('foo'),  undef, "isa_ph: strings are undef");
eq_or_diff( isa_ph(123),    undef, "isa_ph: numbers are undef");
eq_or_diff( isa_ph(qr//),   undef, "isa_ph: regexrefs are undef");
eq_or_diff( isa_ph($phfoo), 1,     "isa_ph: placeholders are 1");
my @classes = qw(Foo Bar Baz T1 Quux);
eq_or_diff( isa_ph_or('foo'            ), undef, "isa_ph_or: basic types are undef");
eq_or_diff( isa_ph_or($phfoo           ), 1,     "isa_ph_or: matchables are 1");
eq_or_diff( isa_ph_or(T1->new          ), undef, "isa_ph_or: empty class lists return undef for non-matchables");
eq_or_diff( isa_ph_or($phfoo           ), 1,     "isa_ph_or: empty class lists return 1 for matchables");
eq_or_diff( isa_ph_or(T1->new, @classes), 1,     "isa_ph_or: the whole list is searched");

# _equiv_placeholder

my $t1 = T1->new(val=>'foo');
my %ph;
my $phbaz = ph(baz);
my $phquux = ph(quux);
my $ret = $t1->_equiv_placeholder($phfoo,$t1,\%ph);
eq_or_diff($ret,$t1,"_equiv_placeholder: complex classes are returned");
$ret->{'val'} = "bar";
eq_or_diff($t1->val,'foo',"_equiv_placeholder: clones cleanly");
$ret = $t1->_equiv_placeholder(12,$phbar,\%ph),
eq_or_diff($ret, 12,"_equiv_placeholder: numeric data are returned");
eq_or_diff(\%ph,{foo=>$t1,bar=>12},"_equiv_placeholder: placeholders have been set correctly");
%ph = ();
eq_or_diff($t1->_equiv_placeholder($phfoo,[qw(foo bar)],\%ph),[qw(foo bar)],"_equiv_placeholder: ARRAY refs are looped (left)");
eq_or_diff($t1->_equiv_placeholder([qw(bar foo)],$phbar,\%ph),[qw(bar foo)],"_equiv_placeholder: ARRAY refs are looped (right)");
eq_or_diff(\%ph,{foo=>[qw(foo bar)],bar =>[qw(bar foo)]},"_equiv_placeholder: placeholders have been set correctly");
%ph = ();
eq_or_diff($t1->_equiv_placeholder($phfoo,{qw(foo bar baz quux)},\%ph),{qw(foo bar baz quux)},"_equiv_placeholder: HASH refs are looped (left)");
eq_or_diff($t1->_equiv_placeholder({qw(bar foo quux baz)},$phbar,\%ph),{qw(bar foo quux baz)},"_equiv_placeholder: HASH refs are looped (right)");
eq_or_diff(\%ph,{foo=>{qw(foo bar baz quux)},bar =>{qw(bar foo quux baz)}},"_equiv_placeholder: placeholders have been set correctly");
my $t2 = T2->new;
throws_ok {
  $t2->_equiv_placeholder($t2,$phfoo);
} qr/We don't support objects we can't clone\(\)/;
throws_ok {
  $t2->_equiv_placeholder($t1,$phfoo,\%ph);
} qr/Placeholder 'foo' already exists. Refusing to overwrite/;
throws_ok {
  $t1->_equiv_placeholder($phfoo,$phbar);
} qr/We expect ONE placeholder in _equiv_placeholder. Two or zero will not work/;
throws_ok {
  $t1->_equiv_placeholder(1,2);
} qr/We expect ONE placeholder in _equiv_placeholder. Two or zero will not work/;

# _equiv_array

# TODO: Nested placeholders
eq_or_diff($t1->_equiv_array([1,2,3],     [1,2,3]),     [1,2,3],     "_equiv_array: integers equate cleanly");
eq_or_diff($t1->_equiv_array([qw(a b c)], [qw(a b c)]), [qw(a b c)], "_equiv_array: strings equate cleanly");
eq_or_diff($t1->_equiv_array({},          []),          undef,       "_equiv_array: when one argument is a hashref, undef (left)");
eq_or_diff($t1->_equiv_array([],          {}),          undef,       "_equiv_array: when one argument is a hashref, undef (right)");
eq_or_diff($t1->_equiv_array([1..3],      [4..6]),      undef,       "_equiv_array: unequivalent ARRAYs are undef");
$ret = $t1->_equiv_array([$t1,$t1],[$t1,$t1]);
eq_or_diff($ret, [$t1,$t1], "_equiv_array: t1s equate cleanly");
$ret->[0]->{'val'} = 'bar';
eq_or_diff($t1->val, 'foo', "_equiv_array: t1s clone cleanly");
# _equiv_hash
eq_or_diff($t1->_equiv_hash(+{qw(a b c d)},+{qw(a b c d)}),+{qw(a b c d)}, "_equiv_hash: strings equate cleanly");
eq_or_diff($t1->_equiv_hash(+{a => $t1, b => $t1},+{a => $t1, b => $t1}),+{a => $t1, b => $t1}, "_equiv_hash: mixed types inc t1 equate cleanly");
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
