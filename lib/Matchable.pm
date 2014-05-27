package Matchable;

# ABSTRACT: Functional language-like pattern matching, perl Moo style

use Moo::Role;

no autovivification;

use Carp qw(carp croak);
use Safe::Isa;
use Scalar::Util 'blessed';
use Sub::Exporter -setup => {
  exports => [qw(ph isa_ph isa_ph_or)],
};

requires '_compare';

sub against {
  my ($self, $cb, $return) = @_;
  local $_ = $self;
  local *escape = sub { $return = shift; goto done; };
  $return = $cb->();
 done:
  $return;
}

sub match {
  my ($self, $cb) = @_;
  return undef unless $self->equiv($_);
  local $_ = $self;
  escape($cb->());
}

sub _equiv_placeholder {
  my ($self, $left, $right, $placeholders) = @_;
  croak("We expect ONE placeholder in _equiv_placeholder. Two or zero will not work") unless (grep {isa_ph($_)} ($left,$right)) == 1;
  my ($real,$fake);
  if (isa_ph($left)) {
    ($real, $fake) = ($right, $left);
  } else {
    ($real, $fake) = ($left, $right);
  }
  croak("Placeholder '" . $fake->name . "' already exists. Refusing to overwrite")
    if defined ($placeholders->{$fake->name});
  $placeholders->{$fake->name} = $real;
  if (blessed($real)) {
    return $real->clone if $real->$_can('clone');
    croak("We don't support objects we can't clone()");
  }
  if (ref($real)) {
    croak("We don't support non-blessed ref-types other than ARRAY and HASH") if (ref($real) !~ /^(?:ARRAY|HASH)$/);
    my $method = "_equiv_" . lc(ref($real));
    my $ret = $self->$method($real,$real,$placeholders);
    return undef unless $ret;
    return $ret;
  }
  $real
}
use Carp qw(cluck);
sub _equiv_array {
  my ($self, $left, $right, $placeholders) = @_;
  return undef unless ref($left) eq 'ARRAY' && ref($right) eq 'ARRAY';
  return undef unless @$left == @$right;
  my @new;
  my $i = 0;
  foreach my $l (@$left) {
    my $r = $right->[$i];
    my $ret = $self->_equiv_one($l,$r,$placeholders);
    return undef unless defined $ret;
    push @new, $ret;
    $i++;
  }
  [@new];
}
sub _equiv_hash {
  my ($self, $left, $right, $placeholders) = @_;
  return undef unless ref($left) eq 'HASH' && ref($right) eq 'HASH';
  return undef unless (join(",", sort keys %$left)) eq (join(",", sort keys %$right));
  my %new;
  foreach my $k (keys %$left) {
    my ($l, $r) = ($left->{$k}, $right->{$k});
    my $ret = $self->_equiv_one($l,$r, $placeholders);
    return undef unless defined $ret;
    $new{$k} = $ret;
  }
  return {%new};
}

sub _equiv_one {
  my ($self, $left, $right, $placeholders) = @_;
  return undef unless defined($left) eq defined($right);
  return $self->_equiv_placeholder($left,$right,$placeholders) if isa_ph($left) || isa_ph($right);
  if (blessed($left)) {
    # It doesn't make sense if we're handed a *less* specific class
    return undef unless blessed($right);
    return undef unless $left->$_isa(blessed($right));
    return undef unless $left->can('equiv');
    # This should auto-merge the placeholders. We assume the object has implemented equiv correctly.
    my ($ret, $ph) = $left->equiv($right,$placeholders);
    return undef unless $ret;
    return $ret;
  } elsif (ref($left)) {
    return $self->_equiv_array($left,$right,$placeholders) if ref($left) eq 'ARRAY';
    return $self->_equiv_hash($left,$right,$placeholders) if ref($left) eq 'HASH';
    croak("We cannot handle any non-blessed ref types other than ARRAY or HASH");
  }
  return undef unless "$left" eq "$right";
  $left;
}

sub equiv {
  my ($self,$other,$placeholders) = @_;
  $placeholders ||= {};
  my $new = $self->clone;
  my @compare = @{$self->_compare};
  foreach my $a (@compare) {
    my $ret = $self->_equiv_one($self->$a, $other->$a, $placeholders);
    return undef unless $ret;
    $new->{$a} = $ret;
  }
  ($new, $placeholders);
}

sub ph (*;$) {
  my ($name, $isa) = @_;
  $name =~ s/(.+::)(?=[a-z]+)$//i;
  require Matchable::Placeholder;
  Matchable::Placeholder->new(name => $name, isa => $isa);
}

sub isa_ph {
  shift->$_isa("Matchable::Placeholder") || undef;
}
sub isa_ph_or {
  my ($item,@classes) = @_;
  return 1 if isa_ph($item);
  return undef unless @classes;
  foreach my $c (@classes) {
    return 1 if $item->$_isa($c)
  }
  return;
}

1
__END__

=head1 SYNOPSIS

    package Foo;
    use Safe::Isa;
    use Moo;
    with 'Matchable';
    has val => (
      is => 'ro',
    );
    sub equiv {
      my ($self, $other) = @_;
      return unless $other->$_isa('Foo');
      $self->val eq $other->val;
    }
    1

And over in your main file:

    use Foo;
    Foo->new(val=>'foo')->against(sub {
      Foo->new(val=>'bar')->match(sub {
        print "val is bar";
      });
      # ->against sets $_ to the thing being matched against
      $_->match(sub {
        # And match sets $_ to the thing that successfully matched
        print "val is " . $_->val; # val is foo
      });
    });

Here's a nice way to tidy code up:

    package Types;Thi
    use Exporter;
    use Foo;
    our @ISA = qw(Exporter);
    @EXPORT_OK = qw(Foo);
    sub Foo {
      my ($self, $val) = @_;
      Foo->new(val => $val)
    }
    1

Then the main becomes:

    use Types 'Foo';
    Foo('foo')->against(sub {
      Foo('bar')->match(sub {
        print "val is bar";
      });
      $_->match(sub {
        print "val is " . $_->val; # val is foo
      });
    });

=head1 GOTCHAS

Watch that both against and match modify $_. I can see that it could make for some confusing bugs.

=head1 PLANS

It would be nice to get placeholders working at some point, They'd work like this in an idealised world, but I haven't thought about how to achieve it. And I probably don't want to abuse the placeholder() function like this because it's an icky way of designing things.

    use Matchable 'P';
    use Types 'Foo';
    Foo('bar')->against(sub {
      Foo(P("val"))->match(sub {
        print "Got " . placeholder->val; # Got bar
      })
    });

