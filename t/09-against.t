use Test::Most;

use lib 't/lib';
use T1;

# against/match
my $leaky;
eq_or_diff(
  T1->new( val => 'foo' )->against(
    sub {
      T1->new( val => 'bar' )->match(
        sub {
          # Using $_ to prove that we can get the current item in the subref
          $leaky .= 'bar' . $_->val;
        }
      );
      T1->new( val => 'foo' )->match(
        sub {
          $leaky .= 'foo' . $_->val;
        }
      );

      # If it didn't fall out, it'll add this again, and the tests will fail
      T1->new( val => 'foo' )->match(
        sub {
          $leaky .= 'foo' . $_->val;
        }
      );
    }
  ),
  'foofoo',
  'The correct function was called, execution was terminated after'
);

done_testing;
